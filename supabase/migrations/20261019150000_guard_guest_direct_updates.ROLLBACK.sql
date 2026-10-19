-- ============================================================================
-- ROLLBACK de 20261019150000_guard_guest_direct_updates.sql
-- ⚠️ Vuelve a dejar que el huésped modifique directamente su check-in y la
--    fianza de su reserva.
-- ============================================================================

BEGIN;

DROP TRIGGER IF EXISTS trg_guard_checkin_direct_update ON public.checkins;
DROP TRIGGER IF EXISTS trg_guard_booking_direct_update ON public.bookings;
DROP FUNCTION IF EXISTS public.trg_guard_checkin_direct_update();
DROP FUNCTION IF EXISTS public.trg_guard_booking_direct_update();
DROP FUNCTION IF EXISTS public.is_direct_non_staff_write();

COMMIT;
