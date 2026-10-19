// ============================================================================
// send-deposit-email
// ----------------------------------------------------------------------------
// Envía al huésped el email "Fianza pendiente" (plantilla Brevo ID 8) con el
// importe y el enlace de pago de su reserva.
//
// A diferencia de las send-*-email antiguas:
//   · Exige sesión de staff (admin, o staff de la propiedad de la reserva).
//   · Solo recibe `booking_id`: destinatario, importe y enlace se leen de la
//     base de datos, así que no se puede usar para enviar otra cosa.
//   · Solo envía si la fianza está realmente pendiente.
//
// Plantilla de referencia: docs/email_templates/brevo_template_fianza_pendiente.html
// ============================================================================
import 'jsr:@supabase/functions-js/edge-runtime.d.ts';
import { createClient } from 'jsr:@supabase/supabase-js@2';

const BREVO_API_URL = 'https://api.brevo.com/v3/smtp/email';
const TEMPLATE_ID = 8;

// Remitente sobre dominio autenticado en Brevo (grupohotelerobf.com)
const VERIFIED_SENDER_EMAIL = 'info@grupohotelerobf.com';
// Buzón del gestor: recibe respuestas (Reply-To) y copia oculta (BCC)
const MANAGER_EMAIL = 'ghotelerobf@gmail.com';

const DEFAULTS = {
  hero_image_url:
    'https://qwepisgdqlmqfxwqkztz.supabase.co/storage/v1/object/public/email-assets/heroimagen.png',
  telefono_1: '+34 656 61 80 65',
  telefono_2: '+34 674 27 70 16',
};

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/** 2026-10-19 -> 19/10/2026 */
function formatDate(value: string | null): string {
  if (!value) return '';
  const [year, month, day] = value.slice(0, 10).split('-');
  return `${day}/${month}/${year}`;
}

/** 15000 -> "150,00 €" */
function formatCents(cents: number): string {
  return new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' })
    .format(cents / 100);
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  // ── 1. Solo staff ──────────────────────────────────────────────────────
  const authHeader = req.headers.get('Authorization') ?? '';
  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
  if (authError || !user) return json({ error: 'unauthorized' }, 401);

  const { data: roleData } = await supabaseAdmin
    .from('user_roles')
    .select('role, property_id')
    .eq('user_id', user.id)
    .maybeSingle();

  if (!roleData || !['admin', 'staff'].includes(roleData.role)) {
    return json({ error: 'forbidden', message: 'Acceso denegado' }, 403);
  }

  try {
    const { booking_id } = await req.json();
    if (!booking_id) return json({ error: 'missing_fields', message: 'booking_id requerido' }, 422);

    // ── 2. Datos de la reserva (nunca del cliente) ─────────────────────────
    const { data: booking, error: bookingError } = await supabaseAdmin
      .from('bookings')
      .select(`
        id, booking_code, property_id, checkin_date, checkout_date,
        guest_first_name, last_name, guest_email,
        deposit_status, deposit_amount_cents, deposit_payment_link,
        properties ( name ),
        units ( name )
      `)
      .eq('id', booking_id)
      .single();

    if (bookingError || !booking) {
      return json({ error: 'not_found', message: 'Reserva no encontrada' }, 404);
    }

    if (roleData.role === 'staff' && roleData.property_id !== booking.property_id) {
      return json({ error: 'forbidden', message: 'No tienes acceso a esta propiedad' }, 403);
    }

    if (booking.deposit_status !== 'pending') {
      return json({ error: 'deposit_not_pending', message: 'La reserva no tiene una fianza pendiente' }, 409);
    }

    if (!booking.guest_email) {
      return json({ error: 'no_email', message: 'La reserva no tiene email del huésped' }, 422);
    }

    if (!booking.deposit_payment_link || !booking.deposit_amount_cents) {
      return json({ error: 'missing_deposit_data', message: 'Faltan el importe o el enlace de la fianza' }, 422);
    }

    const guestName =
      `${booking.guest_first_name ?? ''} ${booking.last_name ?? ''}`.trim() || 'Huésped';
    const propertyName = (booking.properties as { name: string } | null)?.name ?? 'BF Stay';
    const unitName = (booking.units as { name: string } | null)?.name;

    const params = {
      nombre_huesped: booking.guest_first_name || guestName,
      nombre_propiedad: unitName ? `${propertyName} - ${unitName}` : propertyName,
      codigo_reserva: booking.booking_code,
      fecha_entrada: formatDate(booking.checkin_date),
      fecha_salida: formatDate(booking.checkout_date),
      importe_fianza: formatCents(booking.deposit_amount_cents),
      link_pago: booking.deposit_payment_link,
      ...DEFAULTS,
    };

    // ── 3. Envío por Brevo ────────────────────────────────────────────────
    const response = await fetch(BREVO_API_URL, {
      method: 'POST',
      headers: {
        'accept': 'application/json',
        'content-type': 'application/json',
        'api-key': Deno.env.get('BREVO_API_KEY')!,
      },
      body: JSON.stringify({
        sender: { name: 'BF Stay', email: VERIFIED_SENDER_EMAIL },
        to: [{ email: booking.guest_email, name: guestName }],
        replyTo: { name: 'BF Stay', email: MANAGER_EMAIL },
        bcc: [{ email: MANAGER_EMAIL, name: 'BF Stay' }],
        templateId: TEMPLATE_ID,
        params,
      }),
    });

    const responseText = await response.text();
    let messageId: string | null = null;
    try {
      messageId = JSON.parse(responseText).messageId ?? null;
    } catch {
      // Brevo no devolvió JSON
    }

    // Registro (no bloquea el envío si falla)
    await supabaseAdmin.from('email_logs').insert({
      booking_id: booking.id,
      recipient: booking.guest_email,
      subject: `Fianza pendiente de tu reserva ${booking.booking_code}`,
      template: `brevo_${TEMPLATE_ID}_deposit`,
      status: response.ok ? 'sent' : 'error',
      provider_id: messageId,
      error_message: response.ok ? null : responseText.slice(0, 1000),
      sent_at: response.ok ? new Date().toISOString() : null,
    }).then(({ error }) => {
      if (error) console.warn('[send-deposit-email] No se pudo registrar el envío:', error.message);
    });

    if (!response.ok) {
      console.error('[send-deposit-email] Brevo error:', response.status, responseText);
      return json({ error: 'brevo_error', message: 'No se pudo enviar el email' }, 502);
    }

    return json({ success: true, messageId });
  } catch (err) {
    console.error('[send-deposit-email] Error inesperado:', err);
    return json({ error: 'server_error', message: 'Error interno del servidor' }, 500);
  }
});
