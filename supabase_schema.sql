-- 0001_bf_stay_init.sql
-- BF Stay (Grupo Hotelero BF) - Supabase schema + RLS + RPC + seed
-- Requires: Supabase default schema + auth.users available

-- Extensions
create extension if not exists "pgcrypto";

-- =========================
-- 1) Helper: roles & access
-- =========================

-- Roles for auth users
create table if not exists public.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('guest','staff','admin')),
  property_id uuid null, -- staff is typically scoped to a property
  created_at timestamptz not null default now()
);

alter table public.user_roles enable row level security;

-- Helper function: current role
create or replace function public.current_role()
returns text
language sql
stable
as $$
  select coalesce((select role from public.user_roles where user_id = auth.uid()), 'guest');
$$;

-- Helper: current property for staff (nullable)
create or replace function public.current_property_id()
returns uuid
language sql
stable
as $$
  select (select property_id from public.user_roles where user_id = auth.uid());
$$;

-- Helper: is admin
create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select public.current_role() = 'admin';
$$;

-- Helper: is staff
create or replace function public.is_staff()
returns boolean
language sql
stable
as $$
  select public.current_role() in ('staff','admin');
$$;

-- =========================
-- 2) Core: properties & units
-- =========================

create table if not exists public.properties (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text,
  city text,
  country text default 'ES',
  timezone text default 'Europe/Madrid',
  lat double precision,
  lng double precision,
  created_at timestamptz not null default now()
);

create table if not exists public.units (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  name text not null,                 -- "Apto 2B", "Habitación 101"
  unit_type text not null default 'apartment', -- apartment/room
  box_location_text text,             -- ubicación de la caja
  box_code text,                      -- código (ver notas seguridad + RPC)
  access_instructions text,           -- instrucciones generales
  created_at timestamptz not null default now()
);

alter table public.properties enable row level security;
alter table public.units enable row level security;

-- =========================
-- 3) Bookings & guests
-- =========================

create table if not exists public.bookings (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  unit_id uuid not null references public.units(id) on delete restrict,

  booking_code text not null,  -- lo que da el hotel al huésped
  last_name text not null,     -- para validar acceso por "código + apellido"

  checkin_date date not null,
  checkout_date date not null,

  status text not null default 'confirmed'
    check (status in ('confirmed','checked_in','checked_out','cancelled')),

  primary_guest_user_id uuid null references auth.users(id) on delete set null,

  created_at timestamptz not null default now()
);

create unique index if not exists bookings_property_code_idx
on public.bookings(property_id, booking_code);

create table if not exists public.guests (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  email text,
  phone text,
  document_number text,    -- opcional (si OCR extrae)
  document_type text,      -- DNI/PASSPORT/OTHER
  nationality text,
  birth_date date,
  created_at timestamptz not null default now()
);

-- Many-to-many between bookings and guests
create table if not exists public.booking_guests (
  booking_id uuid not null references public.bookings(id) on delete cascade,
  guest_id uuid not null references public.guests(id) on delete cascade,
  is_primary boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (booking_id, guest_id)
);

alter table public.bookings enable row level security;
alter table public.guests enable row level security;
alter table public.booking_guests enable row level security;

-- ======================================
-- 4) Check-in, documents, signature, PDF
-- ======================================

create table if not exists public.checkins (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,

  status text not null default 'draft'
    check (status in ('draft','submitted','validated','rejected')),

  submitted_at timestamptz,
  validated_at timestamptz,
  rejected_at timestamptz,
  rejection_reason text,

  signature_svg text,          -- firma del titular (svg path)
  checkin_pdf_path text,       -- storage path del PDF generado

  created_at timestamptz not null default now()
);

-- Documents metadata; actual files go to Supabase Storage (private bucket)
create table if not exists public.guest_documents (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  guest_id uuid null references public.guests(id) on delete set null,

  doc_kind text not null check (doc_kind in ('dni_front','dni_back','passport','other')),
  storage_path text not null,          -- e.g. guest-documents/<booking>/<uuid>.jpg
  mime_type text,
  uploaded_by uuid not null references auth.users(id) on delete cascade,

  created_at timestamptz not null default now()
);

alter table public.checkins enable row level security;
alter table public.guest_documents enable row level security;

-- =========================
-- 5) Digital guide (wifi, jacuzzi, etc.)
-- =========================

