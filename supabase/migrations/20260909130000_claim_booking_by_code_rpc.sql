-- ============================================================================
-- RPC: public.claim_booking_by_code(p_code, p_email)
-- ----------------------------------------------------------------------------
-- Resuelve el acceso del huésped por código de reserva SIN necesidad de que la
-- tabla `bookings` sea legible por cualquiera.
--
-- Motivo: la política `bookings_anon_select_by_code` permitía a CUALQUIER rol
-- leer todas las reservas con status 'confirmed'/'checked_in' (26 filas hoy,
-- todas con `keybox_code`, email y teléfono del huésped). Existía porque el
-- login por código necesita leer la reserva antes de que haya vínculo entre
-- usuario y reserva.
--
-- Esta función hace en el servidor lo que antes hacía el cliente:
--   1. valida código, estado, caducidad del código y checkout,
--   2. valida el email cuando se exige,
--   3. vincula la reserva al usuario actual (`primary_guest_user_id`),
--   4. devuelve SOLO los campos que la app necesita (nunca `keybox_code`).
--
-- El cliente debe tener sesión (los invitados usan `signInAnonymously()`, que
-- les da rol `authenticated`) ANTES de llamar: sin `auth.uid()` no hay a quién
-- vincular la reserva.
--
-- Errores devueltos (el cliente los mapea a mensajes traducidos):
--   booking_not_found · code_expired · email_mismatch · no_session
-- ============================================================================

CREATE OR REPLACE FUNCTION public.claim_booking_by_code(
    p_code text,
    p_email text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    v_uid     uuid := auth.uid();
    v_code    text := upper(btrim(coalesce(p_code, '')));
    v_email   text := lower(btrim(coalesce(p_email, '')));
    v_booking public.bookings%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'no_session';
    END IF;

    IF v_code = '' THEN
        RAISE EXCEPTION 'booking_not_found';
    END IF;

    SELECT * INTO v_booking
    FROM public.bookings
    WHERE booking_code = v_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'booking_not_found';
    END IF;

    -- NOTA: el cliente pedía una columna `code_expires_at` que NO existe en
    -- `bookings` (comprobado en el esquema). La caducidad del acceso se decide
    -- por el estado de la reserva y por la fecha de checkout, que es lo que
    -- realmente hay en la tabla.

    -- Solo reservas activas
    IF v_booking.status IS NOT NULL
       AND v_booking.status NOT IN ('confirmed', 'checked_in') THEN
        RAISE EXCEPTION 'code_expired';
    END IF;

    -- Margen de 1 día tras el checkout, igual que hacía el cliente
    IF v_booking.checkout_date IS NOT NULL
       AND now() > (v_booking.checkout_date::timestamptz + interval '1 day') THEN
        RAISE EXCEPTION 'code_expired';
    END IF;

    -- Validación de email solo cuando el flujo lo exige (login con email).
    -- Si la reserva no tiene email registrado se acepta, como antes.
    IF p_email IS NOT NULL AND v_booking.guest_email IS NOT NULL THEN
        IF lower(btrim(v_booking.guest_email)) <> v_email THEN
            RAISE EXCEPTION 'email_mismatch';
        END IF;
    END IF;

    -- Vincular la reserva al usuario actual. Este UPDATE es el que nunca podía
    -- ejecutarse desde el cliente: la política de UPDATE exige que
    -- `primary_guest_user_id` YA sea `auth.uid()`, justo lo que se establece.
    UPDATE public.bookings
    SET primary_guest_user_id = v_uid,
        guest_email = CASE
            WHEN p_email IS NOT NULL AND v_email <> '' THEN v_email
            ELSE guest_email
        END,
        code_first_used_at = coalesce(code_first_used_at, now())
    WHERE id = v_booking.id
    RETURNING * INTO v_booking;

    RETURN jsonb_build_object(
        'id',                v_booking.id,
        'property_id',       v_booking.property_id,
        'unit_id',           v_booking.unit_id,
        'booking_code',      v_booking.booking_code,
        'guest_first_name',  v_booking.guest_first_name,
        'last_name',         v_booking.last_name,
        'guest_email',       v_booking.guest_email,
        'num_guests',        v_booking.num_guests,
        'checkin_date',      v_booking.checkin_date,
        'checkout_date',     v_booking.checkout_date,
        'status',            v_booking.status,
        'code_first_used_at', v_booking.code_first_used_at
    );
END;
$$;

COMMENT ON FUNCTION public.claim_booking_by_code(text, text) IS
    'Valida un código de reserva (y opcionalmente el email), vincula la reserva al usuario autenticado y devuelve sus datos basicos. Sustituye a la politica abierta bookings_anon_select_by_code. Nunca devuelve keybox_code.';

-- Solo usuarios con sesión. `anon` NO: el cliente crea sesión anónima antes de
-- llamar, y así la reserva siempre se vincula a un usuario concreto.
REVOKE ALL ON FUNCTION public.claim_booking_by_code(text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.claim_booking_by_code(text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.claim_booking_by_code(text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.claim_booking_by_code(text, text) TO service_role;
