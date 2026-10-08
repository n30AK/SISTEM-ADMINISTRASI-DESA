# Production Acceptance Test — Sistem Administrasi Desa

Dokumen ini adalah checklist penerimaan produksi untuk menguji Sistem Administrasi Desa sebelum dinyatakan GO-LIVE VERIFIED.

## 1. Prasyarat

- [ ] GitHub `main` hijau pada CI.
- [ ] GitHub Pages deployment hijau.
- [x] Supabase project dapat menjalankan regression query produksi.
- [ ] Gunakan akun uji nyata yang memiliki role berbeda untuk authenticated acceptance. Jangan menggunakan service role di browser.
- [ ] Catat `organization_id`, `territory_id`, role, waktu pengujian, dan hasil.

## 2. Identitas & Context

### PLATFORM_ADMIN
- [ ] Login berhasil.
- [ ] `my_context` mengembalikan context yang benar.
- [ ] Dashboard hanya menampilkan data yang sesuai context.
- [ ] Logout mengakhiri sesi.

### RT_OPERATOR
- [ ] Login berhasil.
- [ ] `my_context` mengembalikan territory yang ditetapkan.
- [ ] Data RT/RW yang diizinkan dapat dibaca.
- [ ] Operasi tulis hanya tersedia pada resource yang memang diizinkan.

### WARGA / role tanpa kewenangan operator
- [ ] Tidak dapat memperoleh akses administratif yang tidak diberikan.
- [ ] Tidak dapat menjalankan RPC privileged.

## 3. RLS Isolation Test

Untuk dua pengguna dengan territory berbeda:

- [ ] User A hanya dapat membaca data territory A.
- [ ] User A tidak dapat membaca data territory B.
- [ ] User A tidak dapat mengubah row territory B.
- [ ] User A tidak dapat mengubah `organization_id` atau `territory_id` row menjadi scope lain.
- [ ] User B memperoleh hasil yang sesuai territory B.

Untuk dua organisasi berbeda:

- [ ] User A tidak dapat membaca data organisasi B.
- [ ] User A tidak dapat mengubah data organisasi B.

### Negative test

Setiap percobaan cross-scope harus menghasilkan salah satu dari:
- row tidak ditemukan / hasil kosong; atau
- operasi ditolak oleh RLS.

Tidak boleh ada kebocoran data sensitif melalui error message, view, RPC, atau aggregate.

## 4. RT/RW CONNECT

- [ ] `rt_service_requests` dapat dibaca oleh role yang berwenang.
- [ ] `rt_service_requests` tidak dapat diubah oleh role yang hanya memiliki SELECT.
- [ ] `rt_health_observations` mengikuti organization + territory scope.
- [ ] `rt_education_profiles` mengikuti organization + territory scope.
- [ ] `rt_business_profiles` mengikuti organization + territory scope.
- [ ] INSERT hanya tersedia bagi role yang memang diizinkan.
- [ ] UPDATE hanya tersedia bagi role yang memang diizinkan.
- [ ] Cross-territory read ditolak.
- [ ] Cross-organization read ditolak.

## 5. GPFFE

- [ ] `exchange_datasets` hanya dapat dibaca oleh authenticated user yang berwenang.
- [ ] Anonymous access ditolak.
- [ ] `gpffe_economic_exchange` tidak menerima mutation dari client yang hanya memiliki SELECT.
- [ ] `economic_analysis_snapshots` mengikuti scope role/territory.
- [ ] `v_intelligence_gpffe` mengikuti RLS sumber karena menggunakan `security_invoker`.
- [ ] Hanya exchange dengan `approval_status = APPROVED` yang masuk aggregate intelligence.
- [ ] Row dengan `snapshot_id` tidak valid tidak menyebabkan kebocoran data.
- [ ] Dataset GPFFE aktif terdeteksi oleh Integration Center setelah sumber eksternal benar-benar tersedia.

Catatan: keberadaan tabel/view GPFFE di database bukan bukti bahwa koneksi eksternal GPFFE sudah menghasilkan data.

## 6. Permohonan Layanan

- [ ] Record tersimpan dibuka sebagai form edit saat modul dibuka.
- [ ] Form Baru membuat record baru.
- [ ] Perbarui menyimpan perubahan.
- [ ] Batalkan Perubahan tidak merusak record tersimpan.
- [ ] Duplikat membuat record baru.
- [ ] Arsipkan tidak melakukan hard delete.
- [ ] Riwayat perubahan tercatat.
- [ ] Status hanya dapat berpindah melalui transition yang diizinkan.
- [ ] Transition ilegal ditolak database.

Urutan utama:

`DRAFT → SUBMITTED → VERIFICATION → APPROVED → READY → ISSUED → CLOSED`

Jalur penolakan:

`DRAFT/SUBMITTED/VERIFICATION/APPROVED/READY/ISSUED → REJECTED`

## 7. Peristiwa Penduduk

- [ ] Form lengkap tersedia.
- [ ] Jenis peristiwa hanya menerima nilai yang diizinkan.
- [ ] Status workflow hanya menerima nilai yang diizinkan.
- [ ] Scope organization + territory berlaku.
- [ ] Audit tercatat.
- [ ] Arsip menggunakan soft-delete.

## 8. Audit & Restore

- [ ] INSERT tercatat.
- [ ] UPDATE tercatat.
- [ ] Status workflow tercatat.
- [ ] READ detail penduduk terkendali tercatat.
- [ ] Actor, organization, territory, entity, dan action dapat ditelusuri.
- [ ] Restore hanya dapat dilakukan pada tabel yang diizinkan.
- [ ] Restore tidak dapat digunakan untuk menembus scope organisasi/territory.

