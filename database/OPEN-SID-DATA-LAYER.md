# OpenSID data layer

The supplied OpenSID baseline contains application migrations and schema inventory rather than a single SQL dump.

Primary tables identified:
- tweb_penduduk
- tweb_keluarga
- tweb_desa_pamong
- surat_keluar
- surat_masuk
- permohonan_surat
- keuangan_master and keuangan_ta_*
- pembangunan
- inventaris_asset
- dtks and dtks_*
- analisis_*
- log_penduduk / log_keluarga / log_surat

Principle: read existing OpenSID records first; do not duplicate the citizen master.
