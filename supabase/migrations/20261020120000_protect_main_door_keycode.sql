-- ============================================================================
-- Proteger el código del portal (properties.main_door_keycode)
-- ----------------------------------------------------------------------------
-- La tabla properties tenía la política "Allow public read access" (true): el
-- código del portal era legible por cualquiera, también sin sesión, con la clave
-- pública de la app. No se puede cerrar con REVOKE de columna porque el catálogo
-- hace properties.select() (todas las columnas) sin sesión y las apps
-- instaladas dejarían de funcionar.
--
-- Solución sin nueva versión de la app:
--   1. La tabla pasa al esquema `private` (no expuesto por la API). FKs,
--      índices, políticas y la vista admin_bookings_dashboard la siguen por OID.
--   2. En su lugar, la vista public.properties con las mismas columnas y en el
--      mismo orden; main_door_keycode sale a null salvo para staff de esa
--      propiedad, service_role, conexiones directas a la BD (cron, SQL editor)
--      o el huésped con check-in validado en esa propiedad y dentro de su
--      estancia.
--   3. Las dos escrituras de staff (default_deposit_cents, main_door_keycode)
--      pasan por un trigger INSTEAD OF UPDATE que replica la política
--      properties_staff_update. La vista solo concede SELECT y UPDATE: al ser
--      SECURITY DEFINER, un INSERT/DELETE automático se saltaría la RLS.
--   4. set_keybox_code_on_insert (usa el código del portal como keybox_code en
--      "Bandera") lee la tabla privada y pasa a SECURITY DEFINER; si leyera la
--      vista, con service_role/cron obtendría el valor real, pero así no
--      depende de quién inserte.
--
-- Plan: .claude/plans/proteger_secretos_huesped_plan.md (fase 1b)
-- Rollback: 20261020120000_protect_main_door_keycode.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Mover la tabla a un esquema no expuesto
-- ----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

ALTER TABLE public.properties SET SCHEMA private;
REVOKE ALL ON TABLE private.properties FROM anon, authenticated;

