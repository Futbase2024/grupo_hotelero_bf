-- ============================================================================
-- Quitar al huésped el UPDATE directo de reservas y check-ins
-- ----------------------------------------------------------------------------
-- Continuación de 20261019150000_guard_guest_direct_updates. Aquel trigger
-- protegía solo la validación, la fianza y la auto-validación, pero el huésped
-- seguía pudiendo cambiar cualquier otra columna de su reserva vía API REST.
-- La más peligrosa es `checkout_date`: de ella dependen la ventana de acceso a
-- los códigos (booking_access_ends_at) y la caducidad de su sesión, así que
-- alargándola podía seguir viendo los códigos después de irse.
--
-- La app del huésped NUNCA escribe directamente en `bookings` ni en `checkins`:
-- todo pasa por funciones SECURITY DEFINER (propiedad de `postgres`, que tiene
-- BYPASSRLS), por lo que quitar estas políticas no les afecta. El staff conserva
-- sus políticas propias y las Edge Functions usan service_role.
--
-- Además, el bloqueo por fianza pendiente pasa a aplicarse a CUALQUIER rol:
-- la acción `validate_checkin` de la Edge Function `admin-panel` escribía
-- `status='validated'` directamente con service_role y se lo saltaba.
--
-- Rollback exacto en: 20261019170000_restrict_guest_direct_updates.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- 1) Reservas: el huésped deja de poder hacer UPDATE directo
DROP POLICY IF EXISTS bookings_guest_update_own_simple ON public.bookings;

-- 2) Check-ins: UPDATE directo solo para staff de la propiedad
DROP POLICY IF EXISTS checkins_update ON public.checkins;

CREATE POLICY checkins_update ON public.checkins
  FOR UPDATE
  USING (
    is_staff() AND EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND (is_admin() OR b.property_id = current_property_id())
    )
  )
  WITH CHECK (
    is_staff() AND EXISTS (
      SELECT 1 FROM bookings b
       WHERE b.id = checkins.booking_id
         AND (is_admin() OR b.property_id = current_property_id())
    )
  );

-- 3) Ningún rol valida un check-in con fianza pendiente
CREATE OR REPLACE FUNCTION public.trg_guard_checkin_direct_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_is_validating BOOLEAN :=
    NEW.status = 'validated' AND OLD.status IS DISTINCT FROM 'validated';
BEGIN
  IF public.is_direct_non_staff_write() AND (
       v_is_validating
    OR NEW.validated_at IS DISTINCT FROM OLD.validated_at
  ) THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede validar un check-in'
      USING ERRCODE = '42501';
  END IF;

  -- Aplica también a service_role y a funciones SECURITY DEFINER: la única
  -- forma de validar con fianza es confirm_deposit_and_validate, que la marca
  -- como pagada antes de validar.
  IF v_is_validating AND EXISTS (
    SELECT 1 FROM bookings
     WHERE id = NEW.booking_id AND deposit_status = 'pending'
  ) THEN
    RAISE EXCEPTION 'deposit_pending: la reserva tiene una fianza pendiente de pago'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$function$;

COMMIT;
