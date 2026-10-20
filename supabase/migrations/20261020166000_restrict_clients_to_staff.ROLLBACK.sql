-- ============================================================================
-- ROLLBACK de 20261020166000_restrict_clients_to_staff.sql
-- ⚠️ Vuelve a dejar los datos de clientes legibles y editables por cualquier
--    sesión, también anónima.
-- ============================================================================

BEGIN;

DROP POLICY IF EXISTS "clients_staff_manage_property" ON public.clients;

CREATE POLICY "Authenticated users can manage clients" ON public.clients
  FOR ALL
  USING ((SELECT auth.role() AS role) = 'authenticated'::text)
  WITH CHECK ((SELECT auth.role() AS role) = 'authenticated'::text);

COMMIT;
