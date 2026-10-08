-- Security hardening for legacy/public emergency and household tables.
-- All access is scoped to the authenticated user's current territory.

revoke all on public.emergency_notifications, public.emergency_response_events, public.sv_master_households from anon;

revoke delete, truncate, references, trigger
  on public.emergency_notifications, public.emergency_response_events, public.sv_master_households
  from authenticated;

grant select, insert, update on public.emergency_notifications to authenticated;
grant select, insert on public.emergency_response_events to authenticated;
grant select, insert, update on public.sv_master_households to authenticated;

drop policy if exists "emergency_notifications_scope_select" on public.emergency_notifications;
drop policy if exists "emergency_notifications_scope_insert" on public.emergency_notifications;
drop policy if exists "emergency_notifications_scope_update" on public.emergency_notifications;

create policy "emergency_notifications_scope_select"
on public.emergency_notifications
for select to authenticated
using (territory_id = (select territory_id from public.my_context() limit 1));

create policy "emergency_notifications_scope_insert"
on public.emergency_notifications
for insert to authenticated
with check (territory_id = (select territory_id from public.my_context() limit 1));

create policy "emergency_notifications_scope_update"
on public.emergency_notifications
for update to authenticated
using (territory_id = (select territory_id from public.my_context() limit 1))
with check (territory_id = (select territory_id from public.my_context() limit 1));

drop policy if exists "emergency_response_events_scope_select" on public.emergency_response_events;
drop policy if exists "emergency_response_events_scope_insert" on public.emergency_response_events;

create policy "emergency_response_events_scope_select"
on public.emergency_response_events
for select to authenticated
using (
  exists (
    select 1
    from public.emergency_response_cases c
    where c.id = emergency_response_events.case_id
      and c.territory_id = (select territory_id from public.my_context() limit 1)
  )
);

create policy "emergency_response_events_scope_insert"
on public.emergency_response_events
for insert to authenticated
with check (
  actor_user_id = (select auth.uid())
  and exists (
    select 1
    from public.emergency_response_cases c
    where c.id = emergency_response_events.case_id
      and c.territory_id = (select territory_id from public.my_context() limit 1)
  )
);

drop policy if exists "sv_master_households_scope_select" on public.sv_master_households;
drop policy if exists "sv_master_households_scope_insert" on public.sv_master_households;
drop policy if exists "sv_master_households_scope_update" on public.sv_master_households;

create policy "sv_master_households_scope_select"
on public.sv_master_households
for select to authenticated
using (territory_id = (select territory_id from public.my_context() limit 1));

create policy "sv_master_households_scope_insert"
on public.sv_master_households
for insert to authenticated
with check (territory_id = (select territory_id from public.my_context() limit 1));

create policy "sv_master_households_scope_update"
on public.sv_master_households
for update to authenticated
using (territory_id = (select territory_id from public.my_context() limit 1))
with check (territory_id = (select territory_id from public.my_context() limit 1));
