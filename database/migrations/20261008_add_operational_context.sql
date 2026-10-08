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
set search_path = public, village
as $$
  select ra.organization_id, ra.scope_territory_id, o.name, t.name, ra.role_id
  from public.role_assignments ra
  left join public.organizations o on o.id=ra.organization_id
  left join public.territories t on t.id=ra.scope_territory_id
  where ra.user_id=auth.uid() and ra.active=true;
$$;
revoke all on function village.my_context() from public;
grant execute on function village.my_context() to authenticated;
