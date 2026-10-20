-- ============================================================================
-- ROLLBACK de 20261020165000_lock_user_roles.sql
-- ⚠️ Vuelve a permitir que cualquier sesión (también anónima) se asigne el rol
--    admin. No aplicar salvo emergencia.
-- ============================================================================

BEGIN;

GRANT INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.user_roles TO anon, authenticated;

CREATE POLICY "user_roles_insert_own" ON public.user_roles
  FOR INSERT
  WITH CHECK (user_id = (SELECT auth.uid() AS uid));

COMMIT;
