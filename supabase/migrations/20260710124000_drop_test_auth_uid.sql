-- ============================================================================
-- Migración 5a: Eliminar función de depuración test_auth_uid()
-- ----------------------------------------------------------------------------
-- Función SECURITY DEFINER de debug, sin uso en cliente ni migraciones.
-- Quitarla elimina 1 warning 0029 y reduce superficie de ataque.
-- Rollback en: ...ROLLBACK.sql
-- ============================================================================
DROP FUNCTION IF EXISTS public.test_auth_uid();
