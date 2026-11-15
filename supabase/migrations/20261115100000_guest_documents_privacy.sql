-- ============================================================================
-- Privacidad de los documentos de identidad (DNI / NIE / pasaporte)
-- ----------------------------------------------------------------------------
-- Reglas de borrado de las IMÁGENES (los datos del huésped en `guests` se
-- conservan: son los que exige el registro de viajeros):
--   · Check-in validado        → 24 h después de `checkins.validated_at`
--   · Reserva cancelada        → en la siguiente pasada del cron
--   · Nunca validada ni
--     cancelada                → al día siguiente del `checkout_date`
--   · Retención activa         → NO se borra hasta que el staff la quite
--   · Borrado manual del staff → al momento
--
-- El borrado lo ejecuta la Edge Function `cleanup-documents` (el Storage no se
-- puede borrar desde SQL). Esta migración NO programa el cron: eso va en
-- 20261115100100_schedule_guest_documents_cleanup.sql, que es la que empieza a
-- borrar de verdad (incluidos los documentos antiguos ya caducados).
--
-- Además se eliminan dos funciones SECURITY DEFINER antiguas que cualquier
-- usuario autenticado (los huéspedes anónimos lo son) podía ejecutar:
--   · get_documents_expiring_soon() → devolvía rutas e IDs de TODOS los docs
--   · cleanup_expired_documents()   → borraba filas y no los archivos
--
-- Rollback: 20261115100000_guest_documents_privacy.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Borrado suave: la fila se queda como constancia, el archivo desaparece
-- ----------------------------------------------------------------------------
ALTER TABLE public.guest_documents
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS deleted_reason TEXT,
  ADD COLUMN IF NOT EXISTS deleted_by UUID;

ALTER TABLE public.guest_documents
  DROP CONSTRAINT IF EXISTS guest_documents_deleted_reason_check;
ALTER TABLE public.guest_documents
  ADD CONSTRAINT guest_documents_deleted_reason_check CHECK (
    deleted_reason IS NULL OR deleted_reason IN (
      'validated_24h', 'booking_cancelled', 'checkout_not_validated', 'manual'
    )
  );

COMMENT ON COLUMN public.guest_documents.deleted_at IS
  'Momento en que se borró la imagen del bucket. La fila se conserva como constancia.';
COMMENT ON COLUMN public.guest_documents.deleted_reason IS
  'validated_24h | booking_cancelled | checkout_not_validated | manual';

CREATE INDEX IF NOT EXISTS idx_guest_documents_pending_deletion
  ON public.guest_documents (booking_id)
  WHERE deleted_at IS NULL;

-- La caducidad de 1 año queda sustituida por las reglas de arriba
DROP TRIGGER IF EXISTS trg_set_document_expires_at ON public.guest_documents;
DROP FUNCTION IF EXISTS public.set_document_expires_at();
ALTER TABLE public.guest_documents DROP COLUMN IF EXISTS expires_at;

DROP FUNCTION IF EXISTS public.cleanup_expired_documents();
DROP FUNCTION IF EXISTS public.get_documents_expiring_soon(INTEGER);

-- ----------------------------------------------------------------------------
-- 2) Retención por incidencia (solo staff; el huésped no ve el motivo)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.booking_document_retentions (
  booking_id  UUID PRIMARY KEY REFERENCES public.bookings(id) ON DELETE CASCADE,
  reason      TEXT NOT NULL CHECK (length(btrim(reason)) >= 5),
  retained_by UUID NOT NULL,
  retained_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.booking_document_retentions IS
  'Reservas cuyos documentos NO se borran automáticamente (incidencia, policía, reclamación).';

ALTER TABLE public.booking_document_retentions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS booking_document_retentions_staff_select ON public.booking_document_retentions;
CREATE POLICY booking_document_retentions_staff_select
  ON public.booking_document_retentions
  FOR SELECT TO authenticated
  USING (public.is_staff());

-- Escrituras solo a través de set_booking_documents_retention()
REVOKE ALL ON public.booking_document_retentions FROM anon, authenticated;
GRANT SELECT ON public.booking_document_retentions TO authenticated;

-- ----------------------------------------------------------------------------
-- 3) Cuándo se borra cada reserva (única fuente de verdad de las reglas)
-- ----------------------------------------------------------------------------
-- Devuelve el momento programado y el motivo. `NULL` si está retenida.
CREATE OR REPLACE FUNCTION public.booking_documents_deletion_schedule(p_booking_id UUID)
 RETURNS TABLE (scheduled_at TIMESTAMPTZ, reason TEXT)
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    CASE
      WHEN r.booking_id IS NOT NULL THEN NULL
      WHEN b.status = 'cancelled' THEN COALESCE(b.updated_at, now())
      WHEN c.status = 'validated' AND c.validated_at IS NOT NULL
        THEN c.validated_at + INTERVAL '24 hours'
      ELSE ((b.checkout_date + 1)::timestamp AT TIME ZONE 'Europe/Madrid')
    END,
    CASE
      WHEN r.booking_id IS NOT NULL THEN NULL
      WHEN b.status = 'cancelled' THEN 'booking_cancelled'
      WHEN c.status = 'validated' AND c.validated_at IS NOT NULL THEN 'validated_24h'
      ELSE 'checkout_not_validated'
    END
  FROM public.bookings b
  LEFT JOIN public.checkins c ON c.booking_id = b.id
  LEFT JOIN public.booking_document_retentions r ON r.booking_id = b.id
  WHERE b.id = p_booking_id;
$function$;

REVOKE EXECUTE ON FUNCTION public.booking_documents_deletion_schedule(UUID) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.booking_documents_deletion_schedule(UUID) TO service_role;

