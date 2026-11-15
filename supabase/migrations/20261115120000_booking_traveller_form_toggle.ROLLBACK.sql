-- Rollback de 20261115120000_booking_traveller_form_toggle.sql
-- Vuelve al estado de 20261115110200: el huésped puede usar el formulario
-- nuevo en cualquier reserva. Se pierde qué reservas lo tenían activado.

BEGIN;

CREATE OR REPLACE FUNCTION public._can_access_traveller_register(
  p_booking_id UUID,
  p_write BOOLEAN
)
 RETURNS BOOLEAN
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
  SELECT auth.role() = 'service_role'
    OR (public.is_staff() AND EXISTS (
          SELECT 1 FROM public.bookings b
           WHERE b.id = p_booking_id
             AND (public.is_admin() OR b.property_id = public.current_property_id())))
    OR EXISTS (
          SELECT 1 FROM public.bookings b
           WHERE b.id = p_booking_id
             AND b.primary_guest_user_id = auth.uid()
             AND (NOT p_write OR b.status IN ('confirmed', 'checked_in')));
$function$;

REVOKE EXECUTE ON FUNCTION public._can_access_traveller_register(UUID, BOOLEAN) FROM PUBLIC, anon, authenticated;

DROP FUNCTION IF EXISTS public.set_booking_traveller_form(UUID, BOOLEAN);

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

ALTER TABLE public.bookings DROP COLUMN IF EXISTS traveller_form_enabled;

COMMIT;
