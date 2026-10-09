# Sistem Administrasi Desa (SAD)

Sistem Administrasi Desa adalah aplikasi mandiri yang dibangun dan dikelola sebagai sistem operasional administrasi desa. SAD **tidak menggunakan, mengubah, atau bergantung pada OpenSID**. OpenSID bukan bagian dari arsitektur maupun prasyarat operasional proyek ini.

## Arsitektur

- **SAD** — aplikasi inti dengan database operasional sendiri di Supabase. Data dan modul administrasi dikelola oleh SAD.
- **RT/RW CONNECT** — sistem terpisah yang diintegrasikan melalui pertukaran data/API yang terkontrol sesuai otorisasi.
- **GPFFE** — sistem terpisah untuk pertukaran data ekonomi dan pemberdayaan melalui mekanisme yang terkontrol.
- **Keamanan data** — akses dibatasi berdasarkan identitas, role assignment, organisasi, wilayah, dan kebijakan database. Database antar-aplikasi tidak digabung secara langsung tanpa desain integrasi dan kontrol akses.

## Modul SAD

Dashboard, Penduduk, Keluarga, Perangkat Desa, Surat, Permohonan/Layanan, Keuangan Desa, Pembangunan, Aset, serta program dan bantuan sosial. Cakupan modul berkembang berdasarkan skema dan migrasi database SAD.

## Database dan konfigurasi

Database operasional SAD berada pada proyek Supabase yang dikonfigurasi untuk aplikasi. Skema database, migrasi, autentikasi, role assignment, organisasi, wilayah, dan kebijakan akses SAD menjadi sumber kebenaran untuk implementasi.

Konfigurasi rahasia harus disimpan di environment/secrets, bukan di-commit ke repository. Integrasi RT/RW CONNECT dan GPFFE harus menggunakan kontrak API/pertukaran data yang terdokumentasi dan akses minimum yang diperlukan.

## Status integrasi saat ini

- Database utama SAD berada pada proyek Supabase yang dikonfigurasi untuk aplikasi.
- Proyek SAD saat ini memiliki tabel RT/RW lokal/pilot. Keberadaan tabel dan record tersebut **tidak membuktikan sinkronisasi langsung** dengan database eksternal RT/RW CONNECT.
- Koneksi ke proyek database RT/RW CONNECT eksternal, pemetaan tenant/wilayah, autentikasi server-to-server, dan uji sinkronisasi belum terverifikasi melalui koneksi proyek yang tersedia.
- Jangan menganggap data pilot sebagai data resmi atau menggunakannya untuk keputusan pemerintahan sebelum asal data diverifikasi.
- Modul pemerintahan seperti Perangkat Desa, Surat, APB Desa/Keuangan, Pembangunan, dan Aset tetap merupakan domain data SAD; data RT/RW hanya masuk ke domain yang sesuai melalui integrasi yang disetujui.

## Catatan

- Tidak diperlukan database atau berkas OpenSID untuk menjalankan SAD.
- Jangan mengimpor atau membuat data penduduk fiktif untuk mengisi tampilan kosong.
- Data awal harus dimasukkan melalui alur resmi atau diimpor dari sumber yang secara eksplisit disetujui.
- Keberhasilan CI tidak dengan sendirinya membuktikan deployment live atau integrasi data telah terverifikasi.
