create table if not exists public.opensid_sync_batches (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id),
  source_system text not null default 'opensid',
  source_version text,
  entity_type text not null,
  source_count integer not null default 0,
  accepted_count integer not null default 0,
  rejected_count integer not null default 0,
  status text not null default 'RECEIVED' check (status in ('RECEIVED','VALIDATED','APPLIED','PARTIAL','REJECTED')),
  error_summary jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  applied_at timestamptz
);
create index if not exists idx_opensid_sync_batches_org on public.opensid_sync_batches(organization_id,created_at desc);
alter table public.opensid_sync_batches enable row level security;
create policy opensid_sync_batches_org_access on public.opensid_sync_batches
for all to authenticated
using (organization_id is null or exists (
  select 1 from public.role_assignments ra
  where ra.organization_id=opensid_sync_batches.organization_id
    and ra.user_id=(select auth.uid()) and ra.active=true
))
with check (organization_id is null or exists (
  select 1 from public.role_assignments ra
  where ra.organization_id=opensid_sync_batches.organization_id
    and ra.user_id=(select auth.uid()) and ra.active=true
));
grant select,insert,update on public.opensid_sync_batches to authenticated;
