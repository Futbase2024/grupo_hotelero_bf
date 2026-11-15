-- ============================================================================
-- Registro de viajeros — 4: formulario RD 933 solo bajo petición
-- ----------------------------------------------------------------------------
-- Decisión del usuario (2026-11-15): el método principal del check-in sigue
-- siendo la subida de fotos del documento (flujo actual). El formulario de
-- registro de viajeros solo aparece en las reservas en las que el staff lo
-- activa desde el panel.
--
-- · bookings.traveller_form_enabled (false por defecto)
-- · set_booking_traveller_form(): solo staff, solo antes de enviar el
--   check-in, queda en audit_log
-- · trg_guard_booking_direct_update: el huésped no puede activárselo
--   (además de la RLS, que ya no le deja hacer UPDATE en bookings)
-- · _can_access_traveller_register: el huésped solo puede ESCRIBIR en el
--   registro (guardar, firmar, enviar) si su reserva lo tiene activado.
--   El staff no depende del interruptor.
--
-- Rollback: 20261115120000_booking_traveller_form_toggle.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1) Interruptor por reserva
-- ----------------------------------------------------------------------------
ALTER TABLE public.bookings
  ADD COLUMN IF NOT EXISTS traveller_form_enabled BOOLEAN NOT NULL DEFAULT false;

COMMENT ON COLUMN public.bookings.traveller_form_enabled IS
  'true = el huésped hace el check-in con el formulario de registro de viajeros (RD 933). false = check-in por fotos del documento (método principal).';

-- ----------------------------------------------------------------------------
-- 2) El huésped no puede cambiarlo (misma lista que antes + la columna nueva)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_guard_booking_direct_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
BEGIN
  IF public.is_direct_non_staff_write() AND (
       NEW.auto_validate_checkin   IS DISTINCT FROM OLD.auto_validate_checkin
    OR NEW.traveller_form_enabled  IS DISTINCT FROM OLD.traveller_form_enabled
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
    RAISE EXCEPTION 'not_allowed: la fianza, la auto-validación y el formulario de registro solo los gestiona el staff'
      USING ERRCODE = '42501';
  END IF;

  RETURN NEW;
END;
$function$;

-- ----------------------------------------------------------------------------
-- 3) Activar / desactivar desde el panel
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_booking_traveller_form(
  p_booking_id UUID,
  p_enabled BOOLEAN
)
 RETURNS JSONB
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_property_id    UUID;
  v_current        BOOLEAN;
  v_checkin_status TEXT;
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not_allowed: se requiere rol staff' USING ERRCODE = '42501';
  END IF;
  IF p_enabled IS NULL THEN
    RAISE EXCEPTION 'invalid_value' USING ERRCODE = '22023';
  END IF;

  SELECT b.property_id, b.traveller_form_enabled, c.status
    INTO v_property_id, v_current, v_checkin_status
    FROM bookings b
    LEFT JOIN checkins c ON c.booking_id = b.id
   WHERE b.id = p_booking_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Reserva no encontrada');
  END IF;

  IF auth.role() <> 'service_role'
     AND NOT public.is_admin()
     AND v_property_id IS DISTINCT FROM public.current_property_id() THEN
    RAISE EXCEPTION 'not_allowed: la reserva no es de tu propiedad' USING ERRCODE = '42501';
  END IF;

  IF v_current = p_enabled THEN
    RETURN jsonb_build_object('success', true, 'traveller_form_enabled', p_enabled, 'changed', false);
  END IF;

  IF v_checkin_status IN ('submitted', 'validated') THEN
    RETURN jsonb_build_object('success', false, 'error',
      'checkin_already_submitted: el check-in ya se ha enviado; no se puede cambiar el método');
  END IF;

  UPDATE bookings SET traveller_form_enabled = p_enabled WHERE id = p_booking_id;

  INSERT INTO audit_log (action, table_name, record_id, user_id, details)
  VALUES ('set_booking_traveller_form', 'bookings', p_booking_id, auth.uid(),
          jsonb_build_object('enabled', p_enabled));

  RETURN jsonb_build_object('success', true, 'traveller_form_enabled', p_enabled, 'changed', true);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.set_booking_traveller_form(UUID, BOOLEAN) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_booking_traveller_form(UUID, BOOLEAN) TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 4) El huésped solo escribe en el registro si su reserva lo tiene activado
-- ----------------------------------------------------------------------------
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
             AND (NOT p_write OR (b.status IN ('confirmed', 'checked_in')
                                  AND b.traveller_form_enabled)));
$function$;

REVOKE EXECUTE ON FUNCTION public._can_access_traveller_register(UUID, BOOLEAN) FROM PUBLIC, anon, authenticated;

COMMIT;
