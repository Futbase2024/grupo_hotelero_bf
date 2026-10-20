// ============================================================================
// COPIA DE SEGURIDAD — versión 12 desplegada de la Edge Function `invoke-send-fcm`
// Retirada el 2026-10-19: stub vacío sin uso, desplegado sin autenticación.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// Delete this function
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  return new Response(JSON.stringify({ deleted: true }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
})
