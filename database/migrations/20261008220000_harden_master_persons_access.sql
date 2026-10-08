-- SISTEM ADMINISTRASI DESA
-- Master resident data: anonymous access is prohibited; destructive privileges are removed.
revoke all on table public.sv_master_persons from anon;
revoke delete, truncate, references, trigger on table public.sv_master_persons from authenticated;
grant select, insert, update on table public.sv_master_persons to authenticated;
-- Existing RLS policy sv_persons_self_read remains the minimum authenticated visibility boundary.
notify pgrst, 'reload schema';
