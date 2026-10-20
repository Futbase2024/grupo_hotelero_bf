-- ROLLBACK de 20260909130000_claim_booking_by_code_rpc.sql
--
-- Solo aplicable si la app publicada NO usa todavía el RPC (o se ha revertido
-- el cliente): sin él, el login por código depende de la política abierta
-- `bookings_anon_select_by_code`, que debe seguir existiendo.

DROP FUNCTION IF EXISTS public.claim_booking_by_code(text, text);
