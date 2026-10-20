-- ============================================================================
-- Cerrar la escalada de privilegios en user_roles
-- ----------------------------------------------------------------------------
-- La política `user_roles_insert_own` (WITH CHECK user_id = auth.uid()) dejaba
-- a cualquier usuario sin fila en user_roles insertarse con role = 'admin'.
-- Como los inicios de sesión anónimos están activados, cualquiera con la clave
-- pública podía crear una sesión, hacerse admin global y leer todas las
-- reservas y documentos de identidad. Verificado el 2026-10-20 en una
-- transacción con ROLLBACK (sin rastro de uso: solo el admin legítimo y 3 filas
-- 'guest' de febrero).
--
-- La app no inserta, actualiza ni borra en user_roles; los roles se gestionan
-- desde el panel de Supabase o con service_role, que no se ven afectados.
--
-- Rollback: 20261020165000_lock_user_roles.ROLLBACK.sql
-- ============================================================================

BEGIN;

DROP POLICY IF EXISTS "user_roles_insert_own" ON public.user_roles;

REVOKE INSERT, UPDATE, DELETE, TRUNCATE ON TABLE public.user_roles FROM anon, authenticated;

COMMIT;
