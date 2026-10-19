-- ============================================================================
-- Fianza opcional por reserva (validación parcial del check-in)
-- ----------------------------------------------------------------------------
-- El admin puede, SOLO en las reservas que quiera, pedir una fianza antes de
-- validar el check-in. El pago no pasa por la app: el admin envía el enlace de
-- su pasarela (chat / WhatsApp / email), comprueba el cobro y lo marca como
-- pagado, lo que valida el check-in con el flujo de siempre.
--
-- Mientras la fianza está 'pending' el check-in se queda en 'submitted', así
-- que el huésped no ve códigos (get_access_for_booking exige 'validated').
-- Todas las vías de validación quedan bloqueadas mientras esté pendiente.
--
-- Por defecto deposit_status = 'none' => las reservas existentes y las nuevas
-- funcionan exactamente igual que antes.
--
-- Plan: .claude/plans/fianza_validacion_parcial_plan.md
-- Rollback exacto en: 20261019120000_add_booking_deposit.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Columnas
-- ----------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN deposit_status text NOT NULL DEFAULT 'none'
    CONSTRAINT bookings_deposit_status_check
    CHECK (deposit_status IN ('none', 'pending', 'paid', 'returned')),
  ADD COLUMN deposit_amount_cents int
    CONSTRAINT bookings_deposit_amount_check CHECK (deposit_amount_cents > 0),
  ADD COLUMN deposit_payment_link text,
  ADD COLUMN deposit_sent_via text[],
  ADD COLUMN deposit_requested_at timestamptz,
  ADD COLUMN deposit_requested_by uuid,
  ADD COLUMN deposit_paid_at timestamptz,
  ADD COLUMN deposit_paid_by uuid,
  ADD COLUMN deposit_reference text,
  ADD COLUMN deposit_returned_at timestamptz,
  ADD COLUMN deposit_returned_by uuid,
  ADD COLUMN deposit_returned_cents int,
  ADD COLUMN deposit_retained_cents int,
  ADD COLUMN deposit_retained_reason text;

COMMENT ON COLUMN public.bookings.deposit_status IS
  'Fianza opcional: none (sin fianza) | pending (pedida, bloquea validación) | paid | returned';

-- Importe sugerido al pedir la fianza. Nunca aplica fianza automáticamente.
ALTER TABLE public.properties
  ADD COLUMN default_deposit_cents int
    CONSTRAINT properties_default_deposit_check CHECK (default_deposit_cents > 0);

-- ----------------------------------------------------------------------------
-- 2) Bloqueo en las vías de validación existentes
-- ----------------------------------------------------------------------------

-- Embudo único de la auto-validación (interruptor, regla nocturna y cron)
CREATE OR REPLACE FUNCTION public.apply_checkin_validation(p_checkin_id uuid, p_booking_id uuid, p_source text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Fianza pendiente: nunca auto-validar
  IF EXISTS (
    SELECT 1 FROM bookings WHERE id = p_booking_id AND deposit_status = 'pending'
  ) THEN
    RETURN false;
  END IF;

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

-- Validación normal del admin
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
  IF EXISTS (SELECT 1 FROM bookings WHERE id = v_booking_id AND deposit_status = 'pending') THEN
    RAISE EXCEPTION 'deposit_pending: la reserva tiene una fianza pendiente de pago';
  END IF;
  UPDATE checkins SET status = 'validated', validated_at = NOW() WHERE id = p_checkin_id;
  UPDATE bookings SET status = 'checked_in' WHERE id = v_booking_id;
  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('validate_checkin', 'checkins', p_checkin_id, p_staff_user_id, jsonb_build_object('booking_id', v_booking_id, 'new_status', 'validated'));
END; $function$;

-- Validación manual sin datos del huésped
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
    b.status, b.checkin_date, b.checkout_date, b.deposit_status INTO v_booking FROM bookings b WHERE b.id = p_booking_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada'); END IF;
  IF v_booking.deposit_status = 'pending' THEN
    RETURN jsonb_build_object('success', false, 'error', 'deposit_pending: la reserva tiene una fianza pendiente de pago');
  END IF;
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

-- ----------------------------------------------------------------------------
-- 3) RPCs de fianza (solo staff)
-- ----------------------------------------------------------------------------

