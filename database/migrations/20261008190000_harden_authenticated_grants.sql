-- Security hardening: authenticated users only receive the privileges required by the village application.
-- RLS remains the row-level authorization boundary; these grants remove unnecessary table capabilities.

revoke delete, truncate, references, trigger
  on village.assets, village.budgets, village.documents, village.letters,
     village.officials, village.programs, village.services
  from authenticated;

revoke insert, update, delete, truncate, references, trigger
  on village.audit_log
  from authenticated;

-- PostGIS helper RPCs are not part of the village application's public API.
revoke execute on function public.st_estimatedextent(text,text) from anon, authenticated;
revoke execute on function public.st_estimatedextent(text,text,text) from anon, authenticated;
revoke execute on function public.st_estimatedextent(text,text,text,boolean) from anon, authenticated;

-- public.my_context() intentionally remains executable by authenticated users only.
-- It is the frontend context bridge and anon execution has already been revoked.
