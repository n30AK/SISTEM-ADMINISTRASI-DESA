-- Harden economic evidence review: move authorization into RLS and make exposed RPCs invoker-rights.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.can_review_economic_evidence(p_organization_id uuid, p_territory_id uuid)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public
as $function$
  select auth.uid() is not null and exists (
    select 1
    from public.role_assignments ra
    join public.roles r on r.id = ra.role_id
    where ra.user_id = auth.uid()
      and ra.active = true
      and (ra.starts_at is null or ra.starts_at <= now())
      and (ra.ends_at is null or ra.ends_at > now())
      and r.role_code in ('PLATFORM_ADMIN','VILLAGE_VALIDATOR','RW_REVIEWER')
      and ra.organization_id = p_organization_id
      and ra.scope_territory_id = p_territory_id
  );
$function$;

revoke all on function private.can_review_economic_evidence(uuid, uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.can_review_economic_evidence(uuid, uuid) to authenticated;

drop policy if exists economic_evidence_reviewer_select on village.economic_evidence_inbox;
create policy economic_evidence_reviewer_select
on village.economic_evidence_inbox
for select to authenticated
using (private.can_review_economic_evidence(organization_id, territory_id));

drop policy if exists economic_evidence_reviewer_update on village.economic_evidence_inbox;
create policy economic_evidence_reviewer_update
on village.economic_evidence_inbox
for update to authenticated
using (private.can_review_economic_evidence(organization_id, territory_id))
with check (private.can_review_economic_evidence(organization_id, territory_id));

grant select on village.economic_evidence_inbox to authenticated;
grant update (status, review_notes) on village.economic_evidence_inbox to authenticated;

create or replace function village.guard_economic_evidence_review()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, village
as $function$
begin
  if new.status is distinct from old.status then
    if new.status not in ('under_review','verified','rejected') then
      raise exception using errcode = '22023', message = 'INVALID_REVIEW_STATUS';
    end if;
    if old.status in ('rejected','superseded') then
      raise exception using errcode = '55000', message = 'EVIDENCE_IS_TERMINAL';
    end if;
    if new.status = 'verified' and jsonb_array_length(coalesce(old.evidence, '[]'::jsonb)) = 0 then
      raise exception using errcode = '22023', message = 'EVIDENCE_ATTACHMENT_REQUIRED_FOR_VERIFICATION';
    end if;
    if new.review_notes is null or length(btrim(new.review_notes)) < 5 or length(new.review_notes) > 2000 then
      raise exception using errcode = '22023', message = 'REVIEW_NOTE_REQUIRED';
    end if;
    new.reviewed_by := auth.uid();
    new.reviewed_at := now();
  elsif new.review_notes is distinct from old.review_notes then
    raise exception using errcode = '22023', message = 'REVIEW_STATUS_CHANGE_REQUIRED';
  end if;
  return new;
end;
$function$;

drop trigger if exists guard_economic_evidence_review on village.economic_evidence_inbox;
create trigger guard_economic_evidence_review
before update on village.economic_evidence_inbox
for each row execute function village.guard_economic_evidence_review();

create or replace function public.list_economic_evidence(
  p_status text default null,
  p_limit integer default 100
)
returns table (
  id uuid, source_system text, event_id uuid, source_tenant_ref text, target_territory_ref text,
  organization_id uuid, territory_id uuid, target_program_id uuid, period_start date, period_end date,
  metric_code text, metric_value numeric, metric_unit text, aggregation_scope text, currency text,
  evidence jsonb, provenance jsonb, payload_sha256 text, status text, review_notes text,
  reviewed_by uuid, reviewed_at timestamptz, received_at timestamptz
)
language plpgsql
stable
security invoker
set search_path = pg_catalog, public, village
as $function$
declare
  v_user_id uuid := auth.uid();
begin
  if v_user_id is null then
    raise exception using errcode = '42501', message = 'AUTHENTICATION_REQUIRED';
  end if;
  if p_status is not null and p_status not in ('received','validated','source_reported','under_review','verified','rejected','superseded') then
    raise exception using errcode = '22023', message = 'INVALID_STATUS_FILTER';
  end if;
  return query
  select e.id, e.source_system, e.event_id, e.source_tenant_ref, e.target_territory_ref,
         e.organization_id, e.territory_id, e.target_program_id, e.period_start, e.period_end,
         e.metric_code, e.metric_value, e.metric_unit, e.aggregation_scope, e.currency,
         e.evidence, e.provenance, e.payload_sha256, e.status, e.review_notes,
         e.reviewed_by, e.reviewed_at, e.received_at
  from village.economic_evidence_inbox e
  where (p_status is null or e.status = p_status)
  order by e.received_at desc
  limit greatest(1, least(coalesce(p_limit, 100), 200));
end;
$function$;

create or replace function public.review_economic_evidence(
  p_evidence_id uuid,
  p_status text,
  p_review_notes text
)
returns table (id uuid, status text, reviewed_by uuid, reviewed_at timestamptz)
language plpgsql
security invoker
set search_path = pg_catalog, public, village
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

  select e.* into v_row
  from village.economic_evidence_inbox e
  where e.id = p_evidence_id
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

revoke all on function public.list_economic_evidence(text, integer) from public, anon;
revoke all on function public.review_economic_evidence(uuid, text, text) from public, anon;
grant execute on function public.list_economic_evidence(text, integer) to authenticated;
grant execute on function public.review_economic_evidence(uuid, text, text) to authenticated;
