# Architecture — Sistem Administrasi Desa

## Data ownership

OpenSID remains the source-compatible operational data layer for legacy/imported village administration data. RT/RW CONNECT Supabase remains the governed shared platform for identity, territory, organization, access control, and cross-system exchange.

### Canonical domains
- Identity: `public.persons`, `public.households`
- Territory: `public.territories`
- Organization/access: `public.organizations`, `public.role_assignments`
- Village administration: `village.*`
- Cross-system exchange: `public.exchange_*`
- GPFFE: `public.gpffe_economic_exchange`

## OpenSID synchronization

OpenSID MySQL is external to Supabase. Synchronization must therefore be explicit and auditable.

Flow:

OpenSID MySQL
→ export/adapter
→ authenticated sync endpoint
→ validation
→ canonical RT/RW CONNECT records
→ governed exchange
→ GPFFE

Every batch is recorded in `public.opensid_sync_batches`.

No service-role key is placed in the browser.
No direct public connection to the OpenSID MySQL server is required.

## Production rule

Do not perform destructive migration of OpenSID tables. Map first, validate, then promote.