-- Pedir (o reenviar) la fianza. Se puede pedir en cualquier momento antes de
-- validar; si se pide antes de que el huésped envíe el check-in, la
-- auto-validación ya quedará bloqueada.
CREATE OR REPLACE FUNCTION public.request_booking_deposit(
  p_booking_id uuid,
  p_amount_cents int,
  p_payment_link text,
  p_sent_via text[]
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_deposit_status TEXT;
  v_checkin_status TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  IF p_amount_cents IS NULL OR p_amount_cents <= 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'El importe debe ser mayor que 0');
  END IF;

  IF p_payment_link IS NULL OR p_payment_link !~* '^https?://' THEN
    RETURN jsonb_build_object('success', false, 'error', 'El enlace de pago no es válido');
  END IF;

  IF p_sent_via IS NULL OR NOT (p_sent_via <@ ARRAY['chat', 'whatsapp', 'email']) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Canal de envío no válido');
  END IF;

  SELECT b.deposit_status, c.status
    INTO v_deposit_status, v_checkin_status
    FROM bookings b
    LEFT JOIN checkins c ON c.booking_id = b.id
   WHERE b.id = p_booking_id
     FOR UPDATE OF b;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada');
  END IF;

  IF v_deposit_status NOT IN ('none', 'pending') THEN
    RETURN jsonb_build_object('success', false, 'error', 'La fianza de esta reserva ya está pagada o devuelta');
  END IF;

  IF v_checkin_status IN ('validated', 'cancelled') THEN
    RETURN jsonb_build_object('success', false, 'error', 'El check-in ya está validado o cancelado');
  END IF;

  UPDATE bookings
     SET deposit_status       = 'pending',
         deposit_amount_cents = p_amount_cents,
         deposit_payment_link = p_payment_link,
         deposit_sent_via     = p_sent_via,
         deposit_requested_at = NOW(),
         deposit_requested_by = auth.uid()
   WHERE id = p_booking_id;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('request_booking_deposit', 'bookings', p_booking_id, auth.uid(),
          jsonb_build_object(
            'amount_cents', p_amount_cents,
            'sent_via',     p_sent_via,
            'resend',       v_deposit_status = 'pending'
          ));

  RETURN jsonb_build_object('success', true, 'resend', v_deposit_status = 'pending');
END;
$function$;

-- Eximir: quita la fianza pendiente y la reserva vuelve a la validación normal
CREATE OR REPLACE FUNCTION public.waive_booking_deposit(p_booking_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  UPDATE bookings
     SET deposit_status       = 'none',
         deposit_amount_cents = NULL,
         deposit_payment_link = NULL,
         deposit_sent_via     = NULL,
         deposit_requested_at = NULL,
         deposit_requested_by = NULL
   WHERE id = p_booking_id
     AND deposit_status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'La reserva no tiene una fianza pendiente');
  END IF;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('waive_booking_deposit', 'bookings', p_booking_id, auth.uid(), '{}'::jsonb);

  RETURN jsonb_build_object('success', true);
END;
$function$;

-- Marcar la fianza como pagada (el admin lo comprobó en su pasarela) y, si el
-- check-in ya está enviado, validarlo con el flujo de siempre. Si aún no lo ha
-- enviado, solo queda pagada: al enviarlo seguirá el curso normal.
CREATE OR REPLACE FUNCTION public.confirm_deposit_and_validate(
  p_booking_id uuid,
  p_reference text DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_checkin_id UUID;
  v_checkin_status TEXT;
  v_validated_now BOOLEAN := false;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  UPDATE bookings
     SET deposit_status    = 'paid',
         deposit_paid_at   = NOW(),
         deposit_paid_by   = auth.uid(),
         deposit_reference = NULLIF(TRIM(p_reference), '')
   WHERE id = p_booking_id
     AND deposit_status = 'pending';

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'La reserva no tiene una fianza pendiente');
  END IF;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('confirm_booking_deposit', 'bookings', p_booking_id, auth.uid(),
          jsonb_build_object('reference', NULLIF(TRIM(p_reference), '')));

  SELECT id, status INTO v_checkin_id, v_checkin_status
    FROM checkins WHERE booking_id = p_booking_id;

  IF v_checkin_status = 'submitted' THEN
    PERFORM public.validate_checkin(v_checkin_id, auth.uid());
    v_validated_now := true;
  END IF;

  RETURN jsonb_build_object(
    'success',       true,
    'validated_now', v_validated_now,
    'checkin_id',    v_checkin_id
  );
