# Arsitektur — Sistem Administrasi Desa (SAD)

## Kepemilikan data

SAD adalah aplikasi mandiri dengan database operasional sendiri di Supabase. SAD tidak menggunakan, mengubah, atau bergantung pada OpenSID.

### Domain utama
- Identitas dan keluarga: skema serta tabel kanonis SAD/RT-RW CONNECT.
- Wilayah: `public.territories` dan master geospasial yang telah diverifikasi.
- Organisasi dan akses: `public.organizations`, `public.role_assignments`, role, dan permission.
- Administrasi desa: tabel operasional pada skema `village.*`.
- RT/RW CONNECT: layanan wilayah, infrastruktur, lingkungan, kegiatan, pengaduan, dan ringkasan warga.
- GPFFE: pertukaran data ekonomi melalui kontrak data yang terdokumentasi.
- Audit: perubahan dan pertukaran data harus dapat ditelusuri.

## Integrasi RT/RW CONNECT dan GPFFE

SAD tetap menjadi aplikasi administrasi inti. RT/RW CONNECT dan GPFFE merupakan sistem terpisah yang berintegrasi melalui API atau mekanisme pertukaran data yang terkontrol, tervalidasi, dan diaudit. Jangan menggabungkan database antar-sistem secara langsung tanpa kontrak data, otorisasi, dan pembatasan tenant.

## GIS dan data wilayah

- Seluruh permintaan data harus mengikuti konteks organisasi dan wilayah aktif.
- Geometri harus memiliki SRID yang diketahui, tipe geometri yang diizinkan, dan lolos `ST_IsValid`.
- Koordinat alamat individual tidak ditampilkan sebagai marker massal di peta administrasi.
- Geometri demonstrasi harus selalu diberi label DEMO dan tidak boleh dipresentasikan sebagai batas resmi.
- Batas administrasi resmi baru dapat diaktifkan setelah sumber geometri resmi diverifikasi dan dipetakan ke ID wilayah SAD/RT-RW CONNECT.

## Aturan produksi

- Jangan menggunakan data fiktif sebagai data pemerintahan resmi.
- Simpan rahasia hanya di environment/secrets, bukan di repository atau frontend.
- Perubahan skema dilakukan melalui migrasi yang terdokumentasi.
- Keberhasilan CI tidak dengan sendirinya membuktikan deployment live atau integrasi data telah terverifikasi.
