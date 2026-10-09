drop policy if exists sad_master_configuration_update on village.master_configuration;
create policy sad_master_configuration_update on village.master_configuration
for update to authenticated
using (
  organization_id = (select organization_id from village.my_context() limit 1)
  and territory_id = (select territory_id from village.my_context() limit 1)
  and village.has_current_permission('data.update')
)
with check (
  organization_id = (select organization_id from village.my_context() limit 1)
  and territory_id = (select territory_id from village.my_context() limit 1)
  and village.has_current_permission('data.update')
);