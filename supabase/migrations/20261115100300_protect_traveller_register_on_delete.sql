-- ============================================================================
-- delete_booking no puede borrar el registro de viajeros
-- ----------------------------------------------------------------------------
-- El RD 933/2021 (art. 5.3) obliga a conservar los datos del registro de
-- viajeros 3 años desde el fin de la estancia. delete_booking permitía borrar
-- reservas en estado 'checked_in' (huésped ya alojado), perdiendo la relación
-- huésped ↔ estancia, la firma y el check-in.
--
-- Ahora también se rechaza si el check-in está validado (datos ya registrados),
-- aunque la reserva no haya cambiado de estado. Las reservas sin estancia
-- (confirmadas sin check-in validado, canceladas) se siguen pudiendo borrar.
--
-- Rollback: 20261115100300_protect_traveller_register_on_delete.ROLLBACK.sql
-- ============================================================================

CREATE OR REPLACE FUNCTION public.delete_booking(p_booking_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_status text; v_storage_paths text[] := '{}'::text[]; v_doc_path text; v_pdf_path text; v_count int;
BEGIN
  IF NOT (public.is_admin() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol admin';
  END IF;
  SELECT status INTO v_status FROM bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada'); END IF;
  IF v_status IN ('checked_in', 'checked_out', 'closed', 'in_house') THEN
    RETURN jsonb_build_object('success', false, 'error', format('No se puede eliminar una reserva en estado %s: sus datos forman parte del registro de viajeros (se conservan 3 años)', v_status)); END IF;
  IF EXISTS (SELECT 1 FROM checkins WHERE booking_id = p_booking_id AND status = 'validated') THEN
    RETURN jsonb_build_object('success', false, 'error', 'No se puede eliminar una reserva con el check-in validado: sus datos forman parte del registro de viajeros (se conservan 3 años)'); END IF;
  FOR v_doc_path IN SELECT storage_path FROM guest_documents WHERE booking_id = p_booking_id AND deleted_at IS NULL LOOP
    IF v_doc_path IS NOT NULL THEN v_storage_paths := array_append(v_storage_paths, v_doc_path); END IF; END LOOP;
  SELECT checkin_pdf_path INTO v_pdf_path FROM checkins WHERE booking_id = p_booking_id;
  IF v_pdf_path IS NOT NULL THEN v_storage_paths := array_append(v_storage_paths, v_pdf_path); END IF;
  DELETE FROM payments WHERE booking_id = p_booking_id;
  DELETE FROM invoices WHERE booking_id = p_booking_id;
  DELETE FROM incidents WHERE booking_id = p_booking_id;
  DELETE FROM staff_notifications WHERE booking_id = p_booking_id;
  DELETE FROM notification_log WHERE booking_id = p_booking_id;
  DELETE FROM guest_notifications WHERE booking_id = p_booking_id;
  DELETE FROM email_logs WHERE booking_id = p_booking_id;
  DELETE FROM conversations WHERE booking_id = p_booking_id;
  DELETE FROM guest_documents WHERE booking_id = p_booking_id;
  DELETE FROM booking_guests WHERE booking_id = p_booking_id;
  DELETE FROM booking_units WHERE booking_id = p_booking_id;
  DELETE FROM checkins WHERE booking_id = p_booking_id;
  DELETE FROM bookings WHERE id = p_booking_id;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  IF v_count = 0 THEN RETURN jsonb_build_object('success', false, 'error', 'No se pudo eliminar la reserva'); END IF;
  RETURN jsonb_build_object('success', true, 'storage_paths', v_storage_paths);
END; $function$;
