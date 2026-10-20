-- ============================================================================
-- Migración 4: Guards de autorización en funciones SECURITY DEFINER
-- ----------------------------------------------------------------------------
-- Cierra el hueco: un invitado con sesión anónima (rol `authenticated`) podía
-- ejecutar RPCs de staff (delete_booking, validate_checkin...) y leer PII
-- (get_profile_by_email). Se añade un guard al inicio de cada función.
--
-- Patrones de guard:
--   STAFF     : IF NOT (public.is_staff() OR auth.role()='service_role') RAISE
--   INVITADO  : caller debe ser el primary_guest de la reserva (o staff)
--   SELF      : caller solo puede operar sobre su propio auth.uid()
--
-- El bypass `auth.role()='service_role'` evita romper cron/edge functions.
-- Funciones que YA estaban protegidas (get_checkin_details, get_access_for_booking,
-- insert_guest_for_booking, update_guest_for_booking, assign_primary_guest)
-- NO se tocan.
--
-- FCM (get_fcm_token(s)_for_user(s)) queda para la Migración 5.
-- Rollback (cuerpos originales) en: ...ROLLBACK.sql
-- ============================================================================

-- ===================== GRUPO 1: SOLO STAFF ==================================

CREATE OR REPLACE FUNCTION public.delete_booking(p_booking_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
  v_storage_paths text[] := '{}'::text[];
  v_doc_path text;
  v_pdf_path text;
  v_count int;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT status INTO v_status FROM bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada');
  END IF;

  IF v_status IN ('checked_out', 'closed', 'in_house') THEN
    RETURN jsonb_build_object('success', false,
      'error', format('No se puede eliminar una reserva en estado %s', v_status));
  END IF;

  FOR v_doc_path IN SELECT storage_path FROM guest_documents WHERE booking_id = p_booking_id
  LOOP
    IF v_doc_path IS NOT NULL THEN
      v_storage_paths := array_append(v_storage_paths, v_doc_path);
    END IF;
  END LOOP;

  SELECT checkin_pdf_path INTO v_pdf_path FROM checkins WHERE booking_id = p_booking_id;
  IF v_pdf_path IS NOT NULL THEN
    v_storage_paths := array_append(v_storage_paths, v_pdf_path);
  END IF;

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

  IF v_count = 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'No se pudo eliminar la reserva');
  END IF;

  RETURN jsonb_build_object('success', true, 'storage_paths', v_storage_paths);
END;
$function$;

