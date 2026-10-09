-- Close remaining role-gated operational paths: archive restore and economic evidence review.
insert into public.permissions (permission_code, permission_name, critical)
values ('data.restore', 'Restore archived operational records', true)
on conflict (permission_code) do update
set permission_name = excluded.permission_name,
    critical = excluded.critical;

create or replace function village.restore_row(p_table text, p_id uuid)
returns boolean
language plpgsql
security definer
set search_path to 'village', 'public'
as $function$
declare
  t text := lower(p_table);
  restored_count integer := 0;
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'AUTHENTICATION_REQUIRED';
  end if;
  if not village.has_current_permission('data.restore') then
    raise exception using errcode = '42501', message = 'RESTORE_PERMISSION_REQUIRED';
  end if;
  if t not in ('officials','letters','budgets','programs','assets','documents','services') then
    raise exception 'Tabel pemulihan tidak diizinkan';
  end if;
  execute format(
    'update village.%I set deleted_at=null, deleted_by=null where id=$1 and organization_id=(select organization_id from village.my_context() limit 1) and territory_id=(select territory_id from village.my_context() limit 1) and deleted_at is not null',
    t
  ) using p_id;
  get diagnostics restored_count = row_count;
  return restored_count > 0;
end
$function$;

revoke all on function village.restore_row(text, uuid) from public, anon;
grant execute on function village.restore_row(text, uuid) to authenticated;

create or replace function public.review_economic_evidence(
  p_evidence_id uuid,
  p_status text,
  p_review_notes text
)
returns table(id uuid, status text, reviewed_by uuid, reviewed_at timestamptz)
language plpgsql
set search_path to 'pg_catalog', 'public', 'village'
as $function$
declare
  v_row village.economic_evidence_inbox%rowtype;
begin
  if auth.uid() is null then
    raise exception using errcode = '42501', message = 'AUTHENTICATION_REQUIRED';
  end if;
  if p_evidence_id is null or p_status not in ('under_review','verified','rejected') then
    raise exception using errcode = '22023', message = 'INVALID_REVIEW_INPUT';
  end if;
  if p_review_notes is null or length(btrim(p_review_notes)) < 5 or length(p_review_notes) > 2000 then
    raise exception using errcode = '22023', message = 'REVIEW_NOTE_REQUIRED';
  end if;
  if p_status = 'under_review' then
    if not village.has_current_permission('workflow.review') then
      raise exception using errcode = '42501', message = 'WORKFLOW_REVIEW_PERMISSION_REQUIRED';
    end if;
  elsif not village.has_current_permission('workflow.verify') then
    raise exception using errcode = '42501', message = 'WORKFLOW_VERIFY_PERMISSION_REQUIRED';
  end if;

  select e.* into v_row
  from village.economic_evidence_inbox e
  where e.id = p_evidence_id
    and e.organization_id = (select organization_id from village.my_context() limit 1)
    and e.territory_id = (select territory_id from village.my_context() limit 1)
  for update;

  if not found then
    raise exception using errcode = '42501', message = 'EVIDENCE_NOT_FOUND_OR_OUT_OF_SCOPE';
  end if;

  update village.economic_evidence_inbox e
  set status = p_status,
      review_notes = btrim(p_review_notes)
  where e.id = v_row.id;

  return query
  select e.id, e.status, e.reviewed_by, e.reviewed_at
  from village.economic_evidence_inbox e
  where e.id = v_row.id;
end;
$function$;

drop policy if exists village_scope_update on village.economic_evidence_inbox;
create policy village_scope_update on village.economic_evidence_inbox
for update to authenticated
using (
  organization_id = (select organization_id from village.my_context() limit 1)
  and territory_id = (select territory_id from village.my_context() limit 1)
  and (village.has_current_permission('workflow.review') or village.has_current_permission('workflow.verify'))
)
with check (
  organization_id = (select organization_id from village.my_context() limit 1)
  and territory_id = (select territory_id from village.my_context() limit 1)
  and (
    (status = 'under_review' and village.has_current_permission('workflow.review'))
    or (status in ('verified','rejected') and village.has_current_permission('workflow.verify'))
  )
);
