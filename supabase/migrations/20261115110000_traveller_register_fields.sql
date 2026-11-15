-- ============================================================================
-- Registro de viajeros (RD 933/2021) — 1/3: campos legales del huésped
-- ----------------------------------------------------------------------------
-- · `guests`: nombre y apellidos por separado, número de soporte, domicilio
--   habitual y teléfono fijo. `phone` sigue siendo el MÓVIL.
-- · `register_format`: 'legacy' (todo lo existente y lo que creen versiones
--   antiguas de la app) | 'rd933_v1' (formulario nuevo). Los registros
--   antiguos NO se separan ni se completan: su `full_name` queda intacto.
-- · `full_name` pasa a generarse solo cuando hay `first_name`, para que
--   listados, emails, chat y PDF sigan funcionando sin cambios.
-- · `booking_guests`: adulto responsable y parentesco de los menores. El
--   responsable tiene que pertenecer a la MISMA reserva (FK compuesta).
-- · Validadores puros (sin SECURITY DEFINER) de edad y DNI/NIE.
--
-- No se modifica ninguna RPC existente. Solo añade columnas y funciones.
-- Rollback: 20261115110000_traveller_register_fields.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) guests: campos nuevos
-- ----------------------------------------------------------------------------
ALTER TABLE public.guests
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name_1 TEXT,
  ADD COLUMN IF NOT EXISTS last_name_2 TEXT,
  ADD COLUMN IF NOT EXISTS document_support_number TEXT,
  ADD COLUMN IF NOT EXISTS residence_address TEXT,
  ADD COLUMN IF NOT EXISTS residence_city TEXT,
  ADD COLUMN IF NOT EXISTS residence_postal_code TEXT,
  ADD COLUMN IF NOT EXISTS residence_country TEXT,
  ADD COLUMN IF NOT EXISTS landline_phone TEXT,
  ADD COLUMN IF NOT EXISTS register_format TEXT NOT NULL DEFAULT 'legacy',
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE public.guests DROP CONSTRAINT IF EXISTS guests_register_format_check;
ALTER TABLE public.guests
  ADD CONSTRAINT guests_register_format_check
  CHECK (register_format IN ('legacy', 'rd933_v1'));

-- Países en ISO 3166-1 alfa-3 (pendiente de contrastar con los XSD de SES).
-- Solo se restringe la columna nueva: `nationality` la siguen escribiendo
-- versiones antiguas de la app y se valida en save_traveller_guest().
ALTER TABLE public.guests DROP CONSTRAINT IF EXISTS guests_residence_country_check;
ALTER TABLE public.guests
  ADD CONSTRAINT guests_residence_country_check
  CHECK (residence_country IS NULL OR residence_country ~ '^[A-Z]{3}$');

COMMENT ON COLUMN public.guests.phone IS 'Teléfono MÓVIL del huésped.';
COMMENT ON COLUMN public.guests.landline_phone IS 'Teléfono fijo del huésped.';
COMMENT ON COLUMN public.guests.document_support_number IS
  'Número de soporte del documento (DNI: IDESP, TIE/NIE: IXESP). Solo DNI y NIE.';
COMMENT ON COLUMN public.guests.register_format IS
  'legacy = registro anterior al RD 933 en la app (full_name sin separar) | rd933_v1 = formulario nuevo';
COMMENT ON COLUMN public.guests.age IS
  'OBSOLETO para obligaciones legales: la edad se calcula con birth_date y la fecha de entrada (traveller_age_on).';

-- ----------------------------------------------------------------------------
-- 2) full_name derivado + updated_at
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_guests_build_full_name()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.first_name IS NOT NULL AND btrim(NEW.first_name) <> '' THEN
    NEW.full_name := concat_ws(' ',
      NULLIF(btrim(NEW.first_name), ''),
      NULLIF(btrim(NEW.last_name_1), ''),
      NULLIF(btrim(NEW.last_name_2), ''));
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guests_build_full_name ON public.guests;
CREATE TRIGGER trg_guests_build_full_name
  BEFORE INSERT OR UPDATE OF first_name, last_name_1, last_name_2, full_name
  ON public.guests
  FOR EACH ROW EXECUTE FUNCTION public.trg_guests_build_full_name();