CREATE OR REPLACE FUNCTION public.cancel_booking(p_booking_id uuid, p_reason text DEFAULT NULL::text)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RAISE EXCEPTION 'not_allowed: se requiere rol staff';
    END IF;

    UPDATE bookings
    SET booking_status = 'cancelled', status = 'cancelled',
        staff_notes = COALESCE(p_reason, staff_notes), updated_at = NOW()
    WHERE id = p_booking_id AND booking_status NOT IN ('closed', 'cancelled');
    RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.close_booking(p_booking_id uuid, p_notes text DEFAULT NULL::text)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RAISE EXCEPTION 'not_allowed: se requiere rol staff';
    END IF;

    UPDATE bookings
    SET booking_status = 'closed', status = 'checked_out', checkout_status = 'validated',
        closed_at = NOW(), checkout_validated_at = NOW(),
        checkout_notes = COALESCE(p_notes, checkout_notes)
    WHERE id = p_booking_id AND booking_status IN ('created', 'active', 'confirmed');
    RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.activate_booking(p_booking_id uuid)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RAISE EXCEPTION 'not_allowed: se requiere rol staff';
    END IF;

    UPDATE bookings
    SET booking_status = 'active', status = 'checked_in',
        activated_at = NOW(), updated_at = NOW()
    WHERE id = p_booking_id AND booking_status = 'created';
    RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_booking_with_code(p_property_id uuid, p_unit_id uuid, p_checkin_date date, p_checkout_date date, p_last_name text, p_num_adults integer DEFAULT 1, p_num_children integer DEFAULT 0, p_children_ages integer[] DEFAULT '{}'::integer[], p_staff_notes text DEFAULT NULL::text, p_guest_first_name text DEFAULT NULL::text, p_guest_email text DEFAULT NULL::text, p_guest_phone text DEFAULT NULL::text)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_booking_id    uuid;
  v_booking_code  text;
  v_checkin_id    uuid;
  v_num_guests    integer;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  v_num_guests := COALESCE(p_num_adults, 1) + COALESCE(p_num_children, 0);
  v_booking_code := public.generate_unique_booking_code();

  INSERT INTO public.bookings (
    property_id, unit_id, booking_code, last_name, checkin_date, checkout_date,
    status, num_guests, num_adults, num_children, children_ages, staff_notes,
    guest_first_name, guest_email, guest_phone
  ) VALUES (
    p_property_id, p_unit_id, v_booking_code, p_last_name, p_checkin_date, p_checkout_date,
    'confirmed', v_num_guests, COALESCE(p_num_adults, 1), COALESCE(p_num_children, 0),
    COALESCE(p_children_ages, '{}'::integer[]), p_staff_notes,
    p_guest_first_name, p_guest_email, p_guest_phone
  )
  RETURNING id INTO v_booking_id;

  INSERT INTO public.checkins (booking_id, status)
  VALUES (v_booking_id, 'draft')
  RETURNING id INTO v_checkin_id;

  RETURN jsonb_build_object(
    'booking_id', v_booking_id, 'booking_code', v_booking_code, 'checkin_id', v_checkin_id,
    'property_id', p_property_id, 'unit_id', p_unit_id, 'checkin_date', p_checkin_date,
    'checkout_date', p_checkout_date, 'num_guests', v_num_guests,
    'num_adults', COALESCE(p_num_adults, 1), 'num_children', COALESCE(p_num_children, 0),
    'children_ages', COALESCE(p_children_ages, '{}'::integer[]), 'status', 'confirmed'
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.regenerate_booking_code(p_booking_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
declare
  v_booking_code text;
  v_keybox_code text;
begin
  if not (public.is_staff() or auth.role() = 'service_role') then
    raise exception 'not_allowed: se requiere rol staff';
  end if;

  v_booking_code := public.generate_unique_booking_code();
  v_keybox_code := public.generate_unique_keybox_code();

  update public.bookings
  set booking_code = v_booking_code, keybox_code = v_keybox_code, code_sent_at = null
  where id = p_booking_id;

  if not found then
    raise exception 'booking_not_found';
  end if;

  return jsonb_build_object('booking_code', v_booking_code, 'keybox_code', v_keybox_code);
end;
$function$;

CREATE OR REPLACE FUNCTION public.validate_checkin(p_checkin_id uuid, p_staff_user_id uuid DEFAULT auth.uid())
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_booking_id UUID;
  v_current_status TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT booking_id, status INTO v_booking_id, v_current_status
  FROM checkins WHERE id = p_checkin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Check-in not found';
  END IF;

  IF v_current_status != 'submitted' THEN
    RAISE EXCEPTION 'Check-in must be in submitted status to validate. Current status: %', v_current_status;
  END IF;

  UPDATE checkins SET status = 'validated', validated_at = NOW() WHERE id = p_checkin_id;
  UPDATE bookings SET status = 'checked_in' WHERE id = v_booking_id;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('validate_checkin', 'checkins', p_checkin_id, p_staff_user_id,
    jsonb_build_object('booking_id', v_booking_id, 'new_status', 'validated'));
END;
$function$;

CREATE OR REPLACE FUNCTION public.reject_checkin(p_checkin_id uuid, p_reason text, p_staff_user_id uuid DEFAULT auth.uid())
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_booking_id UUID;
  v_current_status TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT booking_id, status INTO v_booking_id, v_current_status
  FROM checkins WHERE id = p_checkin_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Check-in not found';
  END IF;

  UPDATE checkins
  SET status = 'rejected', rejected_at = NOW(), rejection_reason = p_reason
  WHERE id = p_checkin_id;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('reject_checkin', 'checkins', p_checkin_id, p_staff_user_id,
    jsonb_build_object('booking_id', v_booking_id, 'reason', p_reason));
END;
$function$;

CREATE OR REPLACE FUNCTION public.manual_checkin_validate(p_booking_id uuid)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_checkin_id UUID;
  v_booking RECORD;
  v_result JSONB;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT b.id, b.property_id, b.unit_id, b.booking_code,
    b.guest_first_name, b.last_name, b.guest_email, b.guest_phone,
    b.status, b.checkin_date, b.checkout_date
  INTO v_booking FROM bookings b WHERE b.id = p_booking_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada');
  END IF;

  SELECT id INTO v_checkin_id FROM checkins WHERE booking_id = p_booking_id;

  IF v_checkin_id IS NULL THEN
    INSERT INTO checkins (id, booking_id, property_id, status, validated_at, created_at, updated_at)
    VALUES (gen_random_uuid(), p_booking_id, v_booking.property_id, 'validated', NOW(), NOW(), NOW())
    RETURNING id INTO v_checkin_id;

    INSERT INTO checkin_guests (id, checkin_id, full_name, email, phone, is_primary, created_at)
    VALUES (gen_random_uuid(), v_checkin_id,
      COALESCE(v_booking.guest_first_name || ' ' || v_booking.last_name, 'Huésped'),
      v_booking.guest_email, v_booking.guest_phone, true, NOW());
  ELSE
    UPDATE checkins SET status = 'validated', validated_at = NOW(), updated_at = NOW()
    WHERE id = v_checkin_id AND status IN ('draft', 'not_started', 'in_progress', 'submitted');

    IF NOT FOUND THEN
      RETURN jsonb_build_object('success', false,
        'error', 'El check-in ya está validado, rechazado o cancelado');
    END IF;
  END IF;

  UPDATE bookings SET status = 'checked_in' WHERE id = p_booking_id;

  RETURN jsonb_build_object('success', true, 'checkin_id', v_checkin_id,
    'message', 'Check-in manual validado correctamente');
END;
$function$;

CREATE OR REPLACE FUNCTION public.validate_checkout(p_booking_id uuid, p_notes text DEFAULT NULL::text)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RAISE EXCEPTION 'not_allowed: se requiere rol staff';
    END IF;

    UPDATE bookings
    SET checkout_status = 'validated', checkout_validated_at = NOW(),
        checkout_notes = COALESCE(p_notes, checkout_notes), updated_at = NOW()
    WHERE id = p_booking_id AND checkout_status = 'requested';

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    PERFORM close_booking(p_booking_id, p_notes);
    RETURN TRUE;
END;
$function$;

CREATE OR REPLACE FUNCTION public.reject_checkout(p_booking_id uuid, p_reason text)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RAISE EXCEPTION 'not_allowed: se requiere rol staff';
    END IF;

    UPDATE bookings
    SET checkout_status = 'rejected', checkout_notes = p_reason, updated_at = NOW()
    WHERE id = p_booking_id AND checkout_status IN ('requested', 'validated');
    RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.cleanup_expired_documents()
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  expired_docs RECORD;
  deleted_count INTEGER := 0;
  error_count INTEGER := 0;
  result JSONB := '[]'::JSONB;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  FOR expired_docs IN
    SELECT id, storage_path, guest_id, doc_kind FROM guest_documents WHERE expires_at < NOW()
  LOOP
    BEGIN
      DELETE FROM storage.objects
      WHERE bucket_id = 'guest-documents' AND name = expired_docs.storage_path;
      DELETE FROM guest_documents WHERE id = expired_docs.id;
      deleted_count := deleted_count + 1;
      result := result || jsonb_build_object('id', expired_docs.id,
        'path', expired_docs.storage_path, 'status', 'deleted');
    EXCEPTION WHEN OTHERS THEN
      error_count := error_count + 1;
      result := result || jsonb_build_object('id', expired_docs.id,
        'path', expired_docs.storage_path, 'status', 'error', 'error', SQLERRM);
    END;
  END LOOP;

  RETURN jsonb_build_object('deleted_count', deleted_count,
    'error_count', error_count, 'details', result);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_documents_expiring_soon(days_before integer DEFAULT 7)
 RETURNS TABLE(id uuid, storage_path text, expires_at timestamp with time zone, guest_id uuid, booking_id uuid, days_remaining integer)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  RETURN QUERY
  SELECT gd.id, gd.storage_path, gd.expires_at, gd.guest_id, gd.booking_id,
    EXTRACT(DAY FROM (gd.expires_at - NOW()))::INTEGER as days_remaining
  FROM guest_documents gd
  WHERE gd.expires_at BETWEEN NOW() AND NOW() + (days_before || ' days')::INTERVAL
  ORDER BY gd.expires_at ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.generate_invoice_number()
 RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_year INT := EXTRACT(YEAR FROM CURRENT_DATE);
  v_next_num INT;
  v_invoice_number TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  SELECT COALESCE(MAX(CAST(SPLIT_PART(invoice_number, '-', 3) AS INT)), 0) + 1
  INTO v_next_num FROM public.invoices
  WHERE invoice_number LIKE 'BF-' || v_year || '-%';

  IF v_year = 2026 THEN
    v_next_num := GREATEST(v_next_num, 6);
  END IF;

  v_invoice_number := 'BF-' || v_year || '-' || LPAD(v_next_num::TEXT, 4, '0');
  RETURN v_invoice_number;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_all_units_availability(p_from date DEFAULT CURRENT_DATE, p_to date DEFAULT (CURRENT_DATE + '7 days'::interval), p_property_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(unit_id uuid, unit_name text, unit_type text, property_name text, max_guests integer, status text, next_checkin date, current_guest text, bookings_count integer)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  RETURN QUERY
  WITH unit_bookings AS (
    SELECT b.unit_id, COUNT(*)::integer AS bcount,
      MIN(b.checkin_date) FILTER (WHERE b.checkin_date >= p_from) AS next_ci,
      MAX(b.last_name) FILTER (WHERE b.checkin_date <= p_from AND b.checkout_date > p_from) AS current_guest_name
    FROM bookings b
    WHERE b.status NOT IN ('cancelled', 'checked_out')
      AND b.checkin_date < p_to AND b.checkout_date > p_from
    GROUP BY b.unit_id
  )
  SELECT u.id, u.name, u.unit_type, p.name, u.max_guests,
    CASE WHEN ub.bcount IS NULL THEN 'free'
         WHEN ub.current_guest_name IS NOT NULL THEN 'occupied'
         ELSE 'partial' END,
    ub.next_ci, ub.current_guest_name, COALESCE(ub.bcount, 0)
  FROM units u
  JOIN properties p ON p.id = u.property_id
  LEFT JOIN unit_bookings ub ON ub.unit_id = u.id
  WHERE (p_property_id IS NULL OR u.property_id = p_property_id)
  ORDER BY p.name, u.name;
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_unit_available(p_unit_id uuid, p_checkin date, p_checkout date, p_exclude_booking_id uuid DEFAULT NULL::uuid)
 RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  IF p_checkout <= p_checkin THEN
    RAISE EXCEPTION 'La fecha de salida debe ser posterior a la de entrada';
  END IF;

  RETURN NOT EXISTS (
    SELECT 1 FROM bookings
    WHERE unit_id = p_unit_id
      AND status NOT IN ('cancelled', 'checked_out')
      AND checkin_date < p_checkout
      AND checkout_date > p_checkin
      AND (p_exclude_booking_id IS NULL OR id != p_exclude_booking_id)
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_unit_occupied_ranges(p_unit_id uuid, p_from date DEFAULT CURRENT_DATE, p_to date DEFAULT (CURRENT_DATE + '90 days'::interval))
 RETURNS TABLE(booking_id uuid, checkin_date date, checkout_date date, num_guests integer, last_name text, status text, nights integer)
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff';
  END IF;

  RETURN QUERY
  SELECT b.id, b.checkin_date, b.checkout_date, b.num_guests, b.last_name, b.status,
    (b.checkout_date - b.checkin_date)::integer AS nights
  FROM bookings b
  WHERE b.unit_id = p_unit_id
    AND b.status NOT IN ('cancelled', 'checked_out')
    AND b.checkin_date < p_to AND b.checkout_date > p_from
  ORDER BY b.checkin_date;
END;
$function$;

-- ============ GRUPO 2: INVITADO sobre SU reserva (o staff) ==================

CREATE OR REPLACE FUNCTION public.submit_guest_checkin(p_booking_id uuid, p_signature_svg text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_existing_checkin_id UUID;
  v_primary_guest_user_id UUID;
BEGIN
  -- El caller debe ser el titular de la reserva, staff, o la reserva aún no tiene titular
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM bookings
      WHERE id = p_booking_id
        AND (primary_guest_user_id = auth.uid() OR primary_guest_user_id IS NULL)
  )) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  SELECT primary_guest_user_id INTO v_primary_guest_user_id
  FROM bookings WHERE id = p_booking_id;

  IF v_primary_guest_user_id IS NULL THEN
    UPDATE bookings SET primary_guest_user_id = auth.uid() WHERE id = p_booking_id;
  END IF;

  SELECT id INTO v_existing_checkin_id FROM checkins WHERE booking_id = p_booking_id;

  IF v_existing_checkin_id IS NOT NULL THEN
    UPDATE checkins
    SET status = 'submitted', submitted_at = NOW(), signature_svg = p_signature_svg
    WHERE id = v_existing_checkin_id;
  ELSE
    INSERT INTO checkins (booking_id, status, submitted_at, signature_svg)
    VALUES (p_booking_id, 'submitted', NOW(), p_signature_svg);
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.request_checkout(p_booking_id uuid)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM bookings WHERE id = p_booking_id AND primary_guest_user_id = auth.uid()
    )) THEN
      RAISE EXCEPTION 'not_allowed';
    END IF;

    UPDATE bookings
    SET checkout_status = 'requested', checkout_requested_at = NOW(), updated_at = NOW()
    WHERE id = p_booking_id AND booking_status = 'active' AND checkout_status = 'not_started';
    RETURN FOUND;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_booking_full_status(p_booking_id uuid)
 RETURNS TABLE(booking_id uuid, booking_code text, booking_status text, checkin_status text, checkout_status text, can_access_panel boolean, is_read_only boolean, needs_checkin_action boolean, needs_checkout_action boolean)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM bookings WHERE id = p_booking_id AND primary_guest_user_id = auth.uid()
    )) THEN
      RAISE EXCEPTION 'not_allowed';
    END IF;

    RETURN QUERY
    SELECT b.id, b.booking_code, b.booking_status,
        COALESCE(c.status, 'not_started') as checkin_status, b.checkout_status,
        CASE WHEN COALESCE(c.status, 'not_started') = 'validated' AND b.booking_status = 'active'
             THEN TRUE ELSE FALSE END as can_access_panel,
        CASE WHEN b.booking_status = 'closed' THEN TRUE ELSE FALSE END as is_read_only,
        CASE WHEN COALESCE(c.status, 'not_started') = 'submitted' THEN TRUE ELSE FALSE END as needs_checkin_action,
        CASE WHEN b.checkout_status = 'requested' THEN TRUE ELSE FALSE END as needs_checkout_action
    FROM bookings b
    LEFT JOIN checkins c ON c.booking_id = b.id
    WHERE b.id = p_booking_id;
