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

drop policy if exists ai_regulations_read_authenticated on public.ai_regulations;
create policy ai_regulations_read_authenticated on public.ai_regulations for select to authenticated using (status='BERLAKU');
drop policy if exists ai_obligations_read_authenticated on public.ai_regulatory_obligations;
create policy ai_obligations_read_authenticated on public.ai_regulatory_obligations for select to authenticated using (active=true);
drop policy if exists ai_agents_read_authenticated on public.ai_agent_registry;
create policy ai_agents_read_authenticated on public.ai_agent_registry for select to authenticated using (active=true);
drop policy if exists ai_actions_self_read on public.ai_action_recommendations;
create policy ai_actions_self_read on public.ai_action_recommendations for select to authenticated using (user_id=(select auth.uid()));
drop policy if exists ai_actions_self_insert on public.ai_action_recommendations;
create policy ai_actions_self_insert on public.ai_action_recommendations for insert to authenticated with check (user_id=(select auth.uid()));
drop policy if exists ai_actions_self_update on public.ai_action_recommendations;
create policy ai_actions_self_update on public.ai_action_recommendations for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));

insert into public.ai_agent_registry(agent_code,agent_name,purpose,allowed_actions,restricted_actions,knowledge_domains,human_approval_required) values
('LEGAL_ADVISOR','Legal Advisor','Dasar hukum dan risiko regulasi.',array['search_regulation','compare_rules','draft_guidance'],array['approve_legal_decision','sign_document'],array['UU Desa','PP Desa','Permendesa','Permendagri'],true),
('COMPLIANCE_OFFICER','Compliance Officer','Kewajiban, deadline, bukti dan kepatuhan.',array['scan_obligations','create_alert','recommend_followup'],array['certify_compliance'],array['Regulatory Center','Audit'],true),
('FINANCE_ADVISOR','Finance Advisor','APB Desa, realisasi, deviasi dan bukti.',array['analyze_budget','detect_deviation','draft_report'],array['approve_budget','execute_payment'],array['APB Desa','Dana Desa'],true),
('PLANNING_ADVISOR','Planning Advisor','RPJM, RKP, Musdes, program dan anggaran.',array['trace_plan_chain','detect_gap','draft_plan'],array['approve_plan'],array['RPJM Desa','RKP Desa','Pembangunan'],true),
('DATA_ANALYST','Data Analyst','Kualitas dan tren data Desa.',array['query_authorized_data','detect_anomaly','summarize'],array['change_master_data'],array['Penduduk','Keluarga','Data Quality'],true),
('SERVICE_ADVISOR','Service Advisor','Pelayanan publik dan permohonan.',array['explain_service','track_own_request','draft_response'],array['approve_request','issue_identity'],array['Pelayanan','Surat'],true),
('ASSET_MANAGER','Asset Manager','Inventaris dan verifikasi aset.',array['analyze_assets','flag_missing_evidence'],array['dispose_asset','transfer_asset'],array['Aset Desa'],true),
('PRIVACY_GUARDIAN','Privacy Guardian','Privasi dan redaksi data pribadi.',array['classify_data','redact','flag_privacy_risk'],array['override_rls'],array['PDP','Security'],true),
('INTEGRATION_AGENT','Integration Agent','Pertukaran RT/RW CONNECT dan GPFFE.',array['inspect_exchange','flag_conflict','summarize_sync'],array['override_authority'],array['RT/RW CONNECT','GPFFE'],true)
on conflict(agent_code) do update set active=true;

insert into public.ai_knowledge_items(title,content,classification,status,version,approved_at,module_codes,metadata)
select 'AI Governance Charter','AI adalah pendamping, bukan pengganti pejabat Desa. AI menganalisis, membandingkan, membuat draft dan rekomendasi, tetapi tidak mengambil keputusan final, tidak menandatangani dokumen pejabat, tidak melewati RLS, dan tidak mengubah master data sensitif tanpa otorisasi.','GOVERNANCE','APPROVED',1,now(),array['AI Companion','Kepatuhan','Privasi'],'{"human_in_the_loop":true,"evidence_required":true}'::jsonb
where not exists(select 1 from public.ai_knowledge_items where title='AI Governance Charter');
insert into public.ai_knowledge_items(title,content,classification,status,version,approved_at,module_codes,metadata)
select 'AI Response Evidence Standard','Jawaban tata kelola harus membedakan fakta, analisis, rekomendasi dan keputusan manusia serta menunjukkan sumber, batasan, waktu data dan confidence bila tersedia. Jika bukti tidak cukup, AI harus menyatakan data belum cukup.','GOVERNANCE','APPROVED',1,now(),array['AI Companion','Audit Trail','Kepatuhan'],'{"evidence_mode":true}'::jsonb
where not exists(select 1 from public.ai_knowledge_items where title='AI Response Evidence Standard');
