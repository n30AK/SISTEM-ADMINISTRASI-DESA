-- Controlled resident detail access: privacy-safe, territory-scoped, audited.
create or replace function village.get_person_detail(p_person_id uuid)
returns table (
  person_id uuid,
  full_name text,
  national_id_masked text,
  phone_masked text,
  status text,
  household_id uuid,
  address_id uuid,
  created_at timestamptz,
  updated_at timestamptz,
  access_reason text
)
language plpgsql
security definer
set search_path = pg_catalog, village, public
as $$
declare
  v_uid uuid := auth.uid();
  v_org uuid;
  v_territory uuid;
  v_role text;
  v_household_territory uuid;
begin
  if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;

  select mc.organization_id, mc.territory_id into v_org, v_territory
  from public.my_context() mc limit 1;

  if v_territory is null then raise exception 'TERRITORY_CONTEXT_REQUIRED'; end if;

  select r.role_code into v_role
  from public.role_assignments ra
  join public.roles r on r.id = ra.role_id
  where ra.user_id = v_uid
    and ra.active = true
    and (ra.starts_at is null or ra.starts_at <= now())
    and (ra.ends_at is null or ra.ends_at >= now())
    and r.role_code in ('PLATFORM_ADMIN','OPERATOR_DESA','VILLAGE_VALIDATOR')
    and (ra.scope_territory_id is null or ra.scope_territory_id = v_territory)
  order by case r.role_code when 'PLATFORM_ADMIN' then 1 when 'OPERATOR_DESA' then 2 when 'VILLAGE_VALIDATOR' then 3 else 99 end
  limit 1;

  if v_role is null then raise exception 'PERSON_DETAIL_ACCESS_DENIED'; end if;

  select h.territory_id into v_household_territory
  from public.sv_master_persons p
  left join public.sv_master_households h on h.id = p.household_id
  where p.id = p_person_id limit 1;

  if v_household_territory is null or v_household_territory <> v_territory then
    raise exception 'PERSON_OUTSIDE_CURRENT_TERRITORY';
  end if;

  insert into village.audit_log (
    organization_id, actor_user_id, action, entity_name, entity_id,
    details, created_at, territory_id, metadata
  ) values (
    v_org, v_uid, 'READ_DETAIL', 'sv_master_persons', p_person_id,
    jsonb_build_object('access_mode','controlled_detail','role',v_role),
    now(), v_territory,
    jsonb_build_object('privacy','limited_fields','source','village.get_person_detail')
  );

  return query
  select p.id, p.full_name,
    case when p.national_id is null or length(p.national_id) < 4 then null
         else repeat('*', greatest(length(p.national_id)-4,0)) || right(p.national_id,4) end,
    case when p.phone is null or length(p.phone) < 4 then null
         else repeat('*', greatest(length(p.phone)-4,0)) || right(p.phone,4) end,
    p.status, p.household_id, p.address_id, p.created_at, p.updated_at, v_role
  from public.sv_master_persons p where p.id = p_person_id;
end;
$$;

revoke all on function village.get_person_detail(uuid) from public;
revoke all on function village.get_person_detail(uuid) from anon;
grant execute on function village.get_person_detail(uuid) to authenticated;
