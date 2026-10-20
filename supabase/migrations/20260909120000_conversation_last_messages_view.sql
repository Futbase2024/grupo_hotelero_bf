-- ============================================================================
-- Vista: public.conversation_last_messages
-- ----------------------------------------------------------------------------
-- Devuelve UNA fila por conversación: su mensaje más reciente.
--
-- Motivo: la lista de conversaciones del chat pedía TODOS los mensajes de
-- TODAS las conversaciones y se quedaba con el último de cada una en el
-- cliente. PostgREST corta cada respuesta en `db-max-rows` (1000), así que al
-- superar los 1000 mensajes las conversaciones más inactivas se quedaban sin
-- previsualización y mal ordenadas (30 conversaciones afectadas al crear esta
-- vista, con 1192 mensajes en la tabla).
--
-- Con la vista el cliente pide 1 fila por conversación en lugar del histórico
-- completo, y el volumen deja de crecer con el número de mensajes.
--
-- `security_invoker = on`: la vista se ejecuta con los permisos de quien
-- consulta, así que respeta las políticas RLS de `messages` (participante de
-- la conversación o admin/staff). NO es un SECURITY DEFINER encubierto.
--
-- Se apoya en el índice ya existente `idx_messages_conversation_created`
-- (conversation_id, created_at DESC).
-- ============================================================================

CREATE OR REPLACE VIEW public.conversation_last_messages
WITH (security_invoker = on) AS
SELECT DISTINCT ON (m.conversation_id)
    m.id,
    m.conversation_id,
    m.sender_user_id,
    m.msg_type,
    m.content,
    m.created_at,
    m.read_at,
    m.file_name,
    m.file_size,
    m.mime_type
FROM public.messages m
ORDER BY m.conversation_id, m.created_at DESC, m.id DESC;

COMMENT ON VIEW public.conversation_last_messages IS
    'Último mensaje de cada conversación (1 fila por conversation_id). '
    'Usada por la lista de conversaciones del chat para no descargar el '
    'histórico completo de mensajes. Respeta RLS (security_invoker).';

-- El chat solo lo consumen usuarios con sesión (huéspedes anónimos incluidos,
-- que operan como `authenticated`) y staff. `anon` no lo necesita.
GRANT SELECT ON public.conversation_last_messages TO authenticated;
GRANT SELECT ON public.conversation_last_messages TO service_role;