END;
$function$;

-- ============ GRUPO 3: Fuga de PII =========================================

CREATE OR REPLACE FUNCTION public.get_profile_by_email(p_email text)
 RETURNS TABLE(id uuid, user_id uuid, email text, full_name text, phone text, document_type text, document_number text, nationality text, birth_date date, created_at timestamp with time zone, updated_at timestamp with time zone)
 LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
    -- Staff sin restricción; invitado solo si el email es el de SU reserva
    IF NOT (public.is_staff() OR auth.role() = 'service_role' OR EXISTS (
        SELECT 1 FROM bookings b
        WHERE b.primary_guest_user_id = auth.uid()
          AND lower(b.guest_email) = lower(p_email)
    )) THEN
      RAISE EXCEPTION 'not_allowed';
    END IF;

    RETURN QUERY
    SELECT profiles.id, profiles.user_id, profiles.email, profiles.full_name, profiles.phone,
        profiles.document_type, profiles.document_number, profiles.nationality,
        profiles.birth_date, profiles.created_at, profiles.updated_at
    FROM profiles
    WHERE profiles.email ILIKE p_email
    LIMIT 1;
END;
$function$;

-- ============ GRUPO 4: Claim / migración (SELF o staff) =====================

CREATE OR REPLACE FUNCTION public.assign_primary_guest_to_booking(p_booking_id uuid, p_user_id uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_booking_record RECORD;
BEGIN
  -- El caller solo puede asignarse a sí mismo (o ser staff)
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR p_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  SELECT id, primary_guest_user_id, guest_email, status
  INTO v_booking_record FROM bookings WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Booking not found';
  END IF;

  IF v_booking_record.primary_guest_user_id = p_user_id THEN
    RETURN;
  END IF;

  -- Anti-secuestro: no reasignar una reserva ya reclamada por otro (salvo staff)
  IF v_booking_record.primary_guest_user_id IS NOT NULL
     AND v_booking_record.primary_guest_user_id <> p_user_id
     AND NOT public.is_staff() THEN
    RAISE EXCEPTION 'booking already claimed';
  END IF;

  IF v_booking_record.status NOT IN ('confirmed', 'checked_in') THEN
    RAISE EXCEPTION 'Booking status does not allow update';
  END IF;

  UPDATE bookings SET primary_guest_user_id = p_user_id WHERE id = p_booking_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.migrate_guest_conversation_participant(p_old_user_id uuid, p_new_user_id uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
BEGIN
  -- Solo puedes migrar hacia tu propia sesión (o ser staff)
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR p_new_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  UPDATE conversation_participants SET user_id = p_new_user_id WHERE user_id = p_old_user_id;
  UPDATE messages SET sender_user_id = p_new_user_id WHERE sender_user_id = p_old_user_id;

  RAISE NOTICE 'Migrados participantes y mensajes de % a %', p_old_user_id, p_new_user_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.create_guest_conversation(p_property_id uuid, p_booking_id uuid, p_guest_user_id uuid, p_guest_name text DEFAULT ''::text)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $function$
DECLARE
  v_conversation_id UUID;
BEGIN
  -- Solo puedes crear una conversación para ti mismo (o ser staff)
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR p_guest_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  INSERT INTO conversations (property_id, booking_id)
  VALUES (p_property_id, p_booking_id)
  RETURNING id INTO v_conversation_id;

  INSERT INTO conversation_participants (conversation_id, user_id, role)
  VALUES (v_conversation_id, p_guest_user_id, 'guest');

  RETURN v_conversation_id;
END;
$function$;
