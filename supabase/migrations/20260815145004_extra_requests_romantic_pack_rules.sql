-- ============================================================================
-- Pack Romántico: una sola solicitud por reserva y plazo de 24 h
-- ----------------------------------------------------------------------------
-- Reglas de negocio:
--   1. El huésped NO puede solicitar el Pack Romántico más de una vez por
--      reserva. Una solicitud cancelada libera el bloqueo.
--   2. La solicitud debe hacerse al menos 24 h antes de la entrada. Se toma
--      como hora de entrada las 14:00 del día de `bookings.checkin_date`
--      (misma hora que usa la app para llaves/códigos), en la zona horaria de
--      la propiedad (fallback 'Europe/Madrid').
--
-- Ambas reglas se aplican SOLO a `extra_type = 'romantic_pack'` para no atar
-- futuros extras a esta política.
-- ============================================================================

-- ── 1. Limpieza de duplicados existentes ────────────────────────────────────
-- Se conserva una solicitud por reserva: la gestionada si existe y, si no, la
-- más antigua. Las canceladas no cuentan y no se tocan.
WITH ranked AS (
  SELECT id,
         row_number() OVER (
           PARTITION BY booking_id
           ORDER BY (status = 'managed') DESC, created_at ASC
         ) AS rn
  FROM public.extra_requests
  WHERE extra_type = 'romantic_pack'
    AND status <> 'cancelled'
)
DELETE FROM public.extra_requests er
USING ranked r
WHERE er.id = r.id
  AND r.rn > 1;

-- ── 2. Índice único: una solicitud activa por reserva ───────────────────────
CREATE UNIQUE INDEX IF NOT EXISTS uq_extra_requests_romantic_pack_per_booking
  ON public.extra_requests (booking_id)
  WHERE extra_type = 'romantic_pack' AND status <> 'cancelled';

-- ── 3. Ventana de 24 h antes de la entrada ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.extra_requests_check_request_window()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_deadline timestamptz;
BEGIN
  -- Solo aplica al Pack Romántico.
  IF NEW.extra_type IS DISTINCT FROM 'romantic_pack' THEN
    RETURN NEW;
  END IF;

  -- El staff puede registrar solicitudes manualmente fuera de plazo.
  IF public.is_staff() THEN
    RETURN NEW;
  END IF;

  SELECT (b.checkin_date + time '14:00')
           AT TIME ZONE coalesce(nullif(p.timezone, ''), 'Europe/Madrid')
         - interval '24 hours'
    INTO v_deadline
  FROM public.bookings b
  LEFT JOIN public.properties p ON p.id = b.property_id
  WHERE b.id = NEW.booking_id;

  -- Sin reserva/fecha localizable no bloqueamos (el insert ya fallaría por FK).
  IF v_deadline IS NULL THEN
    RETURN NEW;
  END IF;

  IF now() > v_deadline THEN
    RAISE EXCEPTION 'ROMANTIC_PACK_WINDOW_CLOSED'
      USING ERRCODE = 'P0001',
            HINT = 'El Pack Romántico debe solicitarse al menos 24 h antes de la entrada.';
  END IF;

  RETURN NEW;
END;
$$;

-- Nadie necesita ejecutarla directamente: solo se dispara desde el trigger.
REVOKE ALL ON FUNCTION public.extra_requests_check_request_window() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.extra_requests_check_request_window() FROM anon;
REVOKE ALL ON FUNCTION public.extra_requests_check_request_window() FROM authenticated;

DROP TRIGGER IF EXISTS trg_extra_requests_check_request_window
  ON public.extra_requests;

CREATE TRIGGER trg_extra_requests_check_request_window
  BEFORE INSERT ON public.extra_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.extra_requests_check_request_window();
