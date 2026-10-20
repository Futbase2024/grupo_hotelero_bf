-- ============================================================================
-- RLS: arreglar las políticas de `public.profiles`
-- ----------------------------------------------------------------------------
-- PROBLEMA
-- Las políticas de SELECT y UPDATE comparaban el email contra una subconsulta
-- a `auth.users`:
--
--     email = (SELECT users.email FROM auth.users WHERE users.id = auth.uid())::text
--
-- El rol `authenticated` no tiene permisos sobre `auth.users`, así que la
-- política no es que devuelva falso: **revienta la consulta**.
--
--     select count(*) from profiles;
--     ERROR: 42501: permission denied for table users
--
-- Hoy no se nota porque la app no consulta `profiles` directamente (usa el RPC
-- `get_senders_info`, que es SECURITY DEFINER), pero cualquier
-- `.from('profiles').select()` que se añada fallará.
--
-- SOLUCIÓN
-- `auth.jwt()` expone el email del propio token, sin tocar `auth.users`.
-- Además evita una subconsulta a otra tabla por cada fila evaluada.
-- ============================================================================

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT
    USING (
        (SELECT auth.uid()) = user_id
        OR email = (SELECT auth.jwt() ->> 'email')
    );

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE
    USING (
        (SELECT auth.uid()) = user_id
        OR email = (SELECT auth.jwt() ->> 'email')
    );
