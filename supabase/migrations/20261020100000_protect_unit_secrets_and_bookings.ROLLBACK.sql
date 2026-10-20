-- ============================================================================
-- ROLLBACK de 20261020100000_protect_unit_secrets_and_bookings.sql
-- ⚠️ Vuelve a dejar legibles sin sesión las reservas activas (keybox_code,
--    email, teléfono) y los datos de acceso de las unidades en la vista pública.
-- ============================================================================

BEGIN;

CREATE POLICY "bookings_anon_select_by_code" ON public.bookings
  FOR SELECT
  USING ((status = ANY (ARRAY['confirmed'::text, 'checked_in'::text]))
         AND (now() < booking_access_ends_at(property_id, checkout_date)));

CREATE POLICY "bookings_staff_select_property" ON public.bookings
  FOR SELECT
  USING (is_staff() AND (is_admin() OR (property_id = current_property_id())));

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
    box_location_text,
        CASE
            WHEN can_view_unit_secrets(id) THEN box_code
            ELSE NULL::text
        END AS box_code,
    locker_number,
    access_instructions,
    welcome_instructions,
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

GRANT EXECUTE ON FUNCTION public.can_access_chat_media(text) TO anon;
GRANT EXECUTE ON FUNCTION public.reactivate_booking(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.set_booking_auto_validate_checkin(uuid, boolean) TO anon;
GRANT EXECUTE ON FUNCTION public.trg_checkin_status_notify() TO anon, authenticated;

COMMIT;
