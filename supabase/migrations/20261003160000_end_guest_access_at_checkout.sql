-- ============================================================================
-- El acceso del huésped termina a la hora de check-out del día de salida
-- ----------------------------------------------------------------------------
-- PROBLEMA (2026-10-03)
-- Una reserva del 2 al 3 seguía mostrando los códigos y dejando entrar en la
-- app la tarde del día 3. Causas:
--   · El cron `auto-close-expired-bookings` cerraba con
--     `checkout_date < CURRENT_DATE` a las 06:00 UTC → la reserva seguía
--     `checked_in` hasta el día SIGUIENTE a la salida.
--   · `claim_booking_by_code` permitía entrar hasta `checkout_date + 1 día`.
--   · Las RLS de `bookings` (huésped) no tenían límite temporal, y `units`
--     era legible por cualquiera (incluidos `box_code` y `wifi_password`).
--   · Las salidas marcadas a mano (`status = 'checked_out'`) dejaban
--     `booking_status = 'created'` y el cron las ignoraba (317 + 6 reservas).
--
-- SOLUCIÓN
--   1. `properties.checkout_time` (11:30 apartamentos, 12:00 hoteles: lo mismo
--      que ya muestra la app al huésped) y `booking_access_ends_at()`.
--   2. Cierre automático cada 5 min al pasar la hora de salida.
--   3. Interruptor `bf.silent_close` en los triggers de notificación para
--      cerrar reservas ya salidas sin mandar push.
--   4. RLS de `bookings` (huésped) limitada a la estancia en curso.
--   5. `units`: fuera la lectura pública; el catálogo usa la vista
--      `units_with_full_address`, que oculta `box_code` y `wifi_password` salvo
--      a staff o al huésped durante su estancia.
--   6. `claim_booking_by_code` y `get_access_for_booking` usan el nuevo límite.
--   7. Cierre retroactivo (silencioso) de las reservas ya salidas.
--
-- Rollback: 20261003160000_end_guest_access_at_checkout.ROLLBACK.sql
-- ============================================================================

-- 1. Hora de check-out por propiedad ----------------------------------------
ALTER TABLE public.properties
  ADD COLUMN IF NOT EXISTS checkout_time time NOT NULL DEFAULT '11:30';

UPDATE public.properties
SET checkout_time = '12:00'
WHERE name ILIKE '%hotel%';

COMMENT ON COLUMN public.properties.checkout_time IS
  'Hora local (properties.timezone) a la que termina el acceso del huésped el día de salida';

CREATE OR REPLACE FUNCTION public.booking_access_ends_at(
  p_property_id uuid,
  p_checkout_date date
)
RETURNS timestamptz
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
  SELECT (p_checkout_date + coalesce(p.checkout_time, time '11:30'))
           AT TIME ZONE coalesce(p.timezone, 'Europe/Madrid')
  FROM (SELECT 1) AS one
  LEFT JOIN public.properties p ON p.id = p_property_id;
$function$;

COMMENT ON FUNCTION public.booking_access_ends_at(uuid, date) IS
  'Instante en que el huésped pierde el acceso: checkout_date a la hora checkout_time de la propiedad';

-- 3. Interruptor de notificaciones en los triggers --------------------------
CREATE OR REPLACE FUNCTION public.trg_booking_status_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_title   TEXT;
  v_body    TEXT;
  v_data    JSONB;
BEGIN
  -- Solo disparar si booking_status cambió
  IF NEW.booking_status IS NOT DISTINCT FROM OLD.booking_status THEN
    RETURN NEW;
  END IF;

  -- Cierres de reservas ya salidas: sin push
  IF current_setting('bf.silent_close', true) = 'on' THEN
    RETURN NEW;
  END IF;

  v_user_id := NEW.primary_guest_user_id;
  IF v_user_id IS NULL THEN
    RETURN NEW;  -- reserva sin usuario registrado (reserva externa)
  END IF;

  CASE NEW.booking_status
    WHEN 'active' THEN
      v_title := '🏠 ¡Bienvenido a BF-Stay!';
      v_body  := 'Tu reserva está activa. Ya puedes acceder a toda la información.';
    WHEN 'closed' THEN
      v_title := '✅ Check-out completado';
      v_body  := 'Esperamos que hayas disfrutado tu estancia. ¡Hasta pronto!';
    WHEN 'cancelled' THEN
      v_title := '❌ Reserva cancelada';
      v_body  := 'Tu reserva ha sido cancelada. Contacta con nosotros si tienes dudas.';
    ELSE
      RETURN NEW;  -- otros estados no generan notificación
  END CASE;

  v_data := jsonb_build_object(
    'type',       'booking_status',
    'booking_id', NEW.id::TEXT,
    'status',     NEW.booking_status,
    'url',        '/booking/' || NEW.id::TEXT
  );

  PERFORM public.notify_fcm(jsonb_build_object(
    'user_id',    v_user_id,
    'booking_id', NEW.id,
    'type',       'booking_status',
    'title',      v_title,
    'body',       v_body,
    'data',       v_data
  ));

  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.trg_checkout_status_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_title TEXT;
  v_body  TEXT;
