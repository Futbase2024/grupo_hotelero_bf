-- ============================================================================
-- Check-out del huésped: cierre completo de la reserva
-- ----------------------------------------------------------------------------
-- PROBLEMA
--   · El check-out desde la app del huésped hace un UPDATE directo que solo
--     pone `status = 'checked_out'`: la reserva quedaba con
--     `booking_status = 'created'` (323 reservas así hasta hoy).
--   · Tras 20261003160000, ese UPDATE falla: un UPDATE con WHERE exige que la
--     fila resultante siga pasando las políticas SELECT, y
--     `bookings_guest_select_own` ya no admitía `checked_out`.
--
-- SOLUCIÓN
--   1. `bookings_guest_select_own` admite `checked_out` mientras la reserva no
--      esté cerrada (y siempre antes de la hora de salida), para que las apps
--      publicadas puedan seguir haciendo su UPDATE.
--   2. `auto_close_finished_bookings()` cierra esas salidas en el siguiente
--      ciclo (≤ 5 min), sin esperar a la hora de check-out y sin push.
--   3. RPC `complete_guest_checkout()`: la app nueva cierra la reserva entera
--      en una sola llamada.
--
-- Rollback: 20261003170000_fix_guest_self_checkout.ROLLBACK.sql
-- ============================================================================

-- 1. RLS --------------------------------------------------------------------
DROP POLICY IF EXISTS "bookings_guest_select_own" ON public.bookings;

CREATE POLICY "bookings_guest_select_own" ON public.bookings
  FOR SELECT
  USING (
    primary_guest_user_id = (SELECT auth.uid())
    AND status IN ('confirmed', 'checked_in', 'checked_out')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() < public.booking_access_ends_at(property_id, checkout_date)
  );

-- 2. Cierre automático ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auto_close_finished_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_silent integer;
  v_active integer;
BEGIN
  -- a) Salida ya hecha (por el huésped o a mano) pero reserva sin cerrar:
  --    se cierra en cuanto se detecta, sin push.
  PERFORM set_config('bf.silent_close', 'on', true);

  UPDATE public.bookings
  SET booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = coalesce(closed_at, now()),
      checkout_validated_at = coalesce(checkout_validated_at, now()),
      updated_at            = now()
  WHERE status = 'checked_out'
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled');
  GET DIAGNOSTICS v_silent = ROW_COUNT;

  -- b) Estancias que siguen abiertas pasada la hora de salida: cierre con push.
  PERFORM set_config('bf.silent_close', 'off', true);

  UPDATE public.bookings
  SET status                = 'checked_out',
      booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = coalesce(closed_at, now()),
      checkout_validated_at = coalesce(checkout_validated_at, now()),
      checkout_notes        = coalesce(checkout_notes, 'Auto-closed: checkout time passed'),
      updated_at            = now()
  WHERE status IN ('confirmed', 'checked_in')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() >= public.booking_access_ends_at(property_id, checkout_date);
  GET DIAGNOSTICS v_active = ROW_COUNT;

  RETURN v_silent + v_active;
END;
$function$;

REVOKE ALL ON FUNCTION public.auto_close_finished_bookings() FROM PUBLIC, anon, authenticated;

-- 3. RPC de check-out del huésped -------------------------------------------
CREATE OR REPLACE FUNCTION public.complete_guest_checkout(
  p_booking_id uuid,
  p_feedback text DEFAULT NULL,
  p_rating integer DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_updated integer;
BEGIN
  IF NOT (
    public.is_staff()
    OR EXISTS (
      SELECT 1 FROM public.bookings
      WHERE id = p_booking_id
        AND primary_guest_user_id = auth.uid()
    )
  ) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  UPDATE public.checkins
  SET checkout_status   = 'completed',
      checkout_at       = now(),
      checkout_feedback = p_feedback,
      checkout_rating   = p_rating,
      updated_at        = now()
  WHERE booking_id = p_booking_id;

  -- El huésped está en la app haciendo el check-out: sin push.
  PERFORM set_config('bf.silent_close', 'on', true);

  UPDATE public.bookings
  SET status                = 'checked_out',
      booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = now(),
      checkout_validated_at = now(),
      checkout_notes        = coalesce(checkout_notes, 'Check-out realizado por el huésped'),
      updated_at            = now()
  WHERE id = p_booking_id
    AND status IN ('confirmed', 'checked_in')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled');
  GET DIAGNOSTICS v_updated = ROW_COUNT;

  PERFORM set_config('bf.silent_close', 'off', true);

  RETURN v_updated > 0;
END;
$function$;

REVOKE ALL ON FUNCTION public.complete_guest_checkout(uuid, text, integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.complete_guest_checkout(uuid, text, integer) TO authenticated;
