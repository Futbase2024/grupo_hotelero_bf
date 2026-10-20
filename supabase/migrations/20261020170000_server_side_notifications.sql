-- ============================================================================
-- Avisos al staff generados en el servidor ("Migración 5") y cierre de las
-- tablas de notificaciones
-- ----------------------------------------------------------------------------
-- El huésped generaba desde la app los avisos a los admins (check-in enviado,
-- check-in auto-validado, solicitud de extra): leía los admins en user_roles,
-- pedía sus tokens FCM, insertaba en staff_notifications y notification_queue.
-- Para permitirlo, cualquier sesión (también anónima) podía:
--   - crear notificaciones en la app de OTRO huésped (guest_notifications),
--   - crear avisos falsos en el panel del staff (staff_notifications),
--   - leer los tokens FCM e IDs de los admins y enviarles push con texto libre,
--   - escribir en email_logs.
--
-- Ahora:
--   1. notify_property_admins(): crea el aviso in-app y el push (vía notify_fcm
--      → Edge Function send-fcm) a los admins de la propiedad y globales.
--   2. Trigger DIFERIDO en checkins: al pasar a 'submitted' avisa al confirmar
--      la transacción, mirando el estado final, para mandar UN aviso:
--      "pendiente" o "validado automáticamente" (submit_guest_checkin valida en
--      la misma transacción si toca).
--   3. Trigger en extra_requests (AFTER INSERT): "Nueva solicitud".
--   4. INSERT en guest_notifications, staff_notifications, notification_queue
--      y email_logs: solo staff (los triggers y Edge Functions no se ven
--      afectados). fcm_tokens: cada uno solo los suyos. get_fcm_token(s):
--      solo staff/service_role. Se elimina user_roles_select_admins.
--
-- Apps instaladas: sus intentos de avisar fallan en silencio (todo está en
-- try/catch) y el aviso lo genera el servidor: el admin recibe uno, no dos.
-- Además los avisos se guardan con la hora real (la app enviaba la hora local
-- sin zona y quedaban 2 h adelantados).
--
-- Plan: .claude/plans/notificaciones_push_servidor_plan.md
-- Rollback: 20261020170000_server_side_notifications.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Aviso a los admins de una propiedad (in-app + push)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_property_admins(
  p_property_id uuid,
  p_type text,
  p_title text,
  p_body text,
  p_booking_id uuid DEFAULT NULL,
  p_data jsonb DEFAULT '{}'::jsonb
)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_admin_ids uuid[];
BEGIN
  INSERT INTO public.staff_notifications (type, title, body, booking_id, property_id, data, is_read)
  VALUES (p_type, p_title, p_body, p_booking_id, p_property_id, coalesce(p_data, '{}'::jsonb), false);

  -- Mismos destinatarios que la app: admins de la propiedad y admins globales
  SELECT array_agg(DISTINCT ur.user_id)
    INTO v_admin_ids
    FROM public.user_roles ur
   WHERE ur.role = 'admin'
     AND (ur.property_id IS NULL OR ur.property_id = p_property_id);

  IF v_admin_ids IS NULL THEN
    RETURN;
  END IF;

  PERFORM public.notify_fcm(jsonb_build_object(
    'user_ids',   to_jsonb(v_admin_ids),
    'booking_id', p_booking_id,
    'type',       p_type,
    'title',      p_title,
    'body',       p_body,
    'data',       coalesce(p_data, '{}'::jsonb) || jsonb_build_object(
                    'type',        p_type,
                    'booking_id',  coalesce(p_booking_id::text, ''),
                    'property_id', coalesce(p_property_id::text, '')
                  )
  ));
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.notify_property_admins(uuid, text, text, text, uuid, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_property_admins(uuid, text, text, text, uuid, jsonb) TO service_role;

-- ----------------------------------------------------------------------------
-- 2. Check-in enviado / auto-validado
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_checkin_submitted_notify_admins()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
  v_property_id uuid;
  v_guest_name text;
  v_unit_name text;
BEGIN
  -- Solo el evento en que el check-in pasa a 'submitted'
  IF NEW.status IS DISTINCT FROM 'submitted' THEN
    RETURN NULL;
  END IF;
  IF TG_OP = 'UPDATE' AND OLD.status IS NOT DISTINCT FROM 'submitted' THEN
    RETURN NULL;
  END IF;

  -- Trigger diferido: estado final al confirmar la transacción
  SELECT c.status INTO v_status FROM public.checkins c WHERE c.id = NEW.id;
  IF v_status IS NULL OR v_status NOT IN ('submitted', 'validated') THEN
    RETURN NULL;
  END IF;

  SELECT b.property_id,
         nullif(trim(coalesce(b.guest_first_name, '') || ' ' || coalesce(b.last_name, '')), ''),
         u.name
    INTO v_property_id, v_guest_name, v_unit_name
    FROM public.bookings b
    LEFT JOIN private.units u ON u.id = b.unit_id
   WHERE b.id = NEW.booking_id;

  IF v_property_id IS NULL THEN
    RETURN NULL;
  END IF;

  v_guest_name := coalesce(v_guest_name, 'Huésped');
  v_unit_name := coalesce(v_unit_name, '');

  IF v_status = 'validated' THEN
    PERFORM public.notify_property_admins(
      v_property_id,
      'checkin_submitted',
      '✅ Check-in validado automáticamente',
      v_guest_name || ' ha enviado su check-in para ' || v_unit_name || ' y se ha validado solo.',
      NEW.booking_id,
      jsonb_build_object('action', 'review_checkin')
    );
  ELSE
    PERFORM public.notify_property_admins(
      v_property_id,
      'checkin_submitted',
      '📝 Nuevo Check-in Pendiente',
      v_guest_name || ' ha enviado su check-in para ' || v_unit_name || '. Pendiente de revisión.',
      NEW.booking_id,
      jsonb_build_object('action', 'review_checkin')
    );
  END IF;

  RETURN NULL;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.trg_checkin_submitted_notify_admins() FROM PUBLIC, anon, authenticated;

CREATE CONSTRAINT TRIGGER trg_checkin_submitted_notify_admins
  AFTER INSERT OR UPDATE OF status ON public.checkins
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION public.trg_checkin_submitted_notify_admins();

-- ----------------------------------------------------------------------------
-- 3. Solicitud de extra (Pack Romántico)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_extra_request_notify_admins()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_property_id uuid;
  v_location text := '';
BEGIN
  v_property_id := coalesce(
    NEW.property_id,
    (SELECT b.property_id FROM public.bookings b WHERE b.id = NEW.booking_id)
  );
  IF v_property_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF coalesce(NEW.unit_name, '') <> '' THEN
    v_location := ' en ' || NEW.unit_name;
  END IF;

  PERFORM public.notify_property_admins(
    v_property_id,
    'extra_request',
    '💝 Nueva solicitud: ' || coalesce(NEW.extra_name, 'extra'),
    coalesce(nullif(NEW.guest_name, ''), 'Huésped') || ' ha solicitado "' || coalesce(NEW.extra_name, 'extra')
      || '"' || v_location || '. Pendiente de gestionar.',
    NEW.booking_id,
    jsonb_build_object('action', 'review_extra_request')
  );

  RETURN NEW;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.trg_extra_request_notify_admins() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_extra_request_notify_admins
  AFTER INSERT ON public.extra_requests
  FOR EACH ROW EXECUTE FUNCTION public.trg_extra_request_notify_admins();

-- ----------------------------------------------------------------------------
-- 4. Cerrar las tablas de notificaciones
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "service_role_can_insert" ON public.guest_notifications;
CREATE POLICY "guest_notifications_insert_staff" ON public.guest_notifications
  FOR INSERT WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS "service_insert_notifications" ON public.staff_notifications;
CREATE POLICY "staff_notifications_insert_staff" ON public.staff_notifications
  FOR INSERT WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS "Authenticated users can insert notifications" ON public.notification_queue;
CREATE POLICY "notification_queue_insert_staff" ON public.notification_queue
  FOR INSERT WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS "email_logs_service_insert" ON public.email_logs;
CREATE POLICY "email_logs_insert_staff" ON public.email_logs
  FOR INSERT WITH CHECK (public.is_staff());

DROP POLICY IF EXISTS "Users can view own and admin tokens" ON public.fcm_tokens;
CREATE POLICY "Users can view own tokens" ON public.fcm_tokens
  FOR SELECT USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "user_roles_select_admins" ON public.user_roles;

CREATE OR REPLACE FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[])
 RETURNS TABLE(user_id uuid, token text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RETURN;
    END IF;

    RETURN QUERY
    SELECT ft.user_id, ft.token
    FROM fcm_tokens ft
    WHERE ft.user_id = ANY(target_user_ids) AND ft.is_active = true;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_fcm_token_for_user(target_user_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    token_value TEXT;
BEGIN
    IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
      RETURN NULL;
    END IF;

    SELECT token INTO token_value
    FROM fcm_tokens
    WHERE user_id = target_user_id AND is_active = true
    LIMIT 1;

    RETURN token_value;
END;
$function$;

COMMIT;
