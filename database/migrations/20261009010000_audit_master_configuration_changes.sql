-- Add database audit coverage for village master configuration.
-- Uses the existing hardened audit trigger function; does not change RLS or grants.
drop trigger if exists audit_master_configuration_changes on village.master_configuration;

create trigger audit_master_configuration_changes
after insert or update or delete on village.master_configuration
for each row execute function village.audit_row_change();

notify pgrst, 'reload schema';
