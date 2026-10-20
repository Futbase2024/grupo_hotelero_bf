-- Permite a cada usuario borrar ÚNICAMENTE los mensajes que él mismo envió.
-- Aplica tanto a huéspedes (rol authenticated anónimo) como a admin/staff.
-- Las traducciones (message_translations) se eliminan en cascada.
DROP POLICY IF EXISTS "messages_delete_own" ON public.messages;
CREATE POLICY "messages_delete_own" ON public.messages
FOR DELETE
USING (sender_user_id = (SELECT auth.uid()));