BEGIN
  IF NEW.checkout_status IS NOT DISTINCT FROM OLD.checkout_status THEN
    RETURN NEW;
  END IF;

  -- Cierres de reservas ya salidas: sin push
  IF current_setting('bf.silent_close', true) = 'on' THEN
    RETURN NEW;
  END IF;

  IF NEW.primary_guest_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  CASE NEW.checkout_status
    WHEN 'requested' THEN
      v_title := '🔔 Check-out solicitado';
      v_body  := 'Tu solicitud de check-out ha sido recibida. La revisaremos en breve.';
    WHEN 'validated' THEN
      v_title := '✅ Check-out validado';
      v_body  := 'Tu check-out ha sido aprobado. ¡Gracias por tu estancia!';
    WHEN 'rejected' THEN
      v_title := '⚠️ Check-out pendiente de revisión';
      v_body  := COALESCE(NEW.validation_notes, 'Por favor revisa los comentarios del staff.');
    ELSE
      RETURN NEW;
  END CASE;

  PERFORM public.notify_fcm(jsonb_build_object(
    'user_id',    NEW.primary_guest_user_id,
    'booking_id', NEW.id,
    'type',       'checkout_status',
    'title',      v_title,
    'body',       v_body,
    'data',       jsonb_build_object(
      'type',            'checkout_status',
      'booking_id',      NEW.id::TEXT,
      'checkout_status', NEW.checkout_status,
      'url',             '/booking/' || NEW.id::TEXT || '/checkout'
    )
  ));

  RETURN NEW;
END;
$function$;

-- 2. Cierre automático ------------------------------------------------------
CREATE OR REPLACE FUNCTION public.auto_close_finished_bookings()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_silent integer;
  v_active integer;
BEGIN
  -- a) Salida ya marcada a mano pero reserva sin cerrar: se cierra sin push
  --    (el huésped ya se fue y fue avisado al marcar la salida).
  PERFORM set_config('bf.silent_close', 'on', true);

  UPDATE public.bookings
  SET booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = coalesce(closed_at, now()),
      checkout_validated_at = coalesce(checkout_validated_at, now()),
      updated_at            = now()
  WHERE status = 'checked_out'
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() >= public.booking_access_ends_at(property_id, checkout_date);
  GET DIAGNOSTICS v_silent = ROW_COUNT;

  -- b) Estancias que siguen abiertas pasada la hora de salida: cierre con push.
  PERFORM set_config('bf.silent_close', 'off', true);

  UPDATE public.bookings
  SET status                = 'checked_out',
      booking_status        = 'closed',
      checkout_status       = 'validated',
      closed_at             = coalesce(closed_at, now()),
      checkout_validated_at = coalesce(checkout_validated_at, now()),
      checkout_notes        = coalesce(checkout_notes, 'Auto-closed: checkout time passed'),
      updated_at            = now()
  WHERE status IN ('confirmed', 'checked_in')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() >= public.booking_access_ends_at(property_id, checkout_date);
  GET DIAGNOSTICS v_active = ROW_COUNT;

  RETURN v_silent + v_active;
END;
$function$;

REVOKE ALL ON FUNCTION public.auto_close_finished_bookings() FROM PUBLIC, anon, authenticated;

SELECT cron.alter_job(
  job_id   := (SELECT jobid FROM cron.job WHERE jobname = 'auto-close-expired-bookings'),
  schedule := '*/5 * * * *',
  command  := 'SELECT public.auto_close_finished_bookings();'
);

