# Kontrak Integrasi Ekonomi JOLIE ↔ RT/RW CONNECT ↔ SAD

Status: **Kontrak v1 dan endpoint penerima sudah dibuat; integrasi produksi masih terkunci sampai rahasia dan pemetaan tenant disiapkan serta diuji**.

## 1. Keputusan arsitektur

- Database JOLIE, RT/RW CONNECT, GPFFE, dan SAD tetap terpisah.
- SAD tidak membaca tabel internal JOLIE secara langsung dan tidak menyalin seluruh tabel atau data pelanggan.
- Integrasi menggunakan kontrak data berversi, autentikasi server-to-server, validasi, idempotensi, audit, dan pemetaan organisasi/wilayah yang disetujui.
- JOLIE adalah sumber utama transaksi dan operasional usaha. SAD adalah sumber utama program pemerintahan, anggaran desa, administrasi, dan hasil program publik.
- RT/RW CONNECT menangani konteks kebutuhan lingkungan dan masukan warga. Data hanya dibagikan bila ada dasar, tujuan, dan hak akses yang sah.
- GPFFE bukan sumber yang dianggap aktif hanya karena tabel/view tersedia. Dataset harus memiliki pemilik, asal, waktu pembaruan, status persetujuan, dan cakupan yang jelas.

## 2. Ruang lingkup v1

Arah awal: **JOLIE → SAD**, untuk bukti hasil ekonomi program yang terkait dengan desa. Bukan sinkronisasi dua arah seluruh data.

Data yang boleh dipertukarkan setelah konfigurasi dan persetujuan:
- metrik agregat per periode: jumlah usaha aktif yang berpartisipasi, jumlah produk aktif, jumlah pesanan selesai, total penjualan agregat bila relevan, volume produksi, atau jumlah pelaku yang mengikuti program;
- bukti kegiatan/program: ID referensi, jenis bukti, tanggal, hash dokumen, dan referensi akses terbatas bila tersedia;
- status verifikasi dan asal data;
- status sinkronisasi, versi kontrak, dan waktu pembuatan/penerimaan.

**Tidak dikirim dalam v1:** NIK, nomor KK, nomor telepon, alamat rumah, identitas pelanggan, keranjang, detail transaksi pelanggan, kredensial, token pembayaran, data kesehatan individu, dan buku besar lengkap UMKM/BUMDes.

Metrik penjualan tidak otomatis menjadi bukti realisasi APB Desa. Keterkaitan dengan dana desa hanya boleh dibuat melalui ID program/kegiatan SAD yang disetujui, dokumen relevan, dan verifikasi pihak berwenang.

## 3. Komponen dan batas kepercayaan

1. JOLIE: sumber metrik usaha dan bukti bisnis yang diizinkan.
2. RT/RW CONNECT: sumber usulan/masukan wilayah dan data komunitas sesuai kewenangan.
3. SAD: penerima bukti program, pemetaan wilayah, pemantauan program, audit dan pelaporan publik yang sudah disanitasi.
4. GPFFE: pertukaran dataset ekonomi terkelola jika sumber eksternal, lisensi, cakupan, dan status persetujuannya tersedia.
5. Adapter/Edge Function server-side: satu-satunya komponen yang memegang rahasia integrasi. Browser tidak boleh memegang HMAC secret, service-role key, atau token server-to-server.

## 4. API v1 yang diusulkan

Endpoint telah dideploy ke Supabase sebagai economic-evidence-ingest dengan autentikasi HMAC khusus. Endpoint tetap fail-closed dan belum siap menerima event produksi sampai secret diverifikasi, mapping tenant disetujui, dan uji penerimaan lulus:

    POST /functions/v1/economic-evidence-ingest

Headers:
- Content-Type: application/json
- X-Integration-Id: identifier non-rahasia
- X-Event-Id: UUID
- X-Timestamp: RFC3339 UTC
- X-Signature: v1=HMAC-SHA256(timestamp + "." + raw request body)

Persyaratan keamanan:
- secret disimpan sebagai secret server-side di kedua lingkungan; tidak di frontend, repository, atau log;
- signature dibandingkan secara constant-time;
- timestamp ditolak jika di luar jendela waktu pendek yang dikonfigurasi;
- event_id/idempotency key unik; retry dengan event sama tidak membuat duplikasi;
- validasi ukuran body, JSON schema, enum, numeric range, tenant mapping, source permissions, dan rate limit;
- log tidak menyimpan signature, secret, data pelanggan, atau payload sensitif;
- HTTPS wajib; secret memiliki prosedur rotasi dan pencabutan;
- signature valid tidak menggantikan pemeriksaan tenant, izin, persetujuan, atau validasi isi.

## 5. Bentuk payload kanonis

Contoh berikut adalah ilustrasi, bukan data produksi:

    {
      "schema_version": "1.0",
      "event_id": "7f7f2df0-18f3-4a1c-bc95-9a16c3d7a900",
      "event_type": "business.metric.snapshot",
      "source_system": "JOLIE",
      "source_tenant_ref": "opaque-approved-tenant-ref",
      "target_territory_ref": "opaque-approved-territory-ref",
      "period": {
        "start": "2026-10-01",
        "end": "2026-10-31"
      },
      "metric": {
        "code": "completed_orders",
        "value": 42,
        "unit": "order",
        "aggregation": "tenant_period",
        "currency": null
      },
      "program_ref": null,
      "evidence": [
        {
          "evidence_ref": "opaque-reference",
          "kind": "business_report",
          "sha256": "64-character-lowercase-hex",
          "captured_at": "2026-10-31T16:00:00Z",
          "access": "restricted"
        }
      ],
      "provenance": {
        "generated_at": "2026-10-31T16:05:00Z",
        "source_record_count": 42,
        "source_query_version": "jolie-metric-v1",
        "verification_status": "source_reported"
      }
    }

