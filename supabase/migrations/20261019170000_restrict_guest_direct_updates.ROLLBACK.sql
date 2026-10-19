-- ============================================================================
-- ROLLBACK de 20261019170000_restrict_guest_direct_updates.sql
-- ⚠️ Devuelve al huésped el UPDATE directo de su reserva y su check-in, y deja
--    que service_role valide aunque haya fianza pendiente.
-- ============================================================================

BEGIN;

CREATE POLICY bookings_guest_update_own_simple ON public.bookings
  FOR UPDATE
  USING (primary_guest_user_id = (SELECT auth.uid() AS uid))
  WITH CHECK (primary_guest_user_id = (SELECT auth.uid() AS uid));

DROP POLICY IF EXISTS checkins_update ON public.checkins;

CREATE POLICY checkins_update ON public.checkins
  FOR UPDATE
  USING (
    (is_staff() AND EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND (is_admin() OR b.property_id = current_property_id())
    ))
    OR EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND b.primary_guest_user_id = (SELECT auth.uid() AS uid)
    )
  )
  WITH CHECK (
    (is_staff() AND EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND (is_admin() OR b.property_id = current_property_id())
    ))
    OR EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND b.primary_guest_user_id = (SELECT auth.uid() AS uid)
    )
  );

-- Versión de 20261019150000 (sin el bloqueo universal por fianza)
CREATE OR REPLACE FUNCTION public.trg_guard_checkin_direct_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.is_direct_non_staff_write() AND (
       (NEW.status = 'validated' AND OLD.status IS DISTINCT FROM 'validated')
    OR NEW.validated_at IS DISTINCT FROM OLD.validated_at
  ) THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede validar un check-in'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

COMMIT;
