import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

// ── Autorización (2026-10-19) ─────────────────────────────────────────────────
// Antes cualquiera con la URL podía enviar este email a cualquier destinatario.
// Ahora solo: staff (JWT de un usuario admin/staff, p. ej. el panel de la app)
// o llamadas internas con la service role (p. ej. la Edge Function admin-panel).
async function requireStaff(req: Request): Promise<Response | null> {
  const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
  if (!token) return denyRequest(401, 'unauthorized');
  if (serviceKey && token === serviceKey) return null;

  const supabaseAdmin = createClient(Deno.env.get('SUPABASE_URL')!, serviceKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: { user } } = await supabaseAdmin.auth.getUser(token);
  if (!user) return denyRequest(401, 'unauthorized');

  const { data: roleData } = await supabaseAdmin
    .from('user_roles')
    .select('role')
    .eq('user_id', user.id)
    .maybeSingle();
  if (!roleData || !['admin', 'staff'].includes(roleData.role)) {
    return denyRequest(403, 'forbidden');
  }
  return null;
}

function denyRequest(status: number, error: string): Response {
  return new Response(JSON.stringify({ success: false, error }), {
    status,
    headers: { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' },
  });
}

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// Remitente sobre dominio autenticado en Brevo (grupohotelerobf.com)
const VERIFIED_SENDER_EMAIL = 'info@grupohotelerobf.com';
// Buzon del gestor: recibe respuestas y copia oculta de cada envio
const MANAGER_EMAIL = 'ghotelerobf@gmail.com';

// CORS headers
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const denied = await requireStaff(req);
  if (denied) return denied;

  try {
    const apiKey = Deno.env.get('BREVO_API_KEY');
    const templateId = parseInt(Deno.env.get('BREVO_TEMPLATE_CANCELLATION') || '2');

    if (!apiKey) {
      throw new Error('BREVO_API_KEY no configurada');
    }

    const body = await req.json();
    const { to_email, to_name, params, booking_id, unit_id } = body;

    console.log('Enviando email de cancelacion de check-in a:', to_email);
    console.log('Template ID:', templateId);

    const payload = {
      sender: {
        name: 'BF Stay',
        email: VERIFIED_SENDER_EMAIL
      },
      to: [{
        email: to_email,
        name: to_name || 'Huesped'
      }],
      replyTo: {
        name: 'BF Stay',
        email: MANAGER_EMAIL
      },
      bcc: [{
        email: MANAGER_EMAIL,
        name: 'BF Stay'
      }],
      templateId: templateId,
      params: params || {},
      tags: ['checkin', 'cancelacion'],
    };

    const response = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'api-key': apiKey
      },
      body: JSON.stringify(payload)
    });

    const responseData = await response.json();
    console.log('Respuesta de Brevo:', JSON.stringify(responseData, null, 2));

    if (!response.ok) {
      console.error('Error de Brevo:', responseData);
      throw new Error(`Error de Brevo: ${responseData.message || response.statusText}`);
    }

    console.log('Email de cancelacion enviado correctamente');

    return new Response(
      JSON.stringify({
        success: true,
        messageId: responseData.messageId,
        templateId: templateId
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    console.error('Error enviando email:', error);

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    );
  }
});
