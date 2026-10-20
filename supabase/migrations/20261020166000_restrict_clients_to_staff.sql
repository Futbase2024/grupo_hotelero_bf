-- ============================================================================
-- clients (datos fiscales: NIF, email, teléfono, dirección) solo para staff
-- ----------------------------------------------------------------------------
-- La política "Authenticated users can manage clients" (FOR ALL, rol
-- authenticated) dejaba a cualquier sesión, también a los huéspedes anónimos,
-- leer, modificar y borrar todos los clientes. Verificado el 2026-10-20: un
-- usuario anónimo veía los 20 clientes.
--
-- Solo los usa el panel de administración (clients_repository_impl.dart). Se
-- aplica el mismo criterio que bookings/units: admin, o staff de la propiedad.
--
-- Rollback: 20261020166000_restrict_clients_to_staff.ROLLBACK.sql
-- ============================================================================

BEGIN;

DROP POLICY IF EXISTS "Authenticated users can manage clients" ON public.clients;

CREATE POLICY "clients_staff_manage_property" ON public.clients
  FOR ALL
  USING (public.is_staff() AND (public.is_admin() OR property_id = public.current_property_id()))
  WITH CHECK (public.is_staff() AND (public.is_admin() OR property_id = public.current_property_id()));

COMMIT;
