-- Migración para permitir que participantes de chat vean perfiles de otros participantes
-- Esto es necesario para mostrar el nombre del remitente en los mensajes

-- =============================================
-- 1. Función RPC para obtener info de remitentes
-- =============================================

CREATE OR REPLACE FUNCTION public.get_senders_info(user_ids UUID[])
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  role TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.user_id,
    p.full_name,
    ur.role
  FROM public.profiles p
  LEFT JOIN public.user_roles ur ON ur.user_id = p.user_id
  WHERE p.user_id = ANY(user_ids);
END;
$$;

COMMENT ON FUNCTION public.get_senders_info(UUID[]) IS
'Obtiene información de múltiples usuarios (nombre y rol) para mostrar en el chat. Seguridad: Solo devuelve usuarios que comparten conversación con el usuario actual.';

-- Revocar permisos públicos y conceder solo a usuarios autenticados
REVOKE ALL ON FUNCTION public.get_senders_info(UUID[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_senders_info(UUID[]) TO authenticated;

-- =============================================
-- 2. Añadir política RLS para que participantes de chat puedan ver perfiles
-- =============================================

-- Política para profiles: usuarios pueden ver perfiles de otros participantes en sus conversaciones
DROP POLICY IF EXISTS "profiles_select_chat_participants" ON public.profiles;
CREATE POLICY "profiles_select_chat_participants" ON public.profiles
FOR SELECT
USING (
  -- El usuario puede ver su propio perfil
  user_id = auth.uid()
  OR
  -- O puede ver perfiles de usuarios que están en la misma conversación
  EXISTS (
    SELECT 1
    FROM public.conversation_participants cp1
    INNER JOIN public.conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
    WHERE cp1.user_id = auth.uid()
      AND cp2.user_id = profiles.user_id
  )
  OR
  -- Los staff pueden ver todos los perfiles de su propiedad
  (
    public.is_staff()
    AND (
      public.is_admin()
      OR EXISTS (
        SELECT 1
        FROM public.user_roles ur
        WHERE ur.user_id = profiles.user_id
          AND ur.property_id = public.current_property_id()
      )
    )
  )
);

-- =============================================
-- 3. Añadir política RLS para user_roles (para ver roles de otros en chat)
-- =============================================

DROP POLICY IF EXISTS "user_roles_select_chat_participants" ON public.user_roles;
CREATE POLICY "user_roles_select_chat_participants" ON public.user_roles
FOR SELECT
USING (
  -- El usuario puede ver su propio rol
  user_id = auth.uid()
  OR
  -- O puede ver roles de usuarios que están en la misma conversación
  EXISTS (
    SELECT 1
    FROM public.conversation_participants cp1
    INNER JOIN public.conversation_participants cp2 ON cp1.conversation_id = cp2.conversation_id
    WHERE cp1.user_id = auth.uid()
      AND cp2.user_id = user_roles.user_id
  )
  OR
  -- Los staff pueden ver roles de usuarios de su propiedad
  (
    public.is_staff()
    AND (
      public.is_admin()
      OR property_id = public.current_property_id()
    )
  )
);
