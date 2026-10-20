-- ============================================================================
-- ROLLBACK de 20261003160000_end_guest_access_at_checkout.sql
-- ----------------------------------------------------------------------------
-- Restaura el esquema anterior. NO reabre las reservas cerradas por la
-- migración (eran salidas ya hechas o estancias terminadas).
-- ============================================================================

-- Cron: vuelve al cierre diario de las 06:00 UTC
SELECT cron.alter_job(
  job_id   := (SELECT jobid FROM cron.job WHERE jobname = 'auto-close-expired-bookings'),
  schedule := '0 6 * * *',
  command  := $cmd$
  UPDATE bookings
  SET
    status = 'checked_out',
    booking_status = 'closed',
    checkout_status = 'validated',
    closed_at = NOW(),
    checkout_validated_at = NOW(),
    checkout_notes = 'Auto-closed: checkout date passed without checkout',
    updated_at = NOW()
  WHERE checkout_date < CURRENT_DATE
    AND status NOT IN ('checked_out', 'closed', 'cancelled');
  $cmd$
);

-- RLS bookings
DROP POLICY IF EXISTS "bookings_guest_select_own" ON public.bookings;
CREATE POLICY "bookings_guest_select_own" ON public.bookings
  FOR SELECT USING (primary_guest_user_id = (SELECT auth.uid()));

CREATE POLICY "guest_select_own_booking" ON public.bookings
  FOR SELECT USING (primary_guest_user_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "bookings_anon_select_by_code" ON public.bookings;
CREATE POLICY "bookings_anon_select_by_code" ON public.bookings
  FOR SELECT USING (status = ANY (ARRAY['confirmed'::text, 'checked_in'::text]));

-- RLS units + vista del catálogo
DROP POLICY IF EXISTS "units_guest_select_active_stay" ON public.units;
CREATE POLICY "Allow public read access" ON public.units
  FOR SELECT USING (true);

CREATE OR REPLACE VIEW public.units_with_full_address AS
 SELECT id,
    property_id,
    name,
    unit_type,
    box_location_text,
    box_code,
    locker_number,
    access_instructions,
    welcome_instructions,
    wifi_network,
    wifi_password,
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
    TRIM(BOTH FROM (((((COALESCE(address_line1, ''::text) ||
        CASE
            WHEN (neighborhood IS NOT NULL) THEN (' - '::text || neighborhood)
            ELSE ''::text
        END) ||
        CASE
            WHEN (city IS NOT NULL) THEN (', '::text || city)
            ELSE ''::text
        END) ||
        CASE
            WHEN (province IS NOT NULL) THEN (', '::text || province)
            ELSE ''::text
        END) ||
        CASE
            WHEN (region IS NOT NULL) THEN (', '::text || region)
            ELSE ''::text
        END) ||
        CASE
            WHEN (country IS NOT NULL) THEN (', '::text || country)
            ELSE ''::text
        END)) AS full_address
   FROM public.units;

ALTER VIEW public.units_with_full_address SET (security_invoker = on);

DROP FUNCTION IF EXISTS public.can_view_unit_secrets(uuid);

-- RPCs
CREATE OR REPLACE FUNCTION public.claim_booking_by_code(p_code text, p_email text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
    v_uid     uuid := auth.uid();
    v_code    text := upper(btrim(coalesce(p_code, '')));
    v_email   text := lower(btrim(coalesce(p_email, '')));
    v_booking public.bookings%ROWTYPE;
BEGIN
    IF v_uid IS NULL THEN
        RAISE EXCEPTION 'no_session';
    END IF;

    IF v_code = '' THEN
        RAISE EXCEPTION 'booking_not_found';
    END IF;

    SELECT * INTO v_booking
    FROM public.bookings
    WHERE booking_code = v_code;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'booking_not_found';
    END IF;

    IF v_booking.status = 'cancelled' THEN
        RAISE EXCEPTION 'code_expired:booking_cancelled';
    END IF;

    IF v_booking.status IS NOT NULL
       AND v_booking.status NOT IN ('confirmed', 'checked_in') THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF v_booking.checkout_date IS NOT NULL
       AND now() > (v_booking.checkout_date::timestamptz + interval '1 day') THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF p_email IS NOT NULL AND v_booking.guest_email IS NOT NULL THEN
        IF lower(btrim(v_booking.guest_email)) <> v_email THEN
            RAISE EXCEPTION 'email_mismatch';
        END IF;
    END IF;

    UPDATE public.bookings
    SET primary_guest_user_id = v_uid,
        guest_email = CASE
            WHEN p_email IS NOT NULL AND v_email <> '' THEN v_email
            ELSE guest_email
        END,
        code_first_used_at = coalesce(code_first_used_at, now())
    WHERE id = v_booking.id
    RETURNING * INTO v_booking;

    RETURN jsonb_build_object(
        'id',                v_booking.id,
        'property_id',       v_booking.property_id,
        'unit_id',           v_booking.unit_id,
        'booking_code',      v_booking.booking_code,
        'guest_first_name',  v_booking.guest_first_name,
        'last_name',         v_booking.last_name,
        'guest_email',       v_booking.guest_email,
        'num_guests',        v_booking.num_guests,
        'checkin_date',      v_booking.checkin_date,
        'checkout_date',     v_booking.checkout_date,
        'status',            v_booking.status,
        'code_first_used_at', v_booking.code_first_used_at
    );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_access_for_booking(p_booking_id uuid)
 RETURNS TABLE(unit_name text, box_location text, box_code text, instructions text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  b record;
  u record;
  c record;
begin
  select * into b from public.bookings where id = p_booking_id;
  if not found then
    raise exception 'booking_not_found';
  end if;

  if b.primary_guest_user_id <> auth.uid() and not public.is_staff() then
    raise exception 'not_allowed';
  end if;

  if current_date < b.checkin_date or current_date >= b.checkout_date then
    raise exception 'outside_access_window';
  end if;

  select * into c from public.checkins where booking_id = b.id;
  if not found or c.status <> 'validated' then
    raise exception 'checkin_not_validated';
  end if;

  select * into u from public.units where id = b.unit_id;

  return query
  select
    u.name,
    u.box_location_text,
    u.box_code,
    coalesce(u.access_instructions,'')
  ;
end;
$function$;

-- Funciones nuevas (el interruptor en los triggers es inocuo si nadie lo activa)
DROP FUNCTION IF EXISTS public.auto_close_finished_bookings();
DROP FUNCTION IF EXISTS public.booking_access_ends_at(uuid, date);

ALTER TABLE public.properties DROP COLUMN IF EXISTS checkout_time;
