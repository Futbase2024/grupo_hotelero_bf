import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

// Remitente sobre dominio autenticado en Brevo (grupohotelerobf.com)
const VERIFIED_SENDER_EMAIL = 'info@grupohotelerobf.com';
// Buzon del gestor: recibe respuestas y copia oculta de cada envio
const MANAGER_EMAIL = 'ghotelerobf@gmail.com';

interface EmailRequest {
  to_email: string;
  to_name: string;
  params: {
    nombre_huesped?: string;
    nombre_propiedad?: string;
    fecha_entrada?: string;
    fecha_salida?: string;
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
    console.log('[send-checkin-email] Received request:', JSON.stringify(body, null, 2));

    if (!body.to_email) {
      throw new Error('to_email is required');
    }

    // Template ID 3 = Check-in Validado
    const templateId = 3;

    const params = {
      nombre_huesped: body.params?.nombre_huesped || 'Huesped',
      nombre_propiedad: body.params?.nombre_propiedad || 'Propiedad',
      fecha_entrada: body.params?.fecha_entrada || '',
      fecha_salida: body.params?.fecha_salida || '',
      hero_image_url: "https://qwepisgdqlmqfxwqkztz.supabase.co/storage/v1/object/public/email-assets/heroimagen.png",
      link_ios: "https://apps.apple.com/es/app/bf-stay/id6759832221",
      link_android: body.params?.link_android || 'https://play.google.com/store/apps/details?id=com.bfstay.app&pli=1',
      telefono_1: "+34 656 61 80 65",
      telefono_2: "+34 674 27 70 16",
    };

    console.log('[send-checkin-email] Using template ID:', templateId);
    console.log('[send-checkin-email] Sender:', VERIFIED_SENDER_EMAIL);

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

    console.log('[send-checkin-email] Sending to Brevo...');

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
    console.log('[send-checkin-email] Brevo response status:', response.status);
    console.log('[send-checkin-email] Brevo response:', responseText);

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
    console.error('[send-checkin-email] Error:', error);
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
