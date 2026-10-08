-- Harden application context RPC without changing its authorization model.
-- public.my_context remains available only to authenticated clients.
-- village.my_context remains the privileged internal resolver and now rejects anonymous execution
-- through an explicit auth.uid() guard and a hardened search_path.

create or replace function village.my_context()
returns table(organization_id uuid, territory_id uuid, organization_name text, territory_name text, role_id uuid)
language sql
stable
security definer
set search_path = pg_catalog, public, village
as $function$
  select ra.organization_id, ra.scope_territory_id, o.name, t.name, ra.role_id
  from public.role_assignments ra
  left join public.organizations o on o.id=ra.organization_id
  left join public.territories t on t.id=ra.scope_territory_id
  where auth.uid() is not null
    and ra.user_id=auth.uid()
    and ra.active=true;
$function$;

create or replace function public.my_context()
returns table(organization_id uuid, territory_id uuid, organization_name text, territory_name text, role_id uuid)
language sql
stable
security invoker
set search_path = pg_catalog, village, public
as $function$
  select * from village.my_context();
$function$;

revoke execute on function public.my_context() from public, anon;
grant execute on function public.my_context() to authenticated;

notify pgrst, 'reload schema';
