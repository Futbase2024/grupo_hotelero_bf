// ============================================================================
// COPIA DE SEGURIDAD — versión 20 desplegada de la Edge Function `send-booking-code`
// Retirada el 2026-10-19: sin autenticación y devolvía en la respuesta el código
// de acceso de la reserva (`code`) a cualquiera que conociera su id. La app ya no
// la usa: los códigos se envían con send-new-booking-email (vía admin-panel o la
// app del admin). Último envío registrado en email_logs: 2026-05-07.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  try {
    const body = await req.json();
    const { booking_id, resend = false } = body;

    if (!booking_id) {
      return json({ error: 'missing_fields', message: 'booking_id es requerido' }, 422, corsHeaders);
    }

    // Obtener datos de la reserva
    const { data: booking, error: bookingError } = await supabaseAdmin
      .from('bookings')
      .select(`
        id, booking_code, checkin_date, checkout_date,
        num_guests, guest_first_name, guest_email, guest_last_name:last_name,
        guest_phone, code_sent_at, status,
        units ( name, city, address_line1 ),
        properties ( name )
      `)
      .eq('id', booking_id)
      .single();

    if (bookingError || !booking) {
      return json({ error: 'not_found', message: 'Reserva no encontrada' }, 404, corsHeaders);
    }

    if (!booking.guest_email) {
      return json({
        error: 'no_email',
        message: 'La reserva no tiene email del huésped. Edítala para añadirlo.',
      }, 422, corsHeaders);
    }

    if (booking.code_sent_at && !resend) {
      return json({
        error: 'already_sent',
        message: 'El código ya fue enviado. Usa resend=true para reenviar.',
        sent_at: booking.code_sent_at,
      }, 409, corsHeaders);
    }

    // Construir email HTML
    const firstName  = booking.guest_first_name ?? 'Estimado/a huésped';
    const unitName   = (booking.units as {name:string})?.name ?? 'su alojamiento';
    const propName   = (booking.properties as {name:string})?.name ?? 'BF-Stay';
    const checkIn    = formatDate(booking.checkin_date);
    const checkOut   = formatDate(booking.checkout_date);
    const code       = booking.booking_code;
    const subject    = resend
      ? `Reenvío de tu código de acceso — ${propName}`
      : `Tu reserva está confirmada — ${propName}`;

    const htmlBody = buildEmailHtml({
      firstName,
      code,
      unitName,
      propName,
      checkIn,
      checkOut,
      numGuests: booking.num_guests,
      isResend:  resend,
    });

    // Enviar email via Brevo
    const brevoApiKey = Deno.env.get('BREVO_API_KEY');
    const fromEmail   = 'ghotelerobf@gmail.com';
    const fromName    = 'BF-Stay';

    if (!brevoApiKey) {
      console.warn('BREVO_API_KEY no configurada — email simulado');
      await logEmail(supabaseAdmin, booking_id, booking.guest_email, subject, 'booking_code', 'sent', 'dev-simulated');
      await markCodeSent(supabaseAdmin, booking_id);
      return json({
        success: true,
        simulated: true,
        message:   'Email simulado (configura BREVO_API_KEY para envíos reales)',
        recipient: booking.guest_email,
        code,
      }, 200, corsHeaders);
    }

    const brevoPayload = {
      sender: {
        name: fromName,
        email: fromEmail,
      },
      to: [
        {
          email: booking.guest_email,
          name: firstName,
        },
      ],
      subject,
      htmlContent: htmlBody,
    };

    console.log('[send-booking-code] Sending via Brevo to:', booking.guest_email);

    const brevoResponse = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'api-key': brevoApiKey,
      },
      body: JSON.stringify(brevoPayload),
    });

    const brevoData = await brevoResponse.json();

    if (!brevoResponse.ok) {
      await logEmail(supabaseAdmin, booking_id, booking.guest_email, subject, 'booking_code',
        'failed', null, JSON.stringify(brevoData));
      console.error('[send-booking-code] Brevo error:', brevoData);
      return json({
        error:   'email_failed',
        message: 'No se pudo enviar el email. Revisa la configuración de Brevo.',
        detail:  brevoData,
      }, 502, corsHeaders);
    }

    // Actualizar BD
    await logEmail(supabaseAdmin, booking_id, booking.guest_email, subject, 'booking_code',
      'sent', brevoData.messageId);
    await markCodeSent(supabaseAdmin, booking_id);

    return json({
      success:    true,
      recipient:  booking.guest_email,
      provider_id: brevoData.messageId,
      code,
    }, 200, corsHeaders);

  } catch (err) {
    console.error('send-booking-code error:', err);
    return json({ error: 'server_error', message: 'Error interno del servidor' }, 500, corsHeaders);
  }
});

