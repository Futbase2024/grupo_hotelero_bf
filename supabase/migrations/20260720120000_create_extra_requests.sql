-- ============================================================================
-- Solicitudes de Extras (Pack Romántico y futuros extras)
-- ----------------------------------------------------------------------------
-- El huésped puede "Reservar" un extra (p. ej. Pack Romántico) desde la app,
-- pero el pago se realiza en una web externa y NO podemos confirmar si se
-- completa. Por eso esto NO es una reserva/pedido confirmado, sino una
-- SOLICITUD de interés que el admin gestiona manualmente (seguimiento).
--
-- Estados: 'requested' (solicitado) -> 'managed' (gestionado) | 'cancelled'.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.extra_requests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   uuid NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  property_id  uuid REFERENCES public.properties(id) ON DELETE SET NULL,
  user_id      uuid,
  guest_name   text,
  unit_name    text,
  extra_type   text NOT NULL,
  extra_name   text NOT NULL,
  price        numeric,
  status       text NOT NULL DEFAULT 'requested'
                 CHECK (status IN ('requested', 'managed', 'cancelled')),
  notes        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  managed_at   timestamptz,
  managed_by   uuid
);

CREATE INDEX IF NOT EXISTS idx_extra_requests_booking
  ON public.extra_requests (booking_id);
CREATE INDEX IF NOT EXISTS idx_extra_requests_property_status
  ON public.extra_requests (property_id, status);
CREATE INDEX IF NOT EXISTS idx_extra_requests_created
  ON public.extra_requests (created_at DESC);

-- ── RLS (mismo patrón que public.checkins) ──────────────────────────────────
ALTER TABLE public.extra_requests ENABLE ROW LEVEL SECURITY;

-- El huésped crea solicitudes de SU reserva (y a su propio nombre).
CREATE POLICY extra_requests_guest_insert_own
  ON public.extra_requests
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = extra_requests.booking_id
        AND b.primary_guest_user_id = (SELECT auth.uid())
    )
  );

-- El huésped ve las solicitudes de su reserva.
CREATE POLICY extra_requests_guest_select_own
  ON public.extra_requests
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.bookings b
      WHERE b.id = extra_requests.booking_id
        AND b.primary_guest_user_id = (SELECT auth.uid())
    )
  );

-- El staff/admin gestiona las solicitudes de su propiedad (admin global: todas).
CREATE POLICY extra_requests_staff_all
  ON public.extra_requests
  FOR ALL
  USING (
    is_staff() AND (
      is_admin() OR property_id = current_property_id()
    )
  )
  WITH CHECK (
    is_staff() AND (
      is_admin() OR property_id = current_property_id()
    )
  );

-- ── Realtime (refresco en vivo del listado admin) ───────────────────────────
ALTER TABLE public.extra_requests REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'extra_requests'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.extra_requests;
  END IF;
END $$;
