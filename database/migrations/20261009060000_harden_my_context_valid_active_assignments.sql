-- Keep my_context() from surfacing active assignments that have no valid active organization.
-- Invalid assignments should be repaired by an authorized administrator, not guessed by the application.

create or replace function village.my_context()
returns table (
  organization_id uuid,
  territory_id uuid,
  organization_name text,
  territory_name text,
  role_id uuid
)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public', 'village'
as $function$
  select
    ra.organization_id,
    ra.scope_territory_id,
    o.name,
    t.name,
    ra.role_id
  from public.role_assignments ra
  join public.roles r on r.id = ra.role_id
  join public.organizations o
    on o.id = ra.organization_id
   and o.active = true
  left join public.territories t
    on t.id = ra.scope_territory_id
  where auth.uid() is not null
    and ra.user_id = auth.uid()
    and ra.active = true
    and (ra.starts_at is null or ra.starts_at <= now())
    and (ra.ends_at is null or ra.ends_at > now())
    and (ra.scope_territory_id is null or t.active = true)
  order by
    case when r.role_code = 'PLATFORM_ADMIN' then 0 else 1 end,
    ra.created_at desc;
$function$;

revoke all on function village.my_context() from public, anon;
grant execute on function village.my_context() to authenticated;

create or replace function public.my_context()
returns table (
  organization_id uuid,
  territory_id uuid,
  organization_name text,
  territory_name text,
  role_id uuid
)
language sql
stable
set search_path to 'pg_catalog', 'village', 'public'
as $function$
  select * from village.my_context();
$function$;

revoke all on function public.my_context() from public, anon;
grant execute on function public.my_context() to authenticated;
