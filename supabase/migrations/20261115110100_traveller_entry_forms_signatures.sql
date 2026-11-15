-- ============================================================================
-- Registro de viajeros (RD 933/2021) — 2/3: partes de entrada y firmas
-- ----------------------------------------------------------------------------
-- traveller_entry_forms
--   Un parte por huésped de 14 años o más y reserva. Guarda una COPIA
--   CONGELADA (`snapshot`) de los datos firmados (los suyos y los de los
--   menores de 14 a su cargo) y su hash SHA-256. Si los datos cambian después
--   de firmar, el parte se marca `superseded_at` y hay que volver a firmar:
--   la fila antigua se conserva como evidencia.
--
-- guest_signatures
--   Una firma por parte. La FK compuesta (entry_form_id, booking_id, guest_id)
--   impide que la firma de un huésped quede asociada al parte de otro.
--
-- Ambas tablas son de solo lectura para la app: se escriben exclusivamente
-- con sign_traveller_entry_form() (migración 3/3). Un trigger impide
-- modificar el contenido firmado incluso con privilegios.
--
-- No se tocan checkins.signature_svg ni el flujo actual.
-- Rollback: 20261115110100_traveller_entry_forms_signatures.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Partes de entrada
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.traveller_entry_forms (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id      UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  guest_id        UUID NOT NULL REFERENCES public.guests(id) ON DELETE RESTRICT,
  property_id     UUID NOT NULL,
  form_version    TEXT NOT NULL,
  snapshot        JSONB NOT NULL,
  snapshot_sha256 TEXT NOT NULL CHECK (snapshot_sha256 ~ '^[0-9a-f]{64}$'),
  pdf_path        TEXT,
  created_by      UUID,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  superseded_at   TIMESTAMPTZ,
  CONSTRAINT traveller_entry_forms_id_booking_guest_key UNIQUE (id, booking_id, guest_id)
);

-- Solo un parte vigente por huésped y reserva
CREATE UNIQUE INDEX IF NOT EXISTS uq_traveller_entry_forms_active
  ON public.traveller_entry_forms (booking_id, guest_id)
  WHERE superseded_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_traveller_entry_forms_guest
  ON public.traveller_entry_forms (guest_id);

COMMENT ON TABLE public.traveller_entry_forms IS
  'Partes de entrada del registro de viajeros (RD 933/2021). Se conservan 3 años desde el fin de la estancia.';
COMMENT ON COLUMN public.traveller_entry_forms.snapshot IS
  'Copia congelada de los datos firmados: huésped, menores de 14 a su cargo, reserva y establecimiento.';
COMMENT ON COLUMN public.traveller_entry_forms.superseded_at IS
  'Los datos cambiaron después de firmar: este parte deja de estar vigente y se firma uno nuevo.';

