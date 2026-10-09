-- Permit reviewer notes to be refreshed while an item remains under review, without opening arbitrary status changes.
create or replace function village.guard_economic_evidence_review()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, village
as $function$
declare
  v_status_changed boolean := new.status is distinct from old.status;
  v_notes_changed boolean := new.review_notes is distinct from old.review_notes;
begin
  if not v_status_changed and not v_notes_changed then
    return new;
  end if;

  if old.status in ('rejected','superseded') then
    raise exception using errcode = '55000', message = 'EVIDENCE_IS_TERMINAL';
  end if;

  if v_status_changed and new.status not in ('under_review','verified','rejected') then
    raise exception using errcode = '22023', message = 'INVALID_REVIEW_STATUS';
  end if;

  if not v_status_changed and v_notes_changed and new.status not in ('under_review','verified','rejected') then
    raise exception using errcode = '22023', message = 'REVIEW_STATUS_CHANGE_REQUIRED';
  end if;

  if v_status_changed and new.status = 'verified' and jsonb_array_length(coalesce(old.evidence, '[]'::jsonb)) = 0 then
    raise exception using errcode = '22023', message = 'EVIDENCE_ATTACHMENT_REQUIRED_FOR_VERIFICATION';
  end if;

  if new.review_notes is null or length(btrim(new.review_notes)) < 5 or length(new.review_notes) > 2000 then
    raise exception using errcode = '22023', message = 'REVIEW_NOTE_REQUIRED';
  end if;

  new.reviewed_by := auth.uid();
  new.reviewed_at := now();
  return new;
end;
$function$;
