# Pemulihan Konteks Organisasi dan Role Assignment

## Gejala
Aplikasi dapat mengautentikasi pengguna, tetapi dashboard menolak permintaan data karena `my_context()` mengembalikan `organization_id` kosong.

## Perbaikan yang diterapkan
- Penugasan aktif untuk peran `PLATFORM_ADMIN` milik administrator sistem telah ditautkan ke organisasi aktif `Desa Pilot` dan wilayah `Desa Pilot`, setelah akun, peran, dan organisasi diverifikasi.
- Fungsi `village.my_context()` sekarang hanya mengembalikan penugasan aktif yang memiliki organisasi aktif, memeriksa `starts_at` / `ends_at`, dan memvalidasi wilayah jika wilayah ditetapkan.
- Fungsi wrapper `public.my_context()` hanya dapat dieksekusi oleh peran `authenticated`; akses `anon` dicabut.
- Penugasan lain yang masih kehilangan organisasi tidak otomatis diperbaiki. Setiap penugasan harus dipasangkan ke organisasi berdasarkan pemilik, peran, dan lingkup kewenangan yang benar.

## Verifikasi
- Konteks administrator menghasilkan organisasi dan wilayah Desa Pilot.
- Penugasan RT_OPERATOR dan WARGA yang masih belum memiliki organisasi tidak menghasilkan konteks operasional.
- `anon` tidak memiliki hak EXECUTE atas kedua fungsi; `authenticated` memiliki hak EXECUTE.
- Tidak ada data warga atau data operasional yang diubah oleh hardening fungsi ini.

## Tindak lanjut
1. Administrator keluar lalu masuk kembali agar aplikasi memuat konteks terbaru.
2. Uji halaman utama, modul data, dan audit log menggunakan akun administrator.
3. Perbaiki penugasan RT_OPERATOR dan WARGA secara terpisah setelah organisasi yang benar dikonfirmasi.
4. Lakukan uji lintas organisasi sebelum menyatakan sistem siap produksi.