create table if not exists public.guide_items (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  unit_id uuid null references public.units(id) on delete cascade, -- null = global property
  category text not null,        -- wifi, jacuzzi, rules, manuals, emergency
  title text not null,
  body text,                     -- markdown/text
  media_path text,               -- optional storage path
  sort_order int not null default 0,
  is_published boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.guide_items enable row level security;

-- =========================
-- 6) Chat (realtime)
-- =========================

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  booking_id uuid null references public.bookings(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('guest','staff','admin')),
  created_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_user_id uuid not null references auth.users(id) on delete cascade,
  msg_type text not null default 'text' check (msg_type in ('text','image')),
  content text not null, -- text or storage path for image
  created_at timestamptz not null default now()
);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.messages enable row level security;

-- =========================
-- 7) Payments (BBVA/Redsys)
-- =========================

create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  amount_cents int not null check (amount_cents > 0),
  currency text not null default 'EUR',
  concept text,
  status text not null default 'created'
    check (status in ('created','pending','paid','failed','refunded','cancelled')),
  provider text not null default 'redsys',
  transaction_id text,
  raw_payload jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists payments_touch_updated_at on public.payments;
create trigger payments_touch_updated_at
before update on public.payments
for each row execute procedure public.touch_updated_at();

alter table public.payments enable row level security;

-- =========================
-- 8) Reviews
-- =========================

create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  published boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;

-- =========================
-- 9) Incidents / tickets
-- =========================

create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(),
  property_id uuid not null references public.properties(id) on delete cascade,
  booking_id uuid null references public.bookings(id) on delete set null,
  created_by uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  created_at timestamptz not null default now()
);

alter table public.incidents enable row level security;

-- =========================
-- 10) RLS Policies
-- =========================

-- user_roles
drop policy if exists "user_roles_select_own" on public.user_roles;
create policy "user_roles_select_own" on public.user_roles
for select using (user_id = auth.uid() or public.is_admin());

drop policy if exists "user_roles_admin_manage" on public.user_roles;
create policy "user_roles_admin_manage" on public.user_roles
for all using (public.is_admin()) with check (public.is_admin());

-- properties
drop policy if exists "properties_staff_select" on public.properties;
create policy "properties_staff_select" on public.properties
for select using (
  public.is_staff()
  and (public.is_admin() or id = public.current_property_id())
);

-- units
drop policy if exists "units_staff_select" on public.units;
create policy "units_staff_select" on public.units
for select using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

drop policy if exists "units_staff_manage" on public.units;
create policy "units_staff_manage" on public.units
for all using (public.is_staff() and (public.is_admin() or property_id = public.current_property_id()))
with check (public.is_staff() and (public.is_admin() or property_id = public.current_property_id()));

-- bookings
drop policy if exists "bookings_guest_select_own" on public.bookings;
create policy "bookings_guest_select_own" on public.bookings
for select using (
  primary_guest_user_id = auth.uid()
);

drop policy if exists "bookings_staff_select_property" on public.bookings;
create policy "bookings_staff_select_property" on public.bookings
for select using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