DROP TRIGGER IF EXISTS trg_guests_updated_at ON public.guests;
CREATE TRIGGER trg_guests_updated_at
  BEFORE UPDATE ON public.guests
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ----------------------------------------------------------------------------
-- 3) booking_guests: menores y adulto responsable
-- ----------------------------------------------------------------------------
ALTER TABLE public.booking_guests
  ADD COLUMN IF NOT EXISTS responsible_guest_id UUID,
  ADD COLUMN IF NOT EXISTS relationship TEXT;

-- Códigos internos; el mapeo a los códigos oficiales de SES se hará cuando
-- se disponga de los XSD.
ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_relationship_check;
ALTER TABLE public.booking_guests
  ADD CONSTRAINT booking_guests_relationship_check
  CHECK (relationship IS NULL OR relationship IN (
    'parent', 'grandparent', 'sibling', 'uncle_aunt', 'cousin',
    'legal_guardian', 'other'
  ));

ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_responsible_not_self;
ALTER TABLE public.booking_guests
  ADD CONSTRAINT booking_guests_responsible_not_self
  CHECK (responsible_guest_id IS NULL OR responsible_guest_id <> guest_id);

-- El responsable debe estar en la misma reserva. Si se le quita de la
-- reserva, el menor se queda sin responsable (y el registro, incompleto).
ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_responsible_same_booking_fkey;
ALTER TABLE public.booking_guests
  ADD CONSTRAINT booking_guests_responsible_same_booking_fkey
  FOREIGN KEY (booking_id, responsible_guest_id)
  REFERENCES public.booking_guests (booking_id, guest_id)
  ON DELETE SET NULL (responsible_guest_id);

CREATE INDEX IF NOT EXISTS idx_booking_guests_responsible
  ON public.booking_guests (booking_id, responsible_guest_id)
  WHERE responsible_guest_id IS NOT NULL;

COMMENT ON COLUMN public.booking_guests.responsible_guest_id IS
  'Adulto de la misma reserva responsable del menor.';
COMMENT ON COLUMN public.booking_guests.relationship IS
  'Parentesco del menor con el responsable: parent | grandparent | sibling | uncle_aunt | cousin | legal_guardian | other';

-- ----------------------------------------------------------------------------
-- 4) Validadores puros (IMMUTABLE, sin acceso a datos)
-- ----------------------------------------------------------------------------
-- Edad cumplida en una fecha (la de entrada de la reserva)
CREATE OR REPLACE FUNCTION public.traveller_age_on(p_birth_date DATE, p_on DATE)
 RETURNS INTEGER
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT CASE
    WHEN p_birth_date IS NULL OR p_on IS NULL THEN NULL
    ELSE date_part('year', age(p_on, p_birth_date))::int
  END;
$function$;

-- Quita espacios, guiones y puntos y pasa a mayúsculas
CREATE OR REPLACE FUNCTION public.traveller_normalize_doc(p_value TEXT)
 RETURNS TEXT
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
  SELECT NULLIF(upper(regexp_replace(COALESCE(p_value, ''), '[\s\.\-]', '', 'g')), '');
$function$;

-- DNI: 8 dígitos + letra de control. NIE: X/Y/Z + 7 dígitos + letra.
-- Devuelve NULL para tipos sin formato español fijo (pasaporte, otro).
CREATE OR REPLACE FUNCTION public.is_valid_spanish_id(p_type TEXT, p_number TEXT)
 RETURNS BOOLEAN
 LANGUAGE plpgsql
 IMMUTABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  v_value   TEXT := public.traveller_normalize_doc(p_number);
  v_digits  TEXT;
  c_letters CONSTANT TEXT := 'TRWAGMYFPDXBNJZSQVHLCKE';
BEGIN
  IF p_type = 'dni' THEN
    IF v_value IS NULL OR v_value !~ '^[0-9]{8}[A-Z]$' THEN RETURN false; END IF;
    v_digits := substr(v_value, 1, 8);
  ELSIF p_type = 'nie' THEN
    IF v_value IS NULL OR v_value !~ '^[XYZ][0-9]{7}[A-Z]$' THEN RETURN false; END IF;
    v_digits := translate(substr(v_value, 1, 1), 'XYZ', '012') || substr(v_value, 2, 7);
  ELSE
    RETURN NULL;
  END IF;

  RETURN substr(c_letters, (v_digits::bigint % 23)::int + 1, 1) = substr(v_value, 9, 1);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.traveller_age_on(DATE, DATE) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.traveller_normalize_doc(TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.is_valid_spanish_id(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.traveller_age_on(DATE, DATE) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.traveller_normalize_doc(TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_valid_spanish_id(TEXT, TEXT) TO authenticated, service_role;

COMMIT;
