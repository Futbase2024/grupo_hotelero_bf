-- ============================================================================
-- Archivos huérfanos del bucket guest-documents
-- ----------------------------------------------------------------------------
-- Fotos de documentos sin fila en guest_documents (subidas cuyo insert falló,
-- borrados de fila cuyo archivo no llegó a eliminarse…). Ninguna regla de
-- borrado las alcanzaba. La Edge Function cleanup-documents las elimina en
-- cada pasada, con 24 h de margen para no tocar subidas en curso y sin tocar
-- las carpetas de reservas retenidas.
--
-- Rollback: 20261115100200_guest_documents_orphan_files.ROLLBACK.sql
-- ============================================================================

CREATE OR REPLACE FUNCTION public.guest_documents_orphan_files(p_limit INTEGER DEFAULT 500)
 RETURNS TABLE (name TEXT)
 LANGUAGE sql
 STABLE
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT o.name
  FROM storage.objects o
  WHERE o.bucket_id = 'guest-documents'
    AND o.created_at < now() - INTERVAL '24 hours'
    AND NOT EXISTS (
      SELECT 1 FROM public.guest_documents d WHERE d.storage_path = o.name
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.booking_document_retentions r
      WHERE o.name LIKE 'guests/' || r.booking_id::text || '/%'
    )
  ORDER BY o.created_at
  LIMIT GREATEST(1, LEAST(p_limit, 1000));
$function$;

REVOKE EXECUTE ON FUNCTION public.guest_documents_orphan_files(INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.guest_documents_orphan_files(INTEGER) TO service_role;
