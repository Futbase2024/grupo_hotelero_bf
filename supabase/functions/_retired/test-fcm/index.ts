// ============================================================================
// COPIA DE SEGURIDAD — versión 13 desplegada de la Edge Function `test-fcm`
// Retirada el 2026-10-19: stub vacío sin uso, desplegado sin autenticación.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
// Cleanup function
import "jsr:@supabase/functions-js/edge-runtime.d.ts"

Deno.serve(async (req) => {
  return new Response(JSON.stringify({ status: 'ok' }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' }
  })
})