drop policy if exists "bookings_staff_manage_property" on public.bookings;
create policy "bookings_staff_manage_property" on public.bookings
for all using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
)
with check (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

-- guests (staff only; guest can read only those linked to their booking via view/RPC if desired)
drop policy if exists "guests_staff_select" on public.guests;
create policy "guests_staff_select" on public.guests
for select using (public.is_staff());

drop policy if exists "guests_staff_manage" on public.guests;
create policy "guests_staff_manage" on public.guests
for all using (public.is_staff()) with check (public.is_staff());

-- booking_guests (staff manage; guests not direct)
drop policy if exists "booking_guests_staff_all" on public.booking_guests;
create policy "booking_guests_staff_all" on public.booking_guests
for all using (public.is_staff()) with check (public.is_staff());

-- checkins
drop policy if exists "checkins_guest_select_own" on public.checkins;
create policy "checkins_guest_select_own" on public.checkins
for select using (
  exists (
    select 1 from public.bookings b
    where b.id = checkins.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "checkins_guest_update_own" on public.checkins;
create policy "checkins_guest_update_own" on public.checkins
for update using (
  exists (
    select 1 from public.bookings b
    where b.id = checkins.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
)
with check (
  exists (
    select 1 from public.bookings b
    where b.id = checkins.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "checkins_staff_all" on public.checkins;
create policy "checkins_staff_all" on public.checkins
for all using (
  public.is_staff()
  and exists (
    select 1 from public.bookings b
    where b.id = checkins.booking_id
      and (public.is_admin() or b.property_id = public.current_property_id())
  )
)
with check (
  public.is_staff()
  and exists (
    select 1 from public.bookings b
    where b.id = checkins.booking_id
      and (public.is_admin() or b.property_id = public.current_property_id())
  )
);

-- guest_documents
drop policy if exists "guest_documents_guest_select_own" on public.guest_documents;
create policy "guest_documents_guest_select_own" on public.guest_documents
for select using (
  exists (
    select 1 from public.bookings b
    where b.id = guest_documents.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "guest_documents_guest_insert_own" on public.guest_documents;
create policy "guest_documents_guest_insert_own" on public.guest_documents
for insert with check (
  exists (
    select 1 from public.bookings b
    where b.id = guest_documents.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
  and uploaded_by = auth.uid()
);

drop policy if exists "guest_documents_staff_all" on public.guest_documents;
create policy "guest_documents_staff_all" on public.guest_documents
for all using (
  public.is_staff()
) with check (
  public.is_staff()
);

-- guide_items
drop policy if exists "guide_items_guest_select_published" on public.guide_items;
create policy "guide_items_guest_select_published" on public.guide_items
for select using (
  is_published = true
);

drop policy if exists "guide_items_staff_manage" on public.guide_items;
create policy "guide_items_staff_manage" on public.guide_items
for all using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
)
with check (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

-- conversations
drop policy if exists "conversations_participant_select" on public.conversations;
create policy "conversations_participant_select" on public.conversations
for select using (
  exists (
    select 1 from public.conversation_participants p
    where p.conversation_id = conversations.id
      and p.user_id = auth.uid()
  )
);

drop policy if exists "conversations_staff_manage_property" on public.conversations;
create policy "conversations_staff_manage_property" on public.conversations
for all using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
)
with check (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

-- conversation_participants
drop policy if exists "participants_select_own_conversations" on public.conversation_participants;
create policy "participants_select_own_conversations" on public.conversation_participants
for select using (
  user_id = auth.uid()
  or exists (
    select 1 from public.conversation_participants p2
    where p2.conversation_id = conversation_participants.conversation_id
      and p2.user_id = auth.uid()
      and public.is_staff()
  )
);

drop policy if exists "participants_staff_manage" on public.conversation_participants;
create policy "participants_staff_manage" on public.conversation_participants
for all using (public.is_staff()) with check (public.is_staff());

-- messages
drop policy if exists "messages_select_if_participant" on public.messages;
create policy "messages_select_if_participant" on public.messages
for select using (
  exists (
    select 1 from public.conversation_participants p
    where p.conversation_id = messages.conversation_id
      and p.user_id = auth.uid()
  )
);

drop policy if exists "messages_insert_if_participant" on public.messages;
create policy "messages_insert_if_participant" on public.messages
for insert with check (
  sender_user_id = auth.uid()
  and exists (
    select 1 from public.conversation_participants p
    where p.conversation_id = messages.conversation_id
      and p.user_id = auth.uid()
  )
);

-- payments
drop policy if exists "payments_guest_select_own" on public.payments;
create policy "payments_guest_select_own" on public.payments
for select using (
  exists (
    select 1 from public.bookings b
    where b.id = payments.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "payments_staff_select_property" on public.payments;
create policy "payments_staff_select_property" on public.payments
for select using (
  public.is_staff()
  and exists (
    select 1 from public.bookings b
    where b.id = payments.booking_id
      and (public.is_admin() or b.property_id = public.current_property_id())
  )
);

drop policy if exists "payments_staff_manage" on public.payments;
create policy "payments_staff_manage" on public.payments
for all using (
  public.is_staff()
) with check (
  public.is_staff()
);

-- reviews
drop policy if exists "reviews_guest_insert_own" on public.reviews;
create policy "reviews_guest_insert_own" on public.reviews
for insert with check (
  exists (
    select 1 from public.bookings b
    where b.id = reviews.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "reviews_guest_select_own" on public.reviews;
create policy "reviews_guest_select_own" on public.reviews
for select using (
  exists (
    select 1 from public.bookings b
    where b.id = reviews.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "reviews_staff_all" on public.reviews;
create policy "reviews_staff_all" on public.reviews
for all using (public.is_staff()) with check (public.is_staff());

-- incidents
drop policy if exists "incidents_guest_select_own" on public.incidents;
create policy "incidents_guest_select_own" on public.incidents
for select using (
  booking_id is not null
  and exists (
    select 1 from public.bookings b
    where b.id = incidents.booking_id
      and b.primary_guest_user_id = auth.uid()
  )
);

drop policy if exists "incidents_guest_insert_own" on public.incidents;
create policy "incidents_guest_insert_own" on public.incidents
for insert with check (
  created_by = auth.uid()
  and (
    booking_id is null
    or exists (
      select 1 from public.bookings b
      where b.id = incidents.booking_id
        and b.primary_guest_user_id = auth.uid()
    )
  )
);

drop policy if exists "incidents_staff_all" on public.incidents;
create policy "incidents_staff_all" on public.incidents
for all using (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
)
with check (
  public.is_staff()
  and (public.is_admin() or property_id = public.current_property_id())
);

-- =========================
-- 11) RPC for Access (caja llaves)
-- =========================
-- Security: DEFINER + checks date + checkin validated + booking ownership
-- NOTE: This returns box_code stored in units.box_code. For higher security:
-- store encrypted/rotating codes or keep it only in a secrets vault.
create or replace function public.get_access_for_booking(p_booking_id uuid)
returns table (
  unit_name text,
  box_location text,
  box_code text,
  instructions text
)
language plpgsql
security definer
as $$
declare
  b record;
  u record;
  c record;
begin
  -- ensure booking exists and belongs to caller
  select * into b from public.bookings where id = p_booking_id;
  if not found then
    raise exception 'booking_not_found';
  end if;

  if b.primary_guest_user_id <> auth.uid() and not public.is_staff() then
    raise exception 'not_allowed';
  end if;

  -- check dates: only allow on/after checkin_date and before checkout_date
  if current_date < b.checkin_date or current_date >= b.checkout_date then
    raise exception 'outside_access_window';
  end if;

  -- check checkin validated
  select * into c from public.checkins where booking_id = b.id;
  if not found or c.status <> 'validated' then
    raise exception 'checkin_not_validated';
  end if;

  select * into u from public.units where id = b.unit_id;

  return query
  select
    u.name,
    u.box_location_text,
    u.box_code,
    coalesce(u.access_instructions,'')
  ;
end;
$$;

revoke all on function public.get_access_for_booking(uuid) from public;
grant execute on function public.get_access_for_booking(uuid) to authenticated;

-- =========================
-- 12) Seed data (minimal)
-- =========================
-- Create a demo property + unit + guide items.
-- NOTE: This does NOT create auth users. Assign roles from dashboard/admin SQL after creating users.

insert into public.properties (id, name, address, city, country, timezone, lat, lng)
values
  ('11111111-1111-1111-1111-111111111111', 'BF Stay Demo Property', 'Calle Demo 1', 'Jerez de la Frontera', 'ES', 'Europe/Madrid', 36.6850, -6.1260)
on conflict (id) do nothing;

insert into public.units (id, property_id, name, unit_type, box_location_text, box_code, access_instructions)
values
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'Apartamento 1A', 'apartment',
   'Caja negra en la pared junto a la puerta principal.', '1234',
   'Introduce el código, tira de la pestaña y retira la llave. Vuelve a guardar la llave al salir.')
on conflict (id) do nothing;

insert into public.guide_items (property_id, unit_id, category, title, body, sort_order, is_published)
values
  ('11111111-1111-1111-1111-111111111111', null, 'wifi', 'WiFi', 'SSID: BFStay_Guest\nClave: BF2026!', 1, true),
  ('11111111-1111-1111-1111-111111111111', null, 'rules', 'Normas', 'No fumar. Respeta el descanso. Check-out a las 11:00.', 2, true),
  ('11111111-1111-1111-1111-111111111111', null, 'jacuzzi', 'Jacuzzi', '1) Llenar agua\n2) Botón JET\n3) Apagar al terminar', 3, true),
  ('11111111-1111-1111-1111-111111111111', null, 'emergency', 'Emergencias', '112\nRecepción: +34 XXX XXX XXX', 4, true)
on conflict do nothing;
