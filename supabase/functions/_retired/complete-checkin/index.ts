// ============================================================================
// COPIA DE SEGURIDAD — versión 19 desplegada de la Edge Function `complete-checkin`
// Retirada el 2026-10-19: la app ya no la usa (el envío del check-in va por la
// RPC submit_guest_checkin) y devolvía box_code e instrucciones de acceso al
// enviar el check-in, sin esperar a la validación ni a la fianza.
// En producción se ha sustituido por un stub que responde 410.
// ============================================================================
import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'method_not_allowed' }, 405, corsHeaders);
  }

  // ── Verificar JWT del huésped ──────────────────────────────
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return json({ error: 'unauthorized', message: 'Se requiere autenticación' }, 401, corsHeaders);
  }

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  // Verificar el token del usuario que hace la petición
  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);

  if (authError || !user) {
    return json({ error: 'unauthorized', message: 'Token inválido o expirado' }, 401, corsHeaders);
  }

  try {
    const body = await req.json();
    const { booking_id } = body;

    if (!booking_id) {
      return json({ error: 'missing_fields', message: 'booking_id es requerido' }, 422, corsHeaders);
    }

    // ── 1. Verificar que la reserva pertenece al usuario ───────────
    const { data: booking, error: bookingError } = await supabaseAdmin
      .from('bookings')
      .select(`
        id, status, num_guests, booking_code,
        checkin_date, checkout_date,
        primary_guest_user_id,
        units ( name, address_line1, city, box_code, access_instructions ),
        properties ( id, name )
      `)
      .eq('id', booking_id)
      .eq('primary_guest_user_id', user.id)
      .single();

    if (bookingError || !booking) {
      return json({ error: 'not_found', message: 'Reserva no encontrada o sin permisos' }, 404, corsHeaders);
    }

    if (booking.status === 'checked_in') {
      return json({ error: 'already_checked_in', message: 'El check-in ya fue completado' }, 409, corsHeaders);
    }

    if (booking.status !== 'confirmed') {
      return json({ error: 'invalid_status', message: `No se puede hacer check-in con estado: ${booking.status}` }, 422, corsHeaders);
    }

    // ── 2. Llamar a la función SQL can_complete_checkin ────────
    const { data: canComplete, error: checkError } = await supabaseAdmin
      .rpc('can_complete_checkin', { p_booking_id: booking_id });

    if (checkError) {
      console.error('Error en can_complete_checkin:', checkError);
      return json({ error: 'server_error', message: 'Error verificando documentación' }, 500, corsHeaders);
    }

    if (!canComplete) {
      // Obtener detalle de qué falta exactamente
      const { data: pending } = await supabaseAdmin
        .from('booking_guests')
        .select('guest_id, doc_status, requires_document, guests(full_name)')
        .eq('booking_id', booking_id)
        .eq('requires_document', true)
        .not('doc_status', 'in', '("uploaded","verified")');

      return json({
        error: 'incomplete_documents',
        message: 'Faltan documentos por subir',
        pending_guests: pending ?? [],
      }, 422, corsHeaders);
    }

    // ── 3. Ejecutar complete_checkin en la BD ─────────────────
    const { data: result, error: completeError } = await supabaseAdmin
      .rpc('complete_checkin', { p_booking_id: booking_id, p_user_id: user.id });

    if (completeError || !result?.startsWith('OK:')) {
      console.error('Error en complete_checkin:', completeError ?? result);
      return json({ error: 'server_error', message: 'Error al completar el check-in' }, 500, corsHeaders);
    }

    const checkinId = result.replace('OK:', '');

    // ── 4. Generar PDF del check-in ─────────────────────────
    const { data: guests } = await supabaseAdmin
      .from('booking_guests')
      .select('is_primary, age_at_checkin, doc_status, guests(full_name, document_number, document_type, nationality, birth_date, sex)')
      .eq('booking_id', booking_id);

    const unit = booking.units as { name: string; address_line1: string; city: string; box_code: string; access_instructions: string };
    const property = booking.properties as { id: string; name: string };

    const pdfHtml = generateCheckinPdfHtml({
      booking_code: booking.booking_code,
      checkin_date: booking.checkin_date,
      checkout_date: booking.checkout_date,
      unit_name: unit?.name ?? '',
      property_name: property?.name ?? '',
      address: unit?.address_line1 ?? '',
      city: unit?.city ?? '',
      guests: guests ?? [],
      generated_at: new Date().toISOString(),
    });

    // Guardar HTML del PDF en storage (se puede convertir a PDF real con un servicio externo)
    const pdfPath = `checkins/${booking_id}/${checkinId}_checkin.html`;
    const { error: uploadError } = await supabaseAdmin.storage
      .from('guest-documents')
      .upload(pdfPath, new Blob([pdfHtml], { type: 'text/html' }), {
        upsert: true,
        contentType: 'text/html',
      });

    if (!uploadError) {
      // Actualizar ruta del PDF en la tabla checkins
      await supabaseAdmin
        .from('checkins')
        .update({ checkin_pdf_path: pdfPath })
        .eq('id', checkinId);
    } else {
      console.warn('No se pudo guardar el PDF del checkin:', uploadError.message);
    }

    // ── 5. Notificar al staff vía Supabase Realtime / tabla notificaciones ─
    // Insertar en una tabla de notificaciones que el staff escucha por realtime
    await supabaseAdmin
      .from('staff_notifications')
      .insert({
        property_id: property?.id,
        type: 'checkin_completed',
        title: 'Check-in completado',
        body: `La reserva ${booking.booking_code} ha completado el check-in online`,
        data: {
          booking_id: booking_id,
          checkin_id: checkinId,
          booking_code: booking.booking_code,
          unit_name: unit?.name,
          checkin_date: booking.checkin_date,
        },
        is_read: false,
      })
      .select()
      .single();
    // Nota: si falla la notificación no rompemos el flujo, el checkin ya está completado

    // ── 6. Respuesta exitosa ────────────────────────────────────
    return json({
      success: true,
      checkin_id: checkinId,
      booking_id,
      access_info: {
        box_code: unit?.box_code ?? null,
        access_instructions: unit?.access_instructions ?? null,
      },
      pdf_path: pdfPath,
    }, 200, corsHeaders);

  } catch (err) {
    console.error('Error inesperado:', err);
    return json({ error: 'server_error', message: 'Error interno del servidor' }, 500, corsHeaders);
  }
});

