create or replace function village.my_permissions()
returns table(permission_code text)
language sql
stable
security definer
set search_path to 'pg_catalog', 'public', 'village'
as $function$
  select p.permission_code
  from village.my_context() c
  join public.role_permissions rp on rp.role_id = c.role_id
  join public.permissions p on p.id = rp.permission_id
  where auth.uid() is not null
  order by p.permission_code;
$function$;

revoke all on function village.my_permissions() from public, anon;
grant execute on function village.my_permissions() to authenticated;

comment on function village.my_permissions() is
  'Returns only the permission codes attached to the current active role assignment; does not expose other roles permission mappings.';
