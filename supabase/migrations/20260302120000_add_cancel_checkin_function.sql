-- =====================================================
-- MIGRACIÓN: Función RPC para cancelar check-in
-- =====================================================
-- Esta función permite al admin CANCELAR una reserva completa
-- A diferencia del rechazo, la cancelación:
-- - NO permite al huésped corregir y reenviar
-- - La reserva queda eliminada/inutilizable
-- - El huésped debe contactar con recepción
-- =====================================================

-- =====================================================
-- 1. FUNCIÓN: cancel_checkin
-- Permite al staff/admin cancelar un check-in con motivo
-- Cambia estado a 'cancelled' tanto en checkins como en bookings
-- =====================================================

CREATE OR REPLACE FUNCTION public.cancel_checkin(
  p_checkin_id UUID,
  p_reason TEXT DEFAULT 'Sin motivo especificado'
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
    RAISE EXCEPTION 'Solo el personal puede cancelar check-ins';
  END IF;

  -- Obtener el check-in
  SELECT booking_id, status
  INTO v_booking_id, v_current_status
  FROM public.checkins
  WHERE id = p_checkin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Check-in no encontrado';
  END IF;

  -- Solo se pueden cancelar check-ins pendientes (submitted)
  -- También permitimos cancelar si está rejected o in_progress
  IF v_current_status NOT IN ('submitted', 'rejected', 'in_progress', 'draft') THEN
    RAISE EXCEPTION 'Solo se pueden cancelar check-ins pendientes, en progreso o rechazados';
  END IF;

  -- Actualizar el check-in a cancelled
  UPDATE public.checkins
  SET
    status = 'cancelled',
    cancelled_at = NOW(),
    cancellation_reason = p_reason,
    validated_at = NULL,
    rejected_at = NULL,
    rejection_reason = NULL
  WHERE id = p_checkin_id;

  -- Actualizar el estado de la reserva a cancelled
  UPDATE public.bookings
  SET status = 'cancelled'
  WHERE id = v_booking_id;

  RETURN TRUE;
END;
$$;

-- =====================================================
-- 2. OTORGAR PERMISOS
-- =====================================================

REVOKE ALL ON FUNCTION public.cancel_checkin(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cancel_checkin(UUID, TEXT) TO authenticated;

-- =====================================================
-- 3. AÑADIR COLUMNAS A LA TABLA checkins SI NO EXISTEN
-- =====================================================

-- Añadir columna cancelled_at si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'checkins'
    AND column_name = 'cancelled_at'
  ) THEN
    ALTER TABLE public.checkins ADD COLUMN cancelled_at TIMESTAMPTZ;
  END IF;
END $$;

-- Añadir columna cancellation_reason si no existe
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
    AND table_name = 'checkins'
    AND column_name = 'cancellation_reason'
  ) THEN
    ALTER TABLE public.checkins ADD COLUMN cancellation_reason TEXT;
  END IF;
END $$;

-- =====================================================
-- 4. COMENTARIOS
-- =====================================================

COMMENT ON FUNCTION public.cancel_checkin(UUID, TEXT) IS 'Cancela un check-in y su reserva asociada. No permite corrección por el huésped.';
COMMENT ON COLUMN public.checkins.cancelled_at IS 'Fecha y hora de cancelación del check-in';
COMMENT ON COLUMN public.checkins.cancellation_reason IS 'Motivo de la cancelación del check-in';
