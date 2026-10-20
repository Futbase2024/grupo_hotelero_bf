-- ============================================================================
-- ROLLBACK de 20260815120000_extra_requests_romantic_pack_rules.sql
-- ----------------------------------------------------------------------------
-- NOTA: el borrado de solicitudes duplicadas NO es reversible.
-- ============================================================================

DROP TRIGGER IF EXISTS trg_extra_requests_check_request_window
  ON public.extra_requests;

DROP FUNCTION IF EXISTS public.extra_requests_check_request_window();

DROP INDEX IF EXISTS public.uq_extra_requests_romantic_pack_per_booking;
