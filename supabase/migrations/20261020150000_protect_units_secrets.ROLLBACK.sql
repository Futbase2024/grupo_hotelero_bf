-- ============================================================================
-- ROLLBACK de 20261020150000_protect_units_secrets.sql
-- ⚠️ Vuelve a dejar que el huésped con reserva reclamada lea box_code,
--    wifi_password e instrucciones de su unidad sin check-in validado.
-- ============================================================================

BEGIN;

-- Las vistas dependen de public.units: apuntarlas a la tabla antes de borrar
-- la vista (al devolverla a public la siguen por OID).
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
             JOIN private.units u ON u.id = bu.unit_id
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

CREATE OR REPLACE VIEW public.booking_checkin_status
WITH (security_invoker = on) AS
SELECT b.id AS booking_id,
    b.booking_code,
    ( SELECT bu.unit_id
           FROM booking_units bu
          WHERE bu.booking_id = b.id
         LIMIT 1) AS unit_id,
    ( SELECT count(*) AS count
           FROM booking_units bu
          WHERE bu.booking_id = b.id) AS total_units,
    ( SELECT json_agg(json_build_object('id', u.id, 'name', u.name, 'type', u.unit_type)) AS json_agg
           FROM booking_units bu
             JOIN private.units u ON u.id = bu.unit_id
          WHERE bu.booking_id = b.id) AS units,
    b.checkin_date,
    b.checkout_date,
    b.status AS booking_status,
    b.num_guests AS guests_expected,
    count(bg.guest_id) AS guests_registered,
    count(bg.guest_id) FILTER (WHERE bg.requires_document = true) AS guests_requiring_doc,
    count(bg.guest_id) FILTER (WHERE bg.requires_document = true AND (bg.doc_status = ANY (ARRAY['uploaded'::text, 'verified'::text]))) AS guests_doc_ok,
    count(bg.guest_id) FILTER (WHERE bg.requires_document = false) AS guests_exempt,
        CASE
            WHEN count(bg.guest_id) FILTER (WHERE bg.requires_document = true AND (bg.doc_status <> ALL (ARRAY['uploaded'::text, 'verified'::text]))) = 0 AND count(bg.guest_id) > 0 THEN true
            ELSE false
        END AS all_docs_complete,
    c.status AS checkin_status,
    c.submitted_at,
    c.validated_at
   FROM bookings b
     LEFT JOIN booking_guests bg ON bg.booking_id = b.id
     LEFT JOIN checkins c ON c.booking_id = b.id
  GROUP BY b.id, b.booking_code, b.checkin_date, b.checkout_date, b.status, b.num_guests, c.status, c.submitted_at, c.validated_at;

DROP TRIGGER IF EXISTS units_view_update ON public.units;
DROP VIEW IF EXISTS public.units;
DROP FUNCTION IF EXISTS public.units_view_update();
DROP FUNCTION IF EXISTS public.can_read_unit(uuid, uuid);

