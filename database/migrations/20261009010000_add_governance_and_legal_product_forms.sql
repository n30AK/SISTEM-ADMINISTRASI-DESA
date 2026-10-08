-- Persistent right-side forms: Pemerintahan Desa + Produk Hukum Desa
-- Applied to Supabase project gzdusguveeeflmlvvmwe on 2026-10-09.
-- Includes org/territory scope, RLS, restricted grants, soft-delete fields and audit triggers.

create table if not exists village.governance_units (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  territory_id uuid not null,
  unit_code text not null,
  unit_name text not null,
  unit_type text not null,
  parent_unit text,
  leader_name text,
  leader_role text,
  decree_number text,
  decree_date date,
  start_date date,
  end_date date,
  status text not null default 'ACTIVE' check (status in ('DRAFT','ACTIVE','INACTIVE','ARCHIVED')),
  duties text,
  contact text,
  notes text,
  administrative_form jsonb not null default '{}'::jsonb,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid
);

create index if not exists governance_units_scope_idx on village.governance_units(organization_id,territory_id);
create index if not exists governance_units_form_gin_idx on village.governance_units using gin(administrative_form);
alter table village.governance_units enable row level security;
revoke all on village.governance_units from anon;
grant select,insert,update on village.governance_units to authenticated;
drop policy if exists governance_units_select on village.governance_units;
create policy governance_units_select on village.governance_units for select to authenticated using (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop policy if exists governance_units_insert on village.governance_units;
create policy governance_units_insert on village.governance_units for insert to authenticated with check (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop policy if exists governance_units_update on village.governance_units;
create policy governance_units_update on village.governance_units for update to authenticated
using (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
)
with check (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop trigger if exists governance_units_audit on village.governance_units;
create trigger governance_units_audit after insert or update or delete on village.governance_units for each row execute function village.audit_row_change();

create table if not exists village.legal_products (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  territory_id uuid not null,
  product_number text not null,
  product_type text not null,
  title text not null,
  subject text,
  issue_date date,
  effective_date date,
  issuing_authority text,
  legal_basis text,
  status text not null default 'DRAFT' check (status in ('DRAFT','REVIEW','APPROVED','PUBLISHED','ARCHIVED')),
  publication_reference text,
  summary text,
  full_text_reference text,
  attachment_reference text,
  responsible_officer text,
  notes text,
  administrative_form jsonb not null default '{}'::jsonb,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  deleted_by uuid
);

create index if not exists legal_products_scope_idx on village.legal_products(organization_id,territory_id);
create index if not exists legal_products_form_gin_idx on village.legal_products using gin(administrative_form);
alter table village.legal_products enable row level security;
revoke all on village.legal_products from anon;
grant select,insert,update on village.legal_products to authenticated;
drop policy if exists legal_products_select on village.legal_products;
create policy legal_products_select on village.legal_products for select to authenticated using (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop policy if exists legal_products_insert on village.legal_products;
create policy legal_products_insert on village.legal_products for insert to authenticated with check (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop policy if exists legal_products_update on village.legal_products;
create policy legal_products_update on village.legal_products for update to authenticated
using (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
)
with check (
  organization_id=(select organization_id from public.my_context() limit 1)
  and territory_id=(select territory_id from public.my_context() limit 1)
);
drop trigger if exists legal_products_audit on village.legal_products;
create trigger legal_products_audit after insert or update or delete on village.legal_products for each row execute function village.audit_row_change();
