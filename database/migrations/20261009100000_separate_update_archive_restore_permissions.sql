-- Enforce separate update/archive/restore permissions even when callers bypass the UI.
create or replace function village.enforce_sad_write_permissions()
returns trigger
language plpgsql
set search_path to 'pg_catalog', 'public', 'village'
as $function$
declare
  old_business jsonb;
  new_business jsonb;
begin
  old_business := to_jsonb(old) - array['updated_at','deleted_at','deleted_by'];
  new_business := to_jsonb(new) - array['updated_at','deleted_at','deleted_by'];

  if old_business is distinct from new_business
     and not village.has_current_permission('data.update') then
    raise exception using errcode = '42501', message = 'DATA_UPDATE_PERMISSION_REQUIRED';
  end if;

  if old.deleted_at is distinct from new.deleted_at
     or old.deleted_by is distinct from new.deleted_by then
    if old.deleted_at is null and new.deleted_at is not null then
      if not village.has_current_permission('data.archive') then
        raise exception using errcode = '42501', message = 'DATA_ARCHIVE_PERMISSION_REQUIRED';
      end if;
    elsif old.deleted_at is not null and new.deleted_at is null then
      if not village.has_current_permission('data.restore') then
        raise exception using errcode = '42501', message = 'DATA_RESTORE_PERMISSION_REQUIRED';
      end if;
    elsif not (village.has_current_permission('data.archive') or village.has_current_permission('data.restore')) then
      raise exception using errcode = '42501', message = 'DATA_ARCHIVE_OR_RESTORE_PERMISSION_REQUIRED';
    end if;
  end if;

  return new;
end
$function$;

revoke all on function village.enforce_sad_write_permissions() from public, anon, authenticated;

do $migration$
declare
  t text;
  target_tables text[] := array[
    'officials','programs','budgets','assets','documents','letters',
    'governance_units','legal_products','population_events','services',
    'master_configuration','service_requests'
  ];
begin
  foreach t in array target_tables loop
    if exists (
      select 1 from information_schema.columns
      where table_schema='village' and table_name=t and column_name='deleted_at'
    ) and exists (
      select 1 from information_schema.columns
      where table_schema='village' and table_name=t and column_name='deleted_by'
    ) then
      execute format('drop trigger if exists sad_write_permission_guard on village.%I', t);
      execute format(
        'create trigger sad_write_permission_guard before update on village.%I
         for each row execute function village.enforce_sad_write_permissions()', t
      );
    end if;
  end loop;
end
$migration$;

comment on function village.enforce_sad_write_permissions() is
  'Separates ordinary field updates from soft-archive and restore operations on SAD module tables.';
