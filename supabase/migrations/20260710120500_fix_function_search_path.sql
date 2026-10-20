-- ============================================================================
-- Migración 2: Fijar search_path en funciones (advisor 0011)
-- ----------------------------------------------------------------------------
-- function_search_path_mutable: funciones sin search_path fijo son vulnerables
-- a search_path hijacking. Se fija a 'public' (coincide con la convención del
-- resto de funciones del proyecto). No cambia comportamiento.
-- Rollback: ALTER FUNCTION ... RESET search_path;
-- ============================================================================

ALTER FUNCTION public.update_updated_at_column() SET search_path = 'public';
ALTER FUNCTION public.notify_fcm_immediately() SET search_path = 'public';
ALTER FUNCTION public.process_notification_queue_trigger() SET search_path = 'public';
ALTER FUNCTION public.sync_keybox_code_on_box_code_change() SET search_path = 'public';
