-- Role-gated writes for SAD operational modules.
-- Read access remains scoped to the active organization and territory.
-- By default, only PLATFORM_ADMIN can mutate data; other roles need explicit data.* grants.
insert into public.permissions (permission_code, permission_name, critical)
values
  ('data.create', 'Create operational records', false),
  ('data.update', 'Update operational records', false),
  ('data.archive', 'Archive operational records', true)
on conflict (permission_code) do update
set permission_name = excluded.permission_name,
    critical = excluded.critical;

create or replace function village.has_current_permission(p_permission_code text)
returns boolean
language sql
stable
security definer
set search_path to 'pg_catalog', 'public', 'village'
as $function$
  select auth.uid() is not null
    and exists (
      select 1
      from village.my_context() c
      join public.roles r on r.id = c.role_id
      where r.role_code = 'PLATFORM_ADMIN'
         or exists (
           select 1
           from public.role_permissions rp
           join public.permissions p on p.id = rp.permission_id
           where rp.role_id = c.role_id
             and p.permission_code = p_permission_code
         )
    );
$function$;

revoke all on function village.has_current_permission(text) from public, anon;
grant execute on function village.has_current_permission(text) to authenticated;

do $migration$
declare
  t text;
  p record;
  target_tables text[] := array[
    'officials','programs','budgets','assets','documents','letters',
    'governance_units','legal_products','population_events','services',
    'master_configuration','service_requests'
  ];
begin
  foreach t in array target_tables loop
    if to_regclass(format('village.%I', t)) is null then
      raise exception 'Expected SAD table village.% is missing', t;
    end if;

    for p in
      select policyname
      from pg_policies
      where schemaname = 'village' and tablename = t
    loop
      execute format('drop policy %I on village.%I', p.policyname, t);
    end loop;

    execute format(
      'create policy sad_%1$s_select on village.%1$I for select to authenticated using (
        organization_id = (select organization_id from village.my_context() limit 1)
        and territory_id = (select territory_id from village.my_context() limit 1)
      )', t
    );
    execute format(
      'create policy sad_%1$s_insert on village.%1$I for insert to authenticated with check (
        organization_id = (select organization_id from village.my_context() limit 1)
        and territory_id = (select territory_id from village.my_context() limit 1)
        and village.has_current_permission(''data.create'')
      )', t
    );
    execute format(
      'create policy sad_%1$s_update on village.%1$I for update to authenticated using (
        organization_id = (select organization_id from village.my_context() limit 1)
        and territory_id = (select territory_id from village.my_context() limit 1)
        and (village.has_current_permission(''data.update'') or village.has_current_permission(''data.archive''))
      ) with check (
        organization_id = (select organization_id from village.my_context() limit 1)
        and territory_id = (select territory_id from village.my_context() limit 1)
        and (village.has_current_permission(''data.update'') or village.has_current_permission(''data.archive''))
      )', t
    );
  end loop;
end;
$migration$;

comment on function village.has_current_permission(text) is
  'Checks explicit permission for the current active context; PLATFORM_ADMIN is the only implicit full-access role.';
