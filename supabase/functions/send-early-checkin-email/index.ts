import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// Email verificado en Brevo
const VERIFIED_SENDER_EMAIL = 'ghotelerobf@gmail.com';

// Defaults para el template
const DEFAULTS = {
  hero_image_url: 'https://qwepisgdqlmqfxwqkztz.supabase.co/storage/v1/object/public/email-assets/heroimagen.png',
  link_ios: 'https://apps.apple.com/es/app/bf-stay/id6759832221',
  link_android: 'https://bf-stay.pages.dev/',
  telefono_1: '+34 656 61 80 65',
  telefono_2: '+34 674 27 70 16',
};

interface EmailRequest {
  to_email: string;
  to_name: string;
  params: {
    nombre_huesped?: string;
    nombre_propiedad?: string;
    fecha_entrada?: string;
    fecha_salida?: string;
    hora_original?: string;
    hero_image_url?: string;
    link_abrir_app?: string;
    link_ios?: string;
    link_android?: string;
    telefono_1?: string;
    telefono_2?: string;
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

  try {
    const body: EmailRequest = await req.json();
    console.log('[send-early-checkin-email] Received request:', JSON.stringify(body, null, 2));

    // Validar campos requeridos
    if (!body.to_email) {
      throw new Error('to_email is required');
    }

    // Template ID 15 = Early Check-in Available (crear en Brevo si no existe)
    const templateId = 15;

    // Preparar parámetros con defaults
    const params = {
      nombre_huesped: body.params?.nombre_huesped || 'Huésped',
      nombre_propiedad: body.params?.nombre_propiedad || 'Propiedad',
      fecha_entrada: body.params?.fecha_entrada || '',
      fecha_salida: body.params?.fecha_salida || '',
      hora_original: body.params?.hora_original || '14:00',
      // Imagen hero
      hero_image_url: body.params?.hero_image_url || DEFAULTS.hero_image_url,
      // Links de la app
      link_abrir_app: body.params?.link_abrir_app || 'https://bf-stay.pages.dev/',
      link_ios: body.params?.link_ios || DEFAULTS.link_ios,
      link_android: body.params?.link_android || DEFAULTS.link_android,
      // Teléfonos de soporte
      telefono_1: body.params?.telefono_1 || DEFAULTS.telefono_1,
      telefono_2: body.params?.telefono_2 || DEFAULTS.telefono_2,
    };

    console.log('[send-early-checkin-email] Using template ID:', templateId);
    console.log('[send-early-checkin-email] Params:', JSON.stringify(params, null, 2));

    // Construir payload para Brevo
    const brevoPayload = {
      sender: {
        name: 'BF Stay',
        email: VERIFIED_SENDER_EMAIL,
      },
      to: [
        {
          email: body.to_email,
          name: body.to_name || body.params?.nombre_huesped || 'Huésped',
        },
      ],
      templateId: templateId,
      params: params,
    };

    console.log('[send-early-checkin-email] Sending to Brevo...');

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
    console.log('[send-early-checkin-email] Brevo response status:', response.status);
    console.log('[send-early-checkin-email] Brevo response:', responseText);

    if (!response.ok) {
      throw new Error(`Brevo API error: ${response.status} - ${responseText}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Early check-in email sent successfully',
        templateId: templateId,
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
    console.error('[send-early-checkin-email] Error:', error);
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
