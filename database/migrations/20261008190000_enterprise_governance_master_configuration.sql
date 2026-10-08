-- Enterprise governance: master configuration, audit evidence and recoverable soft delete.
create table if not exists village.master_configuration (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null,
  territory_id uuid not null,
  config_version integer not null default 1,
  identity jsonb not null default '{}'::jsonb,
  government jsonb not null default '{}'::jsonb,
  letterhead jsonb not null default '{}'::jsonb,
  letter_format jsonb not null default '{}'::jsonb,
  document_templates jsonb not null default '{}'::jsonb,
  branding jsonb not null default '{}'::jsonb,
  territory jsonb not null default '{}'::jsonb,
  service_settings jsonb not null default '{}'::jsonb,
  finance_settings jsonb not null default '{}'::jsonb,
  access_settings jsonb not null default '{}'::jsonb,
  workflow_settings jsonb not null default '{}'::jsonb,
  notification_settings jsonb not null default '{}'::jsonb,
  security_settings jsonb not null default '{}'::jsonb,
  integration_settings jsonb not null default '{}'::jsonb,
  system_settings jsonb not null default '{}'::jsonb,
  metadata jsonb not null default '{}'::jsonb,
  created_by uuid,
  updated_by uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, territory_id)
);

alter table village.master_configuration enable row level security;
drop policy if exists master_configuration_select on village.master_configuration;
drop policy if exists master_configuration_insert on village.master_configuration;
drop policy if exists master_configuration_update on village.master_configuration;
create policy master_configuration_select on village.master_configuration for select to authenticated
using (organization_id=(select organization_id from public.my_context()) and territory_id=(select territory_id from public.my_context()));
create policy master_configuration_insert on village.master_configuration for insert to authenticated
with check (organization_id=(select organization_id from public.my_context()) and territory_id=(select territory_id from public.my_context()));
create policy master_configuration_update on village.master_configuration for update to authenticated
using (organization_id=(select organization_id from public.my_context()) and territory_id=(select territory_id from public.my_context()))
with check (organization_id=(select organization_id from public.my_context()) and territory_id=(select territory_id from public.my_context()));
grant select,insert,update on village.master_configuration to authenticated;

alter table village.officials add column if not exists deleted_at timestamptz;
alter table village.officials add column if not exists deleted_by uuid;
alter table village.letters add column if not exists deleted_at timestamptz;
alter table village.letters add column if not exists deleted_by uuid;
alter table village.budgets add column if not exists deleted_at timestamptz;
alter table village.budgets add column if not exists deleted_by uuid;
alter table village.programs add column if not exists deleted_at timestamptz;
alter table village.programs add column if not exists deleted_by uuid;
alter table village.assets add column if not exists deleted_at timestamptz;
alter table village.assets add column if not exists deleted_by uuid;
alter table village.documents add column if not exists deleted_at timestamptz;
alter table village.documents add column if not exists deleted_by uuid;
alter table village.services add column if not exists deleted_at timestamptz;
alter table village.services add column if not exists deleted_by uuid;

alter table village.audit_log add column if not exists territory_id uuid;
alter table village.audit_log add column if not exists old_data jsonb;
alter table village.audit_log add column if not exists new_data jsonb;
alter table village.audit_log add column if not exists metadata jsonb not null default '{}'::jsonb;

create or replace function village.audit_row_change()
returns trigger language plpgsql security definer set search_path=village,public as $$
declare org_id uuid; terr_id uuid; rid uuid;
begin
  org_id:=case when tg_op='DELETE' then old.organization_id else new.organization_id end;
  terr_id:=case when tg_op='DELETE' then old.territory_id else new.territory_id end;
  rid:=case when tg_op='DELETE' then old.id else new.id end;
  insert into village.audit_log(organization_id,territory_id,actor_user_id,action,entity_name,entity_id,details,old_data,new_data,metadata)
  values(org_id,terr_id,auth.uid(),tg_op,tg_table_name,rid,
    jsonb_build_object('source','database_trigger','table',tg_table_name),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) end,
    jsonb_build_object('timestamp',now()));
  return case when tg_op='DELETE' then old else new end;
end $$;
revoke all on function village.audit_row_change() from public;
revoke execute on function village.audit_row_change() from anon,authenticated;

drop trigger if exists trg_officials_audit on village.officials;
create trigger trg_officials_audit after insert or update or delete on village.officials for each row execute function village.audit_row_change();
drop trigger if exists trg_letters_audit on village.letters;
create trigger trg_letters_audit after insert or update or delete on village.letters for each row execute function village.audit_row_change();
drop trigger if exists trg_budgets_audit on village.budgets;
create trigger trg_budgets_audit after insert or update or delete on village.budgets for each row execute function village.audit_row_change();
drop trigger if exists trg_programs_audit on village.programs;
create trigger trg_programs_audit after insert or update or delete on village.programs for each row execute function village.audit_row_change();
drop trigger if exists trg_assets_audit on village.assets;
create trigger trg_assets_audit after insert or update or delete on village.assets for each row execute function village.audit_row_change();
drop trigger if exists trg_documents_audit on village.documents;
create trigger trg_documents_audit after insert or update or delete on village.documents for each row execute function village.audit_row_change();
drop trigger if exists trg_services_audit on village.services;
create trigger trg_services_audit after insert or update or delete on village.services for each row execute function village.audit_row_change();

create or replace function village.restore_row(p_table text,p_id uuid)
returns boolean language plpgsql security definer set search_path=village,public as $$
declare t text:=lower(p_table); affected integer;
begin
  if t not in ('officials','letters','budgets','programs','assets','documents','services') then raise exception 'Tabel pemulihan tidak diizinkan'; end if;
  execute format('update village.%I set deleted_at=null,deleted_by=null where id=$1 and organization_id=(select organization_id from public.my_context()) and territory_id=(select territory_id from public.my_context())',t) using p_id;
  get diagnostics affected=row_count;
  return affected>0;
end $$;
revoke all on function village.restore_row(text,uuid) from public;
grant execute on function village.restore_row(text,uuid) to authenticated;

create index if not exists master_configuration_scope_idx on village.master_configuration(organization_id,territory_id);
create index if not exists audit_log_scope_time_idx on village.audit_log(organization_id,territory_id,created_at desc);
