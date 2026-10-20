-- ============================================================================
-- ROLLBACK de 20261020167000_tighten_chat_and_reviews.sql
-- ⚠️ Vuelve a permitir unirse a conversaciones ajenas y editar/borrar reseñas
--    ajenas desde cualquier sesión.
-- ============================================================================

BEGIN;

GRANT INSERT ON TABLE public.conversations TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.conversation_participants TO anon, authenticated;

CREATE POLICY "participants_insert_temp" ON public.conversation_participants
  FOR INSERT
  WITH CHECK ((SELECT auth.uid() AS uid) IS NOT NULL);

CREATE POLICY "conversations_insert_any_user" ON public.conversations
  FOR INSERT
  WITH CHECK ((SELECT auth.uid() AS uid) IS NOT NULL);

DROP POLICY IF EXISTS "reviews_insert_own" ON public.reviews;
DROP POLICY IF EXISTS "reviews_update_own" ON public.reviews;
DROP POLICY IF EXISTS "reviews_delete_own" ON public.reviews;

CREATE POLICY "Authenticated users can insert reviews" ON public.reviews
  FOR INSERT
  WITH CHECK ((SELECT auth.role() AS role) = 'authenticated'::text);

CREATE POLICY "Users can update own reviews" ON public.reviews
  FOR UPDATE
  USING (guest_id IS NOT NULL)
  WITH CHECK (guest_id IS NOT NULL);

CREATE POLICY "Users can delete own reviews" ON public.reviews
  FOR DELETE
  USING (guest_id IS NOT NULL);

COMMIT;
