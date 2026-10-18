-- MONO FINDS - MIGRASI: teks website yang bisa diedit + status tampil produk
-- Jalankan SEKALI di Supabase Dashboard > SQL Editor.
-- Aman dijalankan berulang: tidak menghapus data yang sudah ada.

-- 1) Tabel pengaturan teks website (key-value).
create table if not exists public.site_settings (
  key text primary key,
  value text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.site_settings enable row level security;

drop policy if exists "Public read site settings" on public.site_settings;
drop policy if exists "Admins manage site settings" on public.site_settings;

-- Semua orang boleh membaca teks website.
create policy "Public read site settings"
on public.site_settings for select to anon, authenticated using (true);

-- Hanya admin terdaftar yang boleh mengubah teks website.
create policy "Admins manage site settings"
on public.site_settings for all to authenticated
using ((select private.is_mono_admin()))
with check ((select private.is_mono_admin()));

grant select on public.site_settings to anon;
grant select, insert, update, delete on public.site_settings to authenticated;

-- 2) Nilai awal teks website.
--    "on conflict do nothing" => teks yang sudah kamu ubah TIDAK akan tertimpa.
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

-- 3) Pastikan kolom is_active ada (untuk tombol tampil/sembunyikan produk).
alter table public.products
  add column if not exists is_active boolean not null default true;

-- Selesai. Buka /admin.html lalu login untuk mengedit teks dan status produk.
