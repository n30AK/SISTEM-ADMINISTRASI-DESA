-- Return only aggregate resident/household statistics for the caller's active village context.
-- This bridges the SAD population screens to the scoped master and RT/RW data already stored in this Supabase project.
create or replace function village.population_summary()
returns table (
  organization_id uuid,
  territory_id uuid,
  total_households bigint,
  active_households bigint,
  total_persons bigint,
  linked_persons bigint,
  verified_persons bigint,
  pending_verification_persons bigint,
  rt_service_requests bigint,
  rt_health_observations bigint,
  rt_education_profiles bigint,
  rt_business_profiles bigint,
  generated_at timestamptz
)
language plpgsql
stable
security definer
set search_path to 'pg_catalog', 'public', 'village'
as $function$
declare
  v_context record;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED' using errcode = '42501';
  end if;

  select *
    into v_context
  from village.my_context()
  limit 1;

  if v_context.organization_id is null or v_context.territory_id is null then
    raise exception 'ACTIVE_ORGANIZATION_AND_TERRITORY_REQUIRED' using errcode = '42501';
  end if;

  return query
  select
    v_context.organization_id,
    v_context.territory_id,
    (
      select count(distinct h.id)
      from public.households h
      join public.addresses a on a.id = h.address_id
      where a.territory_id = v_context.territory_id
    ),
    (
      select count(distinct h.id)
      from public.households h
      join public.addresses a on a.id = h.address_id
      where a.territory_id = v_context.territory_id
        and h.status = 'ACTIVE'
    ),
    (
      select count(distinct r.person_id)
      from public.residencies r
      join public.addresses a on a.id = r.address_id
      join public.persons p on p.id = r.person_id
      where a.territory_id = v_context.territory_id
        and r.residency_status = 'ACTIVE'
        and (r.valid_from is null or r.valid_from <= current_date)
        and (r.valid_until is null or r.valid_until >= current_date)
        and p.status = 'ACTIVE'
    ),
    (
      select count(distinct r.person_id)
      from public.residencies r
      join public.addresses a on a.id = r.address_id
      join public.persons p on p.id = r.person_id
      where a.territory_id = v_context.territory_id
        and r.residency_status = 'ACTIVE'
        and r.household_id is not null
        and (r.valid_from is null or r.valid_from <= current_date)
        and (r.valid_until is null or r.valid_until >= current_date)
        and p.status = 'ACTIVE'
    ),
    (
      select count(distinct r.person_id)
      from public.residencies r
      join public.addresses a on a.id = r.address_id
      join public.persons p on p.id = r.person_id
      where a.territory_id = v_context.territory_id
        and r.residency_status = 'ACTIVE'
        and r.verification_status = 'RT_VERIFIED'
        and (r.valid_from is null or r.valid_from <= current_date)
        and (r.valid_until is null or r.valid_until >= current_date)
        and p.status = 'ACTIVE'
    ),
    (
      select count(distinct r.person_id)
      from public.residencies r
      join public.addresses a on a.id = r.address_id
      join public.persons p on p.id = r.person_id
      where a.territory_id = v_context.territory_id
        and r.residency_status = 'ACTIVE'
        and r.verification_status = 'SUBMITTED'
        and (r.valid_from is null or r.valid_from <= current_date)
        and (r.valid_until is null or r.valid_until >= current_date)
        and p.status = 'ACTIVE'
    ),
    (
      select count(*) from public.rt_service_requests x
      where x.territory_id = v_context.territory_id
        and (x.organization_id is null or x.organization_id = v_context.organization_id)
    ),
    (
      select count(*) from public.rt_health_observations x
      where x.territory_id = v_context.territory_id
    ),
    (
      select count(*) from public.rt_education_profiles x
      where x.territory_id = v_context.territory_id
    ),
    (
      select count(*) from public.rt_business_profiles x
      where x.territory_id = v_context.territory_id
    ),
    now();
end;
$function$;

revoke all on function village.population_summary() from public, anon;
grant execute on function village.population_summary() to authenticated;
