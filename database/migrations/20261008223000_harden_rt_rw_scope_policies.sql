-- Scope RT/RW CONNECT sources by authenticated organization/territory.
alter table public.rt_business_profiles enable row level security;
alter table public.rt_education_profiles enable row level security;
alter table public.rt_health_observations enable row level security;
alter table public.rt_service_requests enable row level security;

drop policy if exists rt_business_profiles_scope_select on public.rt_business_profiles;
create policy rt_business_profiles_scope_select on public.rt_business_profiles for select to authenticated using (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_business_profiles_scope_insert on public.rt_business_profiles;
create policy rt_business_profiles_scope_insert on public.rt_business_profiles for insert to authenticated with check (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_business_profiles_scope_update on public.rt_business_profiles;
create policy rt_business_profiles_scope_update on public.rt_business_profiles for update to authenticated using (territory_id = (select territory_id from public.my_context() limit 1)) with check (territory_id = (select territory_id from public.my_context() limit 1));

drop policy if exists rt_education_profiles_scope_select on public.rt_education_profiles;
create policy rt_education_profiles_scope_select on public.rt_education_profiles for select to authenticated using (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_education_profiles_scope_insert on public.rt_education_profiles;
create policy rt_education_profiles_scope_insert on public.rt_education_profiles for insert to authenticated with check (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_education_profiles_scope_update on public.rt_education_profiles;
create policy rt_education_profiles_scope_update on public.rt_education_profiles for update to authenticated using (territory_id = (select territory_id from public.my_context() limit 1)) with check (territory_id = (select territory_id from public.my_context() limit 1));

drop policy if exists rt_health_observations_scope_select on public.rt_health_observations;
create policy rt_health_observations_scope_select on public.rt_health_observations for select to authenticated using (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_health_observations_scope_insert on public.rt_health_observations;
create policy rt_health_observations_scope_insert on public.rt_health_observations for insert to authenticated with check (territory_id = (select territory_id from public.my_context() limit 1));
drop policy if exists rt_health_observations_scope_update on public.rt_health_observations;
create policy rt_health_observations_scope_update on public.rt_health_observations for update to authenticated using (territory_id = (select territory_id from public.my_context() limit 1)) with check (territory_id = (select territory_id from public.my_context() limit 1));

drop policy if exists rt_service_requests_scope_select on public.rt_service_requests;
create policy rt_service_requests_scope_select on public.rt_service_requests for select to authenticated using (
 territory_id = (select territory_id from public.my_context() limit 1)
 and organization_id = (select organization_id from public.my_context() limit 1)
);
notify pgrst,'reload schema';
