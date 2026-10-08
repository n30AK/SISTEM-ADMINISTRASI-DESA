-- Desa AI Companion + Regulatory Intelligence
-- 2026-10-08
create table if not exists public.ai_regulations (
  id uuid primary key default gen_random_uuid(),
  regulation_type text not null,
  regulation_number text not null,
  regulation_year integer not null,
  title text not null,
  issuer text not null,
  status text not null default 'BERLAKU',
  effective_date date,
  replaces text[] not null default '{}',
  amends text[] not null default '{}',
  source_url text,
  summary text not null,
  affected_modules text[] not null default '{}',
  version integer not null default 1,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(regulation_type, regulation_number, regulation_year)
);
create table if not exists public.ai_regulatory_obligations (
  id uuid primary key default gen_random_uuid(),
  regulation_id uuid not null references public.ai_regulations(id) on delete cascade,
  obligation_code text not null unique,
  obligation_title text not null,
  obligation_text text not null,
  module_code text,
  responsible_roles text[] not null default '{}',
  evidence_types text[] not null default '{}',
  deadline_rule text,
  risk_level text not null default 'MEDIUM',
  guidance text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
create table if not exists public.ai_agent_registry (
  agent_code text primary key,
  agent_name text not null,
  purpose text not null,
  allowed_actions text[] not null default '{}',
  restricted_actions text[] not null default '{}',
  knowledge_domains text[] not null default '{}',
  human_approval_required boolean not null default true,
  active boolean not null default true
);
create table if not exists public.ai_action_recommendations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid(),
  territory_id uuid,
  agent_code text references public.ai_agent_registry(agent_code),
  title text not null,
  recommendation text not null,
  priority text not null default 'MEDIUM',
  evidence jsonb not null default '[]'::jsonb,
  status text not null default 'OPEN',
  due_at timestamptz,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
alter table public.ai_knowledge_items add column if not exists source_url text;
alter table public.ai_knowledge_items add column if not exists regulation_id uuid references public.ai_regulations(id) on delete set null;
alter table public.ai_knowledge_items add column if not exists module_codes text[] not null default '{}';
alter table public.ai_knowledge_items add column if not exists metadata jsonb not null default '{}'::jsonb;
alter table public.ai_regulations enable row level security;
alter table public.ai_regulatory_obligations enable row level security;
alter table public.ai_agent_registry enable row level security;
alter table public.ai_action_recommendations enable row level security;
alter table public.ai_knowledge_items enable row level security;
create index if not exists idx_ai_regulations_modules on public.ai_regulations using gin (affected_modules);
create index if not exists idx_ai_obligations_module on public.ai_regulatory_obligations(module_code);
create index if not exists idx_ai_knowledge_modules on public.ai_knowledge_items using gin (module_codes);
create index if not exists idx_ai_actions_user_status on public.ai_action_recommendations(user_id,status);
create or replace function public.ai_companion_search(p_query text, p_limit integer default 8)
returns table(source_type text, source_id uuid, title text, summary text, source_url text, module_codes text[], relevance integer)
language sql security invoker set search_path=public
as $$
  with q as (select lower(trim(coalesce(p_query,''))) as term),
  results as (
    select 'REGULATION'::text,r.id,r.title,r.summary,r.source_url,r.affected_modules,
      case when lower(r.title) like '%'||(select term from q)||'%' then 100 else 80 end
    from public.ai_regulations r where r.status='BERLAKU'
    union all
    select 'OBLIGATION',o.id,o.obligation_title,o.obligation_text,null,array[o.module_code],
      case when lower(o.obligation_title) like '%'||(select term from q)||'%' then 95 else 70 end
    from public.ai_regulatory_obligations o where o.active=true
    union all
    select 'KNOWLEDGE',k.id,k.title,k.content,k.source_url,k.module_codes,
      case when lower(k.title) like '%'||(select term from q)||'%' then 90 else 60 end
    from public.ai_knowledge_items k where k.status in ('APPROVED','ACTIVE')
  )
  select * from results
  where (p_query is null or trim(p_query)='' or lower(title||' '||summary||' '||array_to_string(module_codes,' ')) like '%'||(select term from q)||'%')
  order by 7 desc,title limit greatest(1,least(coalesce(p_limit,8),20));
$$;
revoke all on function public.ai_companion_search(text,integer) from public;
grant execute on function public.ai_companion_search(text,integer) to authenticated;
