# Enterprise Architecture — Sistem Administrasi Desa

## Target Architecture

The application is a standalone village administration platform. OpenSID is used as a reference for administrative concepts and forms; it is not a runtime dependency.

### Core layers

1. Presentation: operator dashboard, public service interface and administrative forms.
2. Application: village administration modules, workflows and business rules.
3. Governance: RLS, roles, permissions, audit trail, approval workflow and data retention.
4. Master Configuration: village identity, officials, letterhead, document templates, branding, service hours, territory and integration settings.
5. Data: Supabase PostgreSQL with organization/territory isolation.
6. Integration: RT/RW CONNECT and GPFFE through governed adapters.
7. Intelligence: regulatory knowledge, AI Companion and advisory agents.

### Enterprise modules

- Data Desa
- Pemerintahan Desa
- Produk Hukum & Naskah Dinas
- Pelayanan Publik
- Keuangan Desa
- Pembangunan Desa
- Indeks Desa & SDGs Desa
- Bantuan Sosial
- Aset Desa
- BUM Desa & Ekonomi
- Musyawarah & Partisipasi
- Informasi Publik
- Arsip & Dokumen
- Kepatuhan
- Privasi & Keamanan
- Integrasi
- AI Companion
- Pengaturan Desa
- Administrasi Sistem

### Master Configuration

The configuration center is the single source of administrative identity for:

- village name and codes
- government officials
- letterhead and logos
- letter numbering
- document templates
- branding
- Dusun/RW/RT
- service hours and channels
- financial defaults
- roles and workflow
- notifications
- integration mappings

The final implementation must persist this configuration in Supabase and scope it to the correct organization and territory.

### Production gates

The platform must not be labeled production-ready until these are verified:

- Supabase connectivity
- RLS policy behavior
- Master Configuration persistence
- Audit Trail
- Soft Delete / recovery
- Version history
- Workflow transition enforcement
- RBAC
- backup/recovery
- integration health
- CI and deployment health

