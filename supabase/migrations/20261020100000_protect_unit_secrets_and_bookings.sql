-- ============================================================================
-- Proteger los datos de acceso de las unidades y cerrar la lectura anónima
-- de reservas
-- ----------------------------------------------------------------------------
-- A) `bookings_anon_select_by_code` dejaba leer, sin sesión y solo con la clave
--    pública de la app, todas las reservas activas con keybox_code, email y
--    teléfono. El login ya no la necesita (usa claim_booking_by_code desde la
--    1.0.49; ambas tiendas están en ≥ 1.0.50 con actualización obligatoria).
--    Es lo que preparaba 20260909140000_close_bookings_select_leak, que se dejó
--    sin aplicar hasta publicar la app.
--    También se quita `bookings_staff_select_property`, duplicado de
--    `bookings_staff_manage_property` (FOR ALL con la misma expresión).
--
-- B) La vista pública `units_with_full_address` (catálogo de alojamientos,
--    SECURITY DEFINER) devolvía a cualquiera las instrucciones de bienvenida y
--    de acceso, la ubicación de la caja y la taquilla. box_code y wifi_password
--    se ocultaban con can_view_unit_secrets(), pero esta no exigía check-in
--    validado (bastaba estar dentro de las fechas, incluso con fianza pendiente).
--    Ahora todos esos campos salen vacíos salvo para staff o para el huésped de
--    esa unidad con el check-in validado y dentro de su estancia. Las columnas
--    de la vista no cambian, así que la app no se rompe.
--
-- C) Funciones que aún podía ejecutar el rol `anon`.
--
-- Rollback: 20261020100000_protect_unit_secrets_and_bookings.ROLLBACK.sql
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- A) Reservas
-- ----------------------------------------------------------------------------
DROP POLICY IF EXISTS "bookings_anon_select_by_code" ON public.bookings;
DROP POLICY IF EXISTS "bookings_staff_select_property" ON public.bookings;

-- ----------------------------------------------------------------------------
-- B) Datos de acceso de las unidades
-- ----------------------------------------------------------------------------
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
      -- Check-in validado (con fianza pendiente no se puede validar)
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

CREATE OR REPLACE VIEW public.units_with_full_address AS
 SELECT id,
    property_id,
    name,
    unit_type,
        CASE
            WHEN can_view_unit_secrets(id) THEN box_location_text
            ELSE NULL::text
        END AS box_location_text,
        CASE
            WHEN can_view_unit_secrets(id) THEN box_code
            ELSE NULL::text
        END AS box_code,
        CASE
            WHEN can_view_unit_secrets(id) THEN locker_number
            ELSE NULL::text
        END AS locker_number,
        CASE
            WHEN can_view_unit_secrets(id) THEN access_instructions
            ELSE NULL::text
        END AS access_instructions,
        CASE
            WHEN can_view_unit_secrets(id) THEN welcome_instructions
            ELSE NULL::text
        END AS welcome_instructions,
    wifi_network,
        CASE
            WHEN can_view_unit_secrets(id) THEN wifi_password
            ELSE NULL::text
        END AS wifi_password,
    created_at,
    address_text,
    city,
    area,
    address_line1,
    address_line2,
    neighborhood,
    province,
    region,
    postal_code,
    country,
    lat,
    lng,
    TRIM(BOTH FROM ((((COALESCE(address_line1, ''::text) ||
        CASE
            WHEN neighborhood IS NOT NULL THEN ' - '::text || neighborhood
            ELSE ''::text
        END) ||
        CASE
            WHEN city IS NOT NULL THEN ', '::text || city
            ELSE ''::text
        END) ||
        CASE
            WHEN province IS NOT NULL THEN ', '::text || province
            ELSE ''::text
        END) ||
        CASE
            WHEN region IS NOT NULL THEN ', '::text || region
            ELSE ''::text
        END) ||
        CASE
            WHEN country IS NOT NULL THEN ', '::text || country
            ELSE ''::text
        END) AS full_address
   FROM units;

-- ----------------------------------------------------------------------------
-- C) Sin ejecución para `anon`
-- ----------------------------------------------------------------------------
REVOKE EXECUTE ON FUNCTION public.can_access_chat_media(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_access_chat_media(text) TO authenticated, service_role;

-- can_view_unit_secrets() conserva EXECUTE para anon: la usa la vista pública
-- units_with_full_address y quien consulta una vista necesita permiso sobre las
-- funciones que llama. Sin sesión devuelve false. (Se aplicó primero el REVOKE y
-- se corrigió con la migración restore_anon_execute_can_view_unit_secrets.)

REVOKE EXECUTE ON FUNCTION public.reactivate_booking(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reactivate_booking(uuid) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.set_booking_auto_validate_checkin(uuid, boolean) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.set_booking_auto_validate_checkin(uuid, boolean) TO authenticated, service_role;

REVOKE EXECUTE ON FUNCTION public.trg_checkin_status_notify() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.trg_checkin_status_notify() TO service_role;

COMMIT;
