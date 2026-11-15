-- Rollback de 20261115110000_traveller_register_fields.sql
-- ⚠️ Aplicar ANTES el rollback de 20261115110200 y 20261115110100.
-- ⚠️ Borra los datos legales recogidos con el formulario nuevo (nombre y
--    apellidos separados, soporte, domicilio, fijo, responsable, parentesco).
--    `full_name` se conserva.

BEGIN;

DROP FUNCTION IF EXISTS public.is_valid_spanish_id(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.traveller_normalize_doc(TEXT);
DROP FUNCTION IF EXISTS public.traveller_age_on(DATE, DATE);

DROP INDEX IF EXISTS public.idx_booking_guests_responsible;
ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_responsible_same_booking_fkey;
ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_responsible_not_self;
ALTER TABLE public.booking_guests DROP CONSTRAINT IF EXISTS booking_guests_relationship_check;
ALTER TABLE public.booking_guests
  DROP COLUMN IF EXISTS relationship,
  DROP COLUMN IF EXISTS responsible_guest_id;

DROP TRIGGER IF EXISTS trg_guests_updated_at ON public.guests;
DROP TRIGGER IF EXISTS trg_guests_build_full_name ON public.guests;
DROP FUNCTION IF EXISTS public.trg_guests_build_full_name();

ALTER TABLE public.guests DROP CONSTRAINT IF EXISTS guests_residence_country_check;
ALTER TABLE public.guests DROP CONSTRAINT IF EXISTS guests_register_format_check;
ALTER TABLE public.guests
  DROP COLUMN IF EXISTS updated_at,
  DROP COLUMN IF EXISTS register_format,
  DROP COLUMN IF EXISTS landline_phone,
  DROP COLUMN IF EXISTS residence_country,
  DROP COLUMN IF EXISTS residence_postal_code,
  DROP COLUMN IF EXISTS residence_city,
  DROP COLUMN IF EXISTS residence_address,
  DROP COLUMN IF EXISTS document_support_number,
  DROP COLUMN IF EXISTS last_name_2,
  DROP COLUMN IF EXISTS last_name_1,
  DROP COLUMN IF EXISTS first_name;

COMMENT ON COLUMN public.guests.phone IS NULL;
COMMENT ON COLUMN public.guests.age IS NULL;

COMMIT;
