-- Detiene el borrado automático de documentos (lo ya borrado no se recupera)
SELECT cron.unschedule(jobid)
  FROM cron.job
 WHERE jobname = 'cleanup-guest-documents';