ALTER TABLE private.units SET SCHEMA public;
GRANT ALL ON TABLE public.units TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION public.can_view_unit_secrets(p_unit_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  IF public.is_staff() THEN
    RETURN true;
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.bookings b
    LEFT JOIN public.properties p ON p.id = b.property_id
    WHERE b.primary_guest_user_id = auth.uid()
      AND b.status IN ('confirmed', 'checked_in')
      AND coalesce(b.booking_status, 'created') NOT IN ('closed', 'cancelled')
      AND now() >= (b.checkin_date::timestamp AT TIME ZONE coalesce(p.timezone, 'Europe/Madrid'))
      AND now() < public.booking_access_ends_at(b.property_id, b.checkout_date)
      AND EXISTS (
        SELECT 1 FROM public.checkins c
         WHERE c.booking_id = b.id AND c.status = 'validated'
      )
      AND (
        b.unit_id = p_unit_id
        OR EXISTS (
          SELECT 1 FROM public.booking_units bu
          WHERE bu.booking_id = b.id AND bu.unit_id = p_unit_id
        )
      )
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_all_units_availability(p_from date DEFAULT CURRENT_DATE, p_to date DEFAULT (CURRENT_DATE + '7 days'::interval), p_property_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(unit_id uuid, unit_name text, unit_type text, property_name text, max_guests integer, status text, next_checkin date, current_guest text, bookings_count integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT (public.is_staff() OR auth.role() = 'service_role') THEN RAISE EXCEPTION 'not_allowed: se requiere rol staff'; END IF;
  RETURN QUERY
  WITH unit_bookings AS (
    SELECT b.unit_id, COUNT(*)::integer AS bcount,
      MIN(b.checkin_date) FILTER (WHERE b.checkin_date >= p_from) AS next_ci,
      MAX(b.last_name) FILTER (WHERE b.checkin_date <= p_from AND b.checkout_date > p_from) AS current_guest_name
    FROM bookings b WHERE b.status NOT IN ('cancelled', 'checked_out') AND b.checkin_date < p_to AND b.checkout_date > p_from
    GROUP BY b.unit_id)
  SELECT u.id, u.name, u.unit_type, p.name, u.max_guests,
    CASE WHEN ub.bcount IS NULL THEN 'free' WHEN ub.current_guest_name IS NOT NULL THEN 'occupied' ELSE 'partial' END,
    ub.next_ci, ub.current_guest_name, COALESCE(ub.bcount, 0)
  FROM units u JOIN properties p ON p.id = u.property_id LEFT JOIN unit_bookings ub ON ub.unit_id = u.id
  WHERE (p_property_id IS NULL OR u.property_id = p_property_id) ORDER BY p.name, u.name;
END; $function$;

CREATE OR REPLACE FUNCTION public.get_checkin_details(p_checkin_id uuid)
 RETURNS TABLE(checkin_id uuid, checkin_status text, signature_svg text, submitted_at timestamp with time zone, validated_at timestamp with time zone, rejected_at timestamp with time zone, rejection_reason text, booking_id uuid, booking_code text, unit_name text, unit_names jsonb, total_units integer, property_name text, checkin_date date, checkout_date date, guest_data jsonb, documents_data jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NOT public.is_staff() THEN
    RAISE EXCEPTION 'Solo el personal puede ver detalles de check-ins';
  END IF;

  RETURN QUERY
  SELECT
    c.id AS checkin_id,
    c.status AS checkin_status,
    c.signature_svg,
    c.submitted_at,
    c.validated_at,
    c.rejected_at,
    c.rejection_reason,
    b.id AS booking_id,
    b.booking_code,
    u.name AS unit_name,
    (
      SELECT jsonb_agg(jsonb_build_object('name', un.name) ORDER BY un.name)
      FROM public.booking_units bu
      JOIN public.units un ON un.id = bu.unit_id
      WHERE bu.booking_id = b.id
    ) AS unit_names,
    (
      SELECT COUNT(*)::int
      FROM public.booking_units bu
      WHERE bu.booking_id = b.id
    ) AS total_units,
    p.name AS property_name,
    b.checkin_date,
    b.checkout_date,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', g.id,
          'full_name', g.full_name,
          'email', g.email,
          'phone', g.phone,
          'document_type', g.document_type,
          'document_number', g.document_number,
          'nationality', g.nationality,
          'birth_date', g.birth_date,
          'type', g.type,
          'age', g.age,
          'is_primary', bg.is_primary
        )
      )
      FROM public.booking_guests bg
      JOIN public.guests g ON g.id = bg.guest_id
      WHERE bg.booking_id = b.id
    ) AS guest_data,
    (
      SELECT jsonb_agg(
        jsonb_build_object(
          'id', gd.id,
          'guest_id', gd.guest_id,
          'doc_kind', gd.doc_kind,
          'storage_path', gd.storage_path,
          'mime_type', gd.mime_type,
          'created_at', gd.created_at
        )
      )
      FROM public.guest_documents gd
      WHERE gd.booking_id = b.id
    ) AS documents_data
  FROM public.checkins c
  JOIN public.bookings b ON b.id = c.booking_id
  JOIN public.units u ON u.id = b.unit_id
  JOIN public.properties p ON p.id = b.property_id
  WHERE c.id = p_checkin_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.set_keybox_code_on_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
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
    join private.properties p on u.property_id = p.id
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

CREATE OR REPLACE FUNCTION public.get_guest_access(p_booking_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  b record;
  v_timezone text;
  v_can_view boolean;
  v_reason text;
  v_main_door_keycode text;
  v_units jsonb;
BEGIN
  IF auth.uid() IS NULL AND auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO b FROM public.bookings WHERE id = p_booking_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_not_found' USING ERRCODE = 'P0002';
  END IF;

  IF NOT (
    b.primary_guest_user_id = auth.uid()
    OR auth.role() = 'service_role'
    OR (public.is_staff() AND (public.is_admin() OR b.property_id = public.current_property_id()))
  ) THEN
    RAISE EXCEPTION 'not_allowed' USING ERRCODE = '42501';
  END IF;

  SELECT p.timezone, p.main_door_keycode
    INTO v_timezone, v_main_door_keycode
    FROM private.properties p
   WHERE p.id = b.property_id;

  v_can_view := public.can_view_booking_secrets(b.id);

  IF v_can_view THEN
    v_reason := 'ok';
  ELSIF b.status NOT IN ('confirmed', 'checked_in')
        OR coalesce(b.booking_status, 'created') IN ('closed', 'cancelled')
        OR now() >= public.booking_access_ends_at(b.property_id, b.checkout_date) THEN
    v_reason := 'outside_window';
  ELSIF NOT EXISTS (
          SELECT 1 FROM public.checkins c
           WHERE c.booking_id = b.id AND c.status = 'validated') THEN
    v_reason := 'checkin_not_validated';
  ELSE
    v_reason := 'before_checkin';
  END IF;

  -- Unidades de la reserva: las de booking_units o, si no hay, la principal.
  SELECT coalesce(jsonb_agg(jsonb_build_object(
           'unit_id', u.id,
           'name', u.name,
           'unit_type', u.unit_type,
           'wifi_network', u.wifi_network,
           'wifi_password', CASE WHEN v_can_view THEN u.wifi_password END,
           'box_code', CASE WHEN v_can_view THEN u.box_code END,
           'box_location_text', CASE WHEN v_can_view THEN u.box_location_text END,
           'locker_number', CASE WHEN v_can_view THEN u.locker_number END,
           'access_instructions', CASE WHEN v_can_view THEN u.access_instructions END,
           'welcome_instructions', CASE WHEN v_can_view THEN u.welcome_instructions END
         ) ORDER BY (u.id = b.unit_id) DESC, x.ord), '[]'::jsonb)
    INTO v_units
    FROM (
      SELECT bu.unit_id, bu.created_at AS ord
        FROM public.booking_units bu
       WHERE bu.booking_id = b.id
      UNION ALL
      SELECT b.unit_id, NULL
       WHERE b.unit_id IS NOT NULL
         AND NOT EXISTS (SELECT 1 FROM public.booking_units bu WHERE bu.booking_id = b.id)
    ) x
    JOIN public.units u ON u.id = x.unit_id;

  RETURN jsonb_build_object(
    'booking_id', b.id,
    'guest_first_name', b.guest_first_name,
    'can_view', v_can_view,
    'reason', v_reason,
    'checkin_date', b.checkin_date,
    'checkout_date', b.checkout_date,
    'early_checkin_available_at', b.early_checkin_available_at,
    'timezone', coalesce(v_timezone, 'Europe/Madrid'),
    'server_time', now(),
    'keybox_code', CASE WHEN v_can_view THEN b.keybox_code END,
    'main_door_keycode', CASE WHEN v_can_view THEN v_main_door_keycode END,
    'units', v_units
  );
END;
$function$;

COMMIT;
