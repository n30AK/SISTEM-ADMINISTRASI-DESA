-- Form metadata for complete administrative forms.
-- National references are implemented as configurable form guidance; local Perdes/Perkades/Perbup remain authoritative where applicable.

alter table if exists village.officials add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.letters add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.budgets add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.programs add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.assets add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.documents add column if not exists administrative_form jsonb not null default '{}'::jsonb;
alter table if exists village.services add column if not exists administrative_form jsonb not null default '{}'::jsonb;

create index if not exists officials_administrative_form_gin on village.officials using gin (administrative_form);
create index if not exists letters_administrative_form_gin on village.letters using gin (administrative_form);
create index if not exists budgets_administrative_form_gin on village.budgets using gin (administrative_form);
create index if not exists programs_administrative_form_gin on village.programs using gin (administrative_form);
create index if not exists assets_administrative_form_gin on village.assets using gin (administrative_form);
create index if not exists documents_administrative_form_gin on village.documents using gin (administrative_form);
create index if not exists services_administrative_form_gin on village.services using gin (administrative_form);
