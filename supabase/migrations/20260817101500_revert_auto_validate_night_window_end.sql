-- ============================================================================
-- Revertir el cierre de la ventana a las 09:00
-- ----------------------------------------------------------------------------
-- Se vuelve a la regla original: **a partir de las 23:00 (hora local de la
-- propiedad) del día de entrada, sin límite superior**.
--
-- Contexto: en 20260817093000 se cerró la franja a las 09:00 para que en
-- estancias largas no se autovalidaran check-ins completados a mitad de
-- estancia. Revisado el caso, se prefiere la regla abierta: el check-in se hace
-- una sola vez, a la llegada, y así ningún check-in tardío se queda esperando
-- revisión manual.
--
-- Ejemplo (reserva 16 → 20):
--   16 ago 22:59  → manual (hasta el barrido de las 23:00)
--   16 ago 23:00  → AUTO
--   17 ago 01:17  → AUTO
--   17 ago 09:00  → AUTO   ← con la franja cerrada era manual
--   18 ago 12:00  → AUTO   ← con la franja cerrada era manual
--
-- El interruptor `bookings.auto_validate_checkin` no se ve afectado.
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
