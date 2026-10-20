-- ============================================================================
-- ROLLBACK de 20261020130000_get_guest_access.sql
-- ⚠️ Solo si ninguna versión publicada de la app usa ya get_guest_access.
-- ============================================================================

BEGIN;

DROP FUNCTION IF EXISTS public.get_guest_access(uuid);

COMMIT;
