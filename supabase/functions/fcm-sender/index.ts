// Función retirada el 2026-10-19.
// Sin uso y sin autenticación; usaba la API Legacy de FCM y podía vaciar la cola.
// La cola la procesa send-fcm-notifications.
// Copia de la versión anterior: supabase/functions/_retired/fcm-sender/index.ts

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve((req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  return new Response(
    JSON.stringify({ error: 'gone', message: 'Esta función se ha retirado' }),
    { status: 410, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
  );
});
