-- ============================================================================
-- ROLLBACK: edición del contacto del huésped desde el panel de admin
-- ============================================================================

DROP FUNCTION IF EXISTS public.admin_update_booking_guest_contact(uuid, text, text);

-- Versión previa de la función de reclamo (sin migración de historial)
CREATE OR REPLACE FUNCTION public.assign_primary_guest_to_booking(
  p_booking_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE v_booking_record RECORD;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR p_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;
  SELECT id, primary_guest_user_id, guest_email, status
    INTO v_booking_record FROM bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Booking not found'; END IF;
  IF v_booking_record.primary_guest_user_id = p_user_id THEN RETURN; END IF;
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

ALTER TABLE public.bookings DROP COLUMN IF EXISTS previous_guest_user_id;
