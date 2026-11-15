-- ============================================================================
-- Activa el borrado automático de documentos de identidad
-- ----------------------------------------------------------------------------
-- ⚠️ IRREVERSIBLE: en cuanto se aplique, la primera pasada empieza a borrar
-- TODAS las imágenes que ya cumplen las reglas (también las antiguas: check-ins
-- validados hace más de 24 h, reservas canceladas y reservas ya terminadas).
-- Cada pasada procesa hasta 1000 documentos; el atraso se vacía en pocas horas.
--
-- Requiere:
--   · 20261115100000_guest_documents_privacy.sql aplicada
--   · Edge Function `cleanup-documents` desplegada con verify_jwt = false
--     (se autentica con la cabecera x-internal-secret)
--
-- Rollback: 20261115100100_schedule_guest_documents_cleanup.ROLLBACK.sql
-- ============================================================================

SELECT cron.unschedule(jobid)
  FROM cron.job
 WHERE jobname = 'cleanup-guest-documents';

SELECT cron.schedule(
  'cleanup-guest-documents',
  '*/15 * * * *',
  $cron$
  SELECT net.http_post(
    url     := 'https://qwepisgdqlmqfxwqkztz.supabase.co/functions/v1/cleanup-documents',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-internal-secret', public.internal_functions_secret()
    ),
    body    := '{}'::jsonb,
    timeout_milliseconds := 120000
  );
  $cron$
);
