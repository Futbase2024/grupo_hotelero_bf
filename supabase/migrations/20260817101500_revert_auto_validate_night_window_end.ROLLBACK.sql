-- ============================================================================
-- ROLLBACK: volver a cerrar la ventana de auto-validación a las 09:00
-- ----------------------------------------------------------------------------
-- Restaura el estado de 20260817093000_auto_validate_night_window_end.sql:
-- franja cerrada 23:00 del día de entrada → 09:00 del día siguiente.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.checkin_auto_validate_window_end()
RETURNS time
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $function$ SELECT TIME '09:00' $function$;

COMMENT ON FUNCTION public.checkin_auto_validate_window_end() IS
  'Hora (local de la propiedad) del día siguiente a la entrada en la que se cierra la ventana de auto-validación nocturna.';

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
           >= (p_checkin_date + public.checkin_auto_validate_cutoff())
     AND (p_at AT TIME ZONE COALESCE(NULLIF(p_timezone, ''), 'Europe/Madrid'))
           <  (p_checkin_date + 1 + public.checkin_auto_validate_window_end());
$function$;

COMMENT ON FUNCTION public.is_late_checkin_window(date, text, timestamptz) IS
  'TRUE dentro de la franja nocturna de la reserva: 23:00 del día de entrada → 09:00 del día siguiente (hora local de la propiedad).';