Nilai pada contoh hanya ilustrasi. target_territory_ref hanya dapat dipetakan setelah admin SAD mengonfirmasi hubungan tenant dengan wilayah. program_ref harus merujuk ke program yang terdaftar dan disetujui di SAD.

## 6. Status penerimaan dan verifikasi

- received: payload diterima; belum berarti benar.
- validated: skema, signature, idempotensi, dan pemetaan lolos.
- source_reported: angka berasal dari sumber, belum diverifikasi independen.
- under_review: sedang diperiksa petugas berwenang.
- verified: bukti telah diperiksa sesuai SOP yang terdokumentasi.
- rejected: tidak lolos validasi/verifikasi dengan alasan yang tercatat.
- superseded: digantikan versi berikutnya tanpa menghapus sejarah.

UI dan laporan publik wajib membedakan status tersebut. Jangan tampilkan source_reported sebagai verified.

## 7. Respons API yang diusulkan

Berhasil:

    {
      "accepted": true,
      "event_id": "7f7f2df0-18f3-4a1c-bc95-9a16c3d7a900",
      "receipt_id": "server-generated-id",
      "status": "received",
      "duplicate": false,
      "received_at": "2026-10-31T16:05:02Z"
    }

Kategori error yang diusulkan: 400 payload tidak valid, 401/403 signature atau izin tidak valid, 409 konflik event, 413 payload terlalu besar, 429 rate limit, 5xx gangguan sementara. Retry hanya untuk kegagalan sementara; gunakan event ID yang sama.

## 8. Bukti dan jejak audit

Setiap event yang diterima harus menyimpan:
- ID penerimaan server, event ID sumber, versi skema, sistem sumber, referensi tenant/wilayah yang dipetakan;
- waktu diterima dan waktu sumber;
- hash payload kanonis atau hash dokumen bukti, status validasi, dan alasan penolakan;
- aktor/service identity, hasil verifikasi, reviewer dan waktu keputusan bila berlaku;
- riwayat perubahan status tanpa hard-delete.

Hash membuktikan apakah byte yang diperiksa berubah, bukan apakah isi bukti benar atau foto asli. Bukti tetap membutuhkan prosedur pemeriksaan sesuai jenis kegiatan.

## 9. Kepemilikan data dan sumber kebenaran

| Domain | Sumber kebenaran |
|---|---|
| Katalog, stok, pesanan, pelanggan, transaksi usaha | JOLIE |
| Identitas administratif dan penetapan wilayah desa | SAD / sistem resmi yang ditetapkan |
| Usulan warga dan laporan lingkungan | RT/RW CONNECT atau kanal resmi yang ditetapkan |
| Anggaran, program, persetujuan dan laporan pemerintahan desa | SAD, mengikuti dokumen resmi |
| Dataset ekonomi eksternal | GPFFE hanya jika sumber, lisensi, freshness dan statusnya terverifikasi |
| Status bukti untuk program desa | SAD berdasarkan review yang tercatat; bukan klaim sumber JOLIE saja |

Tidak ada sistem yang boleh menimpa sumber kebenaran domain lain melalui sinkronisasi.

## 10. Uji penerimaan sebelum produksi

- [ ] Kontrak disetujui pemilik sistem JOLIE, RT/RW CONNECT dan SAD.
- [ ] Tenant/wilayah dipetakan secara eksplisit; tidak ada auto-match berdasarkan nama bebas.
- [ ] Validasi signature gagal jika body atau timestamp diubah.
- [ ] Signature salah, secret hilang, event terlalu lama, dan tenant tak dikenal ditolak.
- [ ] Pengiriman ulang event yang sama idempotent.
- [ ] Payload dengan NIK/telepon/alamat pelanggan ditolak oleh schema/allowlist.
- [ ] Metrik sumber tidak otomatis menjadi bukti terverifikasi.
- [ ] Akses lintas tenant/wilayah diuji dengan akun berwenang dan tes negatif.
- [ ] Gangguan jaringan dapat dicoba ulang tanpa duplikasi.
- [ ] Perubahan status, reviewer, alasan penolakan, dan riwayat tercatat.
- [ ] Data publik hanya memuat agregat yang sudah ditinjau dan layak dibuka.
- [ ] Retensi, penghapusan, koreksi, dan penanganan insiden terdokumentasi.
- [ ] Uji dilakukan pada staging dengan data sintetis; produksi tidak diisi data palsu.

## 11. Tahapan implementasi

1. Setujui pemilik data, tujuan, dan metrik v1.
2. Tambahkan kontrak dan schema validation pada repo kedua sistem.
3. Bangun adapter server-side; jangan letakkan rahasia pada browser.
4. Buat tabel inbox/event dan audit pada SAD dengan RLS dan grants yang sesuai.
5. Uji di staging dengan data sintetis.
6. Uji akun lintas organisasi/wilayah, replay, duplikasi, dan gangguan.
7. Aktifkan untuk satu tenant pilot setelah pemilik sistem menyetujui.
8. Perluas secara bertahap; review akses dan kualitas data berkala.

## 12. Status saat ini

Kontrak, tabel inbox/mapping, trigger audit, dan endpoint economic-evidence-ingest sudah dibuat. Tabel mapping saat verifikasi masih kosong dan inbox belum berisi event. Keberadaan endpoint bukan bukti integrasi aktif: secret HMAC harus dikonfigurasi dan diverifikasi, mapping tenant harus disetujui, lalu tes negatif/positif harus lulus. Jangan kirim data produksi sebelum semua prasyarat itu terpenuhi.
