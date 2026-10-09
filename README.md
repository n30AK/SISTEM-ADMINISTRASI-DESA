# Sistem Administrasi Desa (SAD)

Sistem Administrasi Desa adalah aplikasi mandiri yang dibangun dan dikelola sebagai sistem operasional administrasi desa. SAD **tidak menggunakan, mengubah, atau bergantung pada OpenSID**. OpenSID bukan bagian dari arsitektur maupun prasyarat operasional proyek ini.

## Arsitektur

- **SAD** — pusat kendali pemerintahan desa dan domain data administrasi desa.
- **RT/RW CONNECT** — sistem operasional tingkat RT/RW dan sumber data lapangan.
- **GPFFE** — sistem terpisah untuk pertukaran data ekonomi dan pemberdayaan.
- **Integrasi** — dilakukan melalui mekanisme terkontrol, dengan identitas/tenant mapping, validasi, audit, dan pembatasan akses. Walaupun sistem dapat berbagi proyek database, tidak boleh diasumsikan bahwa seluruh tabel bebas dibaca atau ditulis antar-aplikasi.

## Menu dan roadmap

Peta menu yang disarankan, pemetaan domain RT/RW CONNECT ke SAD, baseline regulasi, kontrol keamanan, serta urutan implementasi tersedia pada [Peta Menu, Kewenangan, dan Roadmap Regulasi SAD](docs/architecture/SAD-MENU-AND-REGULATORY-ROADMAP.md).

## Modul SAD

Pusat Kendali Desa; Pemerintahan dan Kelembagaan; Data Warga dan Keluarga; Pelayanan Publik dan Persuratan; Kesejahteraan Sosial dan Bantuan; Perencanaan, Pembangunan, dan Musyawarah; Keuangan dan Akuntabilitas Desa; Aset, Infrastruktur, dan Lingkungan; Ekonomi Desa dan BUM Desa; Kesehatan, Pendidikan, dan Ketahanan Warga; Kedaruratan dan Perlindungan Warga; Data, Integrasi, dan Analitik; Transparansi Publik; serta Pengaturan dan Kepatuhan.

Daftar ini adalah arsitektur target, bukan klaim bahwa semua modul sudah selesai. Setiap modul harus diberi status implementasi yang jujur (aktif, bertahap, atau rencana).

## Database dan keamanan

Database operasional SAD berada pada proyek Supabase yang dikonfigurasi untuk aplikasi. Skema database, migrasi, autentikasi, role assignment, organisasi, wilayah, dan kebijakan akses SAD menjadi sumber kebenaran implementasi.

- Rahasia disimpan di environment/secrets, bukan di frontend atau repository.
- Data dipilah berdasarkan organisasi dan wilayah; setiap modul harus menghormati RLS dan hak akses.
- Jumlah record tidak otomatis berarti jumlah warga unik atau data resmi yang sudah diverifikasi.
- Data demo harus diberi label jelas dan tidak boleh disajikan sebagai data warga nyata.
- Jangan membuat data warga fiktif untuk sekadar mengisi tampilan kosong.
- Integrasi RT/RW CONNECT dan GPFFE perlu kontrak data, tujuan penggunaan, otorisasi, pencatatan sumber/tanggal, validasi, rekonsiliasi, dan audit.
- Keberhasilan CI tidak dengan sendirinya membuktikan deployment live atau integrasi data telah terverifikasi.

## Regulasi

Peta regulasi di roadmap adalah baseline untuk desain dan perlu diverifikasi terhadap aturan terbaru, Perda/Perbup/Perwali serta SOP yang berlaku sebelum sistem dipakai secara resmi. Aplikasi tidak menggantikan keputusan pejabat yang berwenang atau aplikasi/format pelaporan resmi tanpa validasi yang diperlukan.
