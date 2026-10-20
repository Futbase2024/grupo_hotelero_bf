-- ============================================================================
-- RLS: consolidar políticas staff + huésped en una por comando
-- ----------------------------------------------------------------------------
-- Patrón que había en estas 4 tablas: una política `FOR ALL` para staff más
-- políticas específicas para el huésped. Resultado: para SELECT (y a veces
-- UPDATE) se evaluaban DOS políticas permisivas por fila.
--
-- Aquí se sustituyen por UNA política por comando cuya expresión es el OR de
-- las que aplicaban antes a ese comando. Transformación mecánica y equivalente:
-- las políticas permisivas ya se combinaban con OR.
--
-- VERIFICADO antes de aplicar (mismos cambios dentro de una transacción con
-- ROLLBACK, contando filas visibles con `set local role authenticated` y un
-- JWT simulado para cada perfil):
--
--   perfil            checkins  docs  booking_guests  guests
--   admin               1061    2483      1849         1886   (antes = después)
--   huésped vinculado      1       4         2            2   (antes = después)
--   usuario sin vínculo    0       0         0            0   (antes = después)
--
-- Notas de fidelidad:
--   · `guest_documents`: el huésped no tenía UPDATE → la nueva política de
--     UPDATE es solo para staff.
--   · `booking_guests` y `guests`: el huésped no tenía DELETE → solo staff.
--   · `checkins`: el huésped no tenía INSERT ni DELETE → solo staff.
--   · Las políticas de UPDATE sin `WITH CHECK` usaban su `USING` también como
--     check (comportamiento de Postgres); aquí se escribe explícito.
-- ============================================================================

-- ═══ guest_documents (2483 filas) ═══════════════════════════════════════════
DROP POLICY IF EXISTS "guest_documents_staff_all" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_guest_select_own" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_guest_insert_own" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_guest_delete_own" ON public.guest_documents;

CREATE POLICY "guest_documents_select" ON public.guest_documents FOR SELECT USING (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guest_documents_insert" ON public.guest_documents FOR INSERT WITH CHECK (
  is_staff() OR (uploaded_by = (SELECT auth.uid()) AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid()))));
CREATE POLICY "guest_documents_update" ON public.guest_documents FOR UPDATE USING (is_staff()) WITH CHECK (is_staff());
CREATE POLICY "guest_documents_delete" ON public.guest_documents FOR DELETE USING (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));

-- ═══ booking_guests (1849 filas) ════════════════════════════════════════════
DROP POLICY IF EXISTS "booking_guests_staff_all" ON public.booking_guests;
DROP POLICY IF EXISTS "guest_select_booking_guests" ON public.booking_guests;
DROP POLICY IF EXISTS "guest_insert_booking_guests" ON public.booking_guests;
DROP POLICY IF EXISTS "guest_update_booking_guests" ON public.booking_guests;

CREATE POLICY "booking_guests_select" ON public.booking_guests FOR SELECT USING (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "booking_guests_insert" ON public.booking_guests FOR INSERT WITH CHECK (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "booking_guests_update" ON public.booking_guests FOR UPDATE USING (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())))
  WITH CHECK (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "booking_guests_delete" ON public.booking_guests FOR DELETE USING (is_staff());

-- ═══ guests (1886 filas) ════════════════════════════════════════════════════
DROP POLICY IF EXISTS "guests_staff_all" ON public.guests;
DROP POLICY IF EXISTS "guests_guest_select_own" ON public.guests;
DROP POLICY IF EXISTS "guests_guest_insert_own" ON public.guests;
DROP POLICY IF EXISTS "guests_guest_update_own" ON public.guests;

CREATE POLICY "guests_select" ON public.guests FOR SELECT USING (
  is_staff() OR EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guests_insert" ON public.guests FOR INSERT WITH CHECK (
  is_staff() OR EXISTS (SELECT 1 FROM bookings b WHERE b.primary_guest_user_id = (SELECT auth.uid()) AND b.status = ANY (ARRAY['confirmed','checked_in'])));
CREATE POLICY "guests_update" ON public.guests FOR UPDATE USING (
  is_staff() OR EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())))
  WITH CHECK (
  is_staff() OR EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guests_delete" ON public.guests FOR DELETE USING (is_staff());

-- ═══ checkins (1061 filas) ══════════════════════════════════════════════════
DROP POLICY IF EXISTS "checkins_staff_all" ON public.checkins;
DROP POLICY IF EXISTS "checkins_guest_select_own" ON public.checkins;
DROP POLICY IF EXISTS "checkins_guest_update_own" ON public.checkins;

CREATE POLICY "checkins_select" ON public.checkins FOR SELECT USING (
  (is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())))
  OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "checkins_insert" ON public.checkins FOR INSERT WITH CHECK (
  is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())));
CREATE POLICY "checkins_update" ON public.checkins FOR UPDATE USING (
  (is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())))
  OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())))
  WITH CHECK (
  (is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())))
  OR EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "checkins_delete" ON public.checkins FOR DELETE USING (
  is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())));
