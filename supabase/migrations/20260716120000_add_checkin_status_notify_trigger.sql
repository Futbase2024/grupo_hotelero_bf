-- ============================================================================
-- Notificación automática al huésped cuando cambia el estado de su check-in
-- ----------------------------------------------------------------------------
-- Problema: al validar/rechazar un check-in el huésped no recibía notificación
-- porque la notificación dependía del cliente Flutter y solo se disparaba desde
-- una de las dos pantallas del admin (checkin_detail_screen, NO desde
-- booking_detail_screen). No existía ningún trigger en la tabla `checkins`.
--
-- Solución: trigger en `checkins` (fuente única de verdad) que, ante un cambio
-- de `status` a 'validated' o 'rejected', crea la notificación in-app en
-- `guest_notifications` y dispara el push FCM vía notify_fcm() -> send-fcm.
--
-- La cancelación (status='cancelled' + bookings.status='cancelled') ya está
-- cubierta por el trigger existente trg_booking_status_notify, por eso este
-- trigger no la maneja.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trg_checkin_status_notify()
  RETURNS trigger
  LANGUAGE plpgsql
  SECURITY DEFINER
  SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_type    TEXT;
  v_title   TEXT;
  v_body    TEXT;
BEGIN
  -- Solo actuar si el status cambió realmente
  IF NEW.status IS NOT DISTINCT FROM OLD.status THEN
    RETURN NEW;
  END IF;

  -- Resolver el usuario huésped a partir de la reserva
  SELECT primary_guest_user_id
  INTO v_user_id
  FROM public.bookings
  WHERE id = NEW.booking_id;

  IF v_user_id IS NULL THEN
    RETURN NEW;  -- reserva sin huésped registrado (reserva externa)
  END IF;

  CASE NEW.status
    WHEN 'validated' THEN
      v_type  := 'checkin_validated';
      v_title := '✅ Check-in validado';
      v_body  := 'Tu check-in ha sido validado correctamente. ¡Bienvenido!';
    WHEN 'rejected' THEN
      v_type  := 'checkin_rejected';
      v_title := '❌ Check-in rechazado';
      v_body  := COALESCE(
        NEW.rejection_reason,
        'Tu check-in ha sido rechazado. Por favor, revisa tu documentación.'
      );
    ELSE
      RETURN NEW;  -- otros estados (draft/submitted/cancelled) no notifican aquí
  END CASE;

  -- 1) Notificación in-app (aparece en el home del huésped)
  INSERT INTO public.guest_notifications (
    user_id, booking_id, type, title, body, data, is_read
  ) VALUES (
    v_user_id,
    NEW.booking_id,
    v_type,
    v_title,
    v_body,
    jsonb_build_object('status', NEW.status),
    false
  );

  -- 2) Push FCM a todos los dispositivos del huésped
  PERFORM public.notify_fcm(jsonb_build_object(
    'user_id',    v_user_id,
    'booking_id', NEW.booking_id,
    'type',       'checkin_status',
    'title',      v_title,
    'body',       v_body,
    'data',       jsonb_build_object(
      'type',           'checkin_status',
      'booking_id',     NEW.booking_id::TEXT,
      'checkin_status', NEW.status,
      'url',            '/booking/' || NEW.booking_id::TEXT || '/checkin'
    )
  ));

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_checkin_status_notify ON public.checkins;

CREATE TRIGGER trg_checkin_status_notify
  AFTER UPDATE ON public.checkins
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_checkin_status_notify();

-- ============================================================================
-- Habilitar Realtime en `checkins` para el refresco instantáneo del huésped
-- ----------------------------------------------------------------------------
-- El cliente (watchCheckinStatus) se suscribe con .from('checkins').stream(),
-- pero la tabla NO estaba incluida en la publicación supabase_realtime, por lo
-- que el stream nunca emitía cambios. Se añade la tabla y se pone REPLICA
-- IDENTITY FULL para que RLS pueda evaluarse correctamente sobre los UPDATE.
-- ============================================================================

ALTER TABLE public.checkins REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'checkins'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.checkins;
  END IF;
END $$;
