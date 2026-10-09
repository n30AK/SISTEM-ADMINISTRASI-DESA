# Integrasi Operasional RT/RW CONNECT ke Sistem Administrasi Desa

## Tujuan

SAD adalah pusat administrasi desa. Menu dan fungsi RT/RW CONNECT diakses dari navigasi SAD sehingga pengguna tidak perlu menganggap RT/RW CONNECT sekadar sumber berita atau papan pengumuman.

## Perilaku wilayah aktif

Kartu **Wilayah Aktif** di modul data membuka **Ringkasan Wilayah RT/RW CONNECT**. Halaman tersebut memuat ulang konteks organisasi/wilayah melalui `my_context()`, lalu membaca ringkasan operasional dari `village.population_summary()` dan data RT/RW CONNECT yang memiliki cakupan `territory_id`. Jika konteks tidak valid, permintaan dihentikan. Kesalahan akses ditampilkan berbeda dari hasil kosong.

## Menu RT/RW CONNECT yang ditautkan

- Ringkasan Wilayah RT/RW
- Kabar Desa (feed artikel publik)
- Pengumuman Desa
- Ruang Warga & Pengaduan (jumlah agregat; isi pesan tidak dibuka)
- Peta Wilayah & GIS (ringkasan lapisan; bukan peta interaktif)
- Permohonan RT/RW
- Kegiatan & Musyawarah Warga
- UMKM & Perdagangan Warga
- Kesehatan (agregat)
- Pendidikan & Keterampilan
- Infrastruktur Wilayah
- Lingkungan & Kebersihan
- Kesiapsiagaan & Bencana
- Keuangan RT/RW
- Relawan & Gotong Royong

Menu tambahan di SAD meliputi pemerintahan dan kelembagaan desa, produk hukum, indeks/SDGs, keuangan desa, pembangunan, aset, bantuan, arsip, informasi publik, kepatuhan, audit, dan integrasi GPFFE.

## Sumber data dan batasan privasi

- Sumber RT/RW CONNECT menggunakan tabel operasional yang sudah ada pada proyek Supabase bersama, bukan data contoh yang dibuat oleh SAD.
- Permohonan tidak menampilkan payload/formulir atau identitas pemohon pada daftar ringkas.
- Kesehatan dan pendidikan ditampilkan sebagai agregat; identitas serta catatan individu tidak ditampilkan pada ringkasan.
- Profil usaha pada daftar umum hanya ditampilkan bila `public_visible = true`.
- Data keuangan pada ringkasan menunjukkan jumlah akun/transaksi; rincian finansial harus tetap mengikuti hak akses.
- Query tetap menggunakan territory aktif, dan tabel yang memiliki `organization_id` juga dibatasi ke organisasi aktif atau record yang memang tidak ditautkan ke organisasi.
- RT/RW CONNECT dan SAD tetap terpisah secara logis meskipun menggunakan proyek Supabase yang sama. Integrasi tidak boleh melewati RLS, role assignment, atau audit.
- Angka nol berarti tidak ada record yang dapat dibaca pada cakupan itu; tanda “—” atau pesan kesalahan berarti query tidak berhasil/tidak diizinkan. Keduanya tidak boleh dianggap sama.

## Catatan implementasi

Halaman GitHub Pages adalah preview frontend. Pengujian sintaks JavaScript dilakukan sebelum commit, tetapi deployment live, autentikasi browser, serta akses RLS harus diverifikasi melalui workflow GitHub dan sesi pengguna yang terautentikasi.
