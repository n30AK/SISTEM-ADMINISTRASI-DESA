-- SISTEM ADMINISTRASI DESA
-- Population event workflow: territory-scoped, auditable, archive-only.

alter table village.population_events
  add column if not exists person_id uuid null references public.sv_master_persons(id),
  add column if not exists household_id uuid null references public.sv_master_households(id),
  add column if not exists status text not null default 'DRAFT',
  add column if not exists source text not null default 'DESA',
  add column if not exists authority text null,
  add column if not exists payload jsonb not null default '{}'::jsonb,
  add column if not exists notes text null,
  add column if not exists processed_by uuid null,
  add column if not exists processed_at timestamptz null,
  add column if not exists deleted_at timestamptz null,
  add column if not exists deleted_by uuid null,
  add column if not exists updated_at timestamptz not null default now();

alter table village.population_events drop constraint if exists population_events_event_type_ck;
alter table village.population_events
  add constraint population_events_event_type_ck
  check (event_type in ('LAHIR','MENINGGAL','DATANG','PINDAH','PERUBAHAN_DATA','PERUBAHAN_KK'));

alter table village.population_events drop constraint if exists population_events_status_ck;
alter table village.population_events
  add constraint population_events_status_ck
  check (status in ('DRAFT','DIAJUKAN','DIVERIFIKASI','SELESAI','DITOLAK','DIARSIPKAN'));

alter table village.population_events enable row level security;

revoke all on village.population_events from anon;
revoke delete, truncate, references, trigger on village.population_events from authenticated;
grant select, insert, update on village.population_events to authenticated;

drop policy if exists village_org_access on village.population_events;
drop policy if exists population_events_select_scope on village.population_events;
drop policy if exists population_events_insert_scope on village.population_events;
drop policy if exists population_events_update_scope on village.population_events;

create policy population_events_select_scope
on village.population_events
for select to authenticated
using (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
);

create policy population_events_insert_scope
on village.population_events
for insert to authenticated
with check (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
);

create policy population_events_update_scope
on village.population_events
for update to authenticated
using (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
)
with check (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
);

create index if not exists idx_population_events_scope_date
  on village.population_events (organization_id, territory_id, event_date desc);

create index if not exists idx_population_events_person
  on village.population_events (person_id)
  where person_id is not null;

create index if not exists idx_population_events_household
  on village.population_events (household_id)
  where household_id is not null;

create index if not exists idx_population_events_status
  on village.population_events (organization_id, territory_id, status)
  where deleted_at is null;

drop trigger if exists trg_population_events_audit on village.population_events;
create trigger trg_population_events_audit
after insert or update or delete on village.population_events
for each row execute function village.audit_row_change();

notify pgrst, 'reload schema';
