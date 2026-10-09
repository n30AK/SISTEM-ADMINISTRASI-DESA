-- JOLIE economic evidence integration inbox. Additive and fail-closed: no client role receives access.
create table if not exists village.integration_tenant_mappings (
  id uuid primary key default gen_random_uuid(),
  source_system text not null check (source_system in ('JOLIE')),
  source_tenant_ref text not null check (length(source_tenant_ref) between 1 and 120),
  target_territory_ref text not null check (length(target_territory_ref) between 1 and 120),
  organization_id uuid not null references public.organizations(id),
  territory_id uuid not null references public.territories(id),
  is_active boolean not null default false,
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_system, source_tenant_ref, target_territory_ref),
  check ((is_active = false) or (approved_by is not null and approved_at is not null))
);

create table if not exists village.economic_evidence_inbox (
  id uuid primary key default gen_random_uuid(),
  source_system text not null check (source_system in ('JOLIE')),
  event_id uuid not null,
  schema_version text not null check (schema_version = '1.0'),
  event_type text not null check (event_type = 'business.metric.snapshot'),
  source_tenant_ref text not null,
  target_territory_ref text not null,
  organization_id uuid not null references public.organizations(id),
  territory_id uuid not null references public.territories(id),
  target_program_id uuid references village.programs(id),
  period_start date not null,
  period_end date not null,
  metric_code text not null check (metric_code in ('completed_orders','active_businesses','active_products','production_volume','training_participants','aggregate_sales')),
  metric_value numeric(20,4) not null check (metric_value >= 0),
  metric_unit text not null check (length(metric_unit) between 1 and 32),
  aggregation_scope text not null check (aggregation_scope in ('tenant_period','program_period')),
  currency text check (currency is null or currency ~ '^[A-Z]{3}$'),
  evidence jsonb not null default '[]'::jsonb check (jsonb_typeof(evidence) = 'array'),
  provenance jsonb not null default '{}'::jsonb check (jsonb_typeof(provenance) = 'object'),
  payload_sha256 text not null check (payload_sha256 ~ '^[a-f0-9]{64}$'),
  status text not null default 'received' check (status in ('received','validated','source_reported','under_review','verified','rejected','superseded')),
  review_notes text,
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  received_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (source_system, event_id),
  check (period_end >= period_start),
  check ((status not in ('verified','rejected')) or (reviewed_by is not null and reviewed_at is not null))
);

create index if not exists economic_evidence_scope_period_idx
  on village.economic_evidence_inbox (organization_id, territory_id, period_start desc, status);
create index if not exists economic_evidence_program_idx
  on village.economic_evidence_inbox (target_program_id) where target_program_id is not null;

alter table village.integration_tenant_mappings enable row level security;
alter table village.economic_evidence_inbox enable row level security;
revoke all on village.integration_tenant_mappings from anon, authenticated;
revoke all on village.economic_evidence_inbox from anon, authenticated;
grant all on village.integration_tenant_mappings to service_role;
grant all on village.economic_evidence_inbox to service_role;

drop trigger if exists audit_economic_evidence_inbox_changes on village.economic_evidence_inbox;
create trigger audit_economic_evidence_inbox_changes
after insert or update or delete on village.economic_evidence_inbox
for each row execute function village.audit_row_change();

notify pgrst, 'reload schema';