END;
$function$;

-- Registrar la devolución tras el check-out (total o parcial, para control)
CREATE OR REPLACE FUNCTION public.register_deposit_return(
  p_booking_id uuid,
  p_returned_cents int,
  p_retained_reason text DEFAULT NULL
)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_amount INT;
  v_retained INT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT deposit_amount_cents INTO v_amount
    FROM bookings
   WHERE id = p_booking_id AND deposit_status = 'paid'
     FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'La reserva no tiene una fianza pagada');
  END IF;

  IF p_returned_cents IS NULL OR p_returned_cents < 0 OR p_returned_cents > v_amount THEN
    RETURN jsonb_build_object('success', false, 'error', 'El importe devuelto debe estar entre 0 y el importe de la fianza');
  END IF;

  v_retained := v_amount - p_returned_cents;

  IF v_retained > 0 AND NULLIF(TRIM(p_retained_reason), '') IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Indica el motivo del importe retenido');
  END IF;

  UPDATE bookings
     SET deposit_status          = 'returned',
         deposit_returned_at     = NOW(),
         deposit_returned_by     = auth.uid(),
         deposit_returned_cents  = p_returned_cents,
         deposit_retained_cents  = v_retained,
         deposit_retained_reason = CASE WHEN v_retained > 0 THEN TRIM(p_retained_reason) END
   WHERE id = p_booking_id;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('register_deposit_return', 'bookings', p_booking_id, auth.uid(),
          jsonb_build_object(
            'returned_cents', p_returned_cents,
            'retained_cents', v_retained,
            'reason',         CASE WHEN v_retained > 0 THEN TRIM(p_retained_reason) END
          ));

  RETURN jsonb_build_object('success', true, 'retained_cents', v_retained);
END;
$function$;

-- ----------------------------------------------------------------------------
-- 4) Aviso al huésped cuando se le pide (o reenvía) la fianza
--    Sin enlace ni códigos: solo le indica que revise el enlace recibido.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_deposit_requested_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_title TEXT := '💶 Fianza pendiente';
  v_body  TEXT := 'Te hemos enviado el enlace para abonar la fianza. Cuando la recibamos validaremos tu check-in.';
BEGIN
  IF NEW.deposit_status <> 'pending' THEN
    RETURN NEW;
  END IF;

  -- Solo al pedirla por primera vez o al reenviarla
  IF OLD.deposit_status = 'pending'
     AND NEW.deposit_requested_at IS NOT DISTINCT FROM OLD.deposit_requested_at THEN
    RETURN NEW;
  END IF;

  IF NEW.primary_guest_user_id IS NULL THEN
    RETURN NEW;  -- el huésped aún no ha entrado en la app
  END IF;

  INSERT INTO public.guest_notifications (
    user_id, booking_id, type, title, body, data, is_read
  ) VALUES (
    NEW.primary_guest_user_id,
    NEW.id,
    'deposit_requested',
    v_title,
    v_body,
    jsonb_build_object('deposit_status', NEW.deposit_status),
    false
  );

  PERFORM public.notify_fcm(jsonb_build_object(
    'user_id',    NEW.primary_guest_user_id,
    'booking_id', NEW.id,
    'type',       'checkin_deposit',
    'title',      v_title,
    'body',       v_body,
    'data',       jsonb_build_object(
      'type',           'checkin_deposit',
      'booking_id',     NEW.id::TEXT,
      'deposit_status', NEW.deposit_status
    )
  ));

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_deposit_requested_notify ON public.bookings;

CREATE TRIGGER trg_deposit_requested_notify
  AFTER UPDATE OF deposit_status, deposit_requested_at ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_deposit_requested_notify();

-- ----------------------------------------------------------------------------
-- 5) Permisos (mismo criterio que 20260710120000_revoke_anon_execute...)
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.trg_deposit_requested_notify() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_deposit_requested_notify() TO service_role;

REVOKE EXECUTE ON FUNCTION public.request_booking_deposit(uuid, int, text, text[]) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_booking_deposit(uuid, int, text, text[]) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.waive_booking_deposit(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.waive_booking_deposit(uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.confirm_deposit_and_validate(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.confirm_deposit_and_validate(uuid, text) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.register_deposit_return(uuid, int, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.register_deposit_return(uuid, int, text) TO authenticated, service_role;

COMMIT;
