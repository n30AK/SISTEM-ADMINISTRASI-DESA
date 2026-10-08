-- Transactional service layer. Citizen master data remains external/OpenSID-compatible.
create table if not exists village.service_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  territory_id uuid not null,
  service_id uuid not null references village.services(id),
  citizen_user_id uuid,
  request_number text,
  status text not null default 'SUBMITTED' check (status in ('DRAFT','SUBMITTED','VERIFICATION','APPROVED','REJECTED','READY','ISSUED','CLOSED')),
  applicant_name text not null,
  applicant_phone text,
  payload jsonb not null default '{}'::jsonb,
  submitted_at timestamptz,
  due_at timestamptz,
  processed_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists service_requests_number_uq on village.service_requests(organization_id,request_number) where request_number is not null;
create index if not exists service_requests_org_status_idx on village.service_requests(organization_id,status,created_at desc);
create index if not exists service_requests_citizen_idx on village.service_requests(citizen_user_id,created_at desc);

create table if not exists village.service_request_events (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references village.service_requests(id) on delete cascade,
  organization_id uuid not null,
  from_status text,
  to_status text not null,
  note text,
  actor_user_id uuid,
  created_at timestamptz not null default now()
);
create index if not exists service_request_events_request_idx on village.service_request_events(request_id,created_at);

alter table village.service_requests enable row level security;
alter table village.service_request_events enable row level security;
drop policy if exists service_requests_org_access on village.service_requests;
create policy service_requests_org_access on village.service_requests for all to authenticated using (village.user_has_org(organization_id)) with check (village.user_has_org(organization_id));
drop policy if exists service_request_events_org_access on village.service_request_events;
create policy service_request_events_org_access on village.service_request_events for all to authenticated using (village.user_has_org(organization_id)) with check (village.user_has_org(organization_id));


-- Keep workflow timestamps and append an immutable status transition event.
create or replace function village.touch_service_request()
returns trigger
language plpgsql
security invoker
set search_path = village, public
as $$
begin
  new.updated_at := now();
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    insert into village.service_request_events (
      request_id, organization_id, from_status, to_status, note, actor_user_id
    ) values (
      new.id, new.organization_id, old.status, new.status, null, auth.uid()
    );
  end if;
  return new;
end;
$$;

drop trigger if exists trg_service_request_touch on village.service_requests;
create trigger trg_service_request_touch
before update on village.service_requests
for each row execute function village.touch_service_request();
