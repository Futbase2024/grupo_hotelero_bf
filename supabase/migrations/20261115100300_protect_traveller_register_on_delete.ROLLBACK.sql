-- Restaura delete_booking anterior (permitía borrar reservas 'checked_in' y con check-in validado)
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
  IF v_status IN ('checked_out', 'closed', 'in_house') THEN
    RETURN jsonb_build_object('success', false, 'error', format('No se puede eliminar una reserva en estado %s', v_status)); END IF;
  FOR v_doc_path IN SELECT storage_path FROM guest_documents WHERE booking_id = p_booking_id LOOP
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
