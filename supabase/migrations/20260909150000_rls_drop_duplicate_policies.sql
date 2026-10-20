-- ============================================================================
-- RLS: eliminar políticas permisivas duplicadas
-- ----------------------------------------------------------------------------
-- Las políticas permisivas se combinan con OR y se evalúan EN CADA FILA de
-- CADA consulta. El linter de Supabase reportaba 182 avisos
-- `multiple_permissive_policies`, la causa #1 del `performance_degradation_plan`.
--
-- Esta migración se limita a los casos de RIESGO CERO: parejas con la MISMA
-- expresión y los MISMOS roles, creadas por duplicado con nombres distintos
-- (normalmente una versión en inglés y otra en español). Eliminar una de cada
-- pareja no cambia en absoluto quién puede ver o hacer qué.
--
-- Comprobado con:
--   group by tabla, cmd, roles, using_expr, check_expr having count(*) > 1
--
-- La única excepción, marcada abajo, es `profiles_insert_all`: no es un
-- duplicado exacto sino una política MÁS LAXA que su pareja.
-- ============================================================================

-- ── checkins ────────────────────────────────────────────────────────────────
-- Idéntica a checkins_guest_select_own
DROP POLICY IF EXISTS "guest_select_checkin" ON public.checkins;

-- ── fcm_tokens ──────────────────────────────────────────────────────────────
-- Idénticas a las "Users can ... own token"
DROP POLICY IF EXISTS "Usuario inserta sus propios tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Usuario elimina sus propios tokens" ON public.fcm_tokens;
DROP POLICY IF EXISTS "Usuario actualiza sus propios tokens" ON public.fcm_tokens;

-- ── guest_documents ─────────────────────────────────────────────────────────
-- Idéntica a guest_documents_guest_select_own
DROP POLICY IF EXISTS "guest_select_guest_documents" ON public.guest_documents;
-- Mismo WITH CHECK que guest_documents_guest_insert_own, con los dos operandos
-- del AND en orden inverso
DROP POLICY IF EXISTS "guest_insert_guest_documents" ON public.guest_documents;

-- ── profiles ────────────────────────────────────────────────────────────────
-- Idénticas a profiles_select_own / profiles_update_own
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;

-- ⚠️ NO es un duplicado: `profiles_insert_all` solo exige estar autenticado
--     WITH CHECK ((SELECT auth.uid()) IS NOT NULL)
-- mientras que su pareja exige que el perfil sea tuyo
--     WITH CHECK ((SELECT auth.uid()) = user_id OR user_id IS NULL)
-- Al combinarse con OR, la laxa manda: cualquier usuario autenticado podía
-- insertar un perfil con el `user_id` de otra persona. Se elimina la laxa.
DROP POLICY IF EXISTS "profiles_insert_all" ON public.profiles;

-- ── user_roles ──────────────────────────────────────────────────────────────
-- Idéntica a user_roles_insert_own
DROP POLICY IF EXISTS "user_roles_guest_insert_own" ON public.user_roles;
