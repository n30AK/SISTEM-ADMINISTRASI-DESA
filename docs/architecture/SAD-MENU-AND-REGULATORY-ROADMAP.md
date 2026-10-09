# SAD — Peta Menu, Kewenangan, dan Integrasi (v1)

Tanggal kaji: 9 Oktober 2026

## Keputusan arsitektur

Sistem Administrasi Desa (SAD) adalah pusat kendali dan sistem operasional milik desa. RT/RW CONNECT menjadi sumber data lapangan dan kanal layanan/partisipasi pada tingkat RT/RW. GPFFE menyediakan pertukaran data ekonomi dan pemberdayaan yang disetujui. Sistem-sistem ini tetap terpisah secara kepemilikan dan keamanan; integrasi memakai kontrak API, pemetaan identitas/tenant, validasi, audit, dan persetujuan sesuai tujuan penggunaan.

SAD tidak bergantung pada OpenSID. Tabel dan skema SAD yang sudah ada menjadi titik awal, tetapi nama tabel saja tidak membuktikan bahwa sebuah modul sudah lengkap atau siap produksi.

## Usulan navigasi utama SAD

### 1. Pusat Kendali Desa
- Ringkasan eksekutif dan indikator yang memiliki sumber data jelas
- Notifikasi, pekerjaan tertunda, dan tenggat
- Peta desa/wilayah (bila koordinat dan hak akses tersedia)
- Pusat persetujuan dan jejak audit

### 2. Pemerintahan dan Kelembagaan
- Profil desa, wilayah, organisasi, perangkat dan masa jabatan
- Struktur pemerintahan, lembaga kemasyarakatan, BPD, PKK, Karang Taruna, LPM, lembaga adat bila relevan
- Peraturan desa, keputusan, agenda, rapat, berita acara dan arsip
- Hak akses, penugasan peran dan delegasi

### 3. Data Warga dan Keluarga
- Registrasi/pendataan penduduk dan rumah tangga
- Perubahan status/peristiwa kependudukan dan verifikasi dokumen
- Alamat, RT/RW, wilayah, agregasi statistik
- Permintaan koreksi data dan rekam jejak perubahan
- Data pribadi dibatasi berdasarkan kebutuhan kerja; jangan menampilkan NIK, kondisi kesehatan, atau data sensitif pada dashboard umum.

### 4. Pelayanan Publik dan Persuratan
- Katalog layanan dan persyaratan
- Permohonan, antrean, SLA, verifikasi, persetujuan, penerbitan surat
- Status layanan yang dapat dilihat pemohon
- Pengaduan, aspirasi, tindak lanjut, survei kepuasan
- Arsip dan verifikasi keaslian dokumen

### 5. Kesejahteraan Sosial dan Bantuan
- Pendataan kondisi sosial-ekonomi dan kebutuhan warga
- Data program, kriteria, usulan, verifikasi lapangan, penetapan, penyaluran dan pengaduan
- Riwayat bantuan lintas program dengan kontrol akses ketat
- Rekonsiliasi sumber resmi pemerintah; tandai sumber, tanggal pembaruan dan tingkat verifikasi
- SAD tidak secara otomatis menetapkan penerima program pusat/daerah; keputusan tetap mengikuti instansi dan aturan program yang berwenang.

### 6. Perencanaan, Pembangunan, dan Musyawarah
- Aspirasi/usulan RT/RW dan musyawarah desa
- RPJM Desa, RKP Desa, daftar kegiatan dan indikator
- Lokasi, progres fisik, foto bukti, pemeriksaan dan serah terima
- Pengadaan dan kontrak sebagai referensi/tautan proses yang sah
- Pemantauan risiko, perubahan lingkup dan tindak lanjut

### 7. Keuangan dan Akuntabilitas Desa
- APB Desa: pendapatan, belanja, pembiayaan, pagu dan realisasi
- Rencana kas, transaksi, bukti, rekonsiliasi dan penatausahaan
- Pemantauan penyerapan per kegiatan dan sumber dana
- Pelaporan dan bahan pertanggungjawaban
- Pemisahan tugas: pengusul, pemeriksa, penyetuju, pencatat, dan auditor
- Jangan mengklaim pengganti aplikasi/format resmi pemerintah sebelum validasi terhadap regulasi pusat dan Perbup/Perwali setempat.

