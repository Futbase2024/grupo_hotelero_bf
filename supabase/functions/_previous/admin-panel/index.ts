import { createClient } from 'jsr:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders });
  if (req.method !== 'POST') return json({ error: 'method_not_allowed' }, 405, corsHeaders);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) return json({ error: 'unauthorized' }, 401, corsHeaders);

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { autoRefreshToken: false, persistSession: false } }
  );

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error: authError } = await supabaseAdmin.auth.getUser(token);
  if (authError || !user) return json({ error: 'unauthorized' }, 401, corsHeaders);

  const { data: roleData } = await supabaseAdmin
    .from('user_roles')
    .select('role, property_id')
    .eq('user_id', user.id)
    .single();

  if (!roleData || !['admin', 'staff'].includes(roleData.role)) {
    return json({ error: 'forbidden', message: 'Acceso denegado' }, 403, corsHeaders);
  }

  try {
    const body = await req.json();
    const { action } = body;

    // ═══════════════════════════════════════════════════════
    // dashboard_summary
    // ═══════════════════════════════════════════════════════
    if (action === 'dashboard_summary') {
      const propertyId = roleData.role === 'staff' ? roleData.property_id : body.property_id ?? null;

      const { data, error } = await supabaseAdmin.rpc('admin_dashboard_summary', {
        p_property_id: propertyId,
      });

      if (error) {
        const today = new Date().toISOString().split('T')[0];
        const in7days = new Date(Date.now() + 7 * 86400000).toISOString().split('T')[0];

        const queries = await Promise.all([
          supabaseAdmin.from('checkins').select('id', { count: 'exact', head: true }).eq('status', 'submitted'),
          supabaseAdmin.from('bookings').select('id', { count: 'exact', head: true }).gte('checkin_date', today).lte('checkin_date', in7days).not('status', 'in', '("cancelled","checked_out")'),
          supabaseAdmin.from('staff_notifications').select('id', { count: 'exact', head: true }).eq('is_read', false),
          supabaseAdmin.from('units').select('id', { count: 'exact', head: true }),
          supabaseAdmin.from('bookings').select('id', { count: 'exact', head: true }).eq('status', 'checked_in'),
          supabaseAdmin.from('bookings').select('id', { count: 'exact', head: true }).eq('checkout_date', today).not('status', 'in', '("cancelled","checked_out")'),
        ]);

        const [pending, upcoming, unread, units, occupied, checkoutsToday] = queries;

        return json({
          success: true,
          summary: {
            pending_checkins:    pending.count    ?? 0,
            upcoming_checkins:   upcoming.count   ?? 0,
            unread_notifications: unread.count    ?? 0,
            total_units:         units.count      ?? 0,
            currently_occupied:  occupied.count   ?? 0,
            checkouts_today:     checkoutsToday.count ?? 0,
          },
        }, 200, corsHeaders);
      }

      return json({ success: true, summary: data }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // create_booking
    // NOTA: El email ahora lo envia el Dart code via send-new-booking-email (Brevo template 2)
    // ═══════════════════════════════════════════════════════
    if (action === 'create_booking') {
      const {
        property_id, unit_id, unit_ids, checkin_date, checkout_date,
        last_name, staff_notes,
        guest_first_name, guest_email, guest_phone,
        send_email = true,
        num_adults = 1,
        num_children = 0,
        children_ages = [],
      } = body;

      const resolvedUnitIds: string[] = Array.isArray(unit_ids) && unit_ids.length > 0
        ? unit_ids
        : (unit_id ? [unit_id] : []);

      const primaryUnitId = resolvedUnitIds[0];

      if (!property_id || !primaryUnitId || !checkin_date || !checkout_date) {
        return json({ error: 'missing_fields', message: 'Faltan campos obligatorios' }, 422, corsHeaders);
      }
      if (!guest_first_name || !guest_email) {
        return json({ error: 'missing_fields', message: 'Nombre y email del huésped son obligatorios' }, 422, corsHeaders);
      }
      if (roleData.role === 'staff' && roleData.property_id !== property_id) {
        return json({ error: 'forbidden', message: 'No tienes acceso a esta propiedad' }, 403, corsHeaders);
      }

      const { data: booking, error: rpcError } = await supabaseAdmin.rpc('create_booking_with_code', {
        p_property_id:      property_id,
        p_unit_id:          primaryUnitId,
        p_checkin_date:     checkin_date,
        p_checkout_date:    checkout_date,
        p_last_name:        last_name ?? '',
        p_staff_notes:      staff_notes ?? null,
        p_guest_first_name: guest_first_name,
        p_guest_email:      guest_email,
        p_guest_phone:      guest_phone ?? null,
        p_num_adults:       num_adults,
        p_num_children:     num_children,
        p_children_ages:    children_ages,
      });

      if (rpcError) {
        const errMsg = rpcError.message || '';
        if (errMsg.includes('no_overlapping_bookings') || errMsg.includes('exclusion constraint') || errMsg.includes('conflicts with key')) {
          return json({ error: 'booking_overlap', message: 'Ya existe una reserva para este alojamiento en las fechas seleccionadas' }, 409, corsHeaders);
        }
        return json({ error: 'rpc_error', message: rpcError.message }, 422, corsHeaders);
      }

      const bookingUnitsRows = resolvedUnitIds.map((uid: string) => ({
        booking_id: booking.booking_id,
        unit_id: uid,
      }));
      const { error: buError } = await supabaseAdmin
        .from('booking_units')
        .insert(bookingUnitsRows);

      if (buError) {
        console.error('Error insertando booking_units:', buError.message);
      }

      // Email enviado por el Dart code via send-new-booking-email (Brevo template 2)
      // No enviamos desde aqui para evitar emails duplicados
      return json({ success: true, booking, email_sent: false, email_result: { skipped: true, reason: 'email_sent_by_client' } }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // resend_code - Ahora usa send-new-booking-email (Brevo template 2)
    // ═══════════════════════════════════════════════════════
    if (action === 'resend_code') {
      const { booking_id } = body;
      if (!booking_id) return json({ error: 'missing_fields', message: 'booking_id requerido' }, 422, corsHeaders);

      // Obtener datos de la reserva para construir los parametros del email
      const { data: booking, error: bookingError } = await supabaseAdmin
        .from('bookings')
        .select(`
          id, booking_code, checkin_date, checkout_date,
          num_guests, guest_first_name, guest_email, guest_last_name:last_name,
          units ( name ),
          properties ( name )
        `)
        .eq('id', booking_id)
        .single();

      if (bookingError || !booking) {
        return json({ error: 'not_found', message: 'Reserva no encontrada' }, 404, corsHeaders);
      }

      if (!booking.guest_email) {
        return json({ error: 'no_email', message: 'La reserva no tiene email del huésped.' }, 422, corsHeaders);
      }

      const unitName = (booking.units as {name:string})?.name ?? 'Alojamiento';
      const propName = (booking.properties as {name:string})?.name ?? 'BF-Stay';
      const firstName = booking.guest_first_name ?? 'Huésped';
      const lastName = (booking as any).guest_last_name ?? '';

      // Formatear fechas
      const checkIn = formatDateShort(booking.checkin_date);
      const checkOut = formatDateShort(booking.checkout_date);

      // Llamar a send-new-booking-email (Brevo template 2)
      const emailResponse = await fetch(
        `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-new-booking-email`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            to_email: booking.guest_email,
            to_name: `${firstName} ${lastName}`,
            params: {
              nombre_huesped: firstName,
              nombre_propiedad: `${propName} - ${unitName}`,
              fecha_entrada: checkIn,
              fecha_salida: checkOut,
              codigo_acceso: booking.booking_code,
              link_abrir_app: `https://bf-stay.pages.dev/booking/${booking_id}`,
              num_huespedes: String(booking.num_guests ?? 1),
            },
            booking_id,
          }),
        }
      );
      const emailResult = await emailResponse.json();

      // Actualizar code_sent_at
      await supabaseAdmin.from('bookings')
        .update({ code_sent_at: new Date().toISOString() })
        .eq('id', booking_id);

      return json({ success: emailResponse.ok, ...emailResult }, emailResponse.status, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // regenerate_code - Ahora usa send-new-booking-email (Brevo template 2)
    // ═══════════════════════════════════════════════════════
    if (action === 'regenerate_code') {
      const { booking_id, send_email = true } = body;
      if (!booking_id) return json({ error: 'missing_fields' }, 422, corsHeaders);

      const { data: newCode, error: rpcError } = await supabaseAdmin
        .rpc('regenerate_booking_code', { p_booking_id: booking_id });
      if (rpcError) return json({ error: 'rpc_error', message: rpcError.message }, 422, corsHeaders);

      await supabaseAdmin.from('bookings').update({ code_sent_at: null }).eq('id', booking_id);

      let emailResult: Record<string, unknown> = { skipped: true };
      if (send_email) {
        try {
          // Obtener datos de la reserva
          const { data: booking } = await supabaseAdmin
            .from('bookings')
            .select(`
              id, booking_code, checkin_date, checkout_date,
              num_guests, guest_first_name, guest_email, guest_last_name:last_name,
              units ( name ),
              properties ( name )
            `)
            .eq('id', booking_id)
            .single();

          if (booking?.guest_email) {
            const unitName = (booking.units as {name:string})?.name ?? 'Alojamiento';
            const propName = (booking.properties as {name:string})?.name ?? 'BF-Stay';
            const firstName = booking.guest_first_name ?? 'Huésped';
            const lastName = (booking as any).guest_last_name ?? '';

            const emailResponse = await fetch(
              `${Deno.env.get('SUPABASE_URL')}/functions/v1/send-new-booking-email`,
              {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  to_email: booking.guest_email,
                  to_name: `${firstName} ${lastName}`,
                  params: {
                    nombre_huesped: firstName,
                    nombre_propiedad: `${propName} - ${unitName}`,
                    fecha_entrada: formatDateShort(booking.checkin_date),
                    fecha_salida: formatDateShort(booking.checkout_date),
                    codigo_acceso: booking.booking_code,
                    link_abrir_app: `https://bf-stay.pages.dev/booking/${booking_id}`,
                    num_huespedes: String(booking.num_guests ?? 1),
                  },
                  booking_id,
                }),
              }
            );
            emailResult = await emailResponse.json();

            await supabaseAdmin.from('bookings')
              .update({ code_sent_at: new Date().toISOString() })
              .eq('id', booking_id);
          }
        } catch (e) {
          emailResult = { error: 'email_failed', message: String(e) };
        }
      }

      return json({ success: true, new_code: newCode, email_sent: !emailResult.skipped && !emailResult.error, email_result: emailResult }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // list_bookings
    // ═══════════════════════════════════════════════════════
    if (action === 'list_bookings') {
      const { property_id, status_filter, date_from, date_to, page = 1, per_page = 20 } = body;

      let query = supabaseAdmin
        .from('admin_bookings_dashboard')
        .select('*')
        .order('checkin_date', { ascending: true })
        .range((page - 1) * per_page, page * per_page - 1);

      const allowedPropertyId = roleData.role === 'staff' ? roleData.property_id : property_id;
      if (allowedPropertyId) query = query.eq('property_id', allowedPropertyId);
      if (status_filter)     query = query.eq('booking_status', status_filter);
      if (date_from)         query = query.gte('checkin_date', date_from);
      if (date_to)           query = query.lte('checkin_date', date_to);

      const { data: bookings, error: listError } = await query;
      if (listError) return json({ error: 'query_error', message: listError.message }, 500, corsHeaders);
      return json({ success: true, bookings: bookings ?? [] }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // validate_checkin
    // ═══════════════════════════════════════════════════════
    if (action === 'validate_checkin') {
      const { checkin_id, booking_id } = body;
      if (!checkin_id || !booking_id) return json({ error: 'missing_fields' }, 422, corsHeaders);

      const { error } = await supabaseAdmin.from('checkins')
        .update({ status: 'validated', validated_at: new Date().toISOString() })
        .eq('id', checkin_id).eq('status', 'submitted');

      if (error) return json({ error: 'update_error', message: error.message }, 500, corsHeaders);
      return json({ success: true, message: 'Check-in validado correctamente' }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // reject_checkin
    // ═══════════════════════════════════════════════════════
    if (action === 'reject_checkin') {
      const { checkin_id, booking_id, rejection_reason } = body;
      if (!checkin_id) return json({ error: 'missing_fields' }, 422, corsHeaders);

      const { error } = await supabaseAdmin.from('checkins')
        .update({ status: 'rejected', rejected_at: new Date().toISOString(), rejection_reason: rejection_reason ?? 'Documentación insuficiente' })
        .eq('id', checkin_id);

      if (error) return json({ error: 'update_error', message: error.message }, 500, corsHeaders);

      if (booking_id) {
        await supabaseAdmin.from('bookings').update({ status: 'confirmed' }).eq('id', booking_id);
      }

      return json({ success: true }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // list_units
    // ═══════════════════════════════════════════════════════
    if (action === 'list_units') {
      const { property_id } = body;
      const targetPropId = roleData.role === 'staff' ? roleData.property_id : property_id;

      const { data: units, error } = await supabaseAdmin
        .from('units')
        .select('id, name, unit_type, city, address_line1, max_guests')
        .eq('property_id', targetPropId)
        .order('name');

      if (error) return json({ error: 'query_error', message: error.message }, 500, corsHeaders);
      return json({ success: true, units: units ?? [] }, 200, corsHeaders);
    }

    // ═══════════════════════════════════════════════════════
    // get_notifications
    // ═══════════════════════════════════════════════════════
    if (action === 'get_notifications') {
      const propertyId = roleData.role === 'staff' ? roleData.property_id : body.property_id;

      let query = supabaseAdmin
        .from('staff_notifications')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(50);

      if (propertyId) query = query.eq('property_id', propertyId);

      const { data: notifications, error } = await query;
      if (error) return json({ error: 'query_error', message: error.message }, 500, corsHeaders);

      const unreadIds = (notifications ?? []).filter((n: { is_read: boolean }) => !n.is_read).map((n: { id: string }) => n.id);
      if (unreadIds.length > 0) {
        await supabaseAdmin.from('staff_notifications').update({ is_read: true }).in('id', unreadIds);
      }

      return json({ success: true, notifications: notifications ?? [] }, 200, corsHeaders);
    }

    return json({ error: 'unknown_action', message: `Acción desconocida: ${action}` }, 422, corsHeaders);

  } catch (err) {
    console.error('admin-panel error:', err);
    return json({ error: 'server_error', message: 'Error interno del servidor' }, 500, corsHeaders);
  }
});

// Helpers

function formatDateShort(dateStr: string): string {
  const [year, month, day] = dateStr.split('-');
  return `${day}/${month}/${year}`;
}

function json(data: unknown, status: number, headers: Record<string, string>) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...headers, 'Content-Type': 'application/json' },
  });
}
