-- ============================================================================
-- ROLLBACK de 20261003170000_fix_guest_self_checkout.sql
-- ----------------------------------------------------------------------------
-- ⚠️ Volver a esta política rompe el check-out de las apps que hacen el
-- UPDATE directo (ver cabecera de la migración).
-- ============================================================================

DROP FUNCTION IF EXISTS public.complete_guest_checkout(uuid, text, integer);

DROP POLICY IF EXISTS "bookings_guest_select_own" ON public.bookings;
CREATE POLICY "bookings_guest_select_own" ON public.bookings
  FOR SELECT
  USING (
    primary_guest_user_id = (SELECT auth.uid())
    AND status IN ('confirmed', 'checked_in')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() < public.booking_access_ends_at(property_id, checkout_date)
  );

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
  PERFORM set_config('bf.silent_close', 'on', true);

  UPDATE public.bookings
  SET booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = coalesce(closed_at, now()),
      checkout_validated_at = coalesce(checkout_validated_at, now()),
      updated_at            = now()
  WHERE status = 'checked_out'
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() >= public.booking_access_ends_at(property_id, checkout_date);
  GET DIAGNOSTICS v_silent = ROW_COUNT;

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
