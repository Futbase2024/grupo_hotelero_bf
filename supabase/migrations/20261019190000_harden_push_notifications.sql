-- ============================================================================
-- Blindaje de las notificaciones push
-- ----------------------------------------------------------------------------
-- Problemas:
--   · La Edge Function `send-fcm` no exige autenticación: cualquiera podía
--     mandar un push con cualquier texto a cualquier usuario (o a todo el staff
--     de una propiedad). Solo la llama la BD (notify_fcm).
--   · Cualquier usuario autenticado (los huéspedes lo son, vía sesión anónima)
--     podía insertar en `notification_queue` pushes para cualquier usuario.
--   · get_fcm_token(s)_for_user(s) devolvían los tokens de cualquier usuario.
--
-- Solución:
--   1. Secreto interno en Vault. La BD lo envía en `x-internal-secret` y las
--      Edge Functions lo comprueban leyéndolo con internal_functions_secret()
--      (solo service_role), sin necesidad de variables de entorno.
--   2. Un huésped solo puede encolar pushes para el staff, y con un token que
--      pertenezca de verdad a ese usuario (es lo único que hace la app: avisar
--      al admin de un check-in o de un extra). Staff y triggers sin cambios.
--   3. Un huésped solo obtiene tokens de usuarios staff.
--
-- Plan: .claude/plans/edge_functions_auth_plan.md
-- Rollback: 20261019190000_harden_push_notifications.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Secreto interno
-- ----------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM vault.secrets WHERE name = 'internal_functions_secret') THEN
    PERFORM vault.create_secret(
      encode(extensions.gen_random_bytes(32), 'hex'),
      'internal_functions_secret',
      'Llamadas internas BD -> Edge Functions (cabecera x-internal-secret)'
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.internal_functions_secret()
 RETURNS text
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT decrypted_secret FROM vault.decrypted_secrets
   WHERE name = 'internal_functions_secret' LIMIT 1;
$function$;

REVOKE EXECUTE ON FUNCTION public.internal_functions_secret() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.internal_functions_secret() TO service_role;

-- notify_fcm -> send-fcm ahora firma la llamada
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
      'Content-Type', 'application/json',
      'x-internal-secret', public.internal_functions_secret()
    ),
    body    := payload
  );
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING '[notify_fcm] Error llamando send-fcm: %', SQLERRM;
END;
$function$;

-- ----------------------------------------------------------------------------
-- 2) Cola de push: un huésped solo puede avisar al staff
-- ----------------------------------------------------------------------------
-- Helpers SECURITY DEFINER para que el trigger (que corre con el rol del
-- cliente, necesario para is_direct_non_staff_write) pueda leer sin RLS.
CREATE OR REPLACE FUNCTION public.is_staff_user(p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM user_roles
     WHERE user_id = p_user_id AND role IN ('admin', 'staff')
  );
$function$;

CREATE OR REPLACE FUNCTION public.fcm_token_belongs_to(p_user_id uuid, p_token text)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM fcm_tokens WHERE user_id = p_user_id AND token = p_token
  );
$function$;

REVOKE EXECUTE ON FUNCTION public.is_staff_user(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_staff_user(uuid) TO authenticated, service_role;
REVOKE EXECUTE ON FUNCTION public.fcm_token_belongs_to(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.fcm_token_belongs_to(uuid, text) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.trg_guard_notification_queue_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Solo inserciones directas de clientes no-staff (los triggers SECURITY
  -- DEFINER y el staff no se ven afectados)
  IF public.is_direct_non_staff_write() THEN
    IF NOT public.is_staff_user(NEW.user_id) THEN
      RAISE EXCEPTION 'not_allowed: solo se pueden enviar avisos al staff'
        USING ERRCODE = '42501';
    END IF;

    IF NEW.token IS NULL OR NOT public.fcm_token_belongs_to(NEW.user_id, NEW.token) THEN
      RAISE EXCEPTION 'not_allowed: el token no pertenece al destinatario'
        USING ERRCODE = '42501';
    END IF;
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_notification_queue_insert ON public.notification_queue;

CREATE TRIGGER trg_guard_notification_queue_insert
  BEFORE INSERT ON public.notification_queue
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_guard_notification_queue_insert();

REVOKE EXECUTE ON FUNCTION public.trg_guard_notification_queue_insert() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_guard_notification_queue_insert() TO service_role;

-- ----------------------------------------------------------------------------
-- 3) Tokens: un huésped solo obtiene tokens del staff
-- ----------------------------------------------------------------------------
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

-- Función de trigger sin uso que seguía ejecutable por anon/authenticated
REVOKE EXECUTE ON FUNCTION public.notify_fcm_immediately() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.notify_fcm_immediately() TO service_role;

COMMIT;