-- ----------------------------------------------------------------------------
-- 2. Quién puede ver el código del portal
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.can_view_property_secrets(p_property_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Conexión directa a la BD (cron, SQL editor), no a través de la API: no es
  -- el login de PostgREST y no lleva claims de JWT.
  IF session_user <> 'authenticator'
     AND coalesce(current_setting('request.jwt.claims', true), '') = '' THEN
    RETURN true;
  END IF;

  IF auth.role() = 'service_role' THEN
    RETURN true;
  END IF;

  IF auth.uid() IS NULL THEN
    RETURN false;
  END IF;

  IF public.is_staff() THEN
    RETURN public.is_admin() OR p_property_id = public.current_property_id();
  END IF;

  RETURN EXISTS (
    SELECT 1
    FROM public.bookings b
    JOIN private.properties p ON p.id = b.property_id
    WHERE b.property_id = p_property_id
      AND b.primary_guest_user_id = auth.uid()
      AND b.status IN ('confirmed', 'checked_in')
      AND coalesce(b.booking_status, 'created') NOT IN ('closed', 'cancelled')
      AND now() >= (b.checkin_date::timestamp AT TIME ZONE coalesce(p.timezone, 'Europe/Madrid'))
      AND now() < public.booking_access_ends_at(b.property_id, b.checkout_date)
      AND EXISTS (
        SELECT 1 FROM public.checkins c
         WHERE c.booking_id = b.id AND c.status = 'validated'
      )
  );
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.can_view_property_secrets(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.can_view_property_secrets(uuid) TO anon, authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3. Vista pública con las mismas columnas
-- ----------------------------------------------------------------------------
CREATE VIEW public.properties AS
SELECT p.id,
       p.name,
       p.address,
       p.city,
       p.country,
       p.timezone,
       p.lat,
       p.lng,
       p.created_at,
       p.parent_property_id,
       CASE WHEN public.can_view_property_secrets(p.id) THEN p.main_door_keycode END AS main_door_keycode,
       p.contact_phone,
       p.contact_email,
       p.contact_website,
       p.checkout_time,
       p.default_deposit_cents
FROM private.properties p;

COMMENT ON VIEW public.properties IS
  'Propiedades (tabla real en private.properties). main_door_keycode enmascarado con can_view_property_secrets().';

REVOKE ALL ON TABLE public.properties FROM PUBLIC, anon, authenticated, service_role;
GRANT SELECT ON TABLE public.properties TO anon, authenticated, service_role;
GRANT UPDATE ON TABLE public.properties TO authenticated, service_role;

-- ----------------------------------------------------------------------------
-- 3b. admin_bookings_dashboard (security_invoker) seguía a la tabla por OID y
--     acabaría leyendo private.properties, sin permisos para staff ni huéspedes.
--     Se redefine igual (fase 1a) pero contra la vista public.properties.
-- ----------------------------------------------------------------------------
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
     JOIN public.properties p ON p.id = b.property_id
     LEFT JOIN booking_units_data bud ON bud.booking_id = b.id AND bud.rn = 1
     LEFT JOIN checkins c ON c.booking_id = b.id
     LEFT JOIN booking_guests bg ON bg.booking_id = b.id
  GROUP BY b.id, b.booking_code, b.booking_status, b.checkout_status, b.status, b.checkin_date, b.checkout_date, b.num_guests, b.last_name, b.staff_notes, b.code_first_used_at, b.created_at, b.early_checkin_available_at, b.closed_at, b.checkout_validated_at, b.checkout_notes, b.num_adults, b.num_children, b.children_ages, b.guest_first_name, b.guest_email, b.guest_phone, b.keybox_code, b.code_sent_at, b.auto_validate_checkin, p.id, p.name, c.id, c.status, c.signature_svg, c.submitted_at, c.validated_at, bud.unit_id, bud.unit_name, bud.unit_type, bud.wifi_network, bud.wifi_password;

-- ----------------------------------------------------------------------------
-- 4. Escrituras de staff a través de la vista
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.properties_view_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Mismo criterio que la política properties_staff_update. Sin permiso, la
  -- fila se omite en silencio (0 filas), igual que hacía la RLS.
  IF NOT (
    (session_user <> 'authenticator'
     AND coalesce(current_setting('request.jwt.claims', true), '') = '')
    OR auth.role() = 'service_role'
    OR (public.is_staff() AND (public.is_admin() OR OLD.id = public.current_property_id()))
  ) THEN
    RETURN NULL;
  END IF;

  UPDATE private.properties p
     SET name = NEW.name,
         address = NEW.address,
         city = NEW.city,
         country = NEW.country,
         timezone = NEW.timezone,
         lat = NEW.lat,
         lng = NEW.lng,
         parent_property_id = NEW.parent_property_id,
         -- Si no cambia, se conserva el valor real (OLD puede venir enmascarado).
         main_door_keycode = CASE
           WHEN NEW.main_door_keycode IS DISTINCT FROM OLD.main_door_keycode
             THEN NEW.main_door_keycode
           ELSE p.main_door_keycode
         END,
         contact_phone = NEW.contact_phone,
         contact_email = NEW.contact_email,
         contact_website = NEW.contact_website,
         checkout_time = NEW.checkout_time,
         default_deposit_cents = NEW.default_deposit_cents
   WHERE p.id = OLD.id;

  RETURN NEW;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.properties_view_update() FROM PUBLIC, anon, authenticated;

CREATE TRIGGER properties_view_update
  INSTEAD OF UPDATE ON public.properties
  FOR EACH ROW EXECUTE FUNCTION public.properties_view_update();

-- ----------------------------------------------------------------------------
-- 5. Trigger de reservas que usa el código del portal
-- ----------------------------------------------------------------------------
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

REVOKE EXECUTE ON FUNCTION public.set_keybox_code_on_insert() FROM PUBLIC, anon, authenticated;

COMMIT;
