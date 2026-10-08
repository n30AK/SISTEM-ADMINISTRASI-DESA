-- Privacy-safe population aggregate storage.
-- Person-level data is never exposed through this aggregate table.

create schema if not exists private;

drop function if exists village.population_summary();

create table if not exists village.population_aggregates (
  territory_id uuid primary key,
  total_households bigint not null default 0,
  active_households bigint not null default 0,
  total_persons bigint not null default 0,
  linked_persons bigint not null default 0,
  updated_at timestamptz not null default now()
);

alter table village.population_aggregates enable row level security;
revoke all on table village.population_aggregates from anon;
grant select on table village.population_aggregates to authenticated;

drop policy if exists population_aggregates_select_scope on village.population_aggregates;
create policy population_aggregates_select_scope
on village.population_aggregates
for select to authenticated
using (territory_id = (select territory_id from public.my_context() limit 1));

create or replace function private.refresh_population_aggregate(p_territory_id uuid)
returns void
language plpgsql
security definer
set search_path = public, village, private
as $$
begin
  insert into village.population_aggregates(
    territory_id,total_households,active_households,total_persons,linked_persons,updated_at
  )
  select
    p_territory_id,
    count(h.*)::bigint,
    count(*) filter (where h.active)::bigint,
    (select count(*) from public.sv_master_persons p
      join public.sv_master_households hh on hh.id=p.household_id
      where hh.territory_id=p_territory_id)::bigint,
    (select count(*) from public.sv_master_persons p
      join public.sv_master_households hh on hh.id=p.household_id
      where hh.territory_id=p_territory_id and p.household_id is not null)::bigint,
    now()
  from public.sv_master_households h
  where h.territory_id=p_territory_id
  on conflict (territory_id) do update set
    total_households=excluded.total_households,
    active_households=excluded.active_households,
    total_persons=excluded.total_persons,
    linked_persons=excluded.linked_persons,
    updated_at=excluded.updated_at;
end;
$$;
revoke all on function private.refresh_population_aggregate(uuid) from public;

create or replace function private.refresh_population_aggregate_from_household()
returns trigger
language plpgsql
security definer
set search_path=public,village,private
as $$
begin
  if coalesce(new.territory_id,old.territory_id) is not null then
    perform private.refresh_population_aggregate(coalesce(new.territory_id,old.territory_id));
  end if;
  if tg_op='UPDATE' and old.territory_id is distinct from new.territory_id
     and old.territory_id is not null then
    perform private.refresh_population_aggregate(old.territory_id);
  end if;
  return coalesce(new,old);
end;
$$;
revoke all on function private.refresh_population_aggregate_from_household() from public;

create or replace function private.refresh_population_aggregate_from_person()
returns trigger
language plpgsql
security definer
set search_path=public,village,private
as $$
declare
  t_new uuid;
  t_old uuid;
begin
  select territory_id into t_new from public.sv_master_households where id=new.household_id;
  select territory_id into t_old from public.sv_master_households where id=old.household_id;
  if t_new is not null then perform private.refresh_population_aggregate(t_new); end if;
  if t_old is not null and t_old is distinct from t_new then
    perform private.refresh_population_aggregate(t_old);
  end if;
  return coalesce(new,old);
end;
$$;
revoke all on function private.refresh_population_aggregate_from_person() from public;

drop trigger if exists trg_population_households on public.sv_master_households;
create trigger trg_population_households
after insert or update or delete on public.sv_master_households
for each row execute function private.refresh_population_aggregate_from_household();

drop trigger if exists trg_population_persons on public.sv_master_persons;
create trigger trg_population_persons
after insert or update or delete on public.sv_master_persons
for each row execute function private.refresh_population_aggregate_from_person();

do $$
declare r record;
begin
  for r in select distinct territory_id from public.sv_master_households where territory_id is not null loop
    perform private.refresh_population_aggregate(r.territory_id);
  end loop;
end $$;