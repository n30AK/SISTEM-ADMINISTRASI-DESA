-- Production governance migration: audit read scope and soft-delete indexing.
create index if not exists officials_deleted_scope_idx on village.officials(organization_id,territory_id,deleted_at);
create index if not exists letters_deleted_scope_idx on village.letters(organization_id,territory_id,deleted_at);
create index if not exists budgets_deleted_scope_idx on village.budgets(organization_id,territory_id,deleted_at);
create index if not exists programs_deleted_scope_idx on village.programs(organization_id,territory_id,deleted_at);
create index if not exists assets_deleted_scope_idx on village.assets(organization_id,territory_id,deleted_at);
create index if not exists documents_deleted_scope_idx on village.documents(organization_id,territory_id,deleted_at);
create index if not exists services_deleted_scope_idx on village.services(organization_id,territory_id,deleted_at);

drop policy if exists audit_log_select on village.audit_log;
create policy audit_log_select on village.audit_log
for select to authenticated
using (
  organization_id=(select organization_id from public.my_context())
  and territory_id=(select territory_id from public.my_context())
);

grant select on village.audit_log to authenticated;
