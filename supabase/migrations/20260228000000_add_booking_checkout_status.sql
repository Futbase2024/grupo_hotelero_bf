-- ============================================================================
-- MIGRACIÓN: Sistema completo de estados para reservas y check-in/out
-- Fecha: 2026-02-28
-- Descripción: Añade nuevos estados y campos para el flujo completo de gestión
-- ============================================================================

-- ============================================================================
-- 1. AÑADIR NUEVOS CAMPOS A LA TABLA bookings
-- ============================================================================

-- Añadir booking_status (más granular que status)
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS booking_status TEXT DEFAULT 'created'
CHECK (booking_status IN ('created', 'active', 'closed', 'cancelled'));

-- Añadir checkout_status
ALTER TABLE bookings
ADD COLUMN IF NOT EXISTS checkout_status TEXT DEFAULT 'not_started'
CHECK (checkout_status IN ('not_started', 'requested', 'validated', 'rejected'));

-- Timestamps adicionales
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS activated_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS closed_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS checkout_requested_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS checkout_validated_at TIMESTAMPTZ;

-- Notas de validación
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS validation_notes TEXT;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS checkout_notes TEXT;

-- ============================================================================
-- 2. AÑADIR CAMPO A LA TABLA checkins
-- ============================================================================

ALTER TABLE checkins ADD COLUMN IF NOT EXISTS in_progress_at TIMESTAMPTZ;

-- ============================================================================
-- 3. MIGRAR DATOS EXISTENTES AL NUEVO SISTEMA DE ESTADOS
-- ============================================================================

-- Mapear status existente a booking_status
UPDATE bookings
SET booking_status = CASE
    WHEN status = 'confirmed' THEN 'created'
    WHEN status = 'checked_in' THEN 'active'
    WHEN status = 'checked_out' THEN 'closed'
    WHEN status = 'cancelled' THEN 'cancelled'
    ELSE 'created'
END
WHERE booking_status IS NULL OR booking_status = 'created';

-- ============================================================================
-- 4. ACTUALIZAR CONSTRAINT DE status EXISTENTE PARA INCLUIR NUEVOS VALORES
-- ============================================================================

-- Primero eliminamos el constraint antiguo si existe
ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;

-- Añadimos el nuevo constraint con todos los valores posibles
ALTER TABLE bookings
ADD CONSTRAINT bookings_status_check
CHECK (status IN ('confirmed', 'checked_in', 'checked_out', 'cancelled', 'created', 'active', 'closed'));

-- ============================================================================
-- 5. ÍNDICES PARA MEJORAR RENDIMIENTO
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_bookings_booking_status ON bookings(booking_status);
CREATE INDEX IF NOT EXISTS idx_bookings_checkout_status ON bookings(checkout_status);
CREATE INDEX IF NOT EXISTS idx_bookings_property_status ON bookings(property_id, booking_status);