### 8. Aset, Infrastruktur, dan Lingkungan
- Inventaris aset desa, lokasi, nilai, kondisi, penggunaan dan pemeliharaan
- Jalan, drainase, air, sanitasi, fasilitas publik dan kebutuhan perbaikan
- Persampahan, lingkungan, mitigasi bencana dan ketahanan iklim
- Inspeksi lapangan dan dokumentasi

### 9. Ekonomi Desa dan BUM Desa
- BUM Desa, unit usaha, koperasi/kelompok usaha sesuai kewenangan
- UMKM, pertanian, peternakan, perikanan, perdagangan, tenaga kerja dan keterampilan
- Kegiatan ekonomi dan analisis agregat berbasis data terverifikasi
- Integrasi GPFFE melalui data yang disetujui, tujuan jelas dan audit; tidak menjadikan data individu sebagai data publik.

### 10. Kesehatan, Pendidikan, dan Ketahanan Warga
- Indikator agregat layanan kesehatan, pendidikan, disabilitas, lansia dan anak
- Kegiatan Posyandu/layanan desa sesuai kewenangan
- Rujukan dan koordinasi dengan fasilitas/instansi berwenang
- Informasi kesehatan individual hanya untuk pengguna berwenang dan tujuan sah; dashboard eksekutif memakai agregat.

### 11. Kedaruratan dan Perlindungan Warga
- Pendataan risiko, kejadian, bantuan darurat, relawan dan logistik
- Kontak darurat dengan akses terbatas
- Peringatan dan koordinasi lintas instansi
- Catatan tindak lanjut serta evaluasi pascakejadian

### 12. Data, Integrasi, dan Analitik
- Penerimaan data RT/RW CONNECT dan GPFFE
- Status sinkronisasi, antrean gagal, validasi, duplikasi dan konflik data
- Katalog data, sumber, pemilik, waktu pembaruan dan kualitas
- Dashboard analitik dengan angka yang bisa ditelusuri ke sumber
- API keys/secrets hanya di server/environment; tidak pernah ditanam pada frontend publik.

### 13. Transparansi Publik
- Ringkasan APB Desa dan pelaksanaan yang layak dipublikasikan
- Daftar kegiatan dan progres pembangunan
- Pengumuman, layanan, jadwal musyawarah, kanal pengaduan
- Data ditinjau sebelum publikasi; informasi pribadi, rahasia, dan data yang dilindungi tidak dipublikasikan.

### 14. Pengaturan dan Kepatuhan
- Organisasi/wilayah aktif dan pengelolaan penugasan
- Role-based access control dan kebijakan tenant
- Retensi, koreksi, ekspor, arsip dan penghapusan sesuai aturan
- Log audit, insiden keamanan, persetujuan integrasi dan daftar regulasi
- Monitoring kesehatan sistem, backup dan pemulihan

## Pemetaan RT/RW CONNECT ke SAD

| Domain sumber RT/RW CONNECT | Fungsi SAD | Pola integrasi |
|---|---|---|
| Profil organisasi/wilayah | Data wilayah dan kelembagaan | ID wilayah stabil, mapping dan validasi |
| Profil warga/rumah tangga | Data warga/keluarga | Rekonsiliasi identitas; minimisasi data; deduplikasi |
| Usulan perencanaan dan infrastruktur | Perencanaan dan pembangunan | Usulan berstatus, verifikasi dan keputusan desa |
| Permohonan layanan | Pelayanan publik | Tiket, status, SLA dan jejak audit |
| Kegiatan sosial/relawan | Kelembagaan dan kegiatan masyarakat | Sumber, tanggal, penanggung jawab |
| Data usaha/pekerjaan/pertanian | Ekonomi desa | Agregat analitik dan akses terbatas |
| Catatan kas RT/RW | Pemantauan/rekonsiliasi sesuai kewenangan | Jangan campur otomatis dengan buku kas/APB Desa; persetujuan dan pencatatan terpisah |
| Observasi kesehatan/pendidikan/bencana | Indikator dan tindak lanjut | Agregasi untuk dashboard; detail sensitif dibatasi |
| GPFFE economic exchange | Analitik ekonomi/pemberdayaan | Data exchange yang disetujui dan diaudit |

