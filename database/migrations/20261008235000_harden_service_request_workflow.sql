-- Service request workflow hardening
-- Scope: organization + territory, soft delete, audit, and controlled status transitions.

alter table village.service_requests
  add column if not exists source text default 'DESA',
  add column if not exists authority text,
  add column if not exists deleted_at timestamptz,
  add column if not exists deleted_by uuid;

alter table village.service_request_events
  add column if not exists territory_id uuid references public.territories(id);

update village.service_request_events e
set territory_id = r.territory_id
from village.service_requests r
where r.id = e.request_id and e.territory_id is null;

create index if not exists idx_service_requests_scope_status
  on village.service_requests(organization_id, territory_id, status, due_at);

create index if not exists idx_service_request_events_scope
  on village.service_request_events(organization_id, territory_id, created_at);

drop policy if exists service_requests_org_access on village.service_requests;
drop policy if exists service_request_events_org_access on village.service_request_events;

create policy service_requests_scope_access on village.service_requests
for all to authenticated
using (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
)
with check (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
);

create policy service_request_events_scope_access on village.service_request_events
for all to authenticated
using (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
)
with check (
  organization_id = (select organization_id from public.my_context() limit 1)
  and territory_id = (select territory_id from public.my_context() limit 1)
);

revoke delete, truncate, references, trigger on village.service_requests from authenticated;
revoke delete, truncate, references, trigger on village.service_request_events from authenticated;
grant select, insert, update on village.service_requests to authenticated;
grant select, insert, update on village.service_request_events to authenticated;

create or replace function village.service_request_status_guard()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then return new; end if;
  if new.status = old.status then return new; end if;

  if not (
    (old.status='DRAFT' and new.status in ('SUBMITTED','REJECTED')) or
    (old.status='SUBMITTED' and new.status in ('VERIFICATION','REJECTED')) or
    (old.status='VERIFICATION' and new.status in ('APPROVED','REJECTED')) or
    (old.status='APPROVED' and new.status in ('READY','REJECTED')) or
    (old.status='READY' and new.status in ('ISSUED','REJECTED')) or
    (old.status='ISSUED' and new.status='CLOSED') or
    (old.status='REJECTED' and new.status in ('DRAFT','CLOSED'))
  ) then
    raise exception 'Transisi status permohonan tidak diizinkan: % -> %', old.status, new.status;
  end if;

  if new.status='SUBMITTED' and new.submitted_at is null then
    new.submitted_at=now();
  end if;
  return new;
end;
$$;

alter function village.service_request_status_guard()
  set search_path = pg_catalog, village;

drop trigger if exists trg_service_request_status_guard on village.service_requests;
create trigger trg_service_request_status_guard
before insert or update of status on village.service_requests
for each row execute function village.service_request_status_guard();

drop trigger if exists trg_service_requests_audit on village.service_requests;
create trigger trg_service_requests_audit
after insert or update on village.service_requests
for each row execute function village.audit_row_change();

drop trigger if exists trg_service_request_events_audit on village.service_request_events;
create trigger trg_service_request_events_audit
after insert or update on village.service_request_events
for each row execute function village.audit_row_change();

create or replace function village.service_request_sync_event()
returns trigger
language plpgsql
as $$
begin
  if tg_op='UPDATE' and new.status is distinct from old.status then
    insert into village.service_request_events(
      request_id, organization_id, territory_id, from_status, to_status,
      note, actor_user_id
    ) values (
      new.id, new.organization_id, new.territory_id, old.status, new.status,
      null, auth.uid()
    );
  end if;
  return new;
end;
$$;

alter function village.service_request_sync_event()
  set search_path = pg_catalog, village, public;

drop trigger if exists trg_service_request_sync_event on village.service_requests;
create trigger trg_service_request_sync_event
after update of status on village.service_requests
for each row execute function village.service_request_sync_event();

notify pgrst, 'reload schema';