-- 4. RLS de bookings: el huésped solo ve su reserva durante la estancia -----
DROP POLICY IF EXISTS "guest_select_own_booking" ON public.bookings;  -- duplicado exacto
DROP POLICY IF EXISTS "bookings_guest_select_own" ON public.bookings;

CREATE POLICY "bookings_guest_select_own" ON public.bookings
  FOR SELECT
  USING (
    primary_guest_user_id = (SELECT auth.uid())
    AND status IN ('confirmed', 'checked_in')
    AND coalesce(booking_status, 'created') NOT IN ('closed', 'cancelled')
    AND now() < public.booking_access_ends_at(property_id, checkout_date)
  );

-- La fuga por código sigue mientras haya apps antiguas que hacen login con
-- SELECT directo (ver 20260909140000_close_bookings_select_leak.sql), pero
-- deja de exponer reservas cuya estancia ya terminó.
DROP POLICY IF EXISTS "bookings_anon_select_by_code" ON public.bookings;

CREATE POLICY "bookings_anon_select_by_code" ON public.bookings
  FOR SELECT
  USING (
    status IN ('confirmed', 'checked_in')
    AND now() < public.booking_access_ends_at(property_id, checkout_date)
  );

-- 5. units: sin lectura pública ---------------------------------------------
CREATE OR REPLACE FUNCTION public.can_view_unit_secrets(p_unit_id uuid)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
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

GRANT EXECUTE ON FUNCTION public.can_view_unit_secrets(uuid) TO anon, authenticated;

DROP POLICY IF EXISTS "Allow public read access" ON public.units;

-- El huésped lee directamente su unidad (caja de llaves, parking, nombre)
-- solo mientras dura su estancia.
CREATE POLICY "units_guest_select_active_stay" ON public.units
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.bookings b
      WHERE b.primary_guest_user_id = (SELECT auth.uid())
        AND b.status IN ('confirmed', 'checked_in')
        AND coalesce(b.booking_status, 'created') NOT IN ('closed', 'cancelled')
        AND now() < public.booking_access_ends_at(b.property_id, b.checkout_date)
        AND (
          b.unit_id = units.id
          OR EXISTS (
            SELECT 1 FROM public.booking_units bu
            WHERE bu.booking_id = b.id AND bu.unit_id = units.id
          )
        )
    )
  );

-- Catálogo público: se ejecuta con los permisos del propietario (ya no hay
-- política pública en `units`) y enmascara los secretos.
CREATE OR REPLACE VIEW public.units_with_full_address AS
 SELECT id,
    property_id,
    name,
    unit_type,
    box_location_text,
    CASE WHEN public.can_view_unit_secrets(id) THEN box_code END AS box_code,
    locker_number,
    access_instructions,
    welcome_instructions,
    wifi_network,
    CASE WHEN public.can_view_unit_secrets(id) THEN wifi_password END AS wifi_password,
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

ALTER VIEW public.units_with_full_address SET (security_invoker = off);

-- 6. RPCs con el nuevo límite -----------------------------------------------
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

    IF v_booking.status = 'cancelled' OR v_booking.booking_status = 'cancelled' THEN
        RAISE EXCEPTION 'code_expired:booking_cancelled';
    END IF;

    IF v_booking.status IS NOT NULL
       AND v_booking.status NOT IN ('confirmed', 'checked_in') THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF v_booking.booking_status = 'closed' THEN
        RAISE EXCEPTION 'code_expired:stay_finished';
    END IF;

    IF v_booking.checkout_date IS NOT NULL
       AND now() >= public.booking_access_ends_at(v_booking.property_id, v_booking.checkout_date) THEN
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
  -- ensure booking exists and belongs to caller
  select * into b from public.bookings where id = p_booking_id;
  if not found then
    raise exception 'booking_not_found';
  end if;

  if b.primary_guest_user_id <> auth.uid() and not public.is_staff() then
    raise exception 'not_allowed';
  end if;

  -- check dates: from checkin_date until the property's checkout time
  if current_date < b.checkin_date
     or now() >= public.booking_access_ends_at(b.property_id, b.checkout_date) then
    raise exception 'outside_access_window';
  end if;

  -- check checkin validated
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

-- 7. Cierre retroactivo -----------------------------------------------------
--    · Salidas ya marcadas (323 reservas): silencioso.
--    · Estancias abiertas pasada la hora de salida: cierre normal con push.
SELECT public.auto_close_finished_bookings();
