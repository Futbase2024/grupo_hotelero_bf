-- =====================================================
-- MIGRACIÓN: Funciones RPC para flujo de check-in
-- =====================================================
-- Este archivo contiene las funciones necesarias para:
-- 1. submit_guest_checkin: Huésped envía check-in (estado: submitted)
-- 2. validate_checkin: Admin valida check-in (estado: validated)
-- 3. reject_checkin: Admin rechaza check-in (estado: rejected)
-- =====================================================

-- =====================================================
-- 1. FUNCIÓN: submit_guest_checkin
-- Permite al huésped enviar su check-in completo
-- Cambia estado de 'draft' a 'submitted' (pendiente de validación)
-- =====================================================

CREATE OR REPLACE FUNCTION public.submit_guest_checkin(
  p_booking_id UUID,
  p_signature_svg TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_checkin_id UUID;
  v_user_id UUID;
  v_booking_record RECORD;
BEGIN
  -- Obtener usuario actual
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Usuario no autenticado';
  END IF;

  -- Verificar que la reserva existe y pertenece al usuario
  SELECT id, status, primary_guest_user_id
  INTO v_booking_record
  FROM public.bookings
  WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reserva no encontrada';
  END IF;

  IF v_booking_record.primary_guest_user_id != v_user_id THEN
    RAISE EXCEPTION 'No autorizado para esta reserva';
  END IF;

  -- Crear o actualizar el check-in
  INSERT INTO public.checkins (
    booking_id,
    status,
    signature_svg,
    submitted_at,
    created_at
  )
  VALUES (
    p_booking_id,
    'submitted',
    p_signature_svg,
    NOW(),
    NOW()
  )
  ON CONFLICT (booking_id)
  DO UPDATE SET
    status = 'submitted',
    signature_svg = p_signature_svg,
    submitted_at = NOW(),
    validated_at = NULL,
    rejected_at = NULL,
    rejection_reason = NULL
  RETURNING id INTO v_checkin_id;

  RETURN v_checkin_id;
END;
$$;

-- =====================================================
-- 2. FUNCIÓN: validate_checkin
-- Permite al staff/admin validar un check-in
-- Cambia estado a 'validated' y actualiza booking a 'checked_in'
-- =====================================================

CREATE OR REPLACE FUNCTION public.validate_checkin(
  p_checkin_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking_id UUID;
  v_current_status TEXT;
BEGIN
  -- Verificar que el usuario es staff
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Solo el personal puede validar check-ins';
  END IF;

  -- Obtener el check-in
  SELECT booking_id, status
  INTO v_booking_id, v_current_status
  FROM public.checkins
  WHERE id = p_checkin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Check-in no encontrado';
  END IF;

  IF v_current_status != 'submitted' THEN
    RAISE EXCEPTION 'Solo se pueden validar check-ins pendientes (estado: submitted)';
  END IF;

  -- Actualizar el check-in
  UPDATE public.checkins
  SET
    status = 'validated',
    validated_at = NOW(),
    rejected_at = NULL,
    rejection_reason = NULL
  WHERE id = p_checkin_id;

  -- Actualizar el estado de la reserva
  UPDATE public.bookings
  SET status = 'checked_in'
  WHERE id = v_booking_id;

  RETURN TRUE;
END;
$$;

-- =====================================================
-- 3. FUNCIÓN: reject_checkin
-- Permite al staff/admin rechazar un check-in con motivo
-- Cambia estado a 'rejected'
-- =====================================================

CREATE OR REPLACE FUNCTION public.reject_checkin(
  p_checkin_id UUID,
  p_reason TEXT DEFAULT 'Sin motivo especificado'
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_current_status TEXT;
BEGIN
  -- Verificar que el usuario es staff
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Solo el personal puede rechazar check-ins';
  END IF;

  -- Obtener el check-in
  SELECT status
  INTO v_current_status
  FROM public.checkins
  WHERE id = p_checkin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Check-in no encontrado';
  END IF;

  IF v_current_status != 'submitted' THEN
    RAISE EXCEPTION 'Solo se pueden rechazar check-ins pendientes (estado: submitted)';
  END IF;

  -- Actualizar el check-in
  UPDATE public.checkins
  SET
    status = 'rejected',
    rejected_at = NOW(),
    rejection_reason = p_reason,
    validated_at = NULL
  WHERE id = p_checkin_id;

  RETURN TRUE;
END;
$$;

-- =====================================================
-- 4. FUNCIÓN: get_checkin_details
-- Obtiene todos los detalles de un check-in para admin
-- Incluye huéspedes, documentos y firma
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_checkin_details(
  p_checkin_id UUID
)
RETURNS TABLE (
  checkin_id UUID,
  checkin_status TEXT,
  signature_svg TEXT,
  submitted_at TIMESTAMPTZ,
  validated_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  rejection_reason TEXT,
  booking_id UUID,
  booking_code TEXT,
  unit_name TEXT,
  property_name TEXT,
  checkin_date DATE,
  checkout_date DATE,
  guest_data JSONB,
  documents_data JSONB
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Verificar que el usuario es staff
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
    p.name AS property_name,
    b.checkin_date,
    b.checkout_date,
    -- Huéspedes como JSON
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
    -- Documentos como JSON
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
  JOIN public.units u ON u.id = b.unit_id
  JOIN public.properties p ON p.id = b.property_id
  WHERE c.id = p_checkin_id;
END;
$$;

-- =====================================================
-- 5. FUNCIÓN: get_pending_checkins_count
-- Obtiene el número de check-ins pendientes de validación
-- =====================================================

CREATE OR REPLACE FUNCTION public.get_pending_checkins_count(
  p_property_id UUID DEFAULT NULL
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  -- Verificar que el usuario es staff
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Solo el personal puede ver estadísticas';
  END IF;

  SELECT COUNT(*)::INTEGER INTO v_count
  FROM public.checkins c
  JOIN public.bookings b ON b.id = c.booking_id
  WHERE c.status = 'submitted'
    AND (p_property_id IS NULL OR b.property_id = p_property_id);

  RETURN v_count;
END;
$$;

-- =====================================================
-- 6. POLÍTICA RLS: Permitir INSERT en checkins para huéspedes
-- =====================================================

-- Eliminar política existente si hay
DROP POLICY IF EXISTS checkins_guest_insert_own ON public.checkins;

-- Crear política para INSERT
CREATE POLICY checkins_guest_insert_own ON public.checkins
  FOR INSERT
  TO public
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = checkins.booking_id
        AND b.primary_guest_user_id = auth.uid()
    )
  );

-- =====================================================
-- 7. POLÍTICA RLS: Permitir INSERT en guest_documents para huéspedes
-- =====================================================

-- La política ya existe en el schema principal, pero aseguramos
DROP POLICY IF EXISTS guest_documents_guest_insert_own ON public.guest_documents;

CREATE POLICY guest_documents_guest_insert_own ON public.guest_documents
  FOR INSERT
  TO public
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = guest_documents.booking_id
        AND b.primary_guest_user_id = auth.uid()
    )
    AND uploaded_by = auth.uid()
  );

-- =====================================================
-- 8. OTORGAR PERMISOS
-- =====================================================

REVOKE ALL ON FUNCTION public.submit_guest_checkin(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_guest_checkin(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.validate_checkin(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.validate_checkin(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.reject_checkin(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reject_checkin(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.get_checkin_details(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_checkin_details(UUID) TO authenticated;

REVOKE ALL ON FUNCTION public.get_pending_checkins_count(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_pending_checkins_count(UUID) TO authenticated;
