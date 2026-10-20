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

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// Remitente sobre dominio autenticado en Brevo (grupohotelerobf.com)
const VERIFIED_SENDER_EMAIL = 'reservas@grupohotelerobf.com';
// Buzon del gestor: recibe respuestas y copia oculta de cada envio
const MANAGER_EMAIL = 'ghotelerobf@gmail.com';

// Imagen hero por defecto
const DEFAULT_HERO_IMAGE = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=640&h=300&fit=crop';

interface EmailRequest {
  to_email: string;
  to_name: string;
  params: {
    nombre_huesped?: string;
    nombre_propiedad?: string;
    fecha_entrada?: string;
    fecha_salida?: string;
    codigo_acceso?: string;
    hero_image_url?: string;
    link_abrir_app?: string;
    link_ios?: string;
    link_android?: string;
    telefono_1?: string;
    telefono_2?: string;
    num_huespedes?: string;
    precio_total?: string;
  };
  booking_id?: string;
  unit_id?: string;
}

Deno.serve(async (req: Request) => {
  // CORS handling
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    });
  }

  const denied = await requireStaff(req);
  if (denied) return denied;

  try {
    const body: EmailRequest = await req.json();
    console.log('[send-new-booking-email] Received request:', JSON.stringify(body, null, 2));

    // Validar campos requeridos
    if (!body.to_email) {
      throw new Error('to_email is required');
    }

    // Template ID 2 = Nueva Reserva
    const templateId = 2;

    // Preparar parametros con defaults
    const params = {
      nombre_huesped: body.params?.nombre_huesped || 'Huesped',
      nombre_propiedad: body.params?.nombre_propiedad || 'Propiedad',
      fecha_entrada: body.params?.fecha_entrada || '',
      fecha_salida: body.params?.fecha_salida || '',
      codigo_acceso: body.params?.codigo_acceso || '',
      hero_image_url:
        "https://qwepisgdqlmqfxwqkztz.supabase.co/storage/v1/object/public/email-assets/heroimagen.png",
      link_ios: "https://apps.apple.com/es/app/bf-stay/id6759832221",
      link_android: body.params?.link_android || 'https://play.google.com/store/apps/details?id=com.bfstay.app&pli=1',
      telefono_1: "+34 656 61 80 65",
      telefono_2: "+34 674 27 70 16",
      num_huespedes: body.params?.num_huespedes || '1',
      precio_total: body.params?.precio_total || 'Confirmar con el establecimiento',
    };

    console.log('[send-new-booking-email] Using template ID:', templateId);
    console.log('[send-new-booking-email] Sender:', VERIFIED_SENDER_EMAIL);

    // Construir payload para Brevo
    const brevoPayload = {
      sender: {
        name: 'BF Stay',
        email: VERIFIED_SENDER_EMAIL,
      },
      to: [
        {
          email: body.to_email,
          name: body.to_name || body.params?.nombre_huesped || 'Huesped',
        },
      ],
      replyTo: {
        name: 'BF Stay',
        email: MANAGER_EMAIL,
      },
      bcc: [
        {
          email: MANAGER_EMAIL,
          name: 'BF Stay',
        },
      ],
      templateId: templateId,
      params: params,
    };

    console.log('[send-new-booking-email] Sending to Brevo...');

    const response = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'api-key': BREVO_API_KEY,
      },
      body: JSON.stringify(brevoPayload),
    });

    const responseText = await response.text();
    console.log('[send-new-booking-email] Brevo response status:', response.status);
    console.log('[send-new-booking-email] Brevo response:', responseText);

    if (!response.ok) {
      throw new Error(`Brevo API error: ${response.status} - ${responseText}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Email sent successfully',
        templateId: templateId,
        sender: VERIFIED_SENDER_EMAIL,
        messageId: JSON.parse(responseText).messageId,
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  } catch (error) {
    console.error('[send-new-booking-email] Error:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    );
  }
});
