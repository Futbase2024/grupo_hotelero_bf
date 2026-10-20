-- ============================================================================
-- RPC get_guest_access: única vía del huésped para obtener sus códigos
-- ----------------------------------------------------------------------------
-- Devuelve en un solo JSON lo que pintan "Mi alojamiento", "Instrucciones de
-- acceso" y la "Guía": código del portal, keybox_code de la reserva y, por cada
-- unidad, caja, ubicación, taquilla, WiFi e instrucciones.
--
-- Los secretos solo salen si can_view_booking_secrets() lo permite (staff,
-- service_role o el huésped de esa reserva con check-in validado y dentro de su
-- estancia). Si no, salen a null y `reason` explica por qué, junto con las
-- fechas para que la app muestre "disponible a las…". La regla de las 14:00 /
-- early check-in sigue en la UI.
--
-- Es aditiva: las apps instaladas no la usan. Cuando todas usen esta RPC
-- (fase 3) se podrán cerrar las lecturas directas de units y bookings.
--
-- Plan: .claude/plans/proteger_secretos_huesped_plan.md (fase 2, paso 1)
-- Rollback: 20261020130000_get_guest_access.ROLLBACK.sql
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.get_guest_access(p_booking_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  b record;
  v_timezone text;
  v_can_view boolean;
  v_reason text;
  v_main_door_keycode text;
  v_units jsonb;
BEGIN
  IF auth.uid() IS NULL AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO b FROM public.bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT (
    b.primary_guest_user_id = auth.uid()
    OR auth.role() = 'service_role'
    OR (public.is_staff() AND (public.is_admin() OR b.property_id = public.current_property_id()))
  ) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  SELECT p.timezone, p.main_door_keycode
    INTO v_timezone, v_main_door_keycode
    FROM private.properties p
   WHERE p.id = b.property_id;

  v_can_view := public.can_view_booking_secrets(b.id);

  IF v_can_view THEN
    v_reason := 'ok';
  ELSIF b.status NOT IN ('confirmed', 'checked_in')
        OR coalesce(b.booking_status, 'created') IN ('closed', 'cancelled')
        OR now() >= public.booking_access_ends_at(b.property_id, b.checkout_date) THEN
    v_reason := 'outside_window';
  ELSIF NOT EXISTS (
          SELECT 1 FROM public.checkins c
           WHERE c.booking_id = b.id AND c.status = 'validated') THEN
    v_reason := 'checkin_not_validated';
  ELSE
    v_reason := 'before_checkin';
  END IF;

  -- Unidades de la reserva: las de booking_units o, si no hay, la principal.
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'unit_id', u.id,
           'name', u.name,
           'wifi_network', u.wifi_network,
           'wifi_password', CASE WHEN v_can_view THEN u.wifi_password END,
           'box_code', CASE WHEN v_can_view THEN u.box_code END,
           'box_location_text', CASE WHEN v_can_view THEN u.box_location_text END,
           'locker_number', CASE WHEN v_can_view THEN u.locker_number END,
           'access_instructions', CASE WHEN v_can_view THEN u.access_instructions END,
           'welcome_instructions', CASE WHEN v_can_view THEN u.welcome_instructions END
         ) ORDER BY (u.id = b.unit_id) DESC, x.ord), '[]'::jsonb)
    INTO v_units
    FROM (
      SELECT bu.unit_id, bu.created_at AS ord
        FROM public.booking_units bu
       WHERE bu.booking_id = b.id
      UNION ALL
      SELECT b.unit_id, NULL
       WHERE b.unit_id IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM public.booking_units bu WHERE bu.booking_id = b.id)
    ) x
    JOIN public.units u ON u.id = x.unit_id;

  RETURN jsonb_build_object(
    'booking_id', b.id,
    'can_view', v_can_view,
    'reason', v_reason,
    'checkin_date', b.checkin_date,
    'checkout_date', b.checkout_date,
    'early_checkin_available_at', b.early_checkin_available_at,
    'timezone', coalesce(v_timezone, 'Europe/Madrid'),
    'server_time', now(),
    'keybox_code', CASE WHEN v_can_view THEN b.keybox_code END,
    'main_door_keycode', CASE WHEN v_can_view THEN v_main_door_keycode END,
    'units', v_units
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_guest_access(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_guest_access(uuid) TO authenticated, service_role;

COMMIT;
