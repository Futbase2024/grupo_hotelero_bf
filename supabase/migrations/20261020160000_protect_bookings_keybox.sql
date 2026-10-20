-- ============================================================================
-- Ocultar bookings.keybox_code a las lecturas directas (punto C, sin release)
-- ----------------------------------------------------------------------------
-- Con la RLS bookings_guest_select_own, el huésped con su reserva reclamada
-- podía pedir `select keybox_code from bookings` y obtener el código de acceso
-- sin check-in validado. Staff y huéspedes comparten el rol `authenticated`,
-- así que se cierra por columna:
--   1. anon/authenticated pierden SELECT sobre la tabla y lo recuperan columna
--      a columna, todas menos keybox_code. INSERT/UPDATE no cambian (el staff
--      sigue pudiendo editar el código; sus updates no piden representación).
--   2. admin_bookings_dashboard (security_invoker) ya no lee la columna: la
--      obtiene con booking_keybox_code(), SECURITY DEFINER, que solo la entrega
--      a quien can_view_booking_secrets() permite (staff, service_role o el
--      huésped validado de esa reserva).
-- service_role (Edge Functions) y las funciones SECURITY DEFINER no cambian.
--
-- ⚠️ A partir de aquí, una columna NUEVA en bookings no será legible por la
--    API hasta añadirle `GRANT SELECT (columna) ... TO anon, authenticated`.
--
-- Plan: .claude/plans/proteger_secretos_huesped_plan.md (fase 3)
-- Rollback: 20261020160000_protect_bookings_keybox.ROLLBACK.sql
-- ============================================================================

BEGIN;

CREATE OR REPLACE FUNCTION public.booking_keybox_code(p_booking_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.can_view_booking_secrets(p_booking_id) THEN
    RETURN NULL;
  END IF;

  RETURN (SELECT b.keybox_code FROM public.bookings b WHERE b.id = p_booking_id);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.booking_keybox_code(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.booking_keybox_code(uuid) TO anon, authenticated, service_role;

CREATE OR REPLACE VIEW public.admin_bookings_dashboard
WITH (security_invoker = on) AS
 WITH units_m AS MATERIALIZED (
         -- Materializada: el enmascarado de public.units se evalúa una vez por
         -- unidad y no por cada fila de booking_units.
         SELECT un.id, un.name, un.unit_type, un.wifi_network, un.wifi_password,
                un.box_code, un.access_instructions
           FROM public.units un
        ), booking_units_data AS (
         SELECT bu.booking_id,
            bu.unit_id,
            u.name AS unit_name,
            u.unit_type,
            u.wifi_network,
            u.wifi_password,
            u.box_code,
            u.access_instructions,
            bu.created_at,
            row_number() OVER (PARTITION BY bu.booking_id ORDER BY bu.created_at) AS rn
           FROM booking_units bu
             JOIN units_m u ON u.id = bu.unit_id
        )
 SELECT b.id AS booking_id,
    b.booking_code,
    b.booking_status,
    b.checkout_status,
    b.status,
    b.checkin_date,
    b.checkout_date,
    b.num_guests,
    b.last_name,
    b.staff_notes,
    b.code_first_used_at,
    b.created_at,
    b.early_checkin_available_at,
    b.closed_at,
    b.checkout_validated_at,
    b.checkout_notes,
    bud.unit_id,
    bud.unit_name,
    bud.unit_type,
    bud.wifi_network,
    CASE WHEN can_view_booking_secrets(b.id) THEN bud.wifi_password END AS wifi_password,
    ( SELECT count(*) AS count
           FROM booking_units bu
          WHERE bu.booking_id = b.id) AS total_units,
    ( SELECT json_agg(json_build_object(
                'id', bud2.unit_id,
                'name', bud2.unit_name,
                'type', bud2.unit_type,
                'wifi_network', bud2.wifi_network,
                'wifi_password', CASE WHEN can_view_booking_secrets(b.id) THEN bud2.wifi_password END,
                'box_code', CASE WHEN can_view_booking_secrets(b.id) THEN bud2.box_code END,
                'access_instructions', CASE WHEN can_view_booking_secrets(b.id) THEN bud2.access_instructions END)) AS json_agg
           FROM booking_units_data bud2
          WHERE bud2.booking_id = b.id) AS units,
    p.id AS property_id,
    p.name AS property_name,
    c.status AS checkin_status,
    c.submitted_at AS checkin_submitted_at,
    c.validated_at AS checkin_validated_at,
    count(bg.guest_id) AS guests_registered,
    count(bg.guest_id) FILTER (WHERE bg.requires_document = true AND (bg.doc_status <> ALL (ARRAY['uploaded'::text, 'verified'::text]))) AS docs_pending,
    count(bg.guest_id) FILTER (WHERE bg.doc_status = 'exempt'::text) AS guests_exempt,
        CASE
            WHEN b.code_first_used_at IS NULL THEN false
            ELSE true
        END AS code_used,
    can_complete_checkin(b.id) AS ready_to_complete,
    c.id AS checkin_id,
    c.signature_svg,
    b.num_adults,
    b.num_children,
    b.children_ages,
    b.guest_first_name,
    b.guest_email,
    b.guest_phone,
    public.booking_keybox_code(b.id) AS keybox_code,
    b.code_sent_at,
    b.auto_validate_checkin
   FROM bookings b
     JOIN public.properties p ON p.id = b.property_id
     LEFT JOIN booking_units_data bud ON bud.booking_id = b.id AND bud.rn = 1
     LEFT JOIN checkins c ON c.booking_id = b.id
     LEFT JOIN booking_guests bg ON bg.booking_id = b.id
  GROUP BY b.id, b.booking_code, b.booking_status, b.checkout_status, b.status, b.checkin_date, b.checkout_date, b.num_guests, b.last_name, b.staff_notes, b.code_first_used_at, b.created_at, b.early_checkin_available_at, b.closed_at, b.checkout_validated_at, b.checkout_notes, b.num_adults, b.num_children, b.children_ages, b.guest_first_name, b.guest_email, b.guest_phone, b.code_sent_at, b.auto_validate_checkin, p.id, p.name, c.id, c.status, c.signature_svg, c.submitted_at, c.validated_at, bud.unit_id, bud.unit_name, bud.unit_type, bud.wifi_network, bud.wifi_password;

REVOKE SELECT ON TABLE public.bookings FROM anon, authenticated;
GRANT SELECT (
  id, property_id, booking_code, last_name, checkin_date, checkout_date,
  status, primary_guest_user_id, created_at, num_guests, staff_notes,
  code_first_used_at, guest_first_name, guest_email, guest_phone,
  code_sent_at, num_adults, num_children, children_ages, booking_status,
  checkout_status, activated_at, closed_at, checkout_requested_at,
  checkout_validated_at, validation_notes, checkout_notes,
  early_checkin_available_at, unit_id, updated_at, previous_guest_user_id,
  auto_validate_checkin, deposit_status, deposit_amount_cents,
  deposit_payment_link, deposit_sent_via, deposit_requested_at,
  deposit_requested_by, deposit_paid_at, deposit_paid_by, deposit_reference,
  deposit_returned_at, deposit_returned_by, deposit_returned_cents,
  deposit_retained_cents, deposit_retained_reason
) ON TABLE public.bookings TO anon, authenticated;

COMMIT;
