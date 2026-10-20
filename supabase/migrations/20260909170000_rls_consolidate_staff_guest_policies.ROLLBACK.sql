-- ROLLBACK de 20260909170000_rls_consolidate_staff_guest_policies.sql
-- Restaura el patrón anterior: política FOR ALL de staff + políticas de huésped.

-- ═══ guest_documents ════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "guest_documents_select" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_insert" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_update" ON public.guest_documents;
DROP POLICY IF EXISTS "guest_documents_delete" ON public.guest_documents;

CREATE POLICY "guest_documents_staff_all" ON public.guest_documents FOR ALL USING (is_staff()) WITH CHECK (is_staff());
CREATE POLICY "guest_documents_guest_select_own" ON public.guest_documents FOR SELECT USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guest_documents_guest_insert_own" ON public.guest_documents FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())) AND uploaded_by = (SELECT auth.uid()));
CREATE POLICY "guest_documents_guest_delete_own" ON public.guest_documents FOR DELETE USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = guest_documents.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));

-- ═══ booking_guests ═════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "booking_guests_select" ON public.booking_guests;
DROP POLICY IF EXISTS "booking_guests_insert" ON public.booking_guests;
DROP POLICY IF EXISTS "booking_guests_update" ON public.booking_guests;
DROP POLICY IF EXISTS "booking_guests_delete" ON public.booking_guests;

CREATE POLICY "booking_guests_staff_all" ON public.booking_guests FOR ALL USING (is_staff()) WITH CHECK (is_staff());
CREATE POLICY "guest_select_booking_guests" ON public.booking_guests FOR SELECT USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guest_insert_booking_guests" ON public.booking_guests FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guest_update_booking_guests" ON public.booking_guests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = booking_guests.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));

-- ═══ guests ═════════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "guests_select" ON public.guests;
DROP POLICY IF EXISTS "guests_insert" ON public.guests;
DROP POLICY IF EXISTS "guests_update" ON public.guests;
DROP POLICY IF EXISTS "guests_delete" ON public.guests;

CREATE POLICY "guests_staff_all" ON public.guests FOR ALL USING (is_staff()) WITH CHECK (is_staff());
CREATE POLICY "guests_guest_select_own" ON public.guests FOR SELECT USING (
  EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "guests_guest_insert_own" ON public.guests FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bookings b WHERE b.primary_guest_user_id = (SELECT auth.uid()) AND b.status = ANY (ARRAY['confirmed','checked_in'])));
CREATE POLICY "guests_guest_update_own" ON public.guests FOR UPDATE USING (
  EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())))
  WITH CHECK (
  EXISTS (SELECT 1 FROM booking_guests bg JOIN bookings b ON b.id = bg.booking_id WHERE bg.guest_id = guests.id AND b.primary_guest_user_id = (SELECT auth.uid())));

-- ═══ checkins ═══════════════════════════════════════════════════════════════
DROP POLICY IF EXISTS "checkins_select" ON public.checkins;
DROP POLICY IF EXISTS "checkins_insert" ON public.checkins;
DROP POLICY IF EXISTS "checkins_update" ON public.checkins;
DROP POLICY IF EXISTS "checkins_delete" ON public.checkins;

CREATE POLICY "checkins_staff_all" ON public.checkins FOR ALL USING (
  is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())))
  WITH CHECK (
  is_staff() AND EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND (is_admin() OR b.property_id = current_property_id())));
CREATE POLICY "checkins_guest_select_own" ON public.checkins FOR SELECT USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
CREATE POLICY "checkins_guest_update_own" ON public.checkins FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())))
  WITH CHECK (
  EXISTS (SELECT 1 FROM bookings b WHERE b.id = checkins.booking_id AND b.primary_guest_user_id = (SELECT auth.uid())));
