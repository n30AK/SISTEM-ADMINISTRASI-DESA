# Matriks Kepatuhan — SISTEM ADMINISTRASI DESA

Status: baseline desain aplikasi per Oktober 2026.

## Regulasi utama
1. UU 6/2014 tentang Desa sebagaimana diubah terakhir dengan UU 3/2024.
2. PP 16/2026 tentang Peraturan Pelaksanaan UU Desa. PP ini mencabut PP 43/2014 beserta perubahannya.
3. Permendesa PDT 13/2025 tentang Pedoman Sistem Informasi Desa (SID).
4. Permendagri 2/2026 tentang Pengelolaan Layanan Informasi Publik di Kementerian Dalam Negeri, Pemerintah Daerah dan Pemerintah Desa.

## Prinsip implementasi
- Sistem adalah aplikasi operasional, bukan halaman informasi statis.
- Master penduduk tidak digandakan. Data penduduk harus berasal dari OpenSID/data layer kependudukan yang sah atau integrasi resmi yang ditetapkan pemerintah desa.
- Setiap transaksi memiliki organisasi, wilayah, aktor, status, waktu dan jejak perubahan.
- Layanan desa menggunakan katalog layanan yang dapat dikonfigurasi: kode layanan, nama, dasar hukum, persyaratan, output, tahapan, SLA/estimasi sesuai standar pelayanan yang ditetapkan desa/daerah, biaya bila memang sah, dan pejabat pemutus.
- Data pribadi dipisahkan dari informasi publik dan hanya ditampilkan sesuai kewenangan.
- Form tidak boleh mengarang NIK, KK, nomor surat, tarif, SLA, dasar hukum lokal, atau persyaratan lokal. Nilai tersebut harus dikonfigurasi dari dokumen resmi desa/daerah dan sumber OpenSID.
- Workflow layanan minimal: DRAFT → SUBMITTED → VERIFICATION → APPROVED/REJECTED → READY → ISSUED → CLOSED.
- Perubahan status dicatat pada service_request_events.
- RLS berbasis organisasi digunakan untuk tenant isolation.
- Service-role key tidak boleh berada pada browser.

## Modul dan status implementasi
| Modul | Operasional | Sumber/aturan |
|---|---|---|
| Dashboard | Ya | agregasi transaksi |
| Penduduk | Integrasi | OpenSID/master kependudukan |
| Keluarga | Integrasi | OpenSID/master kependudukan |
| Perangkat Desa | Ya | village.officials |
| Layanan & Permohonan | Ya | village.services + service_requests |
| Surat | Ya | village.letters |
| Dokumen | Ya | village.documents |
| Keuangan | Ya | village.budgets; struktur APBDes perlu dikonfigurasi sesuai dokumen resmi |
| Pembangunan | Ya | village.programs; RPJM/RKP/RAB/monitoring perlu konfigurasi lanjutan |
| Aset | Ya | village.assets |
| Bantuan | Integrasi | sumber program/DTKS resmi; tidak boleh memakai data contoh |
| Kepatuhan | Ya | matriks regulasi |

## Catatan legal
Matriks ini adalah baseline rekayasa perangkat lunak, bukan pendapat hukum. Dasar hukum, persyaratan layanan, format surat, pejabat penandatangan, biaya dan SLA harus divalidasi terhadap regulasi nasional, peraturan daerah/kabupaten, Perdes/Perkades, standar pelayanan dan dokumen resmi desa sebelum produksi.
