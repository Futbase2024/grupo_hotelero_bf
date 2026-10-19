-- ============================================================================
-- Impedir que el huésped se valide a sí mismo o se salte la fianza
-- ----------------------------------------------------------------------------
-- Las políticas RLS `checkins_update` y `bookings_guest_update_own_simple`
-- permiten al huésped hacer UPDATE directo (vía API REST) sobre su check-in y
-- su reserva SIN limitar columnas. Con eso podía:
--   · poner checkins.status = 'validated' y obtener los códigos de acceso
--     (get_access_for_booking solo comprueba ese estado);
--   · cambiar bookings.deposit_status para saltarse la fianza;
--   · activar bookings.auto_validate_checkin y auto-validarse.
--
-- La app del huésped nunca escribe directamente en estas tablas: todo pasa por
-- funciones SECURITY DEFINER (submit_guest_checkin, request_checkout…), que se
-- ejecutan con el rol del propietario y por tanto NO se ven afectadas. Tampoco
-- el staff (is_staff) ni service_role (Edge Functions).
--
-- Se bloquea solo lo que da acceso: el resto del comportamiento no cambia.
-- Rollback exacto en: 20261019150000_guard_guest_direct_updates.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ¿El cambio lo hace directamente un cliente que no es staff?
-- Dentro de una función SECURITY DEFINER current_user es el propietario
-- (postgres), así que solo los UPDATE directos llegan con estos roles.
CREATE OR REPLACE FUNCTION public.is_direct_non_staff_write()
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT current_user IN ('authenticated', 'anon') AND NOT public.is_staff();
$function$;

CREATE OR REPLACE FUNCTION public.trg_guard_checkin_direct_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.is_direct_non_staff_write() AND (
       (NEW.status = 'validated' AND OLD.status IS DISTINCT FROM 'validated')
    OR NEW.validated_at IS DISTINCT FROM OLD.validated_at
  ) THEN
    RAISE EXCEPTION 'not_allowed: solo el staff puede validar un check-in'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_checkin_direct_update ON public.checkins;

CREATE TRIGGER trg_guard_checkin_direct_update
  BEFORE UPDATE ON public.checkins
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_guard_checkin_direct_update();

CREATE OR REPLACE FUNCTION public.trg_guard_booking_direct_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.is_direct_non_staff_write() AND (
       NEW.auto_validate_checkin   IS DISTINCT FROM OLD.auto_validate_checkin
    OR NEW.deposit_status          IS DISTINCT FROM OLD.deposit_status
    OR NEW.deposit_amount_cents    IS DISTINCT FROM OLD.deposit_amount_cents
    OR NEW.deposit_payment_link    IS DISTINCT FROM OLD.deposit_payment_link
    OR NEW.deposit_sent_via        IS DISTINCT FROM OLD.deposit_sent_via
    OR NEW.deposit_requested_at    IS DISTINCT FROM OLD.deposit_requested_at
    OR NEW.deposit_requested_by    IS DISTINCT FROM OLD.deposit_requested_by
    OR NEW.deposit_paid_at         IS DISTINCT FROM OLD.deposit_paid_at
    OR NEW.deposit_paid_by         IS DISTINCT FROM OLD.deposit_paid_by
    OR NEW.deposit_reference       IS DISTINCT FROM OLD.deposit_reference
    OR NEW.deposit_returned_at     IS DISTINCT FROM OLD.deposit_returned_at
    OR NEW.deposit_returned_by     IS DISTINCT FROM OLD.deposit_returned_by
    OR NEW.deposit_returned_cents  IS DISTINCT FROM OLD.deposit_returned_cents
    OR NEW.deposit_retained_cents  IS DISTINCT FROM OLD.deposit_retained_cents
    OR NEW.deposit_retained_reason IS DISTINCT FROM OLD.deposit_retained_reason
  ) THEN
    RAISE EXCEPTION 'not_allowed: la fianza y la auto-validación solo las gestiona el staff'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_booking_direct_update ON public.bookings;

CREATE TRIGGER trg_guard_booking_direct_update
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_guard_booking_direct_update();

-- Funciones de trigger: nunca por RPC
REVOKE EXECUTE ON FUNCTION public.trg_guard_checkin_direct_update() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_guard_checkin_direct_update() TO service_role;
REVOKE EXECUTE ON FUNCTION public.trg_guard_booking_direct_update() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_guard_booking_direct_update() TO service_role;

-- Helper: lo invocan los triggers con el rol del cliente, necesita EXECUTE
REVOKE EXECUTE ON FUNCTION public.is_direct_non_staff_write() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_direct_non_staff_write() TO authenticated, service_role;

COMMIT;
