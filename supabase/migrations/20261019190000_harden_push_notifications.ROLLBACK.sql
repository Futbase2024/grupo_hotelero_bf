-- ============================================================================
-- ROLLBACK de 20261019190000_harden_push_notifications.sql
-- ⚠️ Antes de aplicarlo, volver a desplegar `send-fcm` sin la comprobación del
--    secreto (copia en supabase/functions/_previous/send-fcm/), o los push de
--    los triggers dejarán de funcionar.
-- El secreto del Vault se conserva (borrarlo no aporta nada).
-- ============================================================================

BEGIN;

DROP TRIGGER IF EXISTS trg_guard_notification_queue_insert ON public.notification_queue;
DROP FUNCTION IF EXISTS public.trg_guard_notification_queue_insert();

CREATE OR REPLACE FUNCTION public.notify_fcm(payload jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM net.http_post(
    url     := 'https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/send-fcm',
    headers := jsonb_build_object(
      'Content-Type', 'application/json'
    ),
    body    := payload
  );
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '[notify_fcm] Error llamando send-fcm: %', SQLERRM;
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
    SELECT token INTO token_value
    FROM fcm_tokens
    WHERE user_id = target_user_id AND is_active = true
    LIMIT 1;

    RETURN token_value;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_fcm_tokens_for_users(target_user_ids uuid[])
 RETURNS TABLE(user_id uuid, token text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT ft.user_id, ft.token
    FROM fcm_tokens ft
    WHERE ft.user_id = ANY(target_user_ids) AND ft.is_active = true;
END;
$function$;

DROP FUNCTION IF EXISTS public.fcm_token_belongs_to(uuid, text);
DROP FUNCTION IF EXISTS public.is_staff_user(uuid);
DROP FUNCTION IF EXISTS public.internal_functions_secret();

GRANT EXECUTE ON FUNCTION public.notify_fcm_immediately() TO anon, authenticated;

COMMIT;
