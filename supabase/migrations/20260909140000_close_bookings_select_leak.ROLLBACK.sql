-- ROLLBACK de 20260909140000_close_bookings_select_leak.sql
--
-- ⚠️ Restaura la fuga de lectura en `bookings`. Usar SOLO como medida de
-- emergencia si hubiera que volver a una versión antigua de la app (que hace
-- SELECT directo sobre la tabla para el login por código).

-- Vuelve a dejar todas las reservas activas legibles por cualquier rol
CREATE POLICY "bookings_anon_select_by_code" ON public.bookings
    FOR SELECT
    USING (status = ANY (ARRAY['confirmed'::text, 'checked_in'::text]));

-- Duplicado de bookings_guest_select_own
CREATE POLICY "guest_select_own_booking" ON public.bookings
    FOR SELECT
    USING (primary_guest_user_id = (SELECT auth.uid()));

-- Política de SELECT del staff (redundante con bookings_staff_manage_property)
CREATE POLICY "bookings_staff_select_property" ON public.bookings
    FOR SELECT
    USING (is_staff() AND (is_admin() OR (property_id = current_property_id())));