-- ============================================================================
-- 6. FUNCIONES RPC
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Función: Marcar check-in como "en progreso"
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION mark_checkin_in_progress(p_booking_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_checkin_id UUID;
BEGIN
    -- Obtener o crear check-in
    SELECT id INTO v_checkin_id FROM checkins WHERE booking_id = p_booking_id;

    IF v_checkin_id IS NULL THEN
        -- Crear check-in nuevo
        INSERT INTO checkins (id, booking_id, status, in_progress_at, created_at)
        VALUES (
            gen_random_uuid(),
            p_booking_id,
            'in_progress',
            NOW(),
            NOW()
        );
    ELSE
        -- Actualizar existente
        UPDATE checkins
        SET status = 'in_progress',
            in_progress_at = COALESCE(in_progress_at, NOW()),
            updated_at = NOW()
        WHERE id = v_checkin_id;
    END IF;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Activar reserva (tras validación de check-in)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION activate_booking(p_booking_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET booking_status = 'active',
        status = 'checked_in',
        activated_at = NOW(),
        updated_at = NOW()
    WHERE id = p_booking_id
      AND booking_status = 'created';

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Cerrar reserva (tras validación de check-out)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION close_booking(p_booking_id UUID, p_notes TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET booking_status = 'closed',
        status = 'checked_out',
        closed_at = NOW(),
        checkout_notes = COALESCE(p_notes, checkout_notes),
        updated_at = NOW()
    WHERE id = p_booking_id
      AND booking_status = 'active';

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Solicitar check-out (huésped)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION request_checkout(p_booking_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET checkout_status = 'requested',
        checkout_requested_at = NOW(),
        updated_at = NOW()
    WHERE id = p_booking_id
      AND booking_status = 'active'
      AND checkout_status = 'not_started';

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Validar check-out (admin)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION validate_checkout(p_booking_id UUID, p_notes TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Actualizar checkout_status
    UPDATE bookings
    SET checkout_status = 'validated',
        checkout_validated_at = NOW(),
        checkout_notes = COALESCE(p_notes, checkout_notes),
        updated_at = NOW()
    WHERE id = p_booking_id
      AND checkout_status = 'requested';

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Cerrar la reserva automáticamente
    PERFORM close_booking(p_booking_id, p_notes);

    RETURN TRUE;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Rechazar check-out (admin - incidencias)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION reject_checkout(p_booking_id UUID, p_reason TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET checkout_status = 'rejected',
        checkout_notes = p_reason,
        updated_at = NOW()
    WHERE id = p_booking_id
      AND checkout_status IN ('requested', 'validated');

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Reenviar check-out tras resolver incidencias
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION resubmit_checkout(p_booking_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET checkout_status = 'requested',
        updated_at = NOW()
    WHERE id = p_booking_id
      AND checkout_status = 'rejected';

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Cancelar reserva
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION cancel_booking(p_booking_id UUID, p_reason TEXT DEFAULT NULL)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE bookings
    SET booking_status = 'cancelled',
        status = 'cancelled',
        staff_notes = COALESCE(p_reason, staff_notes),
        updated_at = NOW()
    WHERE id = p_booking_id
      AND booking_status NOT IN ('closed', 'cancelled');

    RETURN FOUND;
END;
$$;

-- ----------------------------------------------------------------------------
-- Función: Obtener estado completo de una reserva
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_booking_full_status(p_booking_id UUID)
RETURNS TABLE (
    booking_id UUID,
    booking_code TEXT,
    booking_status TEXT,
    checkin_status TEXT,
    checkout_status TEXT,
    can_access_panel BOOLEAN,
    is_read_only BOOLEAN,
    needs_checkin_action BOOLEAN,
    needs_checkout_action BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        b.id,
        b.booking_code,
        b.booking_status,
        COALESCE(c.status, 'not_started') as checkin_status,
        b.checkout_status,
        -- can_access_panel: checkin validated AND booking active
        CASE
            WHEN COALESCE(c.status, 'not_started') = 'validated' AND b.booking_status = 'active'
            THEN TRUE
            ELSE FALSE
        END as can_access_panel,
        -- is_read_only: booking closed
        CASE
            WHEN b.booking_status = 'closed' THEN TRUE
            ELSE FALSE
        END as is_read_only,
        -- needs_checkin_action: checkin submitted
        CASE
            WHEN COALESCE(c.status, 'not_started') = 'submitted' THEN TRUE
            ELSE FALSE
        END as needs_checkin_action,
        -- needs_checkout_action: checkout requested
        CASE
            WHEN b.checkout_status = 'requested' THEN TRUE
            ELSE FALSE
        END as needs_checkout_action
    FROM bookings b
    LEFT JOIN checkins c ON c.booking_id = b.id
    WHERE b.id = p_booking_id;
END;
$$;

-- ============================================================================
-- 7. ACTUALIZAR FUNCIÓN validate_checkin EXISTENTE PARA ACTIVAR RESERVA
-- ============================================================================

CREATE OR REPLACE FUNCTION validate_checkin(p_checkin_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_booking_id UUID;
BEGIN
    -- Obtener booking_id
    SELECT booking_id INTO v_booking_id FROM checkins WHERE id = p_checkin_id;

    IF v_booking_id IS NULL THEN
        RAISE EXCEPTION 'Check-in no encontrado';
    END IF;

    -- Actualizar check-in
    UPDATE checkins
    SET status = 'validated',
        validated_at = NOW(),
        updated_at = NOW()
    WHERE id = p_checkin_id
      AND status = 'submitted';

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Activar la reserva automáticamente
    PERFORM activate_booking(v_booking_id);

    RETURN TRUE;
END;
$$;

-- ============================================================================
-- 8. ACTUALIZAR FUNCIÓN submit_guest_checkin PARA MARCAR in_progress_at
-- ============================================================================

CREATE OR REPLACE FUNCTION submit_guest_checkin(p_booking_id UUID, p_signature_svg TEXT DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_checkin_id UUID;
    v_guest_user_id UUID;
BEGIN
    -- Obtener el guest_user_id de la reserva
    SELECT primary_guest_user_id INTO v_guest_user_id
    FROM bookings WHERE id = p_booking_id;

    -- Buscar si ya existe un check-in
    SELECT id INTO v_checkin_id FROM checkins WHERE booking_id = p_booking_id;

    IF v_checkin_id IS NULL THEN
        -- Crear nuevo check-in
        INSERT INTO checkins (
            id,
            booking_id,
            status,
            signature_svg,
            submitted_at,
            in_progress_at,
            created_at
        )
        VALUES (
            gen_random_uuid(),
            p_booking_id,
            'submitted',
            p_signature_svg,
            NOW(),
            NOW(),
            NOW()
        )
        RETURNING id INTO v_checkin_id;
    ELSE
        -- Actualizar existente
        UPDATE checkins
        SET status = 'submitted',
            signature_svg = COALESCE(p_signature_svg, signature_svg),
            submitted_at = NOW(),
            in_progress_at = COALESCE(in_progress_at, NOW()),
            updated_at = NOW()
        WHERE id = v_checkin_id;
    END IF;

    -- Marcar código como usado si no lo estaba
    UPDATE bookings
    SET code_first_used_at = COALESCE(code_first_used_at, NOW()),
        updated_at = NOW()
    WHERE id = p_booking_id;

    RETURN v_checkin_id;
END;
$$;

-- ============================================================================
-- 9. COMENTARIOS EN TABLAS
-- ============================================================================

COMMENT ON COLUMN bookings.booking_status IS 'Estado operativo: created, active, closed, cancelled';
COMMENT ON COLUMN bookings.checkout_status IS 'Estado del check-out: not_started, requested, validated, rejected';
COMMENT ON COLUMN bookings.activated_at IS 'Fecha en que se activó la reserva (check-in validado)';
COMMENT ON COLUMN bookings.closed_at IS 'Fecha en que se cerró la reserva (check-out validado)';
COMMENT ON COLUMN bookings.checkout_requested_at IS 'Fecha en que el huésped solicitó el check-out';
COMMENT ON COLUMN bookings.checkout_validated_at IS 'Fecha en que el admin validó el check-out';
COMMENT ON COLUMN bookings.validation_notes IS 'Notas del admin sobre la validación';
COMMENT ON COLUMN bookings.checkout_notes IS 'Notas del admin sobre el check-out';
COMMENT ON COLUMN checkins.in_progress_at IS 'Fecha en que el huésped empezó a rellenar el check-in';
