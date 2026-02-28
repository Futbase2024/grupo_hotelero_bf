-- ============================================
-- Migración: Expiración automática de documentos
-- Fecha: 2026-02-28
-- Descripción: Los documentos expiran después de 1 año
-- ============================================

-- 1. Añadir columna expires_at a guest_documents
ALTER TABLE guest_documents
ADD COLUMN IF NOT EXISTS expires_at TIMESTAMPTZ;

-- 2. Crear función trigger para auto-calcular expires_at (1 año desde created_at)
CREATE OR REPLACE FUNCTION set_document_expires_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.expires_at := NEW.created_at + INTERVAL '1 year';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Crear el trigger
DROP TRIGGER IF EXISTS trg_set_document_expires_at ON guest_documents;
CREATE TRIGGER trg_set_document_expires_at
  BEFORE INSERT ON guest_documents
  FOR EACH ROW
  EXECUTE FUNCTION set_document_expires_at();

-- 4. Actualizar documentos existentes que no tengan expires_at
UPDATE guest_documents
SET expires_at = created_at + INTERVAL '1 year'
WHERE expires_at IS NULL;

-- ============================================
-- Función para limpiar documentos expirados
-- Llamar periódicamente desde n8n o webhook externo
-- ============================================
CREATE OR REPLACE FUNCTION cleanup_expired_documents()
RETURNS JSONB AS $$
DECLARE
  expired_docs RECORD;
  deleted_count INTEGER := 0;
  error_count INTEGER := 0;
  result JSONB := '[]'::JSONB;
BEGIN
  -- Buscar documentos expirados
  FOR expired_docs IN
    SELECT id, storage_path, guest_id, doc_kind
    FROM guest_documents
    WHERE expires_at < NOW()
  LOOP
    BEGIN
      -- Eliminar archivo del storage bucket
      DELETE FROM storage.objects
      WHERE bucket_id = 'guest-documents'
      AND name = expired_docs.storage_path;

      -- Eliminar registro de la tabla
      DELETE FROM guest_documents WHERE id = expired_docs.id;

      deleted_count := deleted_count + 1;

      result := result || jsonb_build_object(
        'id', expired_docs.id,
        'path', expired_docs.storage_path,
        'status', 'deleted'
      );

    EXCEPTION WHEN OTHERS THEN
      error_count := error_count + 1;
      result := result || jsonb_build_object(
        'id', expired_docs.id,
        'path', expired_docs.storage_path,
        'status', 'error',
        'error', SQLERRM
      );
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'deleted_count', deleted_count,
    'error_count', error_count,
    'details', result
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Función para obtener documentos próximos a expirar
-- Útil para enviar notificaciones
-- ============================================
CREATE OR REPLACE FUNCTION get_documents_expiring_soon(days_before INTEGER DEFAULT 7)
RETURNS TABLE (
  id UUID,
  storage_path TEXT,
  expires_at TIMESTAMPTZ,
  guest_id UUID,
  booking_id UUID,
  days_remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    gd.id,
    gd.storage_path,
    gd.expires_at,
    gd.guest_id,
    gd.booking_id,
    EXTRACT(DAY FROM (gd.expires_at - NOW()))::INTEGER as days_remaining
  FROM guest_documents gd
  WHERE gd.expires_at BETWEEN NOW() AND NOW() + (days_before || ' days')::INTERVAL
  ORDER BY gd.expires_at ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Comentario documentativo
-- ============================================
COMMENT ON FUNCTION cleanup_expired_documents() IS
'Elimina documentos expirados del bucket y la tabla. Ejecutar diariamente via n8n o webhook.';

COMMENT ON FUNCTION get_documents_expiring_soon(INTEGER) IS
'Retorna documentos que expiran en los próximos N días. Útil para notificaciones.';
