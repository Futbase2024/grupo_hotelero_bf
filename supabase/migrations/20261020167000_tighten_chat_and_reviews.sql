-- ============================================================================
-- Chat y reseñas: quitar las políticas de escritura "cualquier sesión"
-- ----------------------------------------------------------------------------
-- Con los inicios de sesión anónimos activos, `auth.uid() IS NOT NULL` o
-- `auth.role() = 'authenticated'` equivalen a "público".
--
-- A) Chat (verificado el 2026-10-20 en transacción con ROLLBACK):
--    - participants_insert_temp: cualquiera con el UUID de una conversación
--      ajena se añadía como participante (incluso role 'admin') y leía sus
--      mensajes.
--    - participants_update_clean deja a cada usuario editar su fila, también
--      conversation_id y role: podía moverse a otra conversación.
--    - conversations_insert_any_user: cualquiera creaba conversaciones.
--    La app crea las conversaciones con la RPC create_guest_conversation y el
--    trigger add_staff_to_conversation (ambos SECURITY DEFINER, no afectados) y
--    solo actualiza unread_count / last_read_at de su participación.
--
-- B) reviews: INSERT abierto a cualquier sesión y UPDATE/DELETE con
--    `guest_id IS NOT NULL` (cualquiera editaba o borraba reseñas ajenas).
--    Ahora cada usuario solo crea/edita/borra las suyas (guest_id = auth.uid(),
--    reserva propia, sin marcarse como verificada); el staff, todas.
--
-- Rollback: 20261020167000_tighten_chat_and_reviews.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- A) Chat
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "participants_insert_temp" ON public.conversation_participants;
DROP POLICY IF EXISTS "conversations_insert_any_user" ON public.conversations;

REVOKE INSERT ON TABLE public.conversations FROM anon, authenticated;
REVOKE INSERT ON TABLE public.conversation_participants FROM anon, authenticated;

-- Solo se pueden tocar los contadores de lectura de la propia participación
REVOKE UPDATE ON TABLE public.conversation_participants FROM anon, authenticated;
GRANT UPDATE (unread_count, last_read_at) ON TABLE public.conversation_participants TO authenticated;

-- ----------------------------------------------------------------------------
-- B) Reseñas
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can insert reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can update own reviews" ON public.reviews;
DROP POLICY IF EXISTS "Users can delete own reviews" ON public.reviews;

CREATE POLICY "reviews_insert_own" ON public.reviews
  FOR INSERT
  WITH CHECK (
    public.is_staff()
    OR (
      guest_id = (SELECT auth.uid())
      AND coalesce(is_verified, false) = false
      AND (
        booking_id IS NULL
        OR EXISTS (
          SELECT 1 FROM public.bookings b
          WHERE b.id = reviews.booking_id
            AND b.primary_guest_user_id = (SELECT auth.uid())
        )
      )
    )
  );

CREATE POLICY "reviews_update_own" ON public.reviews
  FOR UPDATE
  USING (public.is_staff() OR guest_id = (SELECT auth.uid()))
  WITH CHECK (
    public.is_staff()
    OR (guest_id = (SELECT auth.uid()) AND coalesce(is_verified, false) = false)
  );

CREATE POLICY "reviews_delete_own" ON public.reviews
  FOR DELETE
  USING (public.is_staff() OR guest_id = (SELECT auth.uid()));

COMMIT;
