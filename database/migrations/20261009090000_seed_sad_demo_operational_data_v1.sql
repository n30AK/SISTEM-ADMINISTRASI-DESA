-- Safe, repeatable demonstration data for the SAD pilot organization.
-- Every record is visibly marked DEMO; no real resident identity or official financial value is fabricated.
ALTER TABLE village.services
  ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}'::jsonb;

DO $$
DECLARE
  v_org uuid;
  v_territory uuid;
BEGIN
  SELECT o.id, o.territory_id INTO v_org, v_territory
  FROM public.organizations o
  JOIN public.territories t ON t.id = o.territory_id
  WHERE o.name = 'Desa Pilot' AND o.organization_type = 'VILLAGE'
    AND o.active = true AND t.name = 'Desa Pilot' AND t.active = true
  LIMIT 1;

  IF v_org IS NULL OR v_territory IS NULL THEN
    RAISE EXCEPTION 'Active Desa Pilot organization/territory not found; demo seed cancelled.';
  END IF;

  INSERT INTO village.officials
    (organization_id, territory_id, full_name, position_code, position_name, status, metadata, administrative_form)
  SELECT v_org, v_territory, x.full_name, x.position_code, x.position_name, 'DEMO',
    jsonb_build_object('is_demo',true,'source','SAD demo seed','seed_tag','SAD_DEMO_OFFICIAL_EXTRA_'||x.position_code,'notice','Data fiktif untuk uji aplikasi; bukan pejabat sebenarnya'),
    jsonb_build_object('demo',true,'seed_tag','SAD_DEMO_OFFICIAL_EXTRA_'||x.position_code,'note','Ganti dengan data resmi sebelum produksi')
  FROM (VALUES
    ('CONTOH DEMO - Kasi Pemerintahan','KASI_PEMERINTAHAN','Kepala Seksi Pemerintahan'),
    ('CONTOH DEMO - Kasi Kesejahteraan','KASI_KESEJAHTERAAN','Kepala Seksi Kesejahteraan'),
    ('CONTOH DEMO - Kaur Keuangan','KAUR_KEUANGAN','Kepala Urusan Keuangan')
  ) AS x(full_name,position_code,position_name)
  WHERE NOT EXISTS (
    SELECT 1 FROM village.officials o WHERE o.organization_id=v_org AND o.territory_id=v_territory
      AND o.position_code=x.position_code AND o.metadata->>'is_demo'='true'
  );

  INSERT INTO village.services
    (organization_id, territory_id, service_code, service_name, description, active, requirements, workflow, metadata, administrative_form)
  VALUES
    (v_org,v_territory,'DEMO-SRV-001','CONTOH DEMO — Surat Keterangan Domisili','Data demonstrasi; tidak tersedia untuk permohonan resmi.',false,
      '["DEMO: ganti dengan persyaratan resmi"]'::jsonb,'{"demo":true,"steps":["Contoh alur","Verifikasi petugas","Persetujuan"]}'::jsonb,
      '{"is_demo":true,"seed_tag":"SAD_DEMO_SERVICE_001","notice":"Data fiktif; layanan dinonaktifkan"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_SERVICE_001"}'::jsonb),
    (v_org,v_territory,'DEMO-SRV-002','CONTOH DEMO — Surat Keterangan Usaha','Data demonstrasi; tidak tersedia untuk permohonan resmi.',false,
      '["DEMO: ganti dengan persyaratan resmi"]'::jsonb,'{"demo":true,"steps":["Contoh alur","Verifikasi petugas","Persetujuan"]}'::jsonb,
      '{"is_demo":true,"seed_tag":"SAD_DEMO_SERVICE_002","notice":"Data fiktif; layanan dinonaktifkan"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_SERVICE_002"}'::jsonb),
    (v_org,v_territory,'DEMO-SRV-003','CONTOH DEMO — Surat Pengantar Administrasi','Data demonstrasi; tidak tersedia untuk permohonan resmi.',false,
      '["DEMO: ganti dengan persyaratan resmi"]'::jsonb,'{"demo":true,"steps":["Contoh alur","Verifikasi petugas","Persetujuan"]}'::jsonb,
      '{"is_demo":true,"seed_tag":"SAD_DEMO_SERVICE_003","notice":"Data fiktif; layanan dinonaktifkan"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_SERVICE_003"}'::jsonb)
  ON CONFLICT (organization_id, service_code) DO NOTHING;

  INSERT INTO village.budgets
    (organization_id, territory_id, fiscal_year, budget_code, budget_name, budget_type, amount, status, metadata, administrative_form)
  VALUES
    (v_org,v_territory,2026,'DEMO-BDG-001','CONTOH DEMO — Administrasi Pemerintahan Desa','DEMO',0,'DRAFT','{"is_demo":true,"seed_tag":"SAD_DEMO_BUDGET_001","notice":"Nilai nol; bukan angka APBDes resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_BUDGET_001"}'::jsonb),
    (v_org,v_territory,2026,'DEMO-BDG-002','CONTOH DEMO — Pembangunan Sarana Desa','DEMO',0,'DRAFT','{"is_demo":true,"seed_tag":"SAD_DEMO_BUDGET_002","notice":"Nilai nol; bukan angka APBDes resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_BUDGET_002"}'::jsonb),
    (v_org,v_territory,2026,'DEMO-BDG-003','CONTOH DEMO — Pemberdayaan Masyarakat','DEMO',0,'DRAFT','{"is_demo":true,"seed_tag":"SAD_DEMO_BUDGET_003","notice":"Nilai nol; bukan angka APBDes resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_BUDGET_003"}'::jsonb)
  ON CONFLICT (organization_id, fiscal_year, budget_code) DO NOTHING;

  INSERT INTO village.programs
    (organization_id, territory_id, program_code, program_name, fiscal_year, status, progress, metadata, administrative_form)
  VALUES
    (v_org,v_territory,'DEMO-PRG-001','CONTOH DEMO — Perbaikan Infrastruktur Lingkungan',2026,'PLANNED',0,'{"is_demo":true,"seed_tag":"SAD_DEMO_PROGRAM_001"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_PROGRAM_001"}'::jsonb),
    (v_org,v_territory,'DEMO-PRG-002','CONTOH DEMO — Pelatihan UMKM Desa',2026,'PLANNED',0,'{"is_demo":true,"seed_tag":"SAD_DEMO_PROGRAM_002"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_PROGRAM_002"}'::jsonb),
    (v_org,v_territory,'DEMO-PRG-003','CONTOH DEMO — Kebersihan dan Lingkungan',2026,'PLANNED',0,'{"is_demo":true,"seed_tag":"SAD_DEMO_PROGRAM_003"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_PROGRAM_003"}'::jsonb)
  ON CONFLICT (organization_id, program_code) DO NOTHING;

  INSERT INTO village.assets
    (organization_id, territory_id, asset_code, asset_name, category, acquisition_value, condition_status, location, status, metadata, administrative_form)
  VALUES
    (v_org,v_territory,'DEMO-AST-001','CONTOH DEMO — Peralatan Kantor','DEMO',0,'BELUM DIVERIFIKASI','Lokasi demo','INACTIVE','{"is_demo":true,"seed_tag":"SAD_DEMO_ASSET_001","notice":"Bukan inventaris resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_ASSET_001"}'::jsonb),
    (v_org,v_territory,'DEMO-AST-002','CONTOH DEMO — Perangkat Komputer','DEMO',0,'BELUM DIVERIFIKASI','Lokasi demo','INACTIVE','{"is_demo":true,"seed_tag":"SAD_DEMO_ASSET_002","notice":"Bukan inventaris resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_ASSET_002"}'::jsonb),
    (v_org,v_territory,'DEMO-AST-003','CONTOH DEMO — Peralatan Kebersihan','DEMO',0,'BELUM DIVERIFIKASI','Lokasi demo','INACTIVE','{"is_demo":true,"seed_tag":"SAD_DEMO_ASSET_003","notice":"Bukan inventaris resmi"}'::jsonb,'{"demo":true,"seed_tag":"SAD_DEMO_ASSET_003"}'::jsonb)
  ON CONFLICT (organization_id, asset_code) DO NOTHING;

  INSERT INTO village.documents
    (organization_id, territory_id, document_number, document_type, title, document_date, status, metadata, administrative_form)
  SELECT v_org,v_territory,x.doc_no,'DEMO',x.title,current_date,'DRAFT',
    jsonb_build_object('is_demo',true,'seed_tag',x.seed_tag,'notice','Dokumen fiktif untuk pengujian'),
    jsonb_build_object('demo',true,'seed_tag',x.seed_tag)
  FROM (VALUES
    ('DEMO-DOC-001','CONTOH DEMO — Register Administrasi Desa','SAD_DEMO_DOCUMENT_001'),
    ('DEMO-DOC-002','CONTOH DEMO — Berita Acara Kegiatan','SAD_DEMO_DOCUMENT_002'),
    ('DEMO-DOC-003','CONTOH DEMO — Daftar Inventaris','SAD_DEMO_DOCUMENT_003')
  ) AS x(doc_no,title,seed_tag)
  WHERE NOT EXISTS (SELECT 1 FROM village.documents d WHERE d.organization_id=v_org AND d.territory_id=v_territory AND d.administrative_form->>'seed_tag'=x.seed_tag);

  INSERT INTO village.letters
    (organization_id, territory_id, letter_number, letter_type, subject, status, administrative_form)
  SELECT v_org,v_territory,x.letter_no,'DEMO',x.subject,'DRAFT',
    jsonb_build_object('demo',true,'seed_tag',x.seed_tag,'notice','Surat fiktif; tidak berlaku sebagai surat resmi')
  FROM (VALUES
    ('DEMO-DRAFT-001','CONTOH DEMO — Draf Surat Keterangan','SAD_DEMO_LETTER_001'),
    ('DEMO-DRAFT-002','CONTOH DEMO — Draf Surat Pengantar','SAD_DEMO_LETTER_002'),
    ('DEMO-DRAFT-003','CONTOH DEMO — Draf Surat Undangan','SAD_DEMO_LETTER_003')
  ) AS x(letter_no,subject,seed_tag)
  WHERE NOT EXISTS (SELECT 1 FROM village.letters l WHERE l.organization_id=v_org AND l.territory_id=v_territory AND l.administrative_form->>'seed_tag'=x.seed_tag);

  INSERT INTO village.governance_units
    (organization_id, territory_id, unit_code, unit_name, unit_type, status, duties, notes, administrative_form)
  SELECT v_org,v_territory,x.unit_code,x.unit_name,'DEMO','DRAFT',
    'Contoh struktur; harus disesuaikan dengan Perdes dan data resmi.',
    'Data fiktif demonstrasi — bukan unit pemerintahan resmi.',
    jsonb_build_object('demo',true,'seed_tag',x.seed_tag)
  FROM (VALUES
    ('DEMO-UNIT-001','CONTOH DEMO — Sekretariat Desa','SAD_DEMO_UNIT_001'),
    ('DEMO-UNIT-002','CONTOH DEMO — Pelaksana Kewilayahan','SAD_DEMO_UNIT_002'),
    ('DEMO-UNIT-003','CONTOH DEMO — Pelaksana Teknis','SAD_DEMO_UNIT_003')
  ) AS x(unit_code,unit_name,seed_tag)
  WHERE NOT EXISTS (SELECT 1 FROM village.governance_units g WHERE g.organization_id=v_org AND g.territory_id=v_territory AND g.unit_code=x.unit_code);
END $$;