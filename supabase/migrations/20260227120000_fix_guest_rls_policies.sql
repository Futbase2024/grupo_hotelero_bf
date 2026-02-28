-- =====================================================
-- MIGRACIÓN: Arreglar políticas RLS para huéspedes
-- Problema: Los huéspedes no pueden crear sus datos en 'guests'
-- Solución: Añadir políticas que permitan a huéspedes autenticados
-- gestionar sus propios datos cuando están asociados a una reserva
-- =====================================================

-- =====================================================
-- 1. POLÍTICAS PARA TABLA 'guests'
-- =====================================================

-- Eliminar políticas existentes (solo para staff)
DROP POLICY IF EXISTS guests_staff_manage ON guests;
DROP POLICY IF EXISTS guests_staff_select ON guests;

-- Política: Staff puede hacer todo
CREATE POLICY guests_staff_all ON guests
  FOR ALL
  TO public
  USING (is_staff())
  WITH CHECK (is_staff());

-- Política: Huéspedes pueden ver huéspedes de su propia reserva
CREATE POLICY guests_guest_select_own ON guests
  FOR SELECT
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM booking_guests bg
      JOIN bookings b ON b.id = bg.booking_id
      WHERE bg.guest_id = guests.id
      AND b.primary_guest_user_id = auth.uid()
    )
  );

-- Política: Huéspedes pueden crear nuevos huéspedes para su reserva
-- Permite INSERT si el huésped está asociado a una reserva del usuario
CREATE POLICY guests_guest_insert_own ON guests
  FOR INSERT
  TO public
  WITH CHECK (
    -- El huésped se asociará a una reserva donde el usuario es el primary_guest
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.primary_guest_user_id = auth.uid()
      AND b.status IN ('confirmed', 'checked_in')
    )
  );

-- Política: Huéspedes pueden actualizar sus propios datos
CREATE POLICY guests_guest_update_own ON guests
  FOR UPDATE
  TO public
  USING (
    EXISTS (
      SELECT 1 FROM booking_guests bg
      JOIN bookings b ON b.id = bg.booking_id
      WHERE bg.guest_id = guests.id
      AND b.primary_guest_user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM booking_guests bg
      JOIN bookings b ON b.id = bg.booking_id
      WHERE bg.guest_id = guests.id
      AND b.primary_guest_user_id = auth.uid()
    )
  );

-- =====================================================
-- 2. POLÍTICAS PARA TABLA 'bookings' - Permitir establecer primary_guest_user_id
-- =====================================================

-- Eliminar política existente que impide establecer el ID
DROP POLICY IF EXISTS bookings_guest_update_own ON bookings;

-- Nueva política: Permite UPDATE si:
-- 1. El usuario YA es el primary_guest_user_id, O
-- 2. primary_guest_user_id es NULL y el usuario está autenticado (para establecerlo por primera vez)
-- El with_check permite establecer el propio ID del usuario
CREATE POLICY bookings_guest_update_own ON bookings
  FOR UPDATE
  TO public
  USING (
    primary_guest_user_id = auth.uid()
    OR (
      primary_guest_user_id IS NULL
      AND auth.uid() IS NOT NULL
      AND status IN ('confirmed', 'checked_in')
    )
  )
  WITH CHECK (
    primary_guest_user_id = auth.uid()
    OR primary_guest_user_id IS NULL
  );

-- =====================================================
-- 3. FUNCIÓN HELPER: Asignar primary_guest_user_id a una reserva
-- =====================================================

CREATE OR REPLACE FUNCTION assign_primary_guest(booking_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_booking_id UUID;
  v_user_id UUID;
BEGIN
  v_user_id := auth.uid();

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Buscar y actualizar la reserva
  UPDATE bookings
  SET primary_guest_user_id = v_user_id
  WHERE booking_code = upper(booking_code)
    AND status IN ('confirmed', 'checked_in')
    AND (primary_guest_user_id IS NULL OR primary_guest_user_id = v_user_id)
  RETURNING id INTO v_booking_id;

  IF v_booking_id IS NULL THEN
    RAISE EXCEPTION 'Booking not found or already assigned';
  END IF;

  RETURN v_booking_id;
END;
$$;

-- =====================================================
-- 4. FUNCIÓN HELPER: Obtener booking_id del usuario actual
-- =====================================================

CREATE OR REPLACE FUNCTION get_current_user_booking_id()
RETURNS UUID
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT id FROM bookings
  WHERE primary_guest_user_id = auth.uid()
    AND status IN ('confirmed', 'checked_in')
  ORDER BY checkin_date DESC
  LIMIT 1;
$$;

-- =====================================================
-- 5. POLÍTICAS PARA TABLA 'booking_guests' - Simplificar
-- =====================================================

-- Asegurar que existe política de INSERT para huéspedes
DROP POLICY IF EXISTS guest_insert_booking_guests ON booking_guests;

CREATE POLICY guest_insert_booking_guests ON booking_guests
  FOR INSERT
  TO public
  WITH CHECK (
    -- El usuario es el primary_guest de la reserva
    EXISTS (
      SELECT 1 FROM bookings b
      WHERE b.id = booking_guests.booking_id
      AND b.primary_guest_user_id = auth.uid()
    )
  );
