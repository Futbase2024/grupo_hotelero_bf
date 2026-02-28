-- 20260226190000_global_unique_booking_code.sql
-- Migra el índice único de booking_code de propiedad-escópico a global
-- y actualiza las funciones RPC para garantizar códigos únicos globalmente

-- ═══════════════════════════════════════════════════════════════
-- 1. Eliminar índice único anterior (property_id, booking_code)
-- ═══════════════════════════════════════════════════════════════
drop index if exists public.bookings_property_code_idx;

-- ═══════════════════════════════════════════════════════════════
-- 2. Crear nuevo índice único GLOBAL en booking_code
-- ═══════════════════════════════════════════════════════════════
create unique index if not exists bookings_booking_code_unique_idx
on public.bookings(booking_code);

-- ═══════════════════════════════════════════════════════════════
-- 3. Función auxiliar: generar código único global
-- ═══════════════════════════════════════════════════════════════
-- Genera códigos en formato BF-XXXX-XXXX donde X es alfanumérico
-- Reintenta hasta encontrar un código que no exista (máximo 100 intentos)
create or replace function public.generate_unique_booking_code()
returns text
language plpgsql
as $$
declare
  v_code text;
  v_attempts int := 0;
  v_max_attempts int := 100;
  v_chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Sin I, O, 0, 1 para evitar confusiones
begin
  loop
    v_attempts := v_attempts + 1;

    if v_attempts > v_max_attempts then
      raise exception 'No se pudo generar un código único después de % intentos', v_max_attempts;
    end if;

    -- Generar código: BF-XXXX-XXXX
    v_code := 'BF-' ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      '-' ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1) ||
      substr(v_chars, floor(random() * length(v_chars) + 1)::int, 1);

    -- Verificar que no existe
    if not exists (select 1 from public.bookings where booking_code = v_code) then
      return v_code;
    end if;
  end loop;
end;
$$;

-- ═══════════════════════════════════════════════════════════════
-- 4. Función RPC: crear reserva con código único global
-- ═══════════════════════════════════════════════════════════════
create or replace function public.create_booking_with_code(
  p_property_id      uuid,
  p_unit_id          uuid,
  p_checkin_date     date,
  p_checkout_date    date,
  p_num_guests       int,
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
begin
  -- Generar código único global
  v_booking_code := public.generate_unique_booking_code();

  -- Crear la reserva
  insert into public.bookings (
    property_id,
    unit_id,
    booking_code,
    last_name,
    checkin_date,
    checkout_date,
    status,
    num_guests,
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
    p_num_guests,
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
    'num_guests',    p_num_guests,
    'status',        'confirmed'
  );
end;
$$;

revoke all on function public.create_booking_with_code(uuid, uuid, date, date, int, text, text, text, text, text) from public;
grant execute on function public.create_booking_with_code(uuid, uuid, date, date, int, text, text, text, text, text) to service_role;

-- ═══════════════════════════════════════════════════════════════
-- 5. Función RPC: regenerar código único global
-- ═══════════════════════════════════════════════════════════════
create or replace function public.regenerate_booking_code(p_booking_id uuid)
returns text
language plpgsql
security definer
as $$
declare
  v_new_code text;
begin
  -- Generar nuevo código único global
  v_new_code := public.generate_unique_booking_code();

  -- Actualizar la reserva
  update public.bookings
  set booking_code = v_new_code
  where id = p_booking_id;

  if not found then
    raise exception 'booking_not_found';
  end if;

  return v_new_code;
end;
$$;

revoke all on function public.regenerate_booking_code(uuid) from public;
grant execute on function public.regenerate_booking_code(uuid) to service_role;

-- ═══════════════════════════════════════════════════════════════
-- 6. Comentario documental
-- ═══════════════════════════════════════════════════════════════
comment on function public.generate_unique_booking_code() is
'Genera un código de reserva único global en formato BF-XXXX-XXXX. Usa caracteres alfanuméricos sin I, O, 0, 1 para evitar confusiones. Reintenta hasta encontrar un código disponible (máx 100 intentos).';

comment on function public.create_booking_with_code(uuid, uuid, date, date, int, text, text, text, text, text) is
'Crea una nueva reserva con un código de acceso único global. El código se genera automáticamente y se garantiza que no existe en ninguna otra reserva del sistema.';

comment on function public.regenerate_booking_code(uuid) is
'Regenera el código de acceso de una reserva existente. El nuevo código es único globalmente.';
