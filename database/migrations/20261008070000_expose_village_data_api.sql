-- Expose the village schema through Supabase Data API for the operational frontend.
-- RLS remains the authorization boundary; anon receives schema usage only and no table privileges.
alter role authenticator set pgrst.db_schemas = 'public, village';
notify pgrst, 'reload config';

grant usage on schema village to anon, authenticated, service_role;
grant all on all tables in schema village to authenticated, service_role;
grant execute on all functions in schema village to authenticated, service_role;
grant usage, select on all sequences in schema village to authenticated, service_role;

grant select on all tables in schema village to anon;
revoke insert, update, delete on all tables in schema village from anon;
