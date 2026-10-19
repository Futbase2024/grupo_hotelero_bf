-- ============================================================================
-- ROLLBACK de 20261019120000_add_booking_deposit.sql
-- Restaura las funciones de validación a su versión previa y elimina la fianza.
-- ⚠️ Borra los datos de fianza registrados en bookings.
-- ============================================================================

BEGIN;

DROP TRIGGER IF EXISTS trg_deposit_requested_notify ON public.bookings;
DROP FUNCTION IF EXISTS public.trg_deposit_requested_notify();
DROP FUNCTION IF EXISTS public.request_booking_deposit(uuid, int, text, text[]);
DROP FUNCTION IF EXISTS public.waive_booking_deposit(uuid);
DROP FUNCTION IF EXISTS public.confirm_deposit_and_validate(uuid, text);
DROP FUNCTION IF EXISTS public.register_deposit_return(uuid, int, text);

CREATE OR REPLACE FUNCTION public.apply_checkin_validation(p_checkin_id uuid, p_booking_id uuid, p_source text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE checkins
     SET status = 'validated', validated_at = NOW()
   WHERE id = p_checkin_id
     AND status = 'submitted';

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  UPDATE bookings
     SET status = 'checked_in'
   WHERE id = p_booking_id
     AND status = 'confirmed';

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('auto_validate_checkin', 'checkins', p_checkin_id, auth.uid(),
          jsonb_build_object(
            'booking_id', p_booking_id,
            'new_status', 'validated',
            'source',     p_source
          ));

  RETURN true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_checkin(p_checkin_id uuid, p_staff_user_id uuid DEFAULT auth.uid())
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_booking_id UUID; v_current_status TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN RAISE EXCEPTION 'not_allowed: se requiere rol staff'; END IF;
  SELECT booking_id, status INTO v_booking_id, v_current_status FROM checkins WHERE id = p_checkin_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Check-in not found'; END IF;
  IF v_current_status != 'submitted' THEN
    RAISE EXCEPTION 'Check-in must be in submitted status to validate. Current status: %', v_current_status; END IF;
  UPDATE checkins SET status = 'validated', validated_at = NOW() WHERE id = p_checkin_id;
  UPDATE bookings SET status = 'checked_in' WHERE id = v_booking_id;
  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('validate_checkin', 'checkins', p_checkin_id, p_staff_user_id, jsonb_build_object('booking_id', v_booking_id, 'new_status', 'validated'));
END; $function$;

CREATE OR REPLACE FUNCTION public.manual_checkin_validate(p_booking_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_checkin_id UUID; v_booking RECORD; v_result JSONB;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN RAISE EXCEPTION 'not_allowed: se requiere rol staff'; END IF;
  SELECT b.id, b.property_id, b.unit_id, b.booking_code, b.guest_first_name, b.last_name, b.guest_email, b.guest_phone,
    b.status, b.checkin_date, b.checkout_date INTO v_booking FROM bookings b WHERE b.id = p_booking_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada'); END IF;
  SELECT id INTO v_checkin_id FROM checkins WHERE booking_id = p_booking_id;
  IF v_checkin_id IS NULL THEN
    INSERT INTO checkins (id, booking_id, property_id, status, validated_at, created_at, updated_at)
    VALUES (gen_random_uuid(), p_booking_id, v_booking.property_id, 'validated', NOW(), NOW(), NOW()) RETURNING id INTO v_checkin_id;
    INSERT INTO checkin_guests (id, checkin_id, full_name, email, phone, is_primary, created_at)
    VALUES (gen_random_uuid(), v_checkin_id, COALESCE(v_booking.guest_first_name || ' ' || v_booking.last_name, 'Huésped'),
      v_booking.guest_email, v_booking.guest_phone, true, NOW());
  ELSE
    UPDATE checkins SET status = 'validated', validated_at = NOW(), updated_at = NOW()
    WHERE id = v_checkin_id AND status IN ('draft', 'not_started', 'in_progress', 'submitted');
    IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'El check-in ya está validado, rechazado o cancelado'); END IF;
  END IF;
  UPDATE bookings SET status = 'checked_in' WHERE id = p_booking_id;
  RETURN jsonb_build_object('success', true, 'checkin_id', v_checkin_id, 'message', 'Check-in manual validado correctamente');
END; $function$;

ALTER TABLE public.properties DROP COLUMN IF EXISTS default_deposit_cents;

ALTER TABLE public.bookings
  DROP COLUMN IF EXISTS deposit_status,
  DROP COLUMN IF EXISTS deposit_amount_cents,
  DROP COLUMN IF EXISTS deposit_payment_link,
  DROP COLUMN IF EXISTS deposit_sent_via,
  DROP COLUMN IF EXISTS deposit_requested_at,
  DROP COLUMN IF EXISTS deposit_requested_by,
  DROP COLUMN IF EXISTS deposit_paid_at,
  DROP COLUMN IF EXISTS deposit_paid_by,
  DROP COLUMN IF EXISTS deposit_reference,
  DROP COLUMN IF EXISTS deposit_returned_at,
  DROP COLUMN IF EXISTS deposit_returned_by,
  DROP COLUMN IF EXISTS deposit_returned_cents,
  DROP COLUMN IF EXISTS deposit_retained_cents,
  DROP COLUMN IF EXISTS deposit_retained_reason;

COMMIT;
