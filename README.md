# Sistem Administrasi Desa

Modern village administration application using the OpenSID database as the operational data layer.

## Architecture
OpenSID data layer → Sistem Administrasi Desa → RT/RW CONNECT (Supabase) → GPFFE governed data exchange.

The application does not create a second citizen master. The first phase is read-first against OpenSID-compatible MySQL tables.

## Runtime
- PHP 8.1+
- PDO MySQL
- Responsive Indonesian UI
- Modules: Dashboard, Penduduk, Keluarga, Perangkat Desa, Surat, Permohonan, Keuangan, Pembangunan, Aset, DTKS/Bantuan

## Configuration
Copy `.env.example` to the deployment environment and provide DB_* variables.
