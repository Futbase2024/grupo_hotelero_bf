// Supabase Edge Function: cleanup-documents
// Elimina documentos expirados del bucket y la base de datos
// Se ejecuta automáticamente cada día a las 3:00 AM (configurar en Supabase Dashboard)

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const supabaseUrl = Deno.env.get('SUPABASE_URL')!
const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface CleanupResult {
  deleted_count: number
  error_count: number
  details: Array<{
    id: string
    path: string
    status: 'deleted' | 'error'
    error?: string
  }>
}

Deno.serve(async (req: Request) => {
  // Verificar autorización (opcional: proteger con secret)
  const authHeader = req.headers.get('Authorization')
  const expectedAuth = Deno.env.get('CLEANUP_SECRET')

  // Si hay secret configurado, verificarlo
  if (expectedAuth && authHeader !== `Bearer ${expectedAuth}`) {
    // También permitir llamadas internas de Supabase (sin auth)
    const userAgent = req.headers.get('User-Agent') || ''
    if (!userAgent.includes('Supabase')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        { status: 401, headers: { 'Content-Type': 'application/json' } }
      )
    }
  }

  console.log('🧹 [cleanup-documents] Iniciando limpieza de documentos expirados...')
  console.log(`📅 [cleanup-documents] Fecha: ${new Date().toISOString()}`)

  const supabase = createClient(supabaseUrl, supabaseServiceKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  })

  const result: CleanupResult = {
    deleted_count: 0,
    error_count: 0,
    details: [],
  }

  try {
    // 1. Buscar documentos expirados
    const { data: expiredDocs, error: fetchError } = await supabase
      .from('guest_documents')
      .select('id, storage_path, guest_id, doc_kind, expires_at')
      .lt('expires_at', new Date().toISOString())

    if (fetchError) {
      console.error('❌ [cleanup-documents] Error al buscar documentos:', fetchError)
      throw fetchError
    }

    if (!expiredDocs || expiredDocs.length === 0) {
      console.log('✅ [cleanup-documents] No hay documentos expirados')
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No hay documentos expirados',
          ...result,
        }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log(`📋 [cleanup-documents] Encontrados ${expiredDocs.length} documentos expirados`)

    // 2. Eliminar cada documento
    for (const doc of expiredDocs) {
      try {
        console.log(`🗑️ [cleanup-documents] Eliminando: ${doc.storage_path}`)

        // Eliminar archivo del bucket
        const { error: storageError } = await supabase.storage
          .from('guest-documents')
          .remove([doc.storage_path])

        if (storageError) {
          console.warn(`⚠️ [cleanup-documents] Error al eliminar archivo: ${storageError.message}`)
          // Continuar aunque falle la eliminación del archivo
        }

        // Eliminar registro de la base de datos
        const { error: dbError } = await supabase
          .from('guest_documents')
          .delete()
          .eq('id', doc.id)

        if (dbError) {
          throw dbError
        }

        result.deleted_count++
        result.details.push({
          id: doc.id,
          path: doc.storage_path,
          status: 'deleted',
        })

        console.log(`✅ [cleanup-documents] Documento eliminado: ${doc.id}`)
      } catch (error) {
        const errorMessage = error instanceof Error ? error.message : String(error)
        console.error(`❌ [cleanup-documents] Error al eliminar documento ${doc.id}:`, errorMessage)

        result.error_count++
        result.details.push({
          id: doc.id,
          path: doc.storage_path,
          status: 'error',
          error: errorMessage,
        })
      }
    }

    console.log(`🎉 [cleanup-documents] Limpieza completada: ${result.deleted_count} eliminados, ${result.error_count} errores`)

    return new Response(
      JSON.stringify({
        success: true,
        timestamp: new Date().toISOString(),
        ...result,
      }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error)
    console.error('❌ [cleanup-documents] Error general:', errorMessage)

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        timestamp: new Date().toISOString(),
        ...result,
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
