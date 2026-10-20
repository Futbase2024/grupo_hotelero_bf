-- ROLLBACK de 20260909120000_conversation_last_messages_view.sql
--
-- Al eliminar la vista, la lista de conversaciones del chat vuelve a depender
-- de la consulta que descarga todos los mensajes (con el corte de 1000 filas
-- de PostgREST y la pérdida de previsualizaciones que eso implica).
-- Requiere revertir también el cliente Flutter a la versión anterior.

DROP VIEW IF EXISTS public.conversation_last_messages;
