-- Harden RT/RW CONNECT + GPFFE integration metadata and complete service request form storage.
-- Applied and verified against Supabase project gzdusguveeeflmlvvmwe.

alter table village.service_requests
  add column if not exists administrative_form jsonb not null default '{}'::jsonb;

create index if not exists service_requests_administrative_form_gin_idx
  on village.service_requests using gin (administrative_form);

revoke all on public.exchange_datasets from anon;
revoke all on public.exchange_datasets from authenticated;
grant select on public.exchange_datasets to authenticated;

drop policy if exists exchange_datasets_read on public.exchange_datasets;
create policy exchange_datasets_read_authenticated
  on public.exchange_datasets
  for select
  to authenticated
  using (true);

alter view public.v_intelligence_gpffe set (security_invoker = true);

revoke execute on function public.st_estimatedextent(text,text) from public;
revoke execute on function public.st_estimatedextent(text,text,text) from public;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from public;
revoke execute on function public.st_estimatedextent(text,text) from anon, authenticated;
revoke execute on function public.st_estimatedextent(text,text,text) from anon, authenticated;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from anon, authenticated;

notify pgrst, 'reload schema';
