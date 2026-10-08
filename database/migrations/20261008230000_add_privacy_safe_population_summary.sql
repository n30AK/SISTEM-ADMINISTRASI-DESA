-- Privacy-safe population aggregation for the village Control Tower.
-- The function deliberately returns aggregates only; it does not expose NIK,
-- phone numbers or person-level rows.

create or replace function village.population_summary()
returns table(
  total_households bigint,
  active_households bigint,
  total_persons bigint,
  linked_persons bigint
)
language sql
security definer
set search_path = public, village
as $$
  with ctx as (
    select organization_id, territory_id
    from public.my_context()
    limit 1
  ),
  hh as (
    select h.id, h.active
    from public.sv_master_households h
    join ctx c on h.territory_id = c.territory_id
  ),
  pp as (
    select p.id, p.household_id
    from public.sv_master_persons p
    join hh h on h.id = p.household_id
  )
  select
    count(*)::bigint,
    count(*) filter (where active)::bigint,
    (select count(*) from pp)::bigint,
    (select count(*) from pp where household_id is not null)::bigint
  from hh;
$$;

revoke all on function village.population_summary() from public;
grant execute on function village.population_summary() to authenticated;
