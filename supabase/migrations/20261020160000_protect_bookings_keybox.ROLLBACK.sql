-- ============================================================================
-- ROLLBACK de 20261020160000_protect_bookings_keybox.sql
-- ⚠️ Vuelve a dejar keybox_code legible por select directo para el huésped con
--    su reserva reclamada, aunque no esté validado.
-- ============================================================================

BEGIN;

GRANT SELECT ON TABLE public.bookings TO anon, authenticated;

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
    CASE WHEN can_view_booking_secrets(b.id) THEN b.keybox_code END AS keybox_code,
    b.code_sent_at,
    b.auto_validate_checkin
   FROM bookings b
     JOIN public.properties p ON p.id = b.property_id
     LEFT JOIN booking_units_data bud ON bud.booking_id = b.id AND bud.rn = 1
     LEFT JOIN checkins c ON c.booking_id = b.id
     LEFT JOIN booking_guests bg ON bg.booking_id = b.id
  GROUP BY b.id, b.booking_code, b.booking_status, b.checkout_status, b.status, b.checkin_date, b.checkout_date, b.num_guests, b.last_name, b.staff_notes, b.code_first_used_at, b.created_at, b.early_checkin_available_at, b.closed_at, b.checkout_validated_at, b.checkout_notes, b.num_adults, b.num_children, b.children_ages, b.guest_first_name, b.guest_email, b.guest_phone, b.keybox_code, b.code_sent_at, b.auto_validate_checkin, p.id, p.name, c.id, c.status, c.signature_svg, c.submitted_at, c.validated_at, bud.unit_id, bud.unit_name, bud.unit_type, bud.wifi_network, bud.wifi_password;

DROP FUNCTION IF EXISTS public.booking_keybox_code(uuid);

COMMIT;