// ── Generador HTML del documento de check-in ────────────────────
function generateCheckinPdfHtml(data: {
  booking_code: string;
  checkin_date: string;
  checkout_date: string;
  unit_name: string;
  property_name: string;
  address: string;
  city: string;
  guests: unknown[];
  generated_at: string;
}): string {
  const fmtDate = (d: string) => new Date(d).toLocaleDateString('es-ES', { day: '2-digit', month: 'long', year: 'numeric' });

  const guestsRows = (data.guests as Array<{
    is_primary: boolean;
    age_at_checkin: number | null;
    doc_status: string;
    guests: { full_name: string; document_number: string; document_type: string; nationality: string; sex: string } | null;
  }>).map((bg) => {
    const g = bg.guests;
    return `
      <tr>
        <td>${g?.full_name ?? '-'}</td>
        <td>${g?.document_type?.toUpperCase() ?? '-'}</td>
        <td>${g?.document_number ?? 'Menor exento'}</td>
        <td>${g?.nationality ?? '-'}</td>
        <td>${g?.sex ?? '-'}</td>
        <td>${bg.is_primary ? 'Principal' : 'Acompañante'}</td>
      </tr>`;
  }).join('');

  return `<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: Georgia, serif; color: #1a1a1a; padding: 40px; max-width: 800px; margin: 0 auto; }
    .header { border-bottom: 2px solid #C9A84C; padding-bottom: 20px; margin-bottom: 30px; }
    .logo { font-size: 28px; font-weight: bold; color: #C9A84C; letter-spacing: 4px; }
    .subtitle { color: #666; font-size: 13px; margin-top: 4px; }
    .section { margin-bottom: 28px; }
    .section h3 { font-size: 11px; text-transform: uppercase; letter-spacing: 2px; color: #C9A84C; margin-bottom: 12px; }
    .info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
    .info-item label { font-size: 11px; color: #888; display: block; margin-bottom: 2px; }
    .info-item span { font-size: 15px; font-weight: bold; }
    .code { font-family: monospace; font-size: 22px; letter-spacing: 4px; color: #C9A84C; background: #f9f6f0; padding: 12px 20px; display: inline-block; border-radius: 4px; }
    table { width: 100%; border-collapse: collapse; font-size: 13px; }
    th { background: #f9f6f0; padding: 10px 12px; text-align: left; font-size: 10px; text-transform: uppercase; letter-spacing: 1px; color: #666; }
    td { padding: 10px 12px; border-bottom: 1px solid #eee; }
    .footer { margin-top: 40px; padding-top: 20px; border-top: 1px solid #eee; font-size: 11px; color: #999; text-align: center; }
    .stamp { display: inline-block; border: 2px solid #27AE60; color: #27AE60; padding: 8px 20px; font-size: 12px; font-weight: bold; letter-spacing: 2px; transform: rotate(-2deg); margin-top: 20px; }
  </style>
</head>
<body>
  <div class="header">
    <div class="logo">BF STAY</div>
    <div class="subtitle">Documento de registro de viajeros</div>
  </div>

  <div class="section">
    <h3>Reserva</h3>
    <div class="code">${data.booking_code}</div>
    <div class="info-grid" style="margin-top:16px">
      <div class="info-item"><label>Alojamiento</label><span>${data.property_name} — ${data.unit_name}</span></div>
      <div class="info-item"><label>Dirección</label><span>${data.address}, ${data.city}</span></div>
      <div class="info-item"><label>Entrada</label><span>${fmtDate(data.checkin_date)}</span></div>
      <div class="info-item"><label>Salida</label><span>${fmtDate(data.checkout_date)}</span></div>
    </div>
  </div>

  <div class="section">
    <h3>Viajeros registrados</h3>
    <table>
      <thead>
        <tr>
          <th>Nombre completo</th>
          <th>Tipo doc.</th>
          <th>Número documento</th>
          <th>Nacionalidad</th>
          <th>Sexo</th>
          <th>Rol</th>
        </tr>
      </thead>
      <tbody>${guestsRows}</tbody>
    </table>
  </div>

  <div style="text-align:center">
    <div class="stamp">CHECK-IN COMPLETADO</div>
  </div>

  <div class="footer">
    Documento generado el ${new Date(data.generated_at).toLocaleString('es-ES')} · BF Stay · Todos los derechos reservados
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
