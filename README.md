# MONO FINDS — Paket Website + Database

Paket ini berisi website katalog publik, dashboard admin, konfigurasi Supabase, dan SQL setup database dengan akses tulis terbatas untuk admin terdaftar.

## Isi paket
- `index.html`: katalog publik dengan pencarian kode koleksi.
- `admin.html`: dashboard admin untuk login, mengelola koleksi, produk, dan **teks website**.
- `app.js`, `admin.js`, `style.css`: kode website.
- `config.js`: tempat URL project Supabase dan publishable/anon key.
- `SETUP_SUPABASE.sql` / `supabase_schema.sql`: SQL setup lengkap (untuk instalasi baru).
- `MIGRASI_UPDATE.sql`: migrasi untuk database yang **sudah** menjalankan setup sebelumnya (menambah tabel `site_settings`).

## Cara setup

### 1. Siapkan Supabase
1. Buka project Supabase yang ingin digunakan.
2. Buka SQL Editor.
3. Buka `SETUP_SUPABASE.sql`, salin seluruh isinya, tempel di SQL Editor, lalu tekan **Run**.
   - Sudah pernah menjalankan setup sebelumnya? Cukup jalankan `MIGRASI_UPDATE.sql`.
4. Buka **Project Settings → API**. Salin Project URL dan publishable key/anon key publik.

### 2. Buat akun admin
1. Di Supabase, buka **Authentication → Users** lalu buat user dengan email yang kamu kuasai dan password kuat.
2. Salin UUID/ID user tersebut.
3. Kembali ke SQL Editor, jalankan query berikut dengan mengganti UUID contoh:

```sql
insert into public.mono_admin_users (user_id)
values ('GANTI_DENGAN_UUID_USER_ADMIN');
```

Jangan kirim password atau secret key ke siapa pun. Jangan menaruh `service_role` key atau secret key di file website.

### 3. Isi konfigurasi website
Edit `config.js` dan isi `SUPABASE_URL` serta `SUPABASE_ANON_KEY` dengan nilai dari Supabase.
Nama variabel harus tetap `window.MONO_CONFIG` karena dibaca oleh `app.js` dan `admin.js`.

### 4. Deploy website
Unggah semua file di folder ini ke hosting statis, misalnya Vercel. Pastikan `index.html`, `admin.html`, `config.js`, `app.js`, `admin.js`, dan `style.css` berada pada root folder yang sama. Setelah deploy, uji halaman utama dan `/admin.html`.

## Yang bisa diubah dari admin (tanpa edit kode)

**Teks website** (panel "Teks website"):
- Nama brand (tebal + aksen) dan URL logo.
- Catatan header, label koleksi, judul hero kecil, judul hero, deskripsi hero.
- Placeholder pencarian, teks tombol cari, petunjuk pencarian.
- Judul koleksi default, teks footer kiri dan kanan.

**Koleksi**: tambah, edit, hapus.

**Produk**: tambah, edit, hapus, dan **tampilkan/sembunyikan** dari katalog publik
(produk dengan status "Disembunyikan" tidak muncul di halaman publik).

## Logo
Header memakai logo bawaan (monogram "M") bila kolom **URL logo** dikosongkan.
Isi URL gambar HTTPS untuk memakai logo sendiri. Gunakan gambar persegi/transparan
agar tampil rapi (disarankan minimal 64×64 px).

## Data awal
- Koleksi `BOYSTYLE01`: Kaos Polo Pria Onion — Rp115.000; variasi Black, Brown, Ivory, Green.
- Koleksi `BOYSTYLE02`: Ventela [Original] V23 Low White Brown — Rp293.080; link afiliasi sudah diisi.

## Catatan
- Hanya UUID yang terdaftar di `public.mono_admin_users` yang diizinkan mengubah data melalui policy database.
- Gambar produk memakai URL gambar HTTPS, bukan upload langsung.
- Harga, stok, variasi, dan komisi dapat berubah; periksa kembali sebelum promosi.