## 9. Data Penduduk Sensitif

- [ ] Anonymous tidak dapat membaca data penduduk.
- [ ] User tanpa role privileged tidak dapat memperoleh detail terkendali.
- [ ] NIK pada detail terkendali tetap termasking.
- [ ] Nomor telepon tetap termasking.
- [ ] Setiap akses detail tercatat dalam audit trail.

## 10. Master Configuration

- [ ] Identitas desa dapat dibaca sesuai scope.
- [ ] Perubahan konfigurasi hanya dapat dilakukan role yang berwenang.
- [ ] Organization/territory tidak dapat dipindahkan oleh client melalui manipulasi payload.
- [ ] Perubahan konfigurasi tercatat.

## 11. UI / UX Acceptance

- [ ] Seluruh teks operasional menggunakan Bahasa Indonesia.
- [ ] Tidak ada dependency OpenSID pada runtime.
- [ ] Dokumen membuka data tersimpan terlebih dahulu.
- [ ] Katalog Layanan membuka data tersimpan terlebih dahulu.
- [ ] Modul administratif lainnya mengikuti pola Existing Data First.
- [ ] Action bar tersedia dan berfungsi.
- [ ] Tidak ada hard-delete pada UI administratif.
- [ ] Mobile/tablet layout tidak memotong action penting.
- [ ] Error ditampilkan dalam Bahasa Indonesia dan tidak membocorkan detail internal.

## 12. Control Tower

- [ ] Jumlah Perangkat Desa sesuai database.
- [ ] Jumlah Surat Keluar sesuai database.
- [ ] Jumlah Keuangan sesuai database.
- [ ] Jumlah Pembangunan sesuai database.
- [ ] Jumlah Aset sesuai database.
- [ ] Jumlah Dokumen sesuai database.
- [ ] Jumlah Katalog Layanan sesuai database.
- [ ] Jumlah Permohonan sesuai database.
- [ ] Jumlah Peristiwa Penduduk sesuai database.
- [ ] Audit Trail sesuai database.
- [ ] Tidak ada angka dummy/fiktif.
- [ ] Refresh memperbarui metrik.

## 13. Production Regression Evidence — 2026-10-09

Regression query produksi dijalankan langsung pada Supabase project `gzdusguveeeflmlvvmwe`.

### Database / RLS

- [x] Seluruh 21 tabel target yang diaudit memiliki RLS aktif.
- [x] Seluruh tabel target memiliki minimal satu policy.
- [x] Tidak ditemukan status workflow tidak valid pada `village.service_requests`.
- [x] Tidak ditemukan `event_type` tidak valid pada `village.population_events`.
- [x] Tidak ditemukan status tidak valid pada `village.population_events`.

### Data Integration

| Sumber | Row |
|---|---:|
| RT Service Requests | 250 |
| RT Health Observations | 350 |
| RT Education Profiles | 450 |
| RT Business Profiles | 61 |
| GPFFE Economic Exchange | 0 |
| GPFFE Active Dataset | 0 |

Interpretasi: RT/RW CONNECT memiliki data yang terbaca di database. GPFFE telah memiliki struktur dan kontrol akses, tetapi belum memiliki dataset GPFFE aktif maupun payload exchange produksi; karena itu koneksi eksternal GPFFE belum boleh dinyatakan data-producing.

### Security Advisor

Temuan yang masih muncul adalah temuan platform/extension:

- `public.spatial_ref_sys` belum RLS.
- PostGIS terpasang pada schema `public`.
- Tiga overload `public.st_estimatedextent` masih terdeteksi sebagai SECURITY DEFINER yang executable untuk anon/authenticated; ACL tersebut dikelola extension dan tidak boleh dipaksa diubah tanpa evaluasi platform.
- Supabase Auth leaked-password protection masih disabled.

Temuan tersebut dicatat sebagai **platform/system findings**, bukan dianggap sebagai bukti bahwa RLS aplikasi village/RT/RW telah dilewati.

## 14. Go-Live Decision

### PASS
Semua checklist kritis berikut harus PASS:

- [ ] Authenticated isolation.
- [ ] Organization isolation.
- [ ] Territory isolation.
- [ ] RT/RW authorization.
- [ ] GPFFE authorization.
- [x] Workflow data integrity regression.
- [ ] Audit trail authenticated acceptance.
- [ ] Sensitive resident access authenticated acceptance.
- [ ] CI pada commit terbaru.
- [ ] Deployment pada commit terbaru.

### Status Saat Ini

**PRODUCTION CANDIDATE — AUTHENTICATED ACCEPTANCE PENDING**

Regression database sudah dijalankan dan tidak menemukan data workflow invalid. Namun connector yang tersedia tidak menyediakan sesi login dua pengguna nyata untuk melakukan cross-organization/cross-territory RLS negative test. Karena itu sistem belum boleh diberi label **GO-LIVE VERIFIED** secara jujur.

## 15. Evidence Record

| Waktu | Tester | Role | Organization | Territory | Test | Result | Evidence |
|---|---|---|---|---|---|---|---|
| 2026-10-09 | Automated DB regression | Database | production | production | RLS/workflow/integration regression | PASS | Supabase SQL execution |

Jangan menyimpan password, service-role key, access token, refresh token, atau data pribadi sensitif di dokumen evidence ini.
