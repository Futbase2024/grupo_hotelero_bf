-- ============================================================================
-- claim_booking_by_code: distinguir el motivo de un código no válido
-- ============================================================================
-- Antes, una reserva cancelada y una estancia ya terminada devolvían el mismo
-- error `code_expired`, y el huésped veía "pide un código nuevo" en ambos
-- casos. Ahora el error indica el motivo:
--
--   code_expired:booking_cancelled  → reserva cancelada
--   code_expired:stay_finished      → estancia terminada (checked_out o pasada
--                                     la fecha de salida + 1 día)
--
-- Se mantiene el prefijo `code_expired` por compatibilidad: las versiones de
-- la app que solo buscan `code_expired` en el mensaje siguen funcionando.
-- El resto de la función no cambia.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.claim_booking_by_code(p_code text, p_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
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

    IF v_booking.status = 'cancelled' THEN
        RAISE EXCEPTION 'code_expired:booking_cancelled';
    END IF;

    IF v_booking.status IS NOT NULL
       AND v_booking.status NOT IN ('confirmed', 'checked_in') THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF v_booking.checkout_date IS NOT NULL
       AND now() > (v_booking.checkout_date::timestamptz + interval '1 day') THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF p_email IS NOT NULL AND v_booking.guest_email IS NOT NULL THEN
        IF lower(btrim(v_booking.guest_email)) <> v_email THEN
            RAISE EXCEPTION 'email_mismatch';
        END IF;
    END IF;

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
$function$;
