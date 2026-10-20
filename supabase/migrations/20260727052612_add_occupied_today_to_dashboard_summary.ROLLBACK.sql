-- Rollback de 20260727120000_add_occupied_today_to_dashboard_summary.sql
-- Restaura get_dashboard_summary sin `occupied_today` y elimina el índice.
--
-- ⚠️ Requiere desplegar también una versión del cliente que no dependa de
-- `occupied_today` (el KPI de ocupación mostraría 0%).

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
  v_recent_checkins jsonb;
BEGIN
  SELECT COUNT(*) INTO v_pending_checkins
  FROM checkins c
  JOIN bookings b ON b.id = c.booking_id
  WHERE (p_property_id IS NULL OR b.property_id = p_property_id)
    AND c.status IN ('draft', 'submitted');

  SELECT COUNT(*) INTO v_upcoming_checkins
  FROM bookings
  WHERE (p_property_id IS NULL OR property_id = p_property_id)
    AND checkin_date >= CURRENT_DATE
    AND checkin_date <= CURRENT_DATE + INTERVAL '7 days'
    AND status NOT IN ('cancelled', 'closed');

  SELECT COUNT(*) INTO v_total_units
  FROM units
  WHERE (p_property_id IS NULL OR property_id = p_property_id);

  SELECT COUNT(*) INTO v_unread_notifications
  FROM staff_notifications
  WHERE (p_property_id IS NULL OR property_id = p_property_id)
    AND is_read = false;

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

  RETURN jsonb_build_object(
    'pending_checkins', v_pending_checkins,
    'upcoming_checkins', v_upcoming_checkins,
    'unread_notifications', v_unread_notifications,
    'total_units', v_total_units,
    'recent_checkins', COALESCE(v_recent_checkins, '[]'::jsonb)
  );
END;
$function$;

DROP INDEX IF EXISTS public.idx_bookings_checkout_date;
