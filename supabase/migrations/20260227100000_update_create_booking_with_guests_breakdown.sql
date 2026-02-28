-- 20260227100000_update_create_booking_with_guests_breakdown.sql
-- Actualiza la función RPC create_booking_with_code para aceptar el desglose de huéspedes
-- (num_adults, num_children, children_ages) en lugar de solo num_guests

-- ═══════════════════════════════════════════════════════════════
-- Actualizar función RPC: crear reserva con desglose de huéspedes
-- ═══════════════════════════════════════════════════════════════
create or replace function public.create_booking_with_code(
  p_property_id      uuid,
  p_unit_id          uuid,
  p_checkin_date     date,
  p_checkout_date    date,
  p_num_adults       int default 1,
  p_num_children     int default 0,
  p_children_ages    int[] default '{}',
  p_last_name        text,
  p_staff_notes      text default null,
  p_guest_first_name text default null,
  p_guest_email      text default null,
  p_guest_phone      text default null
)
returns jsonb
language plpgsql
security definer
as $$
declare
  v_booking_id    uuid;
  v_booking_code  text;
  v_checkin_id    uuid;
  v_num_guests    int;
begin
  -- Calcular total de huéspedes
  v_num_guests := coalesce(p_num_adults, 1) + coalesce(p_num_children, 0);

  -- Generar código único global
  v_booking_code := public.generate_unique_booking_code();

  -- Crear la reserva con el desglose de huéspedes
  insert into public.bookings (
    property_id,
    unit_id,
    booking_code,
    last_name,
    checkin_date,
    checkout_date,
    status,
    num_guests,
    num_adults,
    num_children,
    children_ages,
    staff_notes,
    guest_first_name,
    guest_email,
    guest_phone
  ) values (
    p_property_id,
    p_unit_id,
    v_booking_code,
    p_last_name,
    p_checkin_date,
    p_checkout_date,
    'confirmed',
    v_num_guests,
    coalesce(p_num_adults, 1),
    coalesce(p_num_children, 0),
    coalesce(p_children_ages, '{}'),
    p_staff_notes,
    p_guest_first_name,
    p_guest_email,
    p_guest_phone
  )
  returning id into v_booking_id;

  -- Crear el check-in en estado draft
  insert into public.checkins (booking_id, status)
  values (v_booking_id, 'draft')
  returning id into v_checkin_id;

  -- Retornar resultado
  return jsonb_build_object(
    'booking_id',    v_booking_id,
    'booking_code',  v_booking_code,
    'checkin_id',    v_checkin_id,
    'property_id',   p_property_id,
    'unit_id',       p_unit_id,
    'checkin_date',  p_checkin_date,
    'checkout_date', p_checkout_date,
    'num_guests',    v_num_guests,
    'num_adults',    coalesce(p_num_adults, 1),
    'num_children',  coalesce(p_num_children, 0),
    'children_ages', coalesce(p_children_ages, '{}'),
    'status',        'confirmed'
  );
end;
$$;

-- Revocar y conceder permisos (nota: la firma de la función ha cambiado)
revoke all on function public.create_booking_with_code(uuid, uuid, date, date, int, int, int[], text, text, text, text, text) from public;
grant execute on function public.create_booking_with_code(uuid, uuid, date, date, int, int, int[], text, text, text, text, text) to service_role;

-- Comentario documental
comment on function public.create_booking_with_code(uuid, uuid, date, date, int, int, int[], text, text, text, text, text) is
'Crea una nueva reserva con un código de acceso único global. Ahora incluye desglose de huéspedes: num_adults, num_children y children_ages para saber las edades de los niños.';