-- ----------------------------------------------------------------------------
-- 2) Firmas
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.guest_signatures (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  entry_form_id     UUID NOT NULL,
  booking_id        UUID NOT NULL,
  guest_id          UUID NOT NULL,
  signature_version TEXT NOT NULL,
  signature_svg     TEXT NOT NULL CHECK (length(signature_svg) BETWEEN 20 AND 500000),
  signature_sha256  TEXT NOT NULL CHECK (signature_sha256 ~ '^[0-9a-f]{64}$'),
  signed_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  signed_by_user_id UUID,
  signed_via        TEXT NOT NULL CHECK (signed_via IN ('guest_app', 'staff_device')),
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT guest_signatures_entry_form_key UNIQUE (entry_form_id),
  CONSTRAINT guest_signatures_entry_form_fkey
    FOREIGN KEY (entry_form_id, booking_id, guest_id)
    REFERENCES public.traveller_entry_forms (id, booking_id, guest_id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_guest_signatures_booking
  ON public.guest_signatures (booking_id);

COMMENT ON TABLE public.guest_signatures IS
  'Firma del parte de entrada. Distinta del consentimiento RGPD. Una firma por parte; no reutilizable.';
COMMENT ON COLUMN public.guest_signatures.signature_version IS
  'Igual que traveller_entry_forms.form_version: versión del texto del parte firmado.';
COMMENT ON COLUMN public.guest_signatures.signed_by_user_id IS
  'auth.uid() de quien gestionó la firma (huésped anónimo o staff).';

-- ----------------------------------------------------------------------------
-- 3) Inmutabilidad
-- ----------------------------------------------------------------------------
-- Parte: solo se permite marcarlo como sustituido o adjuntarle el PDF (una vez)
CREATE OR REPLACE FUNCTION public.trg_traveller_entry_forms_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.id              IS DISTINCT FROM OLD.id
  OR NEW.booking_id      IS DISTINCT FROM OLD.booking_id
  OR NEW.guest_id        IS DISTINCT FROM OLD.guest_id
  OR NEW.property_id     IS DISTINCT FROM OLD.property_id
  OR NEW.form_version    IS DISTINCT FROM OLD.form_version
  OR NEW.snapshot        IS DISTINCT FROM OLD.snapshot
  OR NEW.snapshot_sha256 IS DISTINCT FROM OLD.snapshot_sha256
  OR NEW.created_by      IS DISTINCT FROM OLD.created_by
  OR NEW.created_at      IS DISTINCT FROM OLD.created_at
  OR (OLD.superseded_at IS NOT NULL AND NEW.superseded_at IS DISTINCT FROM OLD.superseded_at)
  OR (OLD.pdf_path      IS NOT NULL AND NEW.pdf_path      IS DISTINCT FROM OLD.pdf_path)
  THEN
    RAISE EXCEPTION 'immutable: un parte de entrada firmado no se puede modificar'
      USING ERRCODE = '42501';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_traveller_entry_forms_immutable ON public.traveller_entry_forms;
CREATE TRIGGER trg_traveller_entry_forms_immutable
  BEFORE UPDATE ON public.traveller_entry_forms
  FOR EACH ROW EXECUTE FUNCTION public.trg_traveller_entry_forms_immutable();

-- Firma: nunca se modifica
CREATE OR REPLACE FUNCTION public.trg_guest_signatures_immutable()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  RAISE EXCEPTION 'immutable: una firma no se puede modificar'
    USING ERRCODE = '42501';
END;
$function$;

DROP TRIGGER IF EXISTS trg_guest_signatures_immutable ON public.guest_signatures;
CREATE TRIGGER trg_guest_signatures_immutable
  BEFORE UPDATE ON public.guest_signatures
  FOR EACH ROW EXECUTE FUNCTION public.trg_guest_signatures_immutable();

-- ----------------------------------------------------------------------------
-- 4) RLS: lectura para el staff de la propiedad y para el titular de la
--    reserva. Sin escrituras directas (solo vía RPC SECURITY DEFINER).
--    El borrado solo ocurre en cascada desde delete_booking (que ya rechaza
--    reservas con estancia) o desde la futura purga de 3 años.
-- ----------------------------------------------------------------------------
ALTER TABLE public.traveller_entry_forms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.guest_signatures ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.traveller_entry_forms FROM PUBLIC, anon, authenticated;
REVOKE ALL ON public.guest_signatures FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.traveller_entry_forms TO authenticated;
GRANT SELECT ON public.guest_signatures TO authenticated;
GRANT ALL ON public.traveller_entry_forms TO service_role;
GRANT ALL ON public.guest_signatures TO service_role;

DROP POLICY IF EXISTS traveller_entry_forms_select ON public.traveller_entry_forms;
CREATE POLICY traveller_entry_forms_select
  ON public.traveller_entry_forms
  FOR SELECT TO authenticated
  USING (
    (public.is_staff() AND (public.is_admin() OR property_id = public.current_property_id()))
    OR EXISTS (
      SELECT 1 FROM public.bookings b
       WHERE b.id = traveller_entry_forms.booking_id
         AND b.primary_guest_user_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS guest_signatures_select ON public.guest_signatures;
CREATE POLICY guest_signatures_select
  ON public.guest_signatures
  FOR SELECT TO authenticated
  USING (
    (public.is_staff() AND EXISTS (
      SELECT 1 FROM public.bookings b
       WHERE b.id = guest_signatures.booking_id
         AND (public.is_admin() OR b.property_id = public.current_property_id())
    ))
    OR EXISTS (
      SELECT 1 FROM public.bookings b
       WHERE b.id = guest_signatures.booking_id
         AND b.primary_guest_user_id = (SELECT auth.uid())
    )
  );

COMMIT;
