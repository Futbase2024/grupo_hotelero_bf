-- ============================================================================
-- Auto-validación de check-in nocturno (a partir de las 23:00)
-- ----------------------------------------------------------------------------
-- Reglas de negocio:
--   1. `bookings.auto_validate_checkin` (interruptor del admin) sigue igual:
--      si está activado, el check-in se autovalida a cualquier hora.
--   2. NUEVO: a partir de las 23:00 hora local de la propiedad del día de
--      entrada (`bookings.checkin_date`), y SIN límite superior, el check-in se
--      autovalida siempre, tenga o no el interruptor activado.
--   3. La regla se aplica tanto en el momento del envío como en un barrido
--      periódico, para que un check-in enviado antes de las 23:00 y no revisado
--      no se quede esperando de madrugada.
--
-- Notas de implementación:
--   - La BD corre en UTC. El corte se calcula SIEMPRE con `AT TIME ZONE` sobre
--     la zona de la propiedad (fallback 'Europe/Madrid') para que el cambio
--     CEST/CET no desplace el corte una hora.
--   - Por ese mismo motivo el cron NO se programa a una hora UTC fija: corre
--     cada 15 min y la condición horaria se evalúa dentro de la función.
--   - Se corrige de paso que las rutas de auto-validación no dejaban la reserva
--     en `checked_in`, cosa que sí hace `validate_checkin` (validación manual).
-- ============================================================================

-- ── 1. Hora de corte (fuente única en SQL) ──────────────────────────────────
-- Espejo de `CheckinPolicy.autoValidateAfterHour` en Dart.
CREATE OR REPLACE FUNCTION public.checkin_auto_validate_cutoff()
RETURNS time
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $function$ SELECT TIME '23:00' $function$;

COMMENT ON FUNCTION public.checkin_auto_validate_cutoff() IS
  'Hora (local de la propiedad) del día de entrada a partir de la cual el check-in se autovalida solo.';

-- ── 2. ¿Estamos en la ventana nocturna de la reserva? ───────────────────────
CREATE OR REPLACE FUNCTION public.is_late_checkin_window(
  p_checkin_date date,
  p_timezone     text        DEFAULT 'Europe/Madrid',
  p_at           timestamptz DEFAULT now()
)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
  SELECT p_checkin_date IS NOT NULL
     AND (p_at AT TIME ZONE COALESCE(NULLIF(p_timezone, ''), 'Europe/Madrid'))
         >= (p_checkin_date + public.checkin_auto_validate_cutoff());
$function$;

COMMENT ON FUNCTION public.is_late_checkin_window(date, text, timestamptz) IS
  'TRUE si ya pasaron las 23:00 locales del día de entrada. Sin límite superior.';

-- ── 3. Helper interno: aplicar la validación de forma uniforme ──────────────
-- Un único sitio donde se decide qué implica "validar": estado del check-in,
-- estado de la reserva y traza en audit_log.
CREATE OR REPLACE FUNCTION public.apply_checkin_validation(
  p_checkin_id uuid,
  p_booking_id uuid,
  p_source     text
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
BEGIN
  -- UPDATE propio (y condicionado a 'submitted') para que dispare
  -- trg_checkin_status_notify y para que sea idempotente.
  UPDATE checkins
     SET status = 'validated', validated_at = NOW()
   WHERE id = p_checkin_id
     AND status = 'submitted';

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Igual que validate_checkin (validación manual del admin), pero sin revivir
  -- reservas ya cerradas o canceladas.
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

-- Función interna: nadie la llama directamente desde el cliente.
REVOKE ALL ON FUNCTION public.apply_checkin_validation(uuid, uuid, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.apply_checkin_validation(uuid, uuid, text) FROM anon, authenticated;

-- ── 4. Envío del check-in: interruptor OR regla nocturna ────────────────────
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
  v_checkin_date DATE;
  v_timezone TEXT;
  v_is_late BOOLEAN;
  v_checkin_id UUID;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM bookings WHERE id = p_booking_id AND (primary_guest_user_id = auth.uid() OR primary_guest_user_id IS NULL)
  )) THEN RAISE EXCEPTION 'not_allowed'; END IF;

  SELECT b.primary_guest_user_id,
         COALESCE(b.auto_validate_checkin, false),
         b.checkin_date,
         COALESCE(p.timezone, 'Europe/Madrid')
    INTO v_primary_guest_user_id, v_auto_validate, v_checkin_date, v_timezone
    FROM bookings b
    LEFT JOIN properties p ON p.id = b.property_id
   WHERE b.id = p_booking_id;

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

  -- Auto-validacion. Dos motivos independientes:
  --   a) la reserva tiene el interruptor del admin activado (cualquier hora)
  --   b) ya pasaron las 23:00 locales del dia de entrada (llegada nocturna)
  v_is_late := public.is_late_checkin_window(v_checkin_date, v_timezone);

  IF v_auto_validate OR v_is_late THEN
    PERFORM public.apply_checkin_validation(
      v_checkin_id,
      p_booking_id,
      CASE WHEN v_auto_validate THEN 'auto_validate_flag' ELSE 'late_night_rule' END
    );
  END IF;
END;
$function$;

-- ── 5. Interruptor del admin: reusar el helper ──────────────────────────────
CREATE OR REPLACE FUNCTION public.set_booking_auto_validate_checkin(p_booking_id uuid, p_enabled boolean)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_checkin_id UUID;
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
    SELECT id INTO v_checkin_id FROM checkins WHERE booking_id = p_booking_id;

    IF v_checkin_id IS NOT NULL THEN
      v_validated_now := public.apply_checkin_validation(
        v_checkin_id, p_booking_id, 'set_booking_auto_validate_checkin'
      );
    END IF;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'auto_validate_checkin', p_enabled,
    'validated_now', v_validated_now
  );
END;
$function$;

-- ── 6. Barrido periódico de check-ins pendientes en ventana ─────────────────
CREATE OR REPLACE FUNCTION public.auto_validate_late_checkins()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_row RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_row IN
    SELECT c.id AS checkin_id, b.id AS booking_id
      FROM checkins c
      JOIN bookings b ON b.id = c.booking_id
      LEFT JOIN properties p ON p.id = b.property_id
     WHERE c.status = 'submitted'
       AND b.status NOT IN ('checked_out', 'cancelled')
       AND public.is_late_checkin_window(b.checkin_date, COALESCE(p.timezone, 'Europe/Madrid'))
  LOOP
    IF public.apply_checkin_validation(v_row.checkin_id, v_row.booking_id, 'late_night_sweep') THEN
      v_count := v_count + 1;
    END IF;
  END LOOP;

  RETURN v_count;
END;
$function$;

REVOKE ALL ON FUNCTION public.auto_validate_late_checkins() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.auto_validate_late_checkins() FROM anon, authenticated;

COMMENT ON FUNCTION public.auto_validate_late_checkins() IS
  'Barrido: valida los check-ins pendientes cuya reserva ya pasó las 23:00 locales del día de entrada. Idempotente.';

-- ── 7. Programación del barrido ─────────────────────────────────────────────
-- Cada 15 min en vez de "a las 23:00": el cron trabaja en UTC y una hora fija
-- se desplazaría con el horario de verano. La condición real vive en la función.
SELECT cron.unschedule('auto-validate-late-checkins')
 WHERE EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'auto-validate-late-checkins');

SELECT cron.schedule(
  'auto-validate-late-checkins',
  '*/15 * * * *',
  $cron$ SELECT public.auto_validate_late_checkins(); $cron$
);