-- Documentos cuyo borrado ya toca (lo llama la Edge Function con service_role)
CREATE OR REPLACE FUNCTION public.guest_documents_due_for_deletion(p_limit INTEGER DEFAULT 1000)
 RETURNS TABLE (id UUID, booking_id UUID, storage_path TEXT, reason TEXT)
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT d.id, d.booking_id, d.storage_path, s.reason
  FROM public.guest_documents d
  CROSS JOIN LATERAL public.booking_documents_deletion_schedule(d.booking_id) s
  WHERE d.deleted_at IS NULL
    AND s.scheduled_at IS NOT NULL
    AND s.scheduled_at <= now()
  ORDER BY s.scheduled_at
  LIMIT GREATEST(1, LEAST(p_limit, 5000));
$function$;

REVOKE EXECUTE ON FUNCTION public.guest_documents_due_for_deletion(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guest_documents_due_for_deletion(INTEGER) TO service_role;

-- ----------------------------------------------------------------------------
-- 4) RPCs para el staff
-- ----------------------------------------------------------------------------
-- Estado de los documentos de una reserva (tarjeta de privacidad del panel)
CREATE OR REPLACE FUNCTION public.get_booking_documents_status(p_booking_id UUID)
 RETURNS JSONB
 LANGUAGE plpgsql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result JSONB;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede consultar los documentos'
      USING ERRCODE = '42501';
  END IF;

  SELECT jsonb_build_object(
    'booking_id', p_booking_id,
    'active_count', (SELECT count(*) FROM guest_documents
                      WHERE booking_id = p_booking_id AND deleted_at IS NULL),
    'deleted_count', (SELECT count(*) FROM guest_documents
                       WHERE booking_id = p_booking_id AND deleted_at IS NOT NULL),
    'last_deleted_at', (SELECT max(deleted_at) FROM guest_documents
                         WHERE booking_id = p_booking_id),
    'scheduled_at', s.scheduled_at,
    'scheduled_reason', s.reason,
    'is_retained', r.booking_id IS NOT NULL,
    'retained_reason', r.reason,
    'retained_at', r.retained_at,
    'retained_by_name', (
      SELECT upper(COALESCE(NULLIF(btrim(pr.full_name), ''), au.email))
      FROM auth.users au
      LEFT JOIN public.profiles pr ON pr.user_id = au.id
      WHERE au.id = r.retained_by
      LIMIT 1
    )
  )
  INTO v_result
  FROM public.bookings b
  LEFT JOIN LATERAL public.booking_documents_deletion_schedule(b.id) s ON TRUE
  LEFT JOIN public.booking_document_retentions r ON r.booking_id = b.id
  WHERE b.id = p_booking_id;

  IF v_result IS NULL THEN
    RAISE EXCEPTION 'not_found: reserva no encontrada' USING ERRCODE = 'P0002';
  END IF;

  RETURN v_result;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_booking_documents_status(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_booking_documents_status(UUID) TO authenticated, service_role;

-- Activa / quita la retención de los documentos de una reserva
CREATE OR REPLACE FUNCTION public.set_booking_documents_retention(
  p_booking_id UUID,
  p_retain BOOLEAN,
  p_reason TEXT DEFAULT NULL
)
 RETURNS VOID
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede retener documentos'
      USING ERRCODE = '42501';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM bookings WHERE id = p_booking_id) THEN
    RAISE EXCEPTION 'not_found: reserva no encontrada' USING ERRCODE = 'P0002';
  END IF;

  IF p_retain THEN
    IF p_reason IS NULL OR length(btrim(p_reason)) < 5 THEN
      RAISE EXCEPTION 'reason_required: indica el motivo de la retención'
        USING ERRCODE = 'P0001';
    END IF;

    INSERT INTO booking_document_retentions (booking_id, reason, retained_by)
    VALUES (p_booking_id, btrim(p_reason), auth.uid())
    ON CONFLICT (booking_id) DO UPDATE
      SET reason = EXCLUDED.reason,
          retained_by = EXCLUDED.retained_by,
          retained_at = now();
  ELSE
    DELETE FROM booking_document_retentions WHERE booking_id = p_booking_id;
  END IF;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.set_booking_documents_retention(UUID, BOOLEAN, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_booking_documents_retention(UUID, BOOLEAN, TEXT) TO authenticated, service_role;

-- Marca como borrados los documentos indicados (borrado manual del staff).
-- La app borra antes los archivos del bucket (el staff tiene permiso de
-- DELETE en storage) y después llama aquí. Si esto fallara, el cron volvería
-- a intentarlo: borrar un archivo que ya no existe no da error.
CREATE OR REPLACE FUNCTION public.mark_booking_documents_deleted(
  p_booking_id UUID,
  p_document_ids UUID[]
)
 RETURNS INTEGER
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count INTEGER;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede borrar documentos'
      USING ERRCODE = '42501';
  END IF;

  IF EXISTS (SELECT 1 FROM booking_document_retentions WHERE booking_id = p_booking_id) THEN
    RAISE EXCEPTION 'retained: los documentos de esta reserva están retenidos'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE guest_documents
     SET deleted_at = now(),
         deleted_reason = 'manual',
         deleted_by = auth.uid()
   WHERE booking_id = p_booking_id
     AND id = ANY (p_document_ids)
     AND deleted_at IS NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.mark_booking_documents_deleted(UUID, UUID[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_booking_documents_deleted(UUID, UUID[]) TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 5) get_checkin_details: cada documento indica si su imagen ya se borró
-- ----------------------------------------------------------------------------
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
          'created_at', gd.created_at,
          'deleted_at', gd.deleted_at,
          'deleted_reason', gd.deleted_reason
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

COMMIT;
