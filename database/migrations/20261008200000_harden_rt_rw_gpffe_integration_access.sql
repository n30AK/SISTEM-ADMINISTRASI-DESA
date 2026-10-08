-- Integration security hardening for RT/RW CONNECT and GPFFE sources.
-- Keeps integration data authenticated-only and preserves least privilege.
revoke all on table public.rt_business_profiles, public.rt_education_profiles, public.rt_health_observations, public.rt_service_requests, public.gpffe_economic_exchange from anon;

revoke delete, truncate, references, trigger, insert, update on table public.rt_service_requests from authenticated;
revoke delete, truncate, references, trigger on table public.rt_business_profiles, public.rt_education_profiles, public.rt_health_observations from authenticated;
revoke insert, update, delete, truncate, references, trigger on table public.gpffe_economic_exchange from authenticated;

grant select, insert, update on table public.rt_business_profiles, public.rt_education_profiles, public.rt_health_observations to authenticated;
grant select on table public.rt_service_requests, public.gpffe_economic_exchange to authenticated;

alter view public.v_intelligence_gpffe set (security_invoker = true);
revoke all on table public.v_intelligence_gpffe from anon;
grant select on table public.v_intelligence_gpffe to authenticated;

notify pgrst, 'reload schema';
