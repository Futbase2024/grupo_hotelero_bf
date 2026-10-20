-- Añade `occupied_today` a get_dashboard_summary.
--
-- Motivo: el KPI de ocupación del panel de admin se calculaba en el cliente
-- recorriendo TODAS las reservas de los últimos 90 días (~530 filas, ~550 kB de
-- JSON) que se descargaban en el arranque solo para eso. Moviendo el cálculo al
-- RPC, la carga inicial del dashboard deja de necesitar la lista de reservas.
--
-- Semántica: unidades DISTINTAS ocupadas hoy (una reserva de 3 habitaciones
-- cuenta 3), coherente con dividir entre `total_units`. Se usa `booking_units`
-- y, si la reserva no tiene filas ahí, la unidad principal de `bookings`.
--
-- Nota: en el proyecto remoto quedó registrada además la migración
-- `20260727052634_fix_dashboard_summary_guest_fallback_accent`, un reintento del
-- mismo CREATE OR REPLACE. El estado final coincide con este archivo.

CREATE OR REPLACE FUNCTION public.get_dashboard_summary(p_property_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
  v_pending_checkins integer;
  v_upcoming_checkins integer;
  v_total_units integer;
  v_unread_notifications integer;
  v_occupied_today integer;
  v_recent_checkins jsonb;
BEGIN
  -- 1. Contar check-ins pendientes (status: draft o submitted)
  SELECT COUNT(*) INTO v_pending_checkins
  FROM checkins c
  JOIN bookings b ON b.id = c.booking_id
  WHERE (p_property_id IS NULL OR b.property_id = p_property_id)
    AND c.status IN ('draft', 'submitted');

  -- 2. Contar llegadas próximas (check-in en los próximos 7 días)
  SELECT COUNT(*) INTO v_upcoming_checkins
  FROM bookings
  WHERE (p_property_id IS NULL OR property_id = p_property_id)
    AND checkin_date >= CURRENT_DATE
    AND checkin_date <= CURRENT_DATE + INTERVAL '7 days'
    AND status NOT IN ('cancelled', 'closed');

  -- 3. Contar unidades activas
  SELECT COUNT(*) INTO v_total_units
  FROM units
  WHERE (p_property_id IS NULL OR property_id = p_property_id);

  -- 4. Contar notificaciones no leídas
  SELECT COUNT(*) INTO v_unread_notifications
  FROM staff_notifications
  WHERE (p_property_id IS NULL OR property_id = p_property_id)
    AND is_read = false;

  -- 5. Unidades ocupadas hoy (estancia en curso: entró hoy o antes y aún no
  --    ha salido). Antes se calculaba en el cliente.
  SELECT COUNT(DISTINCT unit_id) INTO v_occupied_today
  FROM (
    SELECT COALESCE(bu.unit_id, b.unit_id) AS unit_id
    FROM bookings b
    LEFT JOIN booking_units bu ON bu.booking_id = b.id
    WHERE (p_property_id IS NULL OR b.property_id = p_property_id)
      AND b.status <> 'cancelled'
      AND b.checkin_date <= CURRENT_DATE
      AND b.checkout_date > CURRENT_DATE
  ) occupied
  WHERE unit_id IS NOT NULL;

  -- 6. Obtener últimos 5 check-ins con información completa
  -- Ahora incluye TODAS las unidades de la reserva (booking_units)
  SELECT jsonb_agg(
    jsonb_build_object(
      'booking_id', sub.booking_id,
      'booking_code', sub.booking_code,
      'guest_name', sub.guest_name,
      'unit_name', sub.unit_name,
      'checkin_status', sub.checkin_status,
      'submitted_at', sub.submitted_at
    )
  ) INTO v_recent_checkins
  FROM (
    SELECT
      b.id as booking_id,
      b.booking_code,
      COALESCE(b.guest_first_name || ' ' || b.last_name, 'Huésped') as guest_name,
      -- Agregar todas las unidades de la reserva, no solo una
      COALESCE(
        (
          SELECT string_agg(u2.name, ', ' ORDER BY u2.name)
          FROM booking_units bu
          JOIN units u2 ON u2.id = bu.unit_id
          WHERE bu.booking_id = b.id
        ),
        u.name,
        ''
      ) as unit_name,
      c.status as checkin_status,
      c.submitted_at
    FROM checkins c
    JOIN bookings b ON b.id = c.booking_id
    LEFT JOIN units u ON u.id = b.unit_id
    WHERE (p_property_id IS NULL OR b.property_id = p_property_id)
      AND c.submitted_at IS NOT NULL
    ORDER BY c.submitted_at DESC
    LIMIT 5
  ) sub;

  -- Retornar resultado
  RETURN jsonb_build_object(
    'pending_checkins', v_pending_checkins,
    'upcoming_checkins', v_upcoming_checkins,
    'unread_notifications', v_unread_notifications,
    'total_units', v_total_units,
    'occupied_today', v_occupied_today,
    'recent_checkins', COALESCE(v_recent_checkins, '[]'::jsonb)
  );
END;
$function$;

-- Índice de apoyo para el cálculo de ocupación y las llegadas próximas.
CREATE INDEX IF NOT EXISTS idx_bookings_checkout_date
  ON public.bookings (checkout_date);