// Helpers

async function markCodeSent(client: ReturnType<typeof createClient>, bookingId: string) {
  await client.from('bookings')
    .update({ code_sent_at: new Date().toISOString() })
    .eq('id', bookingId);
}

async function logEmail(
  client: ReturnType<typeof createClient>,
  bookingId: string,
  recipient: string,
  subject: string,
  template: string,
  status: string,
  providerId: string | null = null,
  errorMessage: string | null = null,
) {
  await client.from('email_logs').insert({
    booking_id:    bookingId,
    recipient,
    subject,
    template,
    status,
    provider_id:   providerId,
    error_message: errorMessage,
    sent_at:       status === 'sent' ? new Date().toISOString() : null,
  });
}

function formatDate(dateStr: string): string {
  const [year, month, day] = dateStr.split('-');
  const months = ['enero','febrero','marzo','abril','mayo','junio',
                  'julio','agosto','septiembre','octubre','noviembre','diciembre'];
  return `${parseInt(day)} de ${months[parseInt(month) - 1]} de ${year}`;
}

function buildEmailHtml(p: {
  firstName: string;
  code: string;
  unitName: string;
  propName: string;
  checkIn: string;
  checkOut: string;
  numGuests: number;
  isResend: boolean;
}): string {
  const [part1, part2] = [p.code.slice(3, 7), p.code.slice(8, 12)];

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${p.propName} — Tu código de acceso</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background-color: #0D0D0D;
      font-family: 'Helvetica Neue', Arial, sans-serif;
      color: #F5F0E8;
      -webkit-font-smoothing: antialiased;
    }
    .wrapper {
      max-width: 600px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .logo-area {
      text-align: center;
      padding-bottom: 32px;
      border-bottom: 1px solid #2A2825;
    }
    .logo-text {
      font-size: 24px;
      font-weight: 300;
      letter-spacing: 6px;
      color: #C9A84C;
      text-transform: uppercase;
    }
    .greeting {
      padding: 36px 0 24px;
      font-size: 15px;
      line-height: 1.7;
      color: #8A8378;
    }
    .greeting strong {
      color: #F5F0E8;
      font-weight: 500;
    }
    .resend-badge {
      display: inline-block;
      background: #C9A84C22;
      border: 1px solid #C9A84C66;
      color: #C9A84C;
      font-size: 11px;
      letter-spacing: 2px;
      text-transform: uppercase;
      padding: 4px 12px;
      border-radius: 4px;
      margin-bottom: 20px;
    }
    .code-container {
      background: #161616;
      border: 1px solid #2A2825;
      border-radius: 12px;
      padding: 32px;
      margin: 28px 0;
      text-align: center;
    }
    .code-label {
      font-size: 11px;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: #8A8378;
      margin-bottom: 20px;
    }
    .code-prefix {
      font-size: 13px;
      color: #8A8378;
      font-family: 'Courier New', monospace;
      letter-spacing: 2px;
    }
    .code-value {
      font-family: 'Courier New', monospace;
      font-size: 42px;
      font-weight: 700;
      color: #C9A84C;
      letter-spacing: 8px;
      display: block;
      margin: 8px 0 4px;
    }
    .code-separator {
      font-size: 32px;
      color: #3D3A36;
      font-weight: 300;
      margin: 0 4px;
    }
    .code-full {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 0;
    }
    .code-block {
      font-family: 'Courier New', monospace;
      font-size: 38px;
      font-weight: 700;
      color: #C9A84C;
      letter-spacing: 6px;
    }
    .code-hint {
      font-size: 12px;
      color: #3D3A36;
      margin-top: 16px;
    }
    .details-card {
      background: #161616;
      border: 1px solid #2A2825;
      border-radius: 12px;
      overflow: hidden;
      margin: 0 0 28px;
    }
    .details-header {
      padding: 14px 24px;
      background: #1E1E1E;
      border-bottom: 1px solid #2A2825;
      font-size: 11px;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: #8A8378;
    }
    .detail-row {
      display: flex;
      padding: 14px 24px;
      border-bottom: 1px solid #2A2825;
      align-items: center;
    }
    .detail-row:last-child { border-bottom: none; }
    .detail-label {
      font-size: 12px;
      color: #8A8378;
      width: 120px;
      flex-shrink: 0;
    }
    .detail-value {
      font-size: 14px;
      color: #F5F0E8;
      font-weight: 500;
    }
    .steps {
      background: #161616;
      border: 1px solid #2A2825;
      border-radius: 12px;
      padding: 24px;
      margin-bottom: 28px;
    }
    .steps-title {
      font-size: 11px;
      letter-spacing: 3px;
      text-transform: uppercase;
      color: #8A8378;
      margin-bottom: 20px;
    }
    .step {
      display: flex;
      gap: 16px;
      margin-bottom: 16px;
      align-items: flex-start;
    }
    .step:last-child { margin-bottom: 0; }
    .step-num {
      width: 24px;
      height: 24px;
      border-radius: 50%;
      background: #C9A84C22;
      border: 1px solid #C9A84C66;
      color: #C9A84C;
      font-size: 11px;
      font-weight: 700;
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
      text-align: center;
      line-height: 24px;
    }
    .step-text {
      font-size: 13px;
      color: #8A8378;
      line-height: 1.6;
    }
    .step-text strong { color: #F5F0E8; font-weight: 500; }
    .footer {
      text-align: center;
      padding-top: 32px;
      border-top: 1px solid #2A2825;
      font-size: 12px;
      color: #3D3A36;
      line-height: 1.8;
    }
    .footer a { color: #8A8378; text-decoration: none; }
  </style>
</head>
<body>
<div class="wrapper">

  <div class="logo-area">
    <div class="logo-text">BF — Stay</div>
  </div>

  <div class="greeting">
    ${p.isResend ? '<div class="resend-badge">Reenvío de código</div><br>' : ''}
    Hola, <strong>${p.firstName}</strong>.<br><br>
    ${p.isResend
      ? 'Te reenviamos el código de acceso para tu reserva en <strong>' + p.unitName + '</strong>.'
      : 'Tu reserva en <strong>' + p.unitName + '</strong> está confirmada. A continuación encontrarás tu código de acceso personal para completar el check-in online.'}
  </div>

  <div class="code-container">
    <div class="code-label">Tu código de acceso</div>
    <div class="code-prefix">BF —</div>
    <div class="code-full">
      <span class="code-block">${part1}</span>
      <span class="code-separator">—</span>
      <span class="code-block">${part2}</span>
    </div>
    <div class="code-hint">Guarda este código. Es personal e intransferible.</div>
  </div>

  <div class="details-card">
    <div class="details-header">Detalles de tu reserva</div>
    <div class="detail-row">
      <span class="detail-label">Alojamiento</span>
      <span class="detail-value">${p.unitName}</span>
    </div>
    <div class="detail-row">
      <span class="detail-label">Entrada</span>
      <span class="detail-value">${p.checkIn}</span>
    </div>
    <div class="detail-row">
      <span class="detail-label">Salida</span>
      <span class="detail-value">${p.checkOut}</span>
    </div>
    <div class="detail-row">
      <span class="detail-label">Huéspedes</span>
      <span class="detail-value">${p.numGuests} persona${p.numGuests !== 1 ? 's' : ''}</span>
    </div>
  </div>

  <div class="steps">
    <div class="steps-title">Cómo completar tu check-in</div>
    <div class="step">
      <div class="step-num">1</div>
      <div class="step-text">Descarga la app <strong>${p.propName}</strong> en tu dispositivo.</div>
    </div>
    <div class="step">
      <div class="step-num">2</div>
      <div class="step-text">En la pantalla de inicio, toca el botón <strong>"Tengo una reserva"</strong>.</div>
    </div>
    <div class="step">
      <div class="step-num">3</div>
      <div class="step-text">Introduce tu email y el código <strong>BF-${part1}-${part2}</strong>.</div>
    </div>
    <div class="step">
      <div class="step-num">4</div>
      <div class="step-text">Rellena tus datos y sube la documentación requerida.<br>Recibirás el código de la caja de llaves al completar el proceso.</div>
    </div>
  </div>

  <div class="footer">
    ${p.propName} &mdash; Powered by BF-Stay<br>
    <a href="#">Política de privacidad</a> &middot; <a href="#">Cancelar reserva</a><br><br>
    Si no esperabas este email, puedes ignorarlo con total seguridad.
  </div>

</div>
</body>
</html>`;
}

function json(data: unknown, status: number, headers: Record<string, string>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}
