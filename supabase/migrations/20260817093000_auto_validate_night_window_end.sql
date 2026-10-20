-- ============================================================================
-- Auto-validación nocturna: cerrar la ventana a las 09:00
-- ----------------------------------------------------------------------------
-- Cambio sobre 20260817085000_auto_validate_late_night_checkins.sql:
-- la ventana pasa de "23:00 en adelante, sin límite" a la franja cerrada
-- **23:00 del día de entrada → 09:00 del día siguiente** (hora local de la
-- propiedad).
--
-- Motivo: sin límite superior, un check-in completado tarde a mitad de una
-- estancia larga también se autovalidaba (reserva del 16 al 20, check-in
-- enviado el 18 a mediodía). La franja nocturna cubre las llegadas fuera del
-- horario de recepción, que es el caso real que motivó la regla.
--
-- Ejemplo (reserva 16 → 17):
--   16 ago 22:59  → manual (hasta el barrido de las 23:00)
--   16 ago 23:30  → AUTO
--   17 ago 01:17  → AUTO   ← caso que originó la regla
--   17 ago 08:59  → AUTO
--   17 ago 09:00  → manual (ya hay recepción)
--
-- El interruptor `bookings.auto_validate_checkin` NO se ve afectado: sigue
-- autovalidando a cualquier hora.
-- ============================================================================

-- ── 1. Hora de cierre de la ventana ─────────────────────────────────────────
-- Espejo de `CheckinPolicy.autoValidateUntilHour` en Dart.
CREATE OR REPLACE FUNCTION public.checkin_auto_validate_window_end()
RETURNS time
LANGUAGE sql
IMMUTABLE
SET search_path TO 'public'
AS $function$ SELECT TIME '09:00' $function$;

COMMENT ON FUNCTION public.checkin_auto_validate_window_end() IS
  'Hora (local de la propiedad) del día siguiente a la entrada en la que se cierra la ventana de auto-validación nocturna.';

-- ── 2. Ventana cerrada 23:00 → 09:00 del día siguiente ──────────────────────
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
