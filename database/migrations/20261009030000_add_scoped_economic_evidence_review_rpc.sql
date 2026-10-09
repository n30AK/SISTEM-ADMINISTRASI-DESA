-- Controlled review API for Jolie economic evidence.
-- Raw inbox remains inaccessible to anon/authenticated; access is only through scoped RPCs.
create or replace function public.list_economic_evidence(
  p_status text default null,
  p_limit integer default 100
)
returns table (
  id uuid,
  source_system text,
  event_id uuid,
  source_tenant_ref text,
  target_territory_ref text,
  organization_id uuid,
  territory_id uuid,
  target_program_id uuid,
  period_start date,
  period_end date,
  metric_code text,
  metric_value numeric,
  metric_unit text,
  aggregation_scope text,
  currency text,
  evidence jsonb,
  provenance jsonb,
  payload_sha256 text,
  status text,
  review_notes text,
  reviewed_by uuid,
  reviewed_at timestamptz,
  received_at timestamptz
)
language plpgsql
stable
security definer
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
  if not exists (
    select 1
    from public.role_assignments ra
    join public.roles r on r.id = ra.role_id
    where ra.user_id = v_user_id
      and ra.active = true
      and (ra.starts_at is null or ra.starts_at <= now())
      and (ra.ends_at is null or ra.ends_at > now())
      and r.role_code in ('PLATFORM_ADMIN','VILLAGE_VALIDATOR','RW_REVIEWER')
  ) then
    raise exception using errcode = '42501', message = 'EVIDENCE_REVIEW_ROLE_REQUIRED';
  end if;

  return query
  select e.id, e.source_system, e.event_id, e.source_tenant_ref, e.target_territory_ref,
         e.organization_id, e.territory_id, e.target_program_id, e.period_start, e.period_end,
         e.metric_code, e.metric_value, e.metric_unit, e.aggregation_scope, e.currency,
         e.evidence, e.provenance, e.payload_sha256, e.status, e.review_notes,
         e.reviewed_by, e.reviewed_at, e.received_at
  from village.economic_evidence_inbox e
  where (p_status is null or e.status = p_status)
    and exists (
      select 1
      from public.role_assignments ra
      join public.roles r on r.id = ra.role_id
      where ra.user_id = v_user_id
        and ra.active = true
        and (ra.starts_at is null or ra.starts_at <= now())
        and (ra.ends_at is null or ra.ends_at > now())
        and r.role_code in ('PLATFORM_ADMIN','VILLAGE_VALIDATOR','RW_REVIEWER')
        and ra.organization_id = e.organization_id
        and ra.scope_territory_id = e.territory_id
    )
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
security definer
set search_path = pg_catalog, public, village
as $function$
declare
  v_user_id uuid := auth.uid();
  v_row village.economic_evidence_inbox%rowtype;
begin
  if v_user_id is null then
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
    and exists (
      select 1
      from public.role_assignments ra
      join public.roles r on r.id = ra.role_id
      where ra.user_id = v_user_id
        and ra.active = true
        and (ra.starts_at is null or ra.starts_at <= now())
        and (ra.ends_at is null or ra.ends_at > now())
        and r.role_code in ('PLATFORM_ADMIN','VILLAGE_VALIDATOR','RW_REVIEWER')
        and ra.organization_id = e.organization_id
        and ra.scope_territory_id = e.territory_id
    )
  for update;

  if not found then
    raise exception using errcode = '42501', message = 'EVIDENCE_NOT_FOUND_OR_OUT_OF_SCOPE';
  end if;
  if v_row.status in ('rejected','superseded') then
    raise exception using errcode = '55000', message = 'EVIDENCE_IS_TERMINAL';
  end if;
  if p_status = 'verified' and jsonb_array_length(coalesce(v_row.evidence, '[]'::jsonb)) = 0 then
    raise exception using errcode = '22023', message = 'EVIDENCE_ATTACHMENT_REQUIRED_FOR_VERIFICATION';
  end if;

  update village.economic_evidence_inbox e
  set status = p_status,
      review_notes = btrim(p_review_notes),
      reviewed_by = v_user_id,
      reviewed_at = now()
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

comment on function public.list_economic_evidence(text, integer) is
'Lists Jolie economic evidence only for active reviewer assignments matching the same organization and territory.';
comment on function public.review_economic_evidence(uuid, text, text) is
'Reviews one Jolie economic evidence record within the caller active organization and territory scope; every mutation is audit-triggered.';