Tidak semua fitur RT/RW CONNECT perlu disalin. SAD menampilkan ringkasan, alur persetujuan, dan keputusan tingkat desa; RT/RW CONNECT tetap mengelola kegiatan operasional yang memang menjadi lingkupnya.

## Aturan desain untuk kartu Wilayah Aktif

1. Kartu wilayah harus benar-benar interaktif jika menampilkan teks “Klik untuk memuat data wilayah ini”.
2. Klik harus memicu pemuatan ulang data modul menggunakan organization_id dan territory_id yang diperoleh dari konteks server/database, bukan dari label teks atau UUID buatan browser.
3. Tampilkan status loading, hasil jumlah record, empty state yang menjelaskan “belum ada data”, dan pesan error yang dapat ditindaklanjuti.
4. Jangan menganggap klik sebagai pergantian kewenangan. Pemilihan wilayah harus memvalidasi daftar wilayah yang memang boleh diakses pengguna.
5. Jangan pernah melemahkan RLS atau menghapus filter organisasi/wilayah hanya agar data tampil.
6. Jika kontrol belum punya aksi, hilangkan instruksi “Klik” sampai implementasinya selesai.

## Regulasi dasar yang harus dipetakan dan divalidasi

- UU 6/2014 tentang Desa sebagaimana diubah, termasuk UU 3/2024.
- Permendagri 20/2018 tentang Pengelolaan Keuangan Desa.
- Permendesa PDT Nomor 16/2025 tentang Petunjuk Operasional atas Fokus Penggunaan Dana Desa Tahun 2026.
- Permenkeu Nomor 7/2026 tentang Pengelolaan Dana Desa Tahun Anggaran 2026.
- UU 27/2022 tentang Pelindungan Data Pribadi.
- Ketentuan kearsipan, keterbukaan informasi publik, pengadaan, statistik sektoral, SPBE, serta Perda/Perbup/Perwali dan SOP kabupaten/kota yang berlaku.

Daftar ini merupakan baseline desain, bukan pendapat hukum final. Sebelum dipakai sebagai sistem resmi, status aturan, perubahan terbaru, peraturan daerah, kewenangan program dan format pelaporan wajib diverifikasi oleh pejabat/penasihat hukum yang berwenang.

## Urutan implementasi

**P0 — Kebenaran dan keamanan data**
- Pastikan pemilih wilayah berfungsi dan filter organisasi/wilayah konsisten.
- Verifikasi RLS, role assignments, audit log, backup, serta pemisahan tugas.
- Pastikan empty state berbeda dari error/permission denied.

**P1 — Fondasi data desa**
- Data warga/keluarga, perangkat/kelembagaan, persuratan, pelayanan dan arsip.
- Impor awal melalui template tervalidasi; jangan membuat data fiktif.

**P2 — Pengawasan desa**
- APB Desa/realisasi, program/bantuan, pembangunan/aset, pengaduan, dan dashboard kualitas data.

**P3 — Integrasi RT/RW CONNECT dan GPFFE**
- Kontrak API, tenant mapping, persetujuan, idempotensi, log pertukaran, rekonsiliasi dan pemantauan kegagalan.

**P4 — Analitik dan transparansi**
- Indikator sosial-ekonomi agregat, pemantauan capaian dan portal publik dengan proses review.

## Kriteria penerimaan

- Tiap menu memiliki pemilik, sumber data, role yang boleh mengakses, dan status implementasi (aktif, bertahap, atau rencana).
- Tidak ada angka analitik tanpa sumber, tanggal pembaruan, definisi, dan jejak penelusuran.
- Pengujian membuktikan pengguna satu organisasi tidak dapat membaca data organisasi lain.
- Klik Wilayah Aktif mengubah pemuatan data sesuai scope yang diotorisasi dan menampilkan status yang benar.
- Kegagalan integrasi tidak menggandakan data dan bisa direkonsiliasi.
- Tidak ada data pribadi sensitif yang bocor melalui dashboard, log, ekspor atau portal publik.
