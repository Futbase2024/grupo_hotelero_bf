-- ============================================================================
-- ⚠️ NO APLICAR HASTA QUE LA APP QUE USA `claim_booking_by_code` ESTÉ PUBLICADA
-- ----------------------------------------------------------------------------
-- Cierra la fuga de lectura en `public.bookings`.
--
-- ESTADO ANTES DE ESTA MIGRACIÓN
-- `bookings` tiene 4 políticas SELECT permisivas (se combinan con OR). Una de
-- ellas no comprueba nada más que el estado:
--
--     bookings_anon_select_by_code  →  USING (status IN ('confirmed','checked_in'))
--
-- Está concedida al rol `public` (todos los roles). Como los invitados entran
-- con `signInAnonymously()`, CUALQUIERA que abra la app podía leer todas las
-- reservas activas. Verificado como rol `authenticated` sin JWT: 26 reservas
-- visibles, las 26 con `keybox_code`, 26 con email y 10 con teléfono.
--
-- POR QUÉ SE PUEDE ELIMINAR AHORA
-- El login por código ya no lee la tabla: usa el RPC `claim_booking_by_code`
-- (migración 20260909130000), que valida en el servidor y vincula la reserva a
-- `auth.uid()`. A partir de ahí, el huésped ve su reserva por
-- `bookings_guest_select_own`, y el staff por `bookings_staff_manage_property`.
--
-- Comprobado antes de escribir esta migración:
--     begin;
--     drop policy "bookings_anon_select_by_code" on public.bookings;
--     set local role authenticated;
--     set local request.jwt.claims = '{"sub":"<uid de huésped real>", ...}';
--     select count(*) from bookings;   -- → 1 (solo la suya) ✅
--     rollback;
--
-- ORDEN DE DESPLIEGUE
-- La app publicada hoy hace SELECT directo sobre `bookings` para el login, así
-- que aplicar esto antes de publicar la nueva versión dejaría a los huéspedes
-- sin poder entrar con su código.
-- ============================================================================

-- 1. La fuga
DROP POLICY IF EXISTS "bookings_anon_select_by_code" ON public.bookings;

-- 2. Duplicado exacto de `bookings_guest_select_own`
--    (misma expresión: primary_guest_user_id = (SELECT auth.uid()))
DROP POLICY IF EXISTS "guest_select_own_booking" ON public.bookings;

-- 3. Redundante: `bookings_staff_manage_property` es FOR ALL con la misma
--    expresión, así que ya cubre el SELECT del staff. Una política permisiva
--    menos que evaluar en cada fila de cada consulta.
DROP POLICY IF EXISTS "bookings_staff_select_property" ON public.bookings;

-- Resultado: SELECT sobre `bookings` pasa de 4 políticas permisivas a 2
--   · bookings_guest_select_own        → el huésped ve su reserva
--   · bookings_staff_manage_property   → staff ve las de su propiedad
