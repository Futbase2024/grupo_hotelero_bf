-- ============================================================================
-- Registro de viajeros — 5: lectura del interruptor traveller_form_enabled
-- ----------------------------------------------------------------------------
-- `bookings` tiene permisos de SELECT por columna (para ocultar keybox_code y
-- otros secretos). Las columnas nuevas no heredan el permiso, así que ni el
-- staff (panel) ni el huésped (para saber qué check-in mostrar) podían leer
-- traveller_form_enabled. Es un booleano sin datos sensibles; la RLS sigue
-- limitando QUÉ reservas ve cada uno.
--
-- Rollback: 20261115130000_grant_traveller_form_enabled_select.ROLLBACK.sql
-- ============================================================================

GRANT SELECT (traveller_form_enabled) ON public.bookings TO authenticated;
