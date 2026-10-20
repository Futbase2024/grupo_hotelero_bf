-- ============================================================================
-- ROLLBACK de 20261020170000_server_side_notifications.sql
-- ⚠️ Vuelve a permitir que cualquier sesión cree notificaciones para otros
--    usuarios y lea los tokens FCM de los admins. Los avisos al staff vuelven a
--    depender de la app.
-- ============================================================================

BEGIN;

DROP TRIGGER IF EXISTS trg_checkin_submitted_notify_admins ON public.checkins;
DROP TRIGGER IF EXISTS trg_extra_request_notify_admins ON public.extra_requests;
DROP FUNCTION IF EXISTS public.trg_checkin_submitted_notify_admins();
DROP FUNCTION IF EXISTS public.trg_extra_request_notify_admins();
DROP FUNCTION IF EXISTS public.notify_property_admins(uuid, text, text, text, uuid, jsonb);

DROP POLICY IF EXISTS "guest_notifications_insert_staff" ON public.guest_notifications;
CREATE POLICY "service_role_can_insert" ON public.guest_notifications
  FOR INSERT WITH CHECK ((SELECT auth.uid() AS uid) IS NOT NULL);

DROP POLICY IF EXISTS "staff_notifications_insert_staff" ON public.staff_notifications;
CREATE POLICY "service_insert_notifications" ON public.staff_notifications
  FOR INSERT WITH CHECK ((SELECT auth.uid() AS uid) IS NOT NULL);

DROP POLICY IF EXISTS "notification_queue_insert_staff" ON public.notification_queue;
CREATE POLICY "Authenticated users can insert notifications" ON public.notification_queue
  FOR INSERT WITH CHECK ((SELECT auth.role() AS role) = 'authenticated'::text);

DROP POLICY IF EXISTS "email_logs_insert_staff" ON public.email_logs;
CREATE POLICY "email_logs_service_insert" ON public.email_logs
  FOR INSERT WITH CHECK ((SELECT auth.uid() AS uid) IS NOT NULL);

DROP POLICY IF EXISTS "Users can view own tokens" ON public.fcm_tokens;
CREATE POLICY "Users can view own and admin tokens" ON public.fcm_tokens
  FOR SELECT USING (
    ((SELECT auth.uid() AS uid) = user_id)
    OR (EXISTS (SELECT 1 FROM user_roles
                 WHERE user_roles.user_id = fcm_tokens.user_id AND user_roles.role = 'admin'::text))
    OR (EXISTS (SELECT 1 FROM user_roles ur
                 WHERE ur.user_id = (SELECT auth.uid() AS uid)
                   AND ur.role = ANY (ARRAY['admin'::text, 'staff'::text])))
  );

CREATE POLICY "user_roles_select_admins" ON public.user_roles
  FOR SELECT USING (role = 'admin'::text);

CREATE OR REPLACE FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[])
 RETURNS TABLE(user_id uuid, token text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_privileged BOOLEAN := public.is_staff() OR auth.role() = 'service_role';
BEGIN
    RETURN QUERY
    SELECT ft.user_id, ft.token
    FROM fcm_tokens ft
    WHERE ft.user_id = ANY(target_user_ids) AND ft.is_active = true
      AND (v_privileged OR public.is_staff_user(ft.user_id));
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
    IF NOT (public.is_staff() OR auth.role() = 'service_role'
            OR public.is_staff_user(target_user_id)) THEN
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
