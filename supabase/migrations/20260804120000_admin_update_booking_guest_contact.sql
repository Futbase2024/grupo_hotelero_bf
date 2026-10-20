-- ============================================================================
-- Edición del contacto del huésped (email / teléfono) desde el panel de admin
-- ============================================================================
-- Contexto: el login del huésped crea o reutiliza una cuenta de Supabase Auth a
-- partir de `bookings.guest_email`. Si el admin corrige el email de una reserva
-- que el huésped ya ha reclamado, la próxima vez entrará con una cuenta distinta
-- y `assign_primary_guest_to_booking` la rechazaría con 'booking already claimed'.
--
-- Solución: al cambiar el email se libera el vínculo y se guarda el usuario
-- anterior en `previous_guest_user_id`. Cuando el huésped vuelve a reclamar la
-- reserva con la cuenta nueva, se migra su historial (chat, notificaciones y
-- extras de esa reserva) del usuario anterior al nuevo.
-- ============================================================================

-- 1) Columna que guarda el vínculo anterior pendiente de migrar -------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS previous_guest_user_id uuid;

COMMENT ON COLUMN public.bookings.previous_guest_user_id IS
  'Usuario que tenía reclamada la reserva antes de que el admin corrigiera el '
  'guest_email. Al reclamar la reserva con la cuenta nueva se migra su historial '
  'y esta columna vuelve a NULL.';

-- 2) RPC para actualizar el contacto del huésped ----------------------------
CREATE OR REPLACE FUNCTION public.admin_update_booking_guest_contact(
  p_booking_id uuid,
  p_guest_email text,
  p_guest_phone text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_booking        RECORD;
  v_new_email      text := lower(btrim(coalesce(p_guest_email, '')));
  v_new_phone      text := nullif(btrim(coalesce(p_guest_phone, '')), '');
  v_email_changed  boolean := false;
  v_access_reset   boolean := false;
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  SELECT id, property_id, guest_email, guest_phone, primary_guest_user_id
    INTO v_booking
    FROM bookings
   WHERE id = p_booking_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found';
  END IF;

  -- El staff no administrador solo puede tocar reservas de su propiedad
  IF NOT public.is_admin()
     AND v_booking.property_id IS DISTINCT FROM public.current_property_id() THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  IF v_new_email = '' OR v_new_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$' THEN
    RAISE EXCEPTION 'invalid_email';
  END IF;

  v_email_changed := lower(btrim(coalesce(v_booking.guest_email, ''))) IS DISTINCT FROM v_new_email;

  IF v_email_changed AND v_booking.primary_guest_user_id IS NOT NULL THEN
    -- Se libera el vínculo para que el huésped pueda reclamar la reserva con la
    -- cuenta asociada al email corregido, conservando el usuario anterior.
    UPDATE bookings
       SET guest_email             = v_new_email,
           guest_phone             = v_new_phone,
           previous_guest_user_id  = v_booking.primary_guest_user_id,
           primary_guest_user_id   = NULL
     WHERE id = p_booking_id;

    v_access_reset := true;
  ELSE
    UPDATE bookings
       SET guest_email = v_new_email,
           guest_phone = v_new_phone
     WHERE id = p_booking_id;
  END IF;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES (
    'update_guest_contact',
    'bookings',
    p_booking_id,
    auth.uid(),
    jsonb_build_object(
      'old_email',    v_booking.guest_email,
      'new_email',    v_new_email,
      'old_phone',    v_booking.guest_phone,
      'new_phone',    v_new_phone,
      'access_reset', v_access_reset
    )
  );

  RETURN jsonb_build_object(
    'email_changed', v_email_changed,
    'access_reset',  v_access_reset
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_update_booking_guest_contact(uuid, text, text) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_update_booking_guest_contact(uuid, text, text) FROM anon;
GRANT EXECUTE ON FUNCTION public.admin_update_booking_guest_contact(uuid, text, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_booking_guest_contact(uuid, text, text) TO service_role;

-- 3) Reclamo de reserva con migración del historial del usuario anterior -----
CREATE OR REPLACE FUNCTION public.assign_primary_guest_to_booking(
  p_booking_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_booking_record RECORD;
  v_previous_user_id uuid;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role' OR p_user_id = auth.uid()) THEN
    RAISE EXCEPTION 'not_allowed';
  END IF;

  SELECT id, primary_guest_user_id, previous_guest_user_id, guest_email, status
    INTO v_booking_record
    FROM bookings
   WHERE id = p_booking_id;

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

  v_previous_user_id := v_booking_record.previous_guest_user_id;

  UPDATE bookings
     SET primary_guest_user_id  = p_user_id,
         previous_guest_user_id = NULL
   WHERE id = p_booking_id;

  -- Migración del historial cuando el admin corrigió el email de la reserva
  IF v_previous_user_id IS NOT NULL AND v_previous_user_id <> p_user_id THEN
    -- Conversaciones de esta reserva: se traspasa la participación salvo que el
    -- usuario nuevo ya participe (la PK es (conversation_id, user_id)).
    UPDATE conversation_participants cp
       SET user_id = p_user_id
     WHERE cp.user_id = v_previous_user_id
       AND cp.conversation_id IN (SELECT id FROM conversations WHERE booking_id = p_booking_id)
       AND NOT EXISTS (
         SELECT 1 FROM conversation_participants x
          WHERE x.conversation_id = cp.conversation_id
            AND x.user_id = p_user_id
       );

    DELETE FROM conversation_participants cp
     WHERE cp.user_id = v_previous_user_id
       AND cp.conversation_id IN (SELECT id FROM conversations WHERE booking_id = p_booking_id);

    UPDATE messages m
       SET sender_user_id = p_user_id
     WHERE m.sender_user_id = v_previous_user_id
       AND m.conversation_id IN (SELECT id FROM conversations WHERE booking_id = p_booking_id);

    UPDATE guest_notifications
       SET user_id = p_user_id
     WHERE user_id = v_previous_user_id
       AND booking_id = p_booking_id;

    UPDATE extra_requests
       SET user_id = p_user_id
     WHERE user_id = v_previous_user_id
       AND booking_id = p_booking_id;
  END IF;
END;
$function$;
