-- ============================================================================
-- ROLLBACK: cerrar la ventana de auto-validación nocturna a las 09:00
-- ----------------------------------------------------------------------------
-- Vuelve a "23:00 en adelante, sin límite superior" (estado tras la migración
-- 20260817085000_auto_validate_late_night_checkins.sql).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_late_checkin_window(
  p_checkin_date date,
  p_timezone     text        DEFAULT 'Europe/Madrid',
  p_at           timestamptz DEFAULT now()
)
RETURNS boolean
LANGUAGE sql
STABLE
SET search_path TO 'public'
AS $function$
  SELECT p_checkin_date IS NOT NULL
     AND (p_at AT TIME ZONE COALESCE(NULLIF(p_timezone, ''), 'Europe/Madrid'))
         >= (p_checkin_date + public.checkin_auto_validate_cutoff());
$function$;

COMMENT ON FUNCTION public.is_late_checkin_window(date, text, timestamptz) IS
  'TRUE si ya pasaron las 23:00 locales del día de entrada. Sin límite superior.';

DROP FUNCTION IF EXISTS public.checkin_auto_validate_window_end();
