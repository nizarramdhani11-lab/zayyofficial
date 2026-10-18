-- MONO FINDS - Supabase setup (admin access restricted)
-- Run in Supabase Dashboard > SQL Editor.
-- Safe to rerun: does not delete existing product data.

create extension if not exists pgcrypto;

create table if not exists public.collections (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null default '',
  created_at timestamptz not null default now(),
  constraint collections_code_format check (code ~ '^[A-Z0-9_-]{3,40}$')
);

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  collection_id uuid not null references public.collections(id) on delete cascade,
  name text not null,
  price numeric(12,2) not null default 0 check (price >= 0),
  category text not null default '',
  variants text not null default '',
  image_url text,
  affiliate_url text,
  description text not null default '',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Admin accounts are added manually by the project owner in SQL Editor.
create table if not exists public.mono_admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

alter table public.collections enable row level security;
alter table public.products enable row level security;
alter table public.mono_admin_users enable row level security;

-- Security-definer helper checks the signed-in user's UUID against the admin list.
create schema if not exists private;
create or replace function private.is_mono_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.mono_admin_users
    where user_id = (select auth.uid())
  );
$$;
revoke all on function private.is_mono_admin() from public;
revoke all on function private.is_mono_admin() from anon;
grant usage on schema private to authenticated;
grant execute on function private.is_mono_admin() to authenticated;

-- Remove the old overly-permissive policies.
drop policy if exists "Public can read collections" on public.collections;
drop policy if exists "Public can read active products" on public.products;
drop policy if exists "Authenticated admins manage collections" on public.collections;
drop policy if exists "Authenticated admins manage products" on public.products;
drop policy if exists "Public read collections" on public.collections;
drop policy if exists "Public read active products" on public.products;
drop policy if exists "Admins manage collections" on public.collections;
drop policy if exists "Admins manage products" on public.products;
drop policy if exists "Admins read admin list" on public.mono_admin_users;

create policy "Public read collections"
on public.collections for select to anon, authenticated using (true);

create policy "Public read active products"
on public.products for select to anon, authenticated using (is_active = true);

create policy "Admins manage collections"
on public.collections for all to authenticated
using ((select private.is_mono_admin()))
with check ((select private.is_mono_admin()));

create policy "Admins manage products"
on public.products for all to authenticated
using ((select private.is_mono_admin()))
with check ((select private.is_mono_admin()));

create policy "Admins read admin list"
on public.mono_admin_users for select to authenticated
using ((select private.is_mono_admin()));

grant select on public.collections, public.products to anon;
grant select, insert, update, delete on public.collections, public.products to authenticated;
grant select on public.mono_admin_users to authenticated;
revoke all on public.mono_admin_users from anon;
revoke insert, update, delete on public.mono_admin_users from anon, authenticated;

create index if not exists products_collection_id_idx on public.products(collection_id);
create index if not exists products_active_idx on public.products(is_active);

insert into public.collections (code, name, description) values
('BOYSTYLE01', 'Boys Style — Polo', 'Kaos polo pria'),
('BOYSTYLE02', 'Boys Style — Sneakers', 'Sepatu pilihan')
on conflict (code) do update
set name = excluded.name, description = excluded.description;

insert into public.products
(collection_id, name, price, category, variants, image_url, affiliate_url, description, is_active)
select c.id, 'Kaos Polo Pria Onion', 115000, 'Fashion pria',
       'Black, Brown, Ivory, Green', null, null, '', true
from public.collections c
where c.code = 'BOYSTYLE01'
and not exists (
  select 1 from public.products p
  where p.name = 'Kaos Polo Pria Onion' and p.collection_id = c.id
);

insert into public.products
(collection_id, name, price, category, variants, image_url, affiliate_url, description, is_active)
select c.id, 'Ventela [Original] V23 Low White Brown', 293080, 'Sepatu',
       'White Brown', null,
       'https://vt.tokopedia.com/t/ZS9UmmrNJhsKM-yhh3b/',
       'Harga sesuai informasi produk yang diberikan', true
from public.collections c
where c.code = 'BOYSTYLE02'
and not exists (
  select 1 from public.products p
  where p.name = 'Ventela [Original] V23 Low White Brown' and p.collection_id = c.id
);

-- Editable website text (key-value). Public read, admin write.
create table if not exists public.site_settings (
  key text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.site_settings enable row level security;

drop policy if exists "Public read site settings" on public.site_settings;
drop policy if exists "Admins manage site settings" on public.site_settings;

create policy "Public read site settings"
on public.site_settings for select to anon, authenticated using (true);

create policy "Admins manage site settings"
on public.site_settings for all to authenticated
using ((select private.is_mono_admin()))
with check ((select private.is_mono_admin()));

grant select on public.site_settings to anon;
grant select, insert, update, delete on public.site_settings to authenticated;

insert into public.site_settings (key, value) values
  ('brand_primary',      'MONO'),
  ('brand_accent',       'FINDS'),
  ('logo_url',           ''),
  ('topnote',            'CURATED EVERYDAY FINDS'),
  ('hero_eyebrow',       'A LITTLE LESS NOISE, BETTER FINDS.'),
  ('hero_title',         E'Temukan pilihanmu.\nTanpa ribet.'),
  ('hero_lead',          'Koleksi pilihan untuk gaya sehari-hari. Masukkan kode koleksi untuk menemukan produk yang kamu cari.'),
  ('search_placeholder', 'Masukkan kode koleksi, mis. BOYSTYLE01'),
  ('search_button',      'Cari kode'),
  ('search_hint',        'Coba: BOYSTYLE01 atau BOYSTYLE02'),
  ('collection_eyebrow', 'KOLEKSI PILIHAN'),
  ('collection_title',   'Semua produk'),
  ('footer_left',        'MONO FINDS'),
  ('footer_right',       'SIMPLE FINDS. EVERYDAY STYLE.')
on conflict (key) do nothing;

-- AFTER THIS SQL SUCCEEDS:
-- 1. Create your account in Supabase Authentication > Users.
-- 2. Copy that user's UUID.
-- 3. Replace the placeholder and run this separately in SQL Editor:
-- insert into public.mono_admin_users (user_id)
-- values ('PASTE_ADMIN_USER_UUID_HERE');
