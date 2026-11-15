-- ============================================================================
-- ROLLBACK de 20261115100000_guest_documents_privacy.sql
-- ----------------------------------------------------------------------------
-- Ejecutar ANTES el rollback del cron (20261115100100_...ROLLBACK.sql).
-- Las imágenes ya borradas del bucket NO se recuperan.
-- No se recrean cleanup_expired_documents() ni get_documents_expiring_soon():
-- eran ejecutables por cualquier usuario autenticado.
-- ============================================================================

BEGIN;

-- get_checkin_details sin deleted_at / deleted_reason
CREATE OR REPLACE FUNCTION public.get_checkin_details(p_checkin_id uuid)
 RETURNS TABLE(checkin_id uuid, checkin_status text, signature_svg text, submitted_at timestamp with time zone, validated_at timestamp with time zone, rejected_at timestamp with time zone, rejection_reason text, booking_id uuid, booking_code text, unit_name text, unit_names jsonb, total_units integer, property_name text, checkin_date date, checkout_date date, guest_data jsonb, documents_data jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Solo el personal puede ver detalles de check-ins';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS checkin_id,
    c.status AS checkin_status,
    c.signature_svg,
    c.submitted_at,
    c.validated_at,
    c.rejected_at,
    c.rejection_reason,
    b.id AS booking_id,
    b.booking_code,
    u.name AS unit_name,
    (
      SELECT jsonb_agg(jsonb_build_object('name', un.name) ORDER BY un.name)
      FROM public.booking_units bu
      JOIN private.units un ON un.id = bu.unit_id
      WHERE bu.booking_id = b.id
    ) AS unit_names,
    (
      SELECT COUNT(*)::int
      FROM public.booking_units bu
      WHERE bu.booking_id = b.id
    ) AS total_units,
    p.name AS property_name,
    b.checkin_date,
    b.checkout_date,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', g.id,
          'full_name', g.full_name,
          'email', g.email,
          'phone', g.phone,
          'document_type', g.document_type,
          'document_number', g.document_number,
          'nationality', g.nationality,
          'birth_date', g.birth_date,
          'type', g.type,
          'age', g.age,
          'is_primary', bg.is_primary
        )
      )
      FROM public.booking_guests bg
      JOIN public.guests g ON g.id = bg.guest_id
      WHERE bg.booking_id = b.id
    ) AS guest_data,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gd.id,
          'guest_id', gd.guest_id,
          'doc_kind', gd.doc_kind,
          'storage_path', gd.storage_path,
          'mime_type', gd.mime_type,
          'created_at', gd.created_at
        )
      )
      FROM public.guest_documents gd
      WHERE gd.booking_id = b.id
    ) AS documents_data
  FROM public.checkins c
  JOIN public.bookings b ON b.id = c.booking_id
  JOIN private.units u ON u.id = b.unit_id
  JOIN public.properties p ON p.id = b.property_id
  WHERE c.id = p_checkin_id;
END;
$function$;

DROP FUNCTION IF EXISTS public.mark_booking_documents_deleted(UUID, UUID[]);
DROP FUNCTION IF EXISTS public.set_booking_documents_retention(UUID, BOOLEAN, TEXT);
DROP FUNCTION IF EXISTS public.get_booking_documents_status(UUID);
DROP FUNCTION IF EXISTS public.guest_documents_due_for_deletion(INTEGER);
DROP FUNCTION IF EXISTS public.booking_documents_deletion_schedule(UUID);

DROP TABLE IF EXISTS public.booking_document_retentions;

DROP INDEX IF EXISTS public.idx_guest_documents_pending_deletion;

-- Las filas de imágenes ya borradas apuntan a archivos inexistentes
DELETE FROM public.guest_documents WHERE deleted_at IS NOT NULL;

ALTER TABLE public.guest_documents
  DROP CONSTRAINT IF EXISTS guest_documents_deleted_reason_check,
  DROP COLUMN IF EXISTS deleted_at,
  DROP COLUMN IF EXISTS deleted_reason,
  DROP COLUMN IF EXISTS deleted_by;

-- Caducidad de 1 año
ALTER TABLE public.guest_documents ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

CREATE OR REPLACE FUNCTION public.set_document_expires_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.expires_at := NEW.created_at + INTERVAL '1 year';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_document_expires_at ON public.guest_documents;
CREATE TRIGGER trg_set_document_expires_at
  BEFORE INSERT ON public.guest_documents
  FOR EACH ROW
  EXECUTE FUNCTION public.set_document_expires_at();

UPDATE public.guest_documents
   SET expires_at = created_at + INTERVAL '1 year'
 WHERE expires_at IS NULL;

COMMIT;
