-- Rollback de 20261115130000_grant_traveller_form_enabled_select.sql
-- ⚠️ El panel y la app dejarán de poder leer el interruptor.

REVOKE SELECT (traveller_form_enabled) ON public.bookings FROM authenticated;
