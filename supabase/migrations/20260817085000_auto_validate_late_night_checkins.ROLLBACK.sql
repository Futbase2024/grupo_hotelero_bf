-- ============================================================================
-- ROLLBACK: Auto-validación de check-in nocturno (a partir de las 23:00)
-- ----------------------------------------------------------------------------
-- Restaura `submit_guest_checkin` y `set_booking_auto_validate_checkin` a su
-- versión previa (sólo interruptor del admin, sin regla horaria) y elimina el
-- barrido periódico.
--
-- Los check-ins ya autovalidados por la regla NO se revierten: quedan como
-- `validated`. Se pueden localizar con:
--   SELECT * FROM audit_log
--    WHERE action = 'auto_validate_checkin'
--      AND details->>'source' IN ('late_night_rule', 'late_night_sweep');
-- ============================================================================

-- ── 1. Desprogramar el barrido ──────────────────────────────────────────────
SELECT cron.unschedule('auto-validate-late-checkins')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-validate-late-checkins');

-- ── 2. Restaurar submit_guest_checkin ───────────────────────────────────────
CREATE OR REPLACE FUNCTION public.submit_guest_checkin(p_booking_id uuid, p_signature_svg text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_existing_checkin_id UUID;
  v_primary_guest_user_id UUID;
  v_auto_validate BOOLEAN;
  v_checkin_id UUID;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM bookings WHERE id = p_booking_id AND (primary_guest_user_id = auth.uid() OR primary_guest_user_id IS NULL)
  )) THEN RAISE EXCEPTION 'not_allowed'; END IF;

  SELECT primary_guest_user_id, COALESCE(auto_validate_checkin, false)
    INTO v_primary_guest_user_id, v_auto_validate
    FROM bookings WHERE id = p_booking_id;

  IF v_primary_guest_user_id IS NULL THEN
    UPDATE bookings SET primary_guest_user_id = auth.uid() WHERE id = p_booking_id;
  END IF;

  SELECT id INTO v_existing_checkin_id FROM checkins WHERE booking_id = p_booking_id;

  IF v_existing_checkin_id IS NOT NULL THEN
    UPDATE checkins SET status = 'submitted', submitted_at = NOW(), signature_svg = p_signature_svg
      WHERE id = v_existing_checkin_id;
    v_checkin_id := v_existing_checkin_id;
  ELSE
    INSERT INTO checkins (booking_id, status, submitted_at, signature_svg)
      VALUES (p_booking_id, 'submitted', NOW(), p_signature_svg)
      RETURNING id INTO v_checkin_id;
  END IF;

  -- Auto-validacion: si la reserva la tiene activada, el check-in queda validado
  -- sin intervencion del admin. Se hace con un UPDATE independiente para que el
  -- trigger trg_checkin_status_notify dispare la notificacion al huesped, igual
  -- que cuando el admin pulsa "Validar".
  IF v_auto_validate THEN
    UPDATE checkins
       SET status = 'validated', validated_at = NOW()
     WHERE id = v_checkin_id AND status = 'submitted';

    IF FOUND THEN
      INSERT INTO audit_log (action, table_name, record_id, user_id, details)
      VALUES ('auto_validate_checkin', 'checkins', v_checkin_id, auth.uid(),
              jsonb_build_object('booking_id', p_booking_id, 'new_status', 'validated', 'source', 'submit_guest_checkin'));
    END IF;
  END IF;
END; $function$;

-- ── 3. Restaurar set_booking_auto_validate_checkin ──────────────────────────
CREATE OR REPLACE FUNCTION public.set_booking_auto_validate_checkin(p_booking_id uuid, p_enabled boolean)
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

  UPDATE bookings SET auto_validate_checkin = p_enabled WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada');
  END IF;

  -- Si se activa con un check-in ya enviado y pendiente, se valida en el acto
  IF p_enabled THEN
    SELECT id, status INTO v_checkin_id, v_checkin_status
      FROM checkins WHERE booking_id = p_booking_id;

    IF v_checkin_id IS NOT NULL AND v_checkin_status = 'submitted' THEN
      UPDATE checkins SET status = 'validated', validated_at = NOW() WHERE id = v_checkin_id;
      v_validated_now := true;

      INSERT INTO audit_log (action, table_name, record_id, user_id, details)
      VALUES ('auto_validate_checkin', 'checkins', v_checkin_id, auth.uid(),
              jsonb_build_object('booking_id', p_booking_id, 'new_status', 'validated', 'source', 'set_booking_auto_validate_checkin'));
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'auto_validate_checkin', p_enabled,
    'validated_now', v_validated_now
  );
END; $function$;

-- ── 4. Eliminar las funciones nuevas ────────────────────────────────────────
DROP FUNCTION IF EXISTS public.auto_validate_late_checkins();
DROP FUNCTION IF EXISTS public.apply_checkin_validation(uuid, uuid, text);
DROP FUNCTION IF EXISTS public.is_late_checkin_window(date, text, timestamptz);
DROP FUNCTION IF EXISTS public.checkin_auto_validate_cutoff();
