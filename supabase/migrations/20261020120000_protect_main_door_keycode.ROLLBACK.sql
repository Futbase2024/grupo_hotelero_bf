-- ============================================================================
-- ROLLBACK de 20261020120000_protect_main_door_keycode.sql
-- ⚠️ Vuelve a dejar el código del portal legible por cualquiera, sin sesión.
-- ============================================================================

BEGIN;

-- La vista del dashboard depende de public.properties: apuntarla a la tabla
-- antes de borrar la vista (al moverla de esquema la sigue por OID).
CREATE OR REPLACE VIEW public.admin_bookings_dashboard
WITH (security_invoker = on) AS
 WITH booking_units_data AS (
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
             JOIN units u ON u.id = bu.unit_id
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
     JOIN private.properties p ON p.id = b.property_id
     LEFT JOIN booking_units_data bud ON bud.booking_id = b.id AND bud.rn = 1
     LEFT JOIN checkins c ON c.booking_id = b.id
     LEFT JOIN booking_guests bg ON bg.booking_id = b.id
  GROUP BY b.id, b.booking_code, b.booking_status, b.checkout_status, b.status, b.checkin_date, b.checkout_date, b.num_guests, b.last_name, b.staff_notes, b.code_first_used_at, b.created_at, b.early_checkin_available_at, b.closed_at, b.checkout_validated_at, b.checkout_notes, b.num_adults, b.num_children, b.children_ages, b.guest_first_name, b.guest_email, b.guest_phone, b.keybox_code, b.code_sent_at, b.auto_validate_checkin, p.id, p.name, c.id, c.status, c.signature_svg, c.submitted_at, c.validated_at, bud.unit_id, bud.unit_name, bud.unit_type, bud.wifi_network, bud.wifi_password;

DROP TRIGGER IF EXISTS properties_view_update ON public.properties;
DROP VIEW IF EXISTS public.properties;
DROP FUNCTION IF EXISTS public.properties_view_update();

ALTER TABLE private.properties SET SCHEMA public;
GRANT ALL ON TABLE public.properties TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.set_keybox_code_on_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
    v_box_code text;
    v_property_name text;
    v_main_door_keycode text;
    v_is_bandera boolean := false;
begin
    -- Obtener la unidad y propiedad asociadas a la reserva
    select u.box_code,
           p.name as property_name,
           p.main_door_keycode
    into v_box_code, v_property_name, v_main_door_keycode
    from public.units u
    join public.properties p on u.property_id = p.id
    where u.id = new.unit_id;

    if not found then
        raise exception 'No se encontró la unidad para la reserva';
    end if;

    -- Verificar si es "Apartamento Bandera" (por nombre de propiedad)
    v_is_bandera := (v_property_name ilike '%bandera%');

    -- Determinar el código a usar
    if v_is_bandera then
        -- Para Apartamento Bandera: usar el código de la puerta principal de la propiedad
        v_box_code := v_main_door_keycode;
    else
        -- Para el resto de unidades: usar el código de la caja de la unidad
        v_box_code := v_box_code;
    end if;

    -- Si no hay código disponible, generar uno aleatorio (fallback)
    if v_box_code is null or v_box_code = '' then
        v_box_code := public.generate_unique_keybox_code();
    end if;

    -- Establecer el código en la reserva
    new.keybox_code := v_box_code;

    return new;
end;
$function$;

GRANT EXECUTE ON FUNCTION public.set_keybox_code_on_insert() TO PUBLIC;

DROP FUNCTION IF EXISTS public.can_view_property_secrets(uuid);
DROP SCHEMA IF EXISTS private;

COMMIT;
