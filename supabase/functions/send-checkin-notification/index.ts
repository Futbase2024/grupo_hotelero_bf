// ============================================================================
// send-checkin-notification
// ----------------------------------------------------------------------------
// Avisa por email al buzón de administración de que un huésped ha completado
// el check-in. La llama la app del huésped al enviar el check-in.
//
// 2026-10-19: antes no exigía autenticación y montaba el email con los datos
// del body sin escapar (incluido el enlace "Revisar reserva"), lo que permitía
// mandar al buzón del admin emails con contenido y enlaces arbitrarios.
// Ahora: exige sesión, solo recibe el id de la reserva, lee los datos de la BD
// comprobando que la reserva es del usuario (o que es staff), escapa el HTML,
// el enlace es fijo, solo envía con el check-in enviado y como mucho una vez
// cada 10 minutos por reserva.
// Copia de la versión anterior: supabase/functions/_previous/send-checkin-notification/
// ============================================================================
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from 'jsr:@supabase/supabase-js@2';

const BREVO_API_KEY = Deno.env.get('BREVO_API_KEY')!;
const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';

const VERIFIED_SENDER_EMAIL = 'ghotelerobf@gmail.com';
// Email de destino para notificaciones de check-in
const NOTIFICATION_EMAIL = 'grupohotelbf@gmail.com';
const LOG_TEMPLATE = 'checkin_notification_admin';
const MIN_MINUTES_BETWEEN_EMAILS = 10;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function formatDate(dateStr: string): string {
  const date = new Date(dateStr);
  return date.toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
}

/** Escapa texto para insertarlo en HTML */
function esc(value: unknown): string {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  try {
    if (req.method !== 'POST') {
      return jsonResponse({ error: 'Method not allowed' }, 405);
    }

    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // ── Usuario que llama ────────────────────────────────────────────────────
    const token = (req.headers.get('Authorization') ?? '').replace(/^Bearer\s+/i, '');
    if (!token) return jsonResponse({ error: 'unauthorized' }, 401);
    const { data: { user } } = await supabaseAdmin.auth.getUser(token);
    if (!user) return jsonResponse({ error: 'unauthorized' }, 401);

    // La app envía el id de la reserva en `checkin_id`; el resto del body se ignora
    const body = await req.json();
    const bookingId: string | undefined = body?.booking_id ?? body?.checkin_id;
    if (!bookingId) return jsonResponse({ error: 'missing_fields' }, 400);

    // ── Datos de la reserva desde la BD ──────────────────────────────────────
    const { data: booking } = await supabaseAdmin
      .from('bookings')
      .select(`
        id, booking_code, checkin_date, checkout_date,
        guest_first_name, last_name, primary_guest_user_id,
        properties ( name ),
        checkins ( status )
      `)
      .eq('id', bookingId)
      .maybeSingle();

    if (!booking) return jsonResponse({ error: 'not_found' }, 404);

    if (booking.primary_guest_user_id !== user.id) {
      const { data: roleData } = await supabaseAdmin
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .maybeSingle();
      if (!roleData || !['admin', 'staff'].includes(roleData.role)) {
        return jsonResponse({ error: 'forbidden' }, 403);
      }
    }

    const checkin = Array.isArray(booking.checkins) ? booking.checkins[0] : booking.checkins;
    if (!checkin || !['submitted', 'validated'].includes(checkin.status)) {
      return jsonResponse({ error: 'checkin_not_submitted' }, 409);
    }

    // ── Como mucho un aviso cada 10 minutos por reserva ──────────────────────
    const since = new Date(Date.now() - MIN_MINUTES_BETWEEN_EMAILS * 60_000).toISOString();
    const { count: recentCount } = await supabaseAdmin
      .from('email_logs')
      .select('id', { count: 'exact', head: true })
      .eq('booking_id', booking.id)
      .eq('template', LOG_TEMPLATE)
      .gte('created_at', since);
    if ((recentCount ?? 0) > 0) {
      return jsonResponse({ success: true, skipped: 'recently_sent' }, 200);
    }

    const guestName =
      `${booking.guest_first_name ?? ''} ${booking.last_name ?? ''}`.trim() || 'Huésped';
    const propertyName = (booking.properties as { name: string } | null)?.name ?? 'BF Stay';
    const bookingCode = booking.booking_code ?? '';

    const fechaEnvio = new Date().toLocaleDateString('es-ES', {
      weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
      hour: '2-digit', minute: '2-digit'
    });

    const adminUrl = `https://bf-stay.pages.dev/admin/checkins/${encodeURIComponent(booking.id)}`;

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
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666; width:180px;">Nombre del huésped</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${esc(guestName)}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Propiedad</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${esc(propertyName)}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Código de reserva</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${esc(bookingCode)}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Fecha de entrada</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${esc(formatDate(booking.checkin_date))}</td></tr>
                      <tr><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#666666;">Fecha de salida</td><td style="padding:0 0 14px 0; font-size:15px; line-height:22px; color:#111111; font-weight:600;">${esc(formatDate(booking.checkout_date))}</td></tr>
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

Huésped: ${guestName}
Propiedad: ${propertyName}
Reserva: ${bookingCode}
Entrada: ${formatDate(booking.checkin_date)}
Salida: ${formatDate(booking.checkout_date)}
Enviado: ${fechaEnvio}

Revisar: ${adminUrl}
--
BF Stay - Grupo Hotelero BF
`;

    const brevoPayload = {
      sender: { name: 'BF Stay', email: VERIFIED_SENDER_EMAIL },
      to: [{ email: NOTIFICATION_EMAIL, name: 'Administración BF Stay' }],
      subject: `Nuevo check-in completado - ${bookingCode}`,
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

    let messageId: string | null = null;
    try {
      messageId = JSON.parse(responseText).messageId ?? null;
    } catch {
      // Brevo no devolvió JSON
    }

    await supabaseAdmin.from('email_logs').insert({
      booking_id: booking.id,
      recipient: NOTIFICATION_EMAIL,
      subject: `Nuevo check-in completado - ${bookingCode}`,
      template: LOG_TEMPLATE,
      status: response.ok ? 'sent' : 'error',
      provider_id: messageId,
      error_message: response.ok ? null : responseText.slice(0, 1000),
      sent_at: response.ok ? new Date().toISOString() : null,
    }).then(({ error }) => {
      if (error) console.warn('[send-checkin-notification] No se pudo registrar el envío:', error.message);
    });

    if (!response.ok) {
      return jsonResponse({ error: 'brevo_error' }, 502);
    }

    return jsonResponse({ success: true, messageId }, 200);

  } catch (error) {
    console.error('[send-checkin-notification] Error:', error);
    return jsonResponse({ error: 'Internal server error' }, 500);
  }
});
