import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

const VERIFIED_SENDER_EMAIL = 'ghotelerobf@gmail.com';
// Email de destino para notificaciones de check-in
const NOTIFICATION_EMAIL = 'grupohotelbf@gmail.com';

interface CheckinNotificationPayload {
  checkin_id: string;
  guest_name: string;
  property_name: string;
  booking_code: string;
  check_in_date: string;
  check_out_date: string;
  admin_url?: string;
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const body: CheckinNotificationPayload = await req.json();
    console.log('[send-checkin-notification] Received:', JSON.stringify(body, null, 2));

    const requiredFields = ['checkin_id', 'guest_name', 'property_name', 'booking_code', 'check_in_date', 'check_out_date'];
    const missingFields = requiredFields.filter(field => !body[field as keyof CheckinNotificationPayload]);

    if (missingFields.length > 0) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields', details: `Missing: ${missingFields.join(', ')}` }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const fechaEnvio = new Date().toLocaleDateString('es-ES', {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });

    const adminUrl = body.admin_url || `https://bf-stay.pages.dev/admin/checkins/${body.checkin_id}`;

    const htmlContent = `
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Nuevo check-in completado</title>
</head>
<body style="margin:0; padding:0; background-color:#f4f4f4; font-family:Arial, Helvetica, sans-serif; color:#1a1a1a;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#f4f4f4; margin:0; padding:24px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="640" cellspacing="0" cellpadding="0" border="0" style="width:640px; max-width:640px; background-color:#ffffff; border-radius:14px; overflow:hidden;">
          <tr>
            <td style="background-color:#000000; padding:28px 32px; text-align:center;">
              <div style="font-size:28px; line-height:32px; font-weight:700; color:#d4af37; letter-spacing:0.5px;">BF Stay</div>
              <div style="font-size:14px; line-height:20px; color:#ffffff; margin-top:8px;">Grupo Hotelero BF</div>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 32px 16px 32px;">
              <h1 style="margin:0 0 16px 0; font-size:26px; line-height:32px; color:#111111;">Nuevo check-in completado</h1>
              <p style="margin:0; font-size:16px; line-height:26px; color:#333333;">Se ha completado un nuevo check-in y queda <strong>pendiente de revisión y validación</strong> por parte del equipo.</p>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#fafafa; border:1px solid #e8e8e8; border-radius:12px;">
                <tr>
                  <td style="padding:24px;">
                    <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0">
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666; width:180px;">Nombre del huésped</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${body.guest_name}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Propiedad</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${body.property_name}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Código de reserva</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${body.booking_code}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Fecha de entrada</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${formatDate(body.check_in_date)}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Fecha de salida</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${formatDate(body.check_out_date)}</td></tr>
                      <tr><td style="padding:0; font-size:15px; line-height:22px; color:#666666;">Fecha de envío</td><td style="padding:0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${fechaEnvio}</td></tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:8px 32px 0 32px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="background-color:#fff8e6; border:1px solid #f1df9a; border-radius:12px;">
                <tr><td style="padding:18px 20px; font-size:15px; line-height:24px; color:#5a4a14;"><strong>Acción recomendada:</strong> revisa la documentación del huésped y valida el check-in desde el panel de administración.</td></tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:28px 32px 8px 32px; text-align:center;">
              <a href="${adminUrl}" style="display:inline-block; background-color:#000000; color:#d4af37; text-decoration:none; font-size:15px; font-weight:700; padding:14px 26px; border-radius:10px;">Revisar reserva</a>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 32px 32px 32px;">
              <p style="margin:0; font-size:14px; line-height:24px; color:#666666; text-align:center;">Este correo se ha generado automáticamente desde BF Stay al finalizar el proceso de check-in digital.</p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#f8f8f8; padding:22px 32px; text-align:center; border-top:1px solid #ececec;">
              <p style="margin:0; font-size:13px; line-height:22px; color:#777777;">Grupo Hotelero BF</p>
              <p style="margin:4px 0 0 0; font-size:13px; line-height:22px; color:#777777;">Notificación interna de check-in completado</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;

    const textContent = `
BF Stay - Grupo Hotelero BF
================================
NUEVO CHECK-IN COMPLETADO

Huésped: ${body.guest_name}
Propiedad: ${body.property_name}
Reserva: ${body.booking_code}
Entrada: ${formatDate(body.check_in_date)}
Salida: ${formatDate(body.check_out_date)}
Enviado: ${fechaEnvio}

Revisar: ${adminUrl}
--
BF Stay - Grupo Hotelero BF
`;

    const brevoPayload = {
      sender: { name: 'BF Stay', email: VERIFIED_SENDER_EMAIL },
      to: [{ email: NOTIFICATION_EMAIL, name: 'Administración BF Stay' }],
      subject: `Nuevo check-in completado - ${body.booking_code}`,
      htmlContent: htmlContent,
      textContent: textContent,
    };

    console.log('[send-checkin-notification] Sending to Brevo...');
    console.log('[send-checkin-notification] Recipient:', NOTIFICATION_EMAIL);

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
    console.log('[send-checkin-notification] Brevo response:', response.status, responseText);

    if (!response.ok) {
      throw new Error(`Brevo API error: ${response.status} - ${responseText}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Notification email sent',
        recipient: NOTIFICATION_EMAIL,
        checkin_id: body.checkin_id,
        messageId: JSON.parse(responseText).messageId,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );

  } catch (error) {
    console.error('[send-checkin-notification] Error:', error);
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
