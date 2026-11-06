-- v43: rights provenance, roles, editorial history. Existing migrations stay immutable.
begin;
create table if not exists public.pge_members(user_id uuid primary key references auth.users(id) on delete cascade,role text not null check(role in ('superadmin','editor','custom')),permissions text[] not null default '{}',active boolean not null default true,updated_at timestamptz not null default now());
insert into public.pge_members(user_id,role) select user_id,'superadmin' from public.pge_admins on conflict do nothing;
alter table public.pge_members enable row level security;
revoke all on public.pge_members from public,anon,authenticated;
grant select on public.pge_members to authenticated;
grant all on public.pge_members to service_role;
create or replace function public.pge_can(perm text) returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.pge_members m where m.user_id=auth.uid() and m.active and (m.role='superadmin' or (m.role='editor' and (perm like 'content:%' or perm like 'videos:%' or perm='diagnostics:read')) or perm=any(m.permissions)));
$$;
create or replace function public.pge_my_access() returns jsonb language sql stable security definer set search_path='' as $$ select coalesce((select jsonb_build_object('role',role,'permissions',permissions,'active',active,'user_id',user_id) from public.pge_members where user_id=auth.uid()),'{}'); $$;
drop policy if exists member_read on public.pge_members;
create policy member_read on public.pge_members for select to authenticated using(user_id=auth.uid() or public.pge_can('users:manage'));
create or replace function public.pge_set_member(p_user uuid,p_role text,p_permissions text[],p_active boolean) returns void language plpgsql security definer set search_path='' as $$
begin
 if not public.pge_can('users:manage') then raise exception 'administrator_required';end if;
 perform pg_advisory_xact_lock(734129817);
 if p_role not in ('superadmin','editor','custom') or cardinality(p_permissions)>100 then raise exception 'invalid_role';end if;
 if exists(select 1 from unnest(p_permissions) p where p !~ '^(videos:(read|edit|publish|delete)|content:[a-z0-9-]+:(read|write)|diagnostics:read|integrations:run)$') then raise exception 'invalid_permission';end if;
 if exists(select 1 from public.pge_members where user_id=p_user and role='superadmin' and active) and (not p_active or p_role<>'superadmin') and (select count(*) from public.pge_members where role='superadmin' and active)<=1 then raise exception 'last_superadmin';end if;
 insert into public.pge_members(user_id,role,permissions,active) values(p_user,p_role,p_permissions,p_active) on conflict(user_id) do update set role=excluded.role,permissions=excluded.permissions,active=excluded.active,updated_at=now();
 if p_role='superadmin' and p_active then insert into public.pge_admins(user_id) values(p_user) on conflict do nothing;else delete from public.pge_admins where user_id=p_user;end if;
end;$$;
create or replace function public.pge_document_scope(p text) returns text language sql immutable set search_path='' as $$ select 'content:'||regexp_replace(regexp_replace(p,'^.*/',''),'\.(json|txt)$',''); $$;
drop policy if exists pge_documents_read on public.pge_documents;
create policy pge_documents_read on public.pge_documents for select to authenticated using(public.pge_can(public.pge_document_scope(path)||':read') or public.pge_can(public.pge_document_scope(path)||':write'));
drop policy if exists pge_videos_read on public.pge_videos;
create policy pge_videos_read on public.pge_videos for select to authenticated using(public.pge_can('videos:read'));
drop policy if exists pge_commands_read on public.pge_commands;
create policy pge_commands_read on public.pge_commands for select to authenticated using(user_id=auth.uid() and (public.pge_can('integrations:run') or public.pge_can('diagnostics:read') or public.pge_can('videos:read')));
drop policy if exists pge_commands_insert on public.pge_commands;
create policy pge_commands_insert on public.pge_commands for insert to authenticated with check(user_id=auth.uid() and action='run_sync' and status='pending' and result is null and public.pge_can('integrations:run') and ((payload->>'target')<>'platform-update' or public.pge_can('users:manage')));
drop policy if exists pge_decisions_read on public.pge_video_decisions;
-- Replace prior read policy too: permissive policies are OR'ed by PostgreSQL.
do $$ declare p record;begin for p in select policyname from pg_policies where schemaname='public' and tablename='pge_video_decisions' loop execute format('drop policy %I on public.pge_video_decisions',p.policyname);end loop;end;$$;
create policy pge_decisions_read on public.pge_video_decisions for select to authenticated using(public.pge_can('videos:read'));
create table if not exists public.pge_document_versions(id bigint generated always as identity primary key,path text not null,content text not null,sha text not null,saved_at timestamptz not null default now(),saved_by uuid);
alter table public.pge_document_versions enable row level security;
revoke all on public.pge_document_versions from public,anon,authenticated;
grant select on public.pge_document_versions to authenticated;grant all on public.pge_document_versions to service_role;
create policy versions_read on public.pge_document_versions for select to authenticated using(public.pge_can(public.pge_document_scope(path)||':write'));
create or replace function public.pge_keep_version() returns trigger language plpgsql security definer set search_path='' as $$ begin
 if old.content is distinct from new.content then insert into public.pge_document_versions(path,content,sha,saved_by) values(old.path,old.content,old.sha,auth.uid());end if;return new;end;$$;
create trigger pge_versions before update of content on public.pge_documents for each row execute function public.pge_keep_version();
alter table public.pge_video_decisions add column if not exists previous_decision text;
alter table public.pge_video_decisions add column if not exists source_status text not null default 'pending' check(source_status in ('pending','verified'));
alter table public.pge_video_decisions add column if not exists source_url text;
alter table public.pge_video_decisions add column if not exists source_evidence text;
alter table public.pge_video_decisions add column if not exists source_checked_at timestamptz;
alter table public.pge_video_decisions add column if not exists ai_generated boolean not null default false;
alter table public.pge_video_decisions add column if not exists theme text not null default 'biblico' check(theme in ('biblico','cristao','superacao','inspirador'));
-- Pending legacy writes must not race direct publication after this migration. Keep audit records.
update public.pge_commands set status='conflict',result='Solicitação anterior à publicação direta. Revise o estado atual e envie novamente pelo painel.',updated_at=now() where action in ('review_video','save_json') and status in ('pending','processing');
create or replace function public.pge_public_mode() returns jsonb language sql stable security definer set search_path='' as $$ select jsonb_build_object('version',3,'direct',true,'displayEditing',true,'rightsReview',true); $$;
create or replace function public.pge_review_videos(p_items jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();item jsonb;video public.pge_videos;old public.pge_video_decisions;vid text;op text;decision text;category text;confirmed boolean;revision bigint;seen text[]='{}';audit jsonb='[]';
begin
 if uid is null or not public.pge_can('videos:edit') then raise exception 'administrator_required'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 300 then raise exception 'invalid_batch_size'; end if;
 -- Serialize concurrent decisions, including IDs with no row yet.
 perform pg_advisory_xact_lock(734129815);
 for item in select value from jsonb_array_elements(p_items) order by value->>'id' loop
  vid=item->>'id';op=coalesce(item->>'operation','review');
  if op='review' and item->>'decision'='approved' and not public.pge_can('videos:publish') then raise exception 'permission_denied';end if;
  if (op='restore' or item->>'decision' in ('rejected','archived')) and not public.pge_can('videos:delete') then raise exception 'permission_denied';end if;
  if vid is null or vid !~ '^[A-Za-z0-9_-]{11}$' or vid=any(seen) then raise exception 'invalid_video_id'; end if;
  seen=array_append(seen,vid);
  select * into old from public.pge_video_decisions where id=vid;
  revision=coalesce(old.revision,0);
  if coalesce((item->>'expected_revision')::bigint,0)<>revision then raise exception 'conflict_decision_changed'; end if;
  select * into video from public.pge_videos where id=vid;
  if op='restore' then
   if old.decision is null or old.decision not in ('rejected','archived') then raise exception 'conflict_not_blocked'; end if;
   decision=case when old.decision='archived' and (old.previous_decision='approved' or old.portuguese_confirmed) and old.source_status='verified' then 'approved' else 'pending_review' end;category=old.category;confirmed=decision='approved';
  else
   if video.id is null or video.expires_at<=now() or video.sha is distinct from item->>'expected_sha' then raise exception 'conflict_video_changed'; end if;
   category=coalesce(item->>'categoria',old.category,video.record->>'categoria');
   if op in ('category','metadata') then
    decision=coalesce(old.decision,video.record->>'aprovacao','pending_review');
    if decision in ('rejected','archived') then raise exception 'conflict_video_blocked'; end if;
    confirmed=coalesce(old.portuguese_confirmed,false) or (video.record->>'idiomaVerificado'='true' and video.record->>'idioma' like 'pt%');
   elsif op='review' then
    decision=item->>'decision';confirmed=coalesce((item->>'portuguese_confirmed')::boolean,false);if decision='archived' then confirmed=coalesce(old.portuguese_confirmed,false) or (video.record->>'idiomaVerificado'='true' and video.record->>'idioma' like 'pt%');end if;
   else raise exception 'invalid_operation'; end if;
   if decision is null or decision not in ('approved','rejected','archived','pending_review') then raise exception 'invalid_decision'; end if;
   if (op='category' or decision='approved') and (category is null or category not in ('desenho','filme','serie')) then raise exception 'select_category'; end if;
   -- Language checkbox is optional. Never invent a language verification.
   if op='review' and decision='approved' and coalesce(item->>'source_status',old.source_status,'pending')<>'verified' then raise exception 'source_verification_required';end if;
  end if;
  insert into public.pge_video_decisions(id,decision,category,portuguese_confirmed,revision,updated_by) values(vid,decision,case when category in ('desenho','filme','serie') then category else null end,coalesce(confirmed,false),revision+1,uid) on conflict on constraint pge_video_decisions_pkey do update set decision=excluded.decision,category=excluded.category,portuguese_confirmed=excluded.portuguese_confirmed,revision=excluded.revision,updated_at=now(),updated_by=uid;
  if decision='archived' and old.decision is distinct from 'archived' then update public.pge_video_decisions set previous_decision=coalesce(old.decision,video.record->>'aprovacao','pending_review') where id=vid;end if;
  if item ? 'tituloExibicao' then
   if jsonb_typeof(item->'tituloExibicao') not in ('string','null') or length(coalesce(item->>'tituloExibicao',''))>500 then raise exception 'invalid_display_title'; end if;
   update public.pge_video_decisions set display_title=nullif(btrim(item->>'tituloExibicao'),'') where id=vid;
  end if;
  if item ? 'descricaoExibicao' then
   if jsonb_typeof(item->'descricaoExibicao') not in ('string','null') or length(coalesce(item->>'descricaoExibicao',''))>5000 then raise exception 'invalid_display_description'; end if;
   update public.pge_video_decisions set display_description=nullif(btrim(item->>'descricaoExibicao'),'') where id=vid;
  end if;
  if item ? 'source_status' then
   if item->>'source_status' not in ('pending','verified') then raise exception 'invalid_source_status';end if;
   if item->>'source_status'='verified' and (coalesce(item->>'source_url','') !~ '^https://[^/ ]+' or length(btrim(coalesce(item->>'source_evidence','')))<8) then raise exception 'source_evidence_required';end if;
   if length(coalesce(item->>'source_evidence',''))>2000 or length(coalesce(item->>'source_url',''))>2000 then raise exception 'source_too_long';end if;
   update public.pge_video_decisions set source_status=item->>'source_status',source_url=item->>'source_url',source_evidence=item->>'source_evidence',source_checked_at=case when item->>'source_status'='verified' then now() else null end where id=vid;
  end if;
  if item ? 'ai_generated' then update public.pge_video_decisions set ai_generated=(item->>'ai_generated')::boolean where id=vid;end if;
  if item ? 'theme' then update public.pge_video_decisions set theme=item->>'theme' where id=vid;end if;
  audit=audit||jsonb_build_array(jsonb_build_object('id',vid,'decision',decision,'operation',op));
 end loop;
 insert into public.pge_commands(id,user_id,action,payload,status,result) values(pg_catalog.gen_random_uuid(),uid,'review_video',jsonb_build_object('items',audit,'count',jsonb_array_length(audit)),'applied','Decisão publicada imediatamente.');
 return jsonb_build_object('published',jsonb_array_length(audit));
end; $$;

create or replace function public.pge_public_catalog() returns jsonb language sql stable security definer set search_path='' as $$
 with combined as (
 select v.id,v.expires_at,(v.record||jsonb_build_object('id',v.id,'url','https://www.youtube.com/watch?v='||v.id))||
 case when d.id is null then '{}'::jsonb else jsonb_build_object('aprovacao',d.decision,'categoria',coalesce(d.category,v.record->>'categoria'))||case when d.portuguese_confirmed then jsonb_build_object('idioma','pt-BR','idiomaVerificado',true) else '{}'::jsonb end end || jsonb_build_object('tituloOriginal',coalesce(v.record->>'tituloOriginal',v.record->>'titulo'),'descricaoOriginal',coalesce(v.record->>'descricaoOriginal',v.record->>'descricao'),'titulo',coalesce(d.display_title,v.record->>'tituloOriginal',v.record->>'titulo'),'descricao',coalesce(d.display_description,v.record->>'descricaoOriginal',v.record->>'descricao'),'source_status',d.source_status,'source_url',d.source_url,'ai_generated',d.ai_generated,'theme',d.theme) as record
 from public.pge_videos v left join public.pge_video_decisions d on d.id=v.id
 where v.expires_at>now() and d.source_status='verified'
 ), eligible as (
 select * from combined where record->>'aprovacao'='approved' and record->>'disponibilidade' in ('available','embed_restricted')  and record->>'categoria' in ('desenho','filme','serie') and length(coalesce(record->>'titulo',''))>0
 )
 select jsonb_build_object('versao',3,'itens',coalesce(jsonb_agg(record order by record->>'titulo'),'[]'::jsonb),'validUntil',min(expires_at)) from eligible;
$$;

create or replace function public.pge_validate_programs(body jsonb) returns void language plpgsql set search_path='' as $$
declare a text;r jsonb;refs text[];pids text[];
begin
 if jsonb_typeof(body)<>'object' then raise exception 'invalid_programs';end if;
 if jsonb_typeof(body->'programas') is distinct from 'array' then raise exception 'invalid_programs';end if;
 select array_agg(v->>'id') into pids from jsonb_array_elements(body->'programas') v;
 foreach a in array array['programas','formacoes','softwares','acoes'] loop
  if jsonb_typeof(body->a) is distinct from 'array' then raise exception 'invalid_programs';end if;
  if (select count(*)<>count(distinct v->>'id') from jsonb_array_elements(body->a) v) then raise exception 'duplicate_id';end if;
  for r in select value from jsonb_array_elements(body->a) loop
   if coalesce(r->>'id','') !~ '^[a-z0-9-]{1,100}$' or length(btrim(coalesce(r->>'titulo','')))=0 then raise exception 'invalid_program_record';end if;
   if a<>'programas' and exists(select 1 from jsonb_array_elements_text(coalesce(r->'programas','[]')) x where not(x=any(coalesce(pids,'{}')))) then raise exception 'unknown_program';end if;
  end loop;
 end loop;
end;$$;
create or replace function public.pge_validate_public_urls(body jsonb) returns void language plpgsql set search_path='' as $$
declare k text;v jsonb;txt text;
begin
 if jsonb_typeof(body)='object' then
  for k,v in select key,value from jsonb_each(body) loop
   if k in ('link','url','source_url','repositorio','documentacao','capa') and jsonb_typeof(v)='string' then
    txt=v#>>'{}';
    if txt ~* '^\s*(javascript|data|vbscript|file):' then raise exception 'unsafe_public_url';end if;
   end if;
   perform public.pge_validate_public_urls(v);
  end loop;
 elsif jsonb_typeof(body)='array' then
  for v in select value from jsonb_array_elements(body) loop perform public.pge_validate_public_urls(v);end loop;
 end if;
end;$$;
revoke all on function public.pge_validate_public_urls(jsonb) from public,anon,authenticated;
create or replace function public.pge_publish_documents(p_changes jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();change jsonb;doc_path text;body text;doc_current public.pge_documents;version text;count integer=0;seen text[]='{}';
begin
 if uid is null or not exists(select 1 from public.pge_members where user_id=uid and active) then raise exception 'administrator_required'; end if;
 if jsonb_typeof(p_changes) is distinct from 'array' or jsonb_array_length(p_changes) not between 1 and 3 then raise exception 'invalid_changes'; end if;
 for change in select value from jsonb_array_elements(p_changes) order by value->>'path' loop
  doc_path=change->>'path';body=change->>'content';
  if not public.pge_can(public.pge_document_scope(doc_path)||':write') then raise exception 'permission_denied';end if;
  if doc_path like '%.json' then perform public.pge_validate_public_urls(body::jsonb);end if;
  if doc_path='dados/programas.json' then perform public.pge_validate_programs(body::jsonb);end if;
  if doc_path=any(seen) or not exists(select 1 from public.pge_live_paths p where p.path=doc_path) or body is null or octet_length(body)>1048576 or length(trim(body))=0 then raise exception 'invalid_document'; end if;
  seen=array_append(seen,doc_path);
  select * into doc_current from public.pge_documents d where d.path=doc_path for update;
  if not found or doc_current.sha is distinct from change->>'expected_sha' then raise exception 'conflict_document_changed'; end if;
  if doc_path like '%.json' and jsonb_typeof(body::jsonb) is distinct from jsonb_typeof(doc_current.content::jsonb) then raise exception 'invalid_document_type'; end if;
  version='live:'||pg_catalog.gen_random_uuid()::text;
  insert into public.pge_live_documents(path,content,sha,updated_by) values(doc_path,body,version,uid) on conflict on constraint pge_live_documents_pkey do update set content=excluded.content,sha=excluded.sha,updated_at=now(),updated_by=uid;
  update public.pge_documents d set content=body,sha=version,updated_at=now() where d.path=doc_path;
  insert into public.pge_commands(id,user_id,action,payload,status,result) values(pg_catalog.gen_random_uuid(),uid,'save_json',jsonb_build_object('path',doc_path),'applied','Publicado imediatamente no catálogo de conteúdos.');
  count=count+1;
 end loop;
 return jsonb_build_object('published',count);
end; $$;

insert into public.pge_document_versions(path,content,sha) select path,content,sha from public.pge_documents where path in ('dados/projetos.json','dados/formacoes.json','dados/ideias-sociais.json');
insert into public.pge_live_paths(path) values('dados/programas.json') on conflict do nothing;
insert into public.pge_documents(path,content,sha) values('dados/programas.json',$seed${
  "versao": 1,
  "programas": [
    {
      "id": "educacao-inteligente",
      "tipo": "programa",
      "titulo": "Educação Inteligente",
      "subtitulo": "Escolas, Professores e Alunos.",
      "descricao": "Capacitação em inteligência artificial, tecnologia, pensamento crítico e inovação educacional.",
      "descricao_completa": "Capacitação em inteligência artificial, tecnologia, pensamento crítico e inovação educacional.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 1,
      "capa": "assets/programas/educacao-inteligente.svg",
      "alt": "Ilustração do programa Educação Inteligente",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "municipio-inteligente-2040",
      "tipo": "programa",
      "titulo": "Município Inteligente 2040",
      "subtitulo": "Gestão Pública, Tecnologia e Cidadania.",
      "descricao": "Modernização dos serviços públicos, capacitação de servidores, automação e desenvolvimento de soluções municipais.",
      "descricao_completa": "Modernização dos serviços públicos, capacitação de servidores, automação e desenvolvimento de soluções municipais.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 2,
      "capa": "assets/programas/municipio-inteligente-2040.svg",
      "alt": "Ilustração do programa Município Inteligente 2040",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "campo-inteligente-2040",
      "tipo": "programa",
      "titulo": "Campo Inteligente 2040",
      "subtitulo": "Agricultura e Tecnologia Rural.",
      "descricao": "Formação tecnológica para produtores rurais, agricultura familiar, pecuária, gestão da produção e sustentabilidade.",
      "descricao_completa": "Formação tecnológica para produtores rurais, agricultura familiar, pecuária, gestão da produção e sustentabilidade.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 3,
      "capa": "assets/programas/campo-inteligente-2040.svg",
      "alt": "Ilustração do programa Campo Inteligente 2040",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "negocio-inteligente",
      "tipo": "programa",
      "titulo": "Negócio Inteligente",
      "subtitulo": "Comércio e Empreendedorismo.",
      "descricao": "Apoio a pequenos comerciantes e empreendedores por meio de IA, gestão empresarial, ferramentas digitais e inovação.",
      "descricao_completa": "Apoio a pequenos comerciantes e empreendedores por meio de IA, gestão empresarial, ferramentas digitais e inovação.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 4,
      "capa": "assets/programas/negocio-inteligente.svg",
      "alt": "Ilustração do programa Negócio Inteligente",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "rede-solidaria",
      "tipo": "programa",
      "titulo": "Rede Solidária",
      "subtitulo": "Assistência e Mobilização Comunitária.",
      "descricao": "Arrecadação e distribuição de alimentos e roupas, voluntariado, apoio a famílias vulneráveis e ações solidárias.",
      "descricao_completa": "Arrecadação e distribuição de alimentos e roupas, voluntariado, apoio a famílias vulneráveis e ações solidárias.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 5,
      "capa": "assets/programas/rede-solidaria.svg",
      "alt": "Ilustração do programa Rede Solidária",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "cuidar-aprender",
      "tipo": "programa",
      "titulo": "Cuidar e Aprender",
      "subtitulo": "Desenvolvimento Humano e Inclusão.",
      "descricao": "Acolhimento de crianças, adolescentes e idosos, inclusão digital, capacitação profissional e apoio a pessoas e famílias afetadas pelo álcool e outras drogas.",
      "descricao_completa": "Acolhimento de crianças, adolescentes e idosos, inclusão digital, capacitação profissional e apoio a pessoas e famílias afetadas pelo álcool e outras drogas.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 6,
      "capa": "assets/programas/cuidar-aprender.svg",
      "alt": "Ilustração do programa Cuidar e Aprender",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "comunidade-conectada",
      "tipo": "programa",
      "titulo": "Comunidade Conectada",
      "subtitulo": "Igrejas e Organizações Comunitárias.",
      "descricao": "Capacitação de voluntários, organização de atividades, gestão comunitária, produção de materiais educativos e utilização de tecnologias.",
      "descricao_completa": "Capacitação de voluntários, organização de atividades, gestão comunitária, produção de materiais educativos e utilização de tecnologias.",
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "ordem": 7,
      "capa": "assets/programas/comunidade-conectada.svg",
      "alt": "Ilustração do programa Comunidade Conectada",
      "links": [],
      "_admin_hidden": false,
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    }
  ],
  "formacoes": [
    {
      "id": "formacao-1",
      "tipo": "formacao",
      "titulo": "IA para Professores: Planejamento, Avaliação, Inclusão e Segurança.",
      "descricao": "IA para Professores: Planejamento, Avaliação, Inclusão e Segurança.",
      "programas": [
        "educacao-inteligente"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-2",
      "tipo": "formacao",
      "titulo": "IA para Alunos: Aprendizagem, Criatividade, Pensamento Crítico e Futuro Profissional.",
      "descricao": "IA para Alunos: Aprendizagem, Criatividade, Pensamento Crítico e Futuro Profissional.",
      "programas": [
        "educacao-inteligente"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-3",
      "tipo": "formacao",
      "titulo": "Inteligência Artificial e Transformação do Serviço Público.",
      "descricao": "Inteligência Artificial e Transformação do Serviço Público.",
      "programas": [
        "municipio-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-4",
      "tipo": "formacao",
      "titulo": "Gestão Municipal Baseada em Dados, Transparência e Indicadores.",
      "descricao": "Gestão Municipal Baseada em Dados, Transparência e Indicadores.",
      "programas": [
        "municipio-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-5",
      "tipo": "formacao",
      "titulo": "Automação Administrativa, Atendimento e Gestão de Recursos.",
      "descricao": "Automação Administrativa, Atendimento e Gestão de Recursos.",
      "programas": [
        "municipio-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-6",
      "tipo": "formacao",
      "titulo": "Desenvolvimento de Soluções Públicas com IA: do Problema ao Protótipo.",
      "descricao": "Desenvolvimento de Soluções Públicas com IA: do Problema ao Protótipo.",
      "programas": [
        "municipio-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-7",
      "tipo": "formacao",
      "titulo": "IA no Campo: Gestão e Produtividade.",
      "descricao": "IA no Campo: Gestão e Produtividade.",
      "programas": [
        "campo-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-8",
      "tipo": "formacao",
      "titulo": "Produção Inteligente: Colheita, Café e Pecuária.",
      "descricao": "Produção Inteligente: Colheita, Café e Pecuária.",
      "programas": [
        "campo-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-9",
      "tipo": "formacao",
      "titulo": "Agricultura Digital: Sensores, Água, Solo e Sustentabilidade.",
      "descricao": "Agricultura Digital: Sensores, Água, Solo e Sustentabilidade.",
      "programas": [
        "campo-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-10",
      "tipo": "formacao",
      "titulo": "Comercialização, Rastreabilidade e Inovação Rural.",
      "descricao": "Comercialização, Rastreabilidade e Inovação Rural.",
      "programas": [
        "campo-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-19",
      "tipo": "formacao",
      "titulo": "Inteligência Artificial para Pequenos Negócios: Gestão, Vendas, Marketing e Empreendedorismo.",
      "descricao": "Inteligência Artificial para Pequenos Negócios: Gestão, Vendas, Marketing e Empreendedorismo.",
      "programas": [
        "negocio-inteligente"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-11",
      "tipo": "formacao",
      "titulo": "Inclusão Digital e Aprendizagem para Crianças e Adolescentes em Acolhimento.",
      "descricao": "Inclusão Digital e Aprendizagem para Crianças e Adolescentes em Acolhimento.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-12",
      "tipo": "formacao",
      "titulo": "Criatividade, Estudos e Projetos de Vida com IA.",
      "descricao": "Criatividade, Estudos e Projetos de Vida com IA.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-13",
      "tipo": "formacao",
      "titulo": "Trabalho, Empreendedorismo e Ferramentas Digitais para Pessoas Acolhidas.",
      "descricao": "Trabalho, Empreendedorismo e Ferramentas Digitais para Pessoas Acolhidas.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-14",
      "tipo": "formacao",
      "titulo": "Gestão de Casas de Apoio, Comunicação e Organização de Equipes.",
      "descricao": "Gestão de Casas de Apoio, Comunicação e Organização de Equipes.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-15",
      "tipo": "formacao",
      "titulo": "Autonomia Digital e Prevenção de Golpes para Pessoas Idosas.",
      "descricao": "Autonomia Digital e Prevenção de Golpes para Pessoas Idosas.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-16",
      "tipo": "formacao",
      "titulo": "IA, Memória, Arte e Convivência na Terceira Idade.",
      "descricao": "IA, Memória, Arte e Convivência na Terceira Idade.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-17",
      "tipo": "formacao",
      "titulo": "Inteligência Artificial para Comunicação, Educação e Projetos Comunitários.",
      "descricao": "Inteligência Artificial para Comunicação, Educação e Projetos Comunitários.",
      "programas": [
        "comunidade-conectada"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "formacao-18",
      "tipo": "formacao",
      "titulo": "Gestão de Voluntariado, Doações e Prestação de Contas.",
      "descricao": "Gestão de Voluntariado, Doações e Prestação de Contas.",
      "programas": [
        "comunidade-conectada"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    }
  ],
  "softwares": [
    {
      "id": "escola-aberta",
      "tipo": "software",
      "titulo": "Escola Aberta",
      "descricao": "Gestão escolar, organização de informações, atividades, calendário, comunicação e módulos de transporte escolar.",
      "descricao_completa": "Gestão escolar, organização de informações, atividades, calendário, comunicação e módulos de transporte escolar.",
      "programas": [
        "educacao-inteligente"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "municipio-inteligente",
      "tipo": "software",
      "titulo": "Município Inteligente",
      "descricao": "Gestão de solicitações administrativas, processos, indicadores, relatórios e apoio à administração pública.",
      "descricao_completa": "Gestão de solicitações administrativas, processos, indicadores, relatórios e apoio à administração pública.",
      "programas": [
        "municipio-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "campo-conectado",
      "tipo": "software",
      "titulo": "Campo Conectado",
      "descricao": "Gestão de propriedades rurais, produção, colheitas, equipamentos, mapas de áreas e possibilidades de integração com sensores.",
      "descricao_completa": "Gestão de propriedades rurais, produção, colheitas, equipamentos, mapas de áreas e possibilidades de integração com sensores.",
      "programas": [
        "campo-inteligente-2040"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "comunidade-organizada",
      "tipo": "software",
      "titulo": "Comunidade Organizada",
      "descricao": "Gestão de organizações comunitárias, voluntários, atividades, comunicação e acervo digital.",
      "descricao_completa": "Gestão de organizações comunitárias, voluntários, atividades, comunicação e acervo digital.",
      "programas": [
        "comunidade-conectada"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "partilha-solidaria",
      "tipo": "software",
      "titulo": "Partilha Solidária",
      "descricao": "Gestão de campanhas, doações, estoque, distribuição de materiais e voluntariado.",
      "descricao_completa": "Gestão de campanhas, doações, estoque, distribuição de materiais e voluntariado.",
      "programas": [
        "rede-solidaria"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    },
    {
      "id": "negocio-simples",
      "tipo": "software",
      "titulo": "Negócio Simples",
      "descricao": "Gestão de pequenos negócios, vendas, estoque, clientes, despesas, relatórios e experiência de uso em dispositivos móveis.",
      "descricao_completa": "Gestão de pequenos negócios, vendas, estoque, clientes, despesas, relatórios e experiência de uso em dispositivos móveis.",
      "programas": [
        "negocio-inteligente"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "gratuito": true,
      "links": [],
      "capa": "",
      "alt": "",
      "arquitetura": "Aplicação web responsiva; backend quando necessário; Linux/Docker; autenticação, permissões, HTTPS e backups. Arquitetura proposta, sem implantação anunciada.",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04"
    }
  ],
  "acoes": [
    {
      "id": "acao-1",
      "tipo": "acao-social",
      "titulo": "Campanhas de arrecadação",
      "descricao": "Campanhas de arrecadação. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "rede-solidaria"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-2",
      "tipo": "acao-social",
      "titulo": "Distribuição de alimentos, roupas e materiais",
      "descricao": "Distribuição de alimentos, roupas e materiais. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "rede-solidaria"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-3",
      "tipo": "acao-social",
      "titulo": "Mobilização de voluntários",
      "descricao": "Mobilização de voluntários. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "rede-solidaria"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-4",
      "tipo": "acao-social",
      "titulo": "Apoio comunitário a famílias",
      "descricao": "Apoio comunitário a famílias. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "rede-solidaria"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-5",
      "tipo": "acao-social",
      "titulo": "Inclusão digital",
      "descricao": "Inclusão digital. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-6",
      "tipo": "acao-social",
      "titulo": "Capacitação para o trabalho",
      "descricao": "Capacitação para o trabalho. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-7",
      "tipo": "acao-social",
      "titulo": "Apoio a famílias vulneráveis",
      "descricao": "Apoio a famílias vulneráveis. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-8",
      "tipo": "acao-social",
      "titulo": "Apoio e encaminhamento a serviços especializados para pessoas afetadas pelo álcool e outras drogas",
      "descricao": "Apoio e encaminhamento a serviços especializados para pessoas afetadas pelo álcool e outras drogas. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    },
    {
      "id": "acao-9",
      "tipo": "acao-social",
      "titulo": "Apoio à obtenção da CNH",
      "descricao": "Apoio à obtenção da CNH. Proposta em planejamento, sujeita a definição de critérios, equipe e parcerias. Nenhum atendimento ou benefício disponível é anunciado.",
      "programas": [
        "cuidar-aprender"
      ],
      "status": "em-desenvolvimento",
      "etapa": "planejamento",
      "links": [],
      "capa": "",
      "alt": "",
      "criado_em": "2026-11-04",
      "atualizado_em": "2026-11-04",
      "parcerias": []
    }
  ],
  "legado": [
    {
      "origem": "dados/projetos.json",
      "id": "escola-aberta",
      "titulo": "Escola Aberta — gestão escolar",
      "destino": "escola-aberta",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "comunidade-organizada",
      "titulo": "Comunidade Organizada — gestão para igrejas",
      "destino": "comunidade-organizada",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "caminho-escola",
      "titulo": "Caminho da Escola — apoio ao transporte escolar",
      "destino": "escola-aberta",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "partilha-solidaria",
      "titulo": "Partilha Solidária — organização de doações",
      "destino": "partilha-solidaria",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "negocio-simples",
      "titulo": "Negócio Simples — apoio ao comércio local",
      "destino": "negocio-simples",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "acervo-comunitario",
      "titulo": "Acervo Comunitário — materiais para ensinar",
      "destino": "comunidade-organizada",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "aprender-juntos",
      "titulo": "Aprender Juntos — cursos e materiais para acolhimento",
      "destino": "cuidar-aprender",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-historias-imagens",
      "titulo": "Histórias que viram imagens — criatividade com IA",
      "destino": "formacao-12",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-primeiros-passos-digitais",
      "titulo": "Primeiros passos no mundo digital",
      "destino": "formacao-11",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ler-contar-criar",
      "titulo": "Ler, contar e criar histórias",
      "destino": "formacao-11",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-matematica-cotidiano",
      "titulo": "Matemática para a vida e pequenos projetos",
      "destino": "formacao-11",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-para-estudar",
      "titulo": "IA para estudar com responsabilidade",
      "destino": "formacao-12",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "cuidado-em-rede",
      "titulo": "Cuidado em Rede — ferramentas para casas de apoio",
      "destino": "cuidar-aprender",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-curriculo-trabalho",
      "titulo": "IA, currículo e preparação para o trabalho",
      "destino": "formacao-13",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-imagens-pequenos-negocios",
      "titulo": "Criação de imagens para pequenos negócios",
      "destino": "formacao-13",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-planilhas-casas-apoio",
      "titulo": "Planilhas para doações, estoque e rotina",
      "destino": "formacao-14",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-organizacao-apoio-ia",
      "titulo": "Organização de equipes com apoio de IA",
      "destino": "formacao-14",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-escuta-convivencia",
      "titulo": "Escuta, convivência e comunicação no acolhimento",
      "destino": "formacao-14",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "viver-e-aprender",
      "titulo": "Viver e Aprender — cursos para centros de idosos",
      "destino": "cuidar-aprender",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-celular-autonomia",
      "titulo": "Celular com autonomia e tranquilidade",
      "destino": "formacao-15",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-golpes-imagens-falsas",
      "titulo": "Reconhecer golpes, mensagens e imagens fabricadas",
      "destino": "formacao-15",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-memorias-historias",
      "titulo": "Memórias e histórias em palavras e imagens",
      "destino": "formacao-16",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-cotidiano-idosos",
      "titulo": "Conhecendo a IA no cotidiano",
      "destino": "formacao-16",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-arte-musica-encontros",
      "titulo": "Arte, música e encontros para compartilhar",
      "destino": "formacao-16",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "formacao-comunitaria",
      "titulo": "Formação Comunitária — cursos e ferramentas para servir",
      "destino": "comunidade-conectada",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-imagens-comunidades",
      "titulo": "IA para criar imagens e materiais de comunicação",
      "destino": "formacao-17",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-mercado-trabalho",
      "titulo": "IA para o mercado de trabalho e projetos pessoais",
      "destino": "formacao-17",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-ia-educadores",
      "titulo": "IA para educadores e cuidadores — atividades para crianças",
      "destino": "formacao-1",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-slides-aulas",
      "titulo": "Slides, aulas e apresentações com clareza",
      "destino": "formacao-17",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "curso-voluntariado-organizado",
      "titulo": "Voluntariado, doações e prestação de contas",
      "destino": "formacao-18",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "formacao-escolas",
      "titulo": "Palestras para escolas, professores e alunos",
      "destino": "educacao-inteligente",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-ia-aprendizagem",
      "titulo": "IA na escola: aprender mais sem terceirizar o pensamento",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-planejamento-professor",
      "titulo": "O professor e a IA: planejamento, tempo e qualidade da aula",
      "destino": "formacao-1",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-avaliacao-autoria",
      "titulo": "Avaliação na era da IA: autoria, processo e aprendizagem real",
      "destino": "formacao-1",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-acessibilidade",
      "titulo": "Tecnologia e acessibilidade: materiais que mais pessoas conseguem usar",
      "destino": "formacao-1",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-desinformacao",
      "titulo": "Imagens, vozes e notícias fabricadas: educação para verificar",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-dados-criancas",
      "titulo": "Dados pessoais na escola: cuidado desde o primeiro clique",
      "destino": "formacao-1",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-imagens-criacao",
      "titulo": "Criar com IA: arte, histórias e pensamento visual",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-trabalho-futuro",
      "titulo": "Estudar hoje, trabalhar amanhã: habilidades humanas e IA",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-projetos-interdisciplinares",
      "titulo": "Projetos que resolvem problemas reais da escola e do bairro",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "escola-convivencia-digital",
      "titulo": "Convivência digital: respeito, responsabilidade e participação",
      "destino": "formacao-2",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "formacao-servico-publico",
      "titulo": "Palestras para servidores públicos e gestão municipal",
      "destino": "municipio-inteligente-2040",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-rotinas-ia",
      "titulo": "IA no serviço público: automatizar tarefas sem automatizar responsabilidades",
      "destino": "formacao-5",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-documentos",
      "titulo": "Documentos e conhecimento institucional: encontrar, resumir e conferir",
      "destino": "formacao-5",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-indicadores",
      "titulo": "Dados do município: de planilhas a perguntas melhores",
      "destino": "formacao-4",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-atendimento",
      "titulo": "Atendimento público com linguagem clara e apoio de IA",
      "destino": "formacao-5",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-sustentabilidade",
      "titulo": "IA e sustentabilidade municipal: medir antes de prometer",
      "destino": "formacao-4",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-transparencia",
      "titulo": "Transparência e prestação de contas: explicar números com clareza",
      "destino": "formacao-4",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-acessibilidade",
      "titulo": "Serviços digitais que mais cidadãos conseguem utilizar",
      "destino": "formacao-3",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-camara",
      "titulo": "IA na Câmara Municipal: pesquisa, leitura e apoio à organização",
      "destino": "formacao-3",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-estoque",
      "titulo": "Planejamento de materiais, estoque e manutenção com dados",
      "destino": "formacao-5",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "publico-prototipos",
      "titulo": "Do problema ao protótipo: ferramentas públicas com apoio de IA",
      "destino": "formacao-6",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "formacao-campo",
      "titulo": "Cursos para o campo, fazendas e cooperativas",
      "destino": "campo-inteligente-2040",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "agro-colheita",
      "titulo": "Gestão da colheita: planejamento, registros e indicadores",
      "destino": "formacao-8",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "agro-ia-propriedade",
      "titulo": "IA na propriedade rural: começar pelas tarefas certas",
      "destino": "formacao-7",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "agro-sustentabilidade",
      "titulo": "Dados para água, resíduos e uso responsável de recursos no campo",
      "destino": "formacao-9",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "agro-rastreabilidade",
      "titulo": "Rastreabilidade e comunicação: organizar a história da produção",
      "destino": "formacao-10",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "agro-sensores",
      "titulo": "Sensores, planilhas e protótipos para a lavoura",
      "destino": "formacao-9",
      "situacao": "modulo-proposto"
    },
    {
      "origem": "dados/projetos.json",
      "id": "colheita-organizada",
      "titulo": "Colheita Organizada — gestão e acompanhamento da produção",
      "destino": "campo-conectado",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "campo-conectado",
      "titulo": "Campo Conectado — rotinas e manutenção da propriedade",
      "destino": "campo-conectado",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "municipio-sustentavel",
      "titulo": "Município Sustentável — indicadores e acompanhamento de ações",
      "destino": "municipio-inteligente",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "servico-publico-simples",
      "titulo": "Serviço Público Simples — organização de rotinas administrativas",
      "destino": "municipio-inteligente",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "recomecar-alcool",
      "titulo": "Recomeçar — apoio diante da dependência de álcool",
      "destino": "cuidar-aprender",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "recomecar-outras-drogas",
      "titulo": "Recomeçar — caminhos de cuidado diante das drogas",
      "destino": "cuidar-aprender",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "roupas-que-acolhem",
      "titulo": "Roupas que acolhem — partilha com dignidade",
      "destino": "rede-solidaria",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "alimento-e-partilha",
      "titulo": "Alimento e partilha — cuidado que chega à mesa",
      "destino": "rede-solidaria",
      "situacao": "preservado-como-referencia"
    },
    {
      "origem": "dados/projetos.json",
      "id": "mutirao-solidario",
      "titulo": "Mutirão solidário — tempo e trabalho pelo próximo",
      "destino": "rede-solidaria",
      "situacao": "preservado-como-referencia"
    }
  ]
}
$seed$,'seed-v43') on conflict do nothing;
insert into public.pge_live_paths(path) values('dados/plano-biblico.json') on conflict do nothing;
insert into public.pge_documents(path,content,sha) values('dados/plano-biblico.json',$seed${
  "versao": 1,
  "origem": "Estudo Biblico diario.pdf",
  "sha256": "244f8100e80ba7d91ec601b3fc073b6e6c906032dedf23ac7b4cdac2b35a9657",
  "pasta_drive": "https://drive.google.com/drive/folders/1hnMTN1ZAa7enqg5CVtGK_PmhYiQ79aGP",
  "dias": {
    "01-01": {
      "referencias": [
        "Lc 5.27-39",
        "Gn 1-2",
        "Sl 1"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+5%3A27-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+1&version=ARC"
      ]
    },
    "01-02": {
      "referencias": [
        "Lc 6.1-26",
        "Gn 3-5",
        "Sl 2"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+6%3A1-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+3-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+2&version=ARC"
      ]
    },
    "01-03": {
      "referencias": [
        "Lc 6.27-49",
        "Gn 6-7",
        "Sl 3"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+6%3A27-49&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+6-7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+3&version=ARC"
      ]
    },
    "01-04": {
      "referencias": [
        "Lc 7.1-17",
        "Gn 8-10",
        "Sl 4"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+7%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+8-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+4&version=ARC"
      ]
    },
    "01-05": {
      "referencias": [
        "Lc 7.18-50",
        "Gn 11",
        "Sl 5"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+7%3A18-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+5&version=ARC"
      ]
    },
    "01-06": {
      "referencias": [
        "Lc 8.1-25",
        "Gn 12",
        "Sl 6"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+8%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+6&version=ARC"
      ]
    },
    "01-07": {
      "referencias": [
        "Lc 8.26-56",
        "Gn 13-14",
        "Sl 7"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+8%3A26-56&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+7&version=ARC"
      ]
    },
    "01-08": {
      "referencias": [
        "Lc 9.1-27",
        "Gn 15",
        "Sl 8"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+9%3A1-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+8&version=ARC"
      ]
    },
    "01-09": {
      "referencias": [
        "Lc 9.28-62",
        "Gn 16",
        "Sl 9"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+9%3A28-62&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+9&version=ARC"
      ]
    },
    "01-10": {
      "referencias": [
        "Lc 10.1-20",
        "Gn 17",
        "Sl 10"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+10%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+10&version=ARC"
      ]
    },
    "01-11": {
      "referencias": [
        "Lc 10.21-42",
        "Gn 18",
        "Sl 11"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+10%3A21-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+11&version=ARC"
      ]
    },
    "01-12": {
      "referencias": [
        "Lc 11.1-28",
        "Gn 19",
        "Sl 12"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+11%3A1-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+12&version=ARC"
      ]
    },
    "01-13": {
      "referencias": [
        "Lc 11.29-54",
        "Gn 20",
        "Sl 13"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+11%3A29-54&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+13&version=ARC"
      ]
    },
    "01-14": {
      "referencias": [
        "Lc 12.1-31",
        "Gn 21",
        "Sl 14"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+12%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+14&version=ARC"
      ]
    },
    "01-15": {
      "referencias": [
        "Lc 12.32-59",
        "Gn 22",
        "Sl 15"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+12%3A32-59&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+15&version=ARC"
      ]
    },
    "01-16": {
      "referencias": [
        "Lc 13.1-17",
        "Gn 23",
        "Sl 16"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+13%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+16&version=ARC"
      ]
    },
    "01-17": {
      "referencias": [
        "Lc 13.18-35",
        "Gn 24",
        "Sl 17"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+13%3A18-35&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+17&version=ARC"
      ]
    },
    "01-18": {
      "referencias": [
        "Lc 14.1-24",
        "Gn 25",
        "Sl 18"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+14%3A1-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+18&version=ARC"
      ]
    },
    "01-19": {
      "referencias": [
        "Lc 14.25-35",
        "Gn 26",
        "Sl 19"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+14%3A25-35&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+19&version=ARC"
      ]
    },
    "01-20": {
      "referencias": [
        "Lc 15",
        "Gn 27.1-45",
        "Sl 20"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+27%3A1-45&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+20&version=ARC"
      ]
    },
    "01-21": {
      "referencias": [
        "Lc 16",
        "Gn 27.46-28.22",
        "Sl 21"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+27%3A46-28%3A22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+21&version=ARC"
      ]
    },
    "01-22": {
      "referencias": [
        "Lc 17",
        "Gn.29.1-30",
        "Sl 22"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+29%3A1-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+22&version=ARC"
      ]
    },
    "01-23": {
      "referencias": [
        "Lc 18.1-17",
        "Gn 29.31-30.43",
        "Sl 23"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+18%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+29%3A31-30%3A43&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+23&version=ARC"
      ]
    },
    "01-24": {
      "referencias": [
        "Lc 18.18-43",
        "Gn 31",
        "Sl 24"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+18%3A18-43&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+24&version=ARC"
      ]
    },
    "01-25": {
      "referencias": [
        "Lc 19.1-27",
        "Gn 32-33",
        "Sl 25"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+19%3A1-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+32-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+25&version=ARC"
      ]
    },
    "01-26": {
      "referencias": [
        "Lc 19.28-48",
        "Gn 34",
        "Sl 26"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+19%3A28-48&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+26&version=ARC"
      ]
    },
    "01-27": {
      "referencias": [
        "Lc 20.1-26",
        "Gn 35-36",
        "Sl 27"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+20%3A1-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+35-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+27&version=ARC"
      ]
    },
    "01-28": {
      "referencias": [
        "Lc 20.27-47",
        "Gn 37",
        "Sl 28"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+20%3A27-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+37&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+28&version=ARC"
      ]
    },
    "01-29": {
      "referencias": [
        "Lc 21",
        "Gn 38",
        "Sl 29"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+29&version=ARC"
      ]
    },
    "01-30": {
      "referencias": [
        "Lc 22.1-38",
        "Gn 39",
        "Sl 30"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+22%3A1-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+30&version=ARC"
      ]
    },
    "01-31": {
      "referencias": [
        "Lc 22.39-71",
        "Gn 40",
        "Sl 31"
      ],
      "pagina_pdf": 1,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+22%3A39-71&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+40&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+31&version=ARC"
      ]
    },
    "02-01": {
      "referencias": [
        "Lc 23:1-25",
        "Gn 41",
        "Sl 32"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+23%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+41&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+32&version=ARC"
      ]
    },
    "02-02": {
      "referencias": [
        "Lc 23:26-56",
        "Gn 42",
        "Sl 33"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+23%3A26-56&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+42&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+33&version=ARC"
      ]
    },
    "02-03": {
      "referencias": [
        "Lc 24:1-12",
        "Gn 43",
        "Sl 34"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+24%3A1-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+43&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+34&version=ARC"
      ]
    },
    "02-04": {
      "referencias": [
        "Lc 24:13-53",
        "Gn 44",
        "Sl 35"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+24%3A13-53&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+44&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+35&version=ARC"
      ]
    },
    "02-05": {
      "referencias": [
        "Hb 1",
        "Gn 45:1-46:27",
        "Sl 36"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+45%3A1-46%3A27&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+36&version=ARC"
      ]
    },
    "02-06": {
      "referencias": [
        "Hb 2",
        "Gn 46:28-47:31",
        "Sl 37"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+46%3A28-47%3A31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+37&version=ARC"
      ]
    },
    "02-07": {
      "referencias": [
        "Hb 3:1-4:13",
        "Gn 48",
        "Sl 38"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+3%3A1-4%3A13&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+48&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+38&version=ARC"
      ]
    },
    "02-08": {
      "referencias": [
        "Hb 4:14-6:12",
        "Gn 49-50",
        "Sl 39"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+4%3A14-6%3A12&version=ARC",
        "https://www.biblegateway.com/passage/?search=G%C3%AAnesis+49-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+39&version=ARC"
      ]
    },
    "02-09": {
      "referencias": [
        "Hb 6:13-20",
        "Ex 1-2",
        "Sl 40"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+6%3A13-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+40&version=ARC"
      ]
    },
    "02-10": {
      "referencias": [
        "Hb 7",
        "Ex 3-4",
        "Sl 41"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+41&version=ARC"
      ]
    },
    "02-11": {
      "referencias": [
        "Hb 8",
        "Ex 5:1-6:27",
        "Pv 1"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+5%3A1-6%3A27&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+1&version=ARC"
      ]
    },
    "02-12": {
      "referencias": [
        "Hb 9:1-22",
        "Ex 6:28-8:32",
        "Pv 2"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+9%3A1-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+6%3A28-8%3A32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+2&version=ARC"
      ]
    },
    "02-13": {
      "referencias": [
        "Hb 9:23-10:18",
        "Ex 9-10",
        "Pv 3"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+9%3A23-10%3A18&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+3&version=ARC"
      ]
    },
    "02-14": {
      "referencias": [
        "Hb 10:19-39",
        "Ex 11-12",
        "Pv 4"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+10%3A19-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+4&version=ARC"
      ]
    },
    "02-15": {
      "referencias": [
        "Hb 11:1-21",
        "Ex 13-14",
        "Pv 5"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+11%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+5&version=ARC"
      ]
    },
    "02-16": {
      "referencias": [
        "Hb 11:22-40",
        "Ex 15",
        "Pv 6:1-7:5"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+11%3A22-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+6%3A1-7%3A5&version=ARC"
      ]
    },
    "02-17": {
      "referencias": [
        "Hb 12",
        "Ex 16-17",
        "Pv 7:6-27"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+16-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+7%3A6-27&version=ARC"
      ]
    },
    "02-18": {
      "referencias": [
        "Hb 13",
        "Ex 18-19",
        "Pv 8"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Hebreus+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+18-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+8&version=ARC"
      ]
    },
    "02-19": {
      "referencias": [
        "Mt 1",
        "Ex 20-21",
        "Pv 9"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+9&version=ARC"
      ]
    },
    "02-20": {
      "referencias": [
        "Mt 2",
        "Ex 22-23",
        "Pv 10"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+22-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+10&version=ARC"
      ]
    },
    "02-21": {
      "referencias": [
        "Mt 3",
        "Ex 24",
        "Pv 11"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+11&version=ARC"
      ]
    },
    "02-22": {
      "referencias": [
        "Mt 4",
        "Ex 25-27",
        "Pv 12"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+25-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+12&version=ARC"
      ]
    },
    "02-23": {
      "referencias": [
        "Mt 5:1-20",
        "Ex 28-29",
        "Pv 13"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+5%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+28-29&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+13&version=ARC"
      ]
    },
    "02-24": {
      "referencias": [
        "Mt 5:21-48",
        "Ex 30-32",
        "Pv 14"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+5%3A21-48&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+30-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+14&version=ARC"
      ]
    },
    "02-25": {
      "referencias": [
        "Mt 6:1-18",
        "Ex 33-34",
        "Pv 15"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+6%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+33-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+15&version=ARC"
      ]
    },
    "02-26": {
      "referencias": [
        "Mt 6:19-34",
        "Ex 35-36",
        "Pv 16"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+6%3A19-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+35-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+16&version=ARC"
      ]
    },
    "02-27": {
      "referencias": [
        "Mt 7",
        "Ex 37-38",
        "Pv 17"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+37-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+17&version=ARC"
      ]
    },
    "02-28": {
      "referencias": [
        "Mt 8:1-13",
        "Ex 39-40",
        "Pv 18"
      ],
      "pagina_pdf": 2,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+8%3A1-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=%C3%8Axodo+39-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+18&version=ARC"
      ]
    },
    "03-01": {
      "referencias": [
        "Mt 8:14-34",
        "Lv 1-2",
        "Pv 19"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+8%3A14-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+19&version=ARC"
      ]
    },
    "03-02": {
      "referencias": [
        "Mt 9:1-17",
        "Lv 3-4",
        "Pv 20"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+9%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+20&version=ARC"
      ]
    },
    "03-03": {
      "referencias": [
        "Mt 9:18-38",
        "Lv 5-6",
        "Pv 21"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+9%3A18-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+21&version=ARC"
      ]
    },
    "03-04": {
      "referencias": [
        "Mt 10:1-25",
        "Lv 7-8",
        "Pv 22"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+10%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+22&version=ARC"
      ]
    },
    "03-05": {
      "referencias": [
        "Mt 10:26-42",
        "Lv 9-10",
        "Pv 23"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+10%3A26-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+23&version=ARC"
      ]
    },
    "03-06": {
      "referencias": [
        "Mt 11:1-19",
        "Lv 11-12",
        "Pv 24"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+11%3A1-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+24&version=ARC"
      ]
    },
    "03-07": {
      "referencias": [
        "Mt 11:20-30",
        "Lv 13",
        "Pv 25"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+11%3A20-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+25&version=ARC"
      ]
    },
    "03-08": {
      "referencias": [
        "Mt 12:1-21",
        "Lv 14",
        "Pv 26"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+12%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+26&version=ARC"
      ]
    },
    "03-09": {
      "referencias": [
        "Mt 12:22-50",
        "Lv 15-16",
        "Pv 27"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+12%3A22-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+15-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+27&version=ARC"
      ]
    },
    "03-10": {
      "referencias": [
        "Mt 13:1-23",
        "Lv 17-18",
        "Pv 28"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+13%3A1-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+17-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+28&version=ARC"
      ]
    },
    "03-11": {
      "referencias": [
        "Mt 13:24-58",
        "Lv 19",
        "Pv 29"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+13%3A24-58&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+29&version=ARC"
      ]
    },
    "03-12": {
      "referencias": [
        "Mt 14:1-21",
        "Lv 20-21",
        "Pv 30"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+14%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+30&version=ARC"
      ]
    },
    "03-13": {
      "referencias": [
        "Mt 14:22-36",
        "Lv 22-23",
        "Pv 31"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+14%3A22-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+22-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Prov%C3%A9rbios+31&version=ARC"
      ]
    },
    "03-14": {
      "referencias": [
        "Mt 15:1-20",
        "Lv 24-25",
        "Ec 1:1-11"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+15%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+24-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+1%3A1-11&version=ARC"
      ]
    },
    "03-15": {
      "referencias": [
        "Mt 15:21-39",
        "Lv 26-27",
        "Ec 1:12-2:26"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+15%3A21-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lev%C3%ADtico+26-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+1%3A12-2%3A26&version=ARC"
      ]
    },
    "03-16": {
      "referencias": [
        "Mt 16",
        "Nm 1-2",
        "Ec 3:1-15"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+3%3A1-15&version=ARC"
      ]
    },
    "03-17": {
      "referencias": [
        "Mt 17",
        "Nm 3-4",
        "Ec 3:16-4:16"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+3%3A16-4%3A16&version=ARC"
      ]
    },
    "03-18": {
      "referencias": [
        "Mt 18:1-17",
        "Nm 5-6",
        "Ec 5"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+18%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+5&version=ARC"
      ]
    },
    "03-19": {
      "referencias": [
        "Mt 18:18-35",
        "Nm 7-8",
        "Ec 6"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+18%3A18-35&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+6&version=ARC"
      ]
    },
    "03-20": {
      "referencias": [
        "Mt 19:1-14",
        "Nm 9-10",
        "Ec 7"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+19%3A1-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+7&version=ARC"
      ]
    },
    "03-21": {
      "referencias": [
        "Mt 19:16-30",
        "Nm 11-12",
        "Ec 8"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+19%3A16-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+8&version=ARC"
      ]
    },
    "03-22": {
      "referencias": [
        "Mt 20:1-16",
        "Nm 13-14",
        "Ec 9:1-12"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+20%3A1-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+9%3A1-12&version=ARC"
      ]
    },
    "03-23": {
      "referencias": [
        "Mt 20:17-34",
        "Nm 15-16",
        "Ec 9:13-10:20"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+20%3A17-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+15-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+9%3A13-10%3A20&version=ARC"
      ]
    },
    "03-24": {
      "referencias": [
        "Mt 21:1-27",
        "Nm 17-18",
        "Ec 11:1-8"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+21%3A1-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+17-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+11%3A1-8&version=ARC"
      ]
    },
    "03-25": {
      "referencias": [
        "Mt 21:28-46",
        "Nm 19-20",
        "Ec 11:9-12:14"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+21%3A28-46&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+19-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Eclesiastes+11%3A9-12%3A14&version=ARC"
      ]
    },
    "03-26": {
      "referencias": [
        "Mt 22:1-22",
        "Nm 21",
        "Ct 1:1-2:7"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+22%3A1-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+1%3A1-2%3A7&version=ARC"
      ]
    },
    "03-27": {
      "referencias": [
        "Mt 22:23-46",
        "Nm 22:1-40",
        "Ct 2:8-3:5"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+22%3A23-46&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+22%3A1-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+2%3A8-3%3A5&version=ARC"
      ]
    },
    "03-28": {
      "referencias": [
        "Mt 23:1-12",
        "Nm 22:41-23:26",
        "Ct 3:6-5:1"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+23%3A1-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+22%3A41-23%3A26&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+3%3A6-5%3A1&version=ARC"
      ]
    },
    "03-29": {
      "referencias": [
        "Mt 23:13-39",
        "Nm 23:27-24:25",
        "Ct 5:2-6:3"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+23%3A13-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+23%3A27-24%3A25&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+5%3A2-6%3A3&version=ARC"
      ]
    },
    "03-30": {
      "referencias": [
        "Mt 24:1-31",
        "Nm 25-27",
        "Ct 6:4-8:4"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+24%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+25-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+6%3A4-8%3A4&version=ARC"
      ]
    },
    "03-31": {
      "referencias": [
        "Mt 24:32-51",
        "Nm 28-29",
        "Ct 8:5-14"
      ],
      "pagina_pdf": 3,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+24%3A32-51&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+28-29&version=ARC",
        "https://www.biblegateway.com/passage/?search=C%C3%A2nticos+8%3A5-14&version=ARC"
      ]
    },
    "04-01": {
      "referencias": [
        "Mt 25:1-30",
        "Nm 30-31",
        "Jó 1"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+25%3A1-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+30-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+1&version=ARC"
      ]
    },
    "04-02": {
      "referencias": [
        "Mt 25:31-46",
        "Nm 32-34",
        "Jó 2"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+25%3A31-46&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+32-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+2&version=ARC"
      ]
    },
    "04-03": {
      "referencias": [
        "Mt 26:1-25",
        "Nm 35-36",
        "Jó 3"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+26%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=N%C3%BAmeros+35-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+3&version=ARC"
      ]
    },
    "04-04": {
      "referencias": [
        "Mt 26:26-46",
        "Dt 1-2",
        "Jó 4"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+26%3A26-46&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+4&version=ARC"
      ]
    },
    "04-05": {
      "referencias": [
        "Mt 26:47-75",
        "Dt 3-4",
        "Jó 5"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+26%3A47-75&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+5&version=ARC"
      ]
    },
    "04-06": {
      "referencias": [
        "Mt 27:1-31",
        "Dt 5-6",
        "Jó 6"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+27%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+6&version=ARC"
      ]
    },
    "04-07": {
      "referencias": [
        "Mt 27:32-66",
        "Dt 7-8",
        "Jó 7"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+27%3A32-66&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+7&version=ARC"
      ]
    },
    "04-08": {
      "referencias": [
        "Mt 28",
        "Dt 9-10",
        "Jó 8"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Mateus+28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+8&version=ARC"
      ]
    },
    "04-09": {
      "referencias": [
        "At 1",
        "Dt 11-12",
        "Jó 9"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+9&version=ARC"
      ]
    },
    "04-10": {
      "referencias": [
        "At 2:1-13",
        "Dt 13-14",
        "Jó 10"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+2%3A1-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+10&version=ARC"
      ]
    },
    "04-11": {
      "referencias": [
        "At 2:14-47",
        "Dt 15-16",
        "Jó 11"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+2%3A14-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+15-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+11&version=ARC"
      ]
    },
    "04-12": {
      "referencias": [
        "At 3",
        "Dt 17-18",
        "Jó 12"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+17-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+12&version=ARC"
      ]
    },
    "04-13": {
      "referencias": [
        "At 4:1-22",
        "Dt 19-20",
        "Jó 13"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+4%3A1-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+19-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+13&version=ARC"
      ]
    },
    "04-14": {
      "referencias": [
        "At 4:23-37",
        "Dt 21-22",
        "Jó 14"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+4%3A23-37&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+21-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+14&version=ARC"
      ]
    },
    "04-15": {
      "referencias": [
        "At 5:1-16",
        "Dt 23-24",
        "Jó 15"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+5%3A1-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+23-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+15&version=ARC"
      ]
    },
    "04-16": {
      "referencias": [
        "At 5:17-42",
        "Dt 25-27",
        "Jó 16"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+5%3A17-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+25-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+16&version=ARC"
      ]
    },
    "04-17": {
      "referencias": [
        "At 6",
        "Dt 28",
        "Jó 17"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+28&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+17&version=ARC"
      ]
    },
    "04-18": {
      "referencias": [
        "At 7:1-22",
        "Dt 29-30",
        "Jó 18"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+7%3A1-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+29-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+18&version=ARC"
      ]
    },
    "04-19": {
      "referencias": [
        "At 7:23-8:1",
        "Dt 31-32",
        "Jó 19"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+7%3A23-8%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+31-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+19&version=ARC"
      ]
    },
    "04-20": {
      "referencias": [
        "At 8:2-25",
        "Dt 33-34",
        "Jó 20"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+8%3A2-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Deuteron%C3%B4mio+33-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+20&version=ARC"
      ]
    },
    "04-21": {
      "referencias": [
        "At 8:26-40",
        "Js 1-2",
        "Jó 21"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+8%3A26-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+21&version=ARC"
      ]
    },
    "04-22": {
      "referencias": [
        "At 9:1-25",
        "Js 3:1-5:1",
        "Jó 22"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+9%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+3%3A1-5%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+22&version=ARC"
      ]
    },
    "04-23": {
      "referencias": [
        "At 9:26-43",
        "Js 5:2-6:27",
        "Jó 23"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+9%3A26-43&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+5%3A2-6%3A27&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+23&version=ARC"
      ]
    },
    "04-24": {
      "referencias": [
        "At 10:1-33",
        "Js 7-8",
        "Jó 24"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+10%3A1-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+24&version=ARC"
      ]
    },
    "04-25": {
      "referencias": [
        "At 10:34-48",
        "Js 9-10",
        "Jó 25"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+10%3A34-48&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+25&version=ARC"
      ]
    },
    "04-26": {
      "referencias": [
        "At 11:1-18",
        "Js 11-12",
        "Jó 26"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+11%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+26&version=ARC"
      ]
    },
    "04-27": {
      "referencias": [
        "At 11:19-30",
        "Js 13-14",
        "Jó 27"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+11%3A19-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+27&version=ARC"
      ]
    },
    "04-28": {
      "referencias": [
        "At 12",
        "Js 15-17",
        "Jó 28"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+15-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+28&version=ARC"
      ]
    },
    "04-29": {
      "referencias": [
        "At 13:1-25",
        "Js 18-19",
        "Jó 29"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+13%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+18-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+29&version=ARC"
      ]
    },
    "04-30": {
      "referencias": [
        "At 13:26-52",
        "Js 20-21",
        "Jó 30"
      ],
      "pagina_pdf": 4,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+13%3A26-52&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+30&version=ARC"
      ]
    },
    "05-01": {
      "referencias": [
        "At 14",
        "Js 22",
        "Jó 31"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+22&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+31&version=ARC"
      ]
    },
    "05-02": {
      "referencias": [
        "At 15:1-21",
        "Js 23-24",
        "Jó 32"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+15%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Josu%C3%A9+23-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+32&version=ARC"
      ]
    },
    "05-03": {
      "referencias": [
        "At 15:22-41",
        "Jz 1",
        "Jó 33"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+15%3A22-41&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+33&version=ARC"
      ]
    },
    "05-04": {
      "referencias": [
        "At 16:1-15",
        "Jz 2-3",
        "Jó 34"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+16%3A1-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+2-3&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+34&version=ARC"
      ]
    },
    "05-05": {
      "referencias": [
        "At 16:16-40",
        "Jz 4-5",
        "Jó 35"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+16%3A16-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+4-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+35&version=ARC"
      ]
    },
    "05-06": {
      "referencias": [
        "At 17:1-15",
        "Jz 6",
        "Jó 36"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+17%3A1-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+36&version=ARC"
      ]
    },
    "05-07": {
      "referencias": [
        "At 17:16-34",
        "Jz 7-8",
        "Jó 37"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+17%3A16-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+37&version=ARC"
      ]
    },
    "05-08": {
      "referencias": [
        "At 18",
        "Jz 9",
        "Jó 38"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+38&version=ARC"
      ]
    },
    "05-09": {
      "referencias": [
        "At 19:1-20",
        "Jz 10:1-11:33",
        "Jó 39"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+19%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+10%3A1-11%3A33&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+39&version=ARC"
      ]
    },
    "05-10": {
      "referencias": [
        "At 19:21-41",
        "Jz 11:34-12:15",
        "Jó 40"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+19%3A21-41&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+11%3A34-12%3A15&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+40&version=ARC"
      ]
    },
    "05-11": {
      "referencias": [
        "At 20:1-16",
        "Jz 13",
        "Jó 41"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+20%3A1-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+41&version=ARC"
      ]
    },
    "05-12": {
      "referencias": [
        "At 20:17-38",
        "Jz 14-15",
        "Jó 42"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+20%3A17-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+14-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=J%C3%B3+42&version=ARC"
      ]
    },
    "05-13": {
      "referencias": [
        "At 21:1-36",
        "Jz 16",
        "Sl 42"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+21%3A1-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+42&version=ARC"
      ]
    },
    "05-14": {
      "referencias": [
        "At 21:37-22:29",
        "Jz 17-18",
        "Sl 43"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+21%3A37-22%3A29&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+17-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+43&version=ARC"
      ]
    },
    "05-15": {
      "referencias": [
        "At 22:30-23:22",
        "Jz 19",
        "Sl 44"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+22%3A30-23%3A22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+44&version=ARC"
      ]
    },
    "05-16": {
      "referencias": [
        "At 23:23-24:9",
        "Jz 20",
        "Sl 45"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+23%3A23-24%3A9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+45&version=ARC"
      ]
    },
    "05-17": {
      "referencias": [
        "At 24:10-27",
        "Jz 21",
        "Sl 46"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+24%3A10-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ju%C3%ADzes+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+46&version=ARC"
      ]
    },
    "05-18": {
      "referencias": [
        "At 25",
        "Rt 1-2",
        "Sl 47"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Rute+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+47&version=ARC"
      ]
    },
    "05-19": {
      "referencias": [
        "At 26:1-18",
        "Rt 3-4",
        "Sl 48"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+26%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Rute+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+48&version=ARC"
      ]
    },
    "05-20": {
      "referencias": [
        "At 26:19-32",
        "1Sm 1:1-2:11",
        "Sl 49"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+26%3A19-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+1%3A1-2%3A11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+49&version=ARC"
      ]
    },
    "05-21": {
      "referencias": [
        "At 27:1-12",
        "1Sm 2:12-2:36",
        "Sl 50"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+27%3A1-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+2%3A12-2%3A36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+50&version=ARC"
      ]
    },
    "05-22": {
      "referencias": [
        "At 27:13-44",
        "1Sm 3",
        "Sl 51"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+27%3A13-44&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+51&version=ARC"
      ]
    },
    "05-23": {
      "referencias": [
        "At 28:1-15",
        "1Sm 4-5",
        "Sl 52"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+28%3A1-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+4-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+52&version=ARC"
      ]
    },
    "05-24": {
      "referencias": [
        "At 28:16-31",
        "1Sm 6-7",
        "Sl 53"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Atos+28%3A16-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+6-7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+53&version=ARC"
      ]
    },
    "05-25": {
      "referencias": [
        "Rm 1:1-15",
        "1Sm 8",
        "Sl 54"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+1%3A1-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+54&version=ARC"
      ]
    },
    "05-26": {
      "referencias": [
        "Rm 1:16-32",
        "1Sm 9:1-10:16",
        "Sl 55"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+1%3A16-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+9%3A1-10%3A16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+55&version=ARC"
      ]
    },
    "05-27": {
      "referencias": [
        "Rm 2:1-3:8",
        "1Sm 10:17-11:15",
        "Sl 56"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+2%3A1-3%3A8&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+10%3A17-11%3A15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+56&version=ARC"
      ]
    },
    "05-28": {
      "referencias": [
        "Rm 3:9-31",
        "1Sm 12",
        "Sl 57"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+3%3A9-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+57&version=ARC"
      ]
    },
    "05-29": {
      "referencias": [
        "Rm 4",
        "1Sm 13",
        "Sl 58"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+58&version=ARC"
      ]
    },
    "05-30": {
      "referencias": [
        "Rm 5",
        "1Sm 14",
        "Sl 59"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+59&version=ARC"
      ]
    },
    "05-31": {
      "referencias": [
        "Rm 6",
        "1Sm 15",
        "Sl 60"
      ],
      "pagina_pdf": 5,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+60&version=ARC"
      ]
    },
    "06-01": {
      "referencias": [
        "Rm 7",
        "1Sm 16",
        "Sl 61"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+61&version=ARC"
      ]
    },
    "06-02": {
      "referencias": [
        "Rm 8",
        "1Sm 17:1-54",
        "Sl 62"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+17%3A1-54&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+62&version=ARC"
      ]
    },
    "06-03": {
      "referencias": [
        "Rm 9:1-29",
        "1Sm 17:55-18:30",
        "Sl 63"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+9%3A1-29&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+17%3A55-18%3A30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+63&version=ARC"
      ]
    },
    "06-04": {
      "referencias": [
        "Rm 9:30-10:21",
        "1Sm 19",
        "Sl 64"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+9%3A30-10%3A21&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+64&version=ARC"
      ]
    },
    "06-05": {
      "referencias": [
        "Rm 11:1-24",
        "1Sm 20",
        "Sl 65"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+11%3A1-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+65&version=ARC"
      ]
    },
    "06-06": {
      "referencias": [
        "Rm 11:25-36",
        "1Sm 21-22",
        "Sl 66"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+11%3A25-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+21-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+66&version=ARC"
      ]
    },
    "06-07": {
      "referencias": [
        "Rm 12",
        "1Sm 23-24",
        "Sl 67"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+23-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+67&version=ARC"
      ]
    },
    "06-08": {
      "referencias": [
        "Rm 13",
        "1Sm 25",
        "Sl 68"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+68&version=ARC"
      ]
    },
    "06-09": {
      "referencias": [
        "Rm 14",
        "1Sm 26",
        "Sl 69"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+69&version=ARC"
      ]
    },
    "06-10": {
      "referencias": [
        "Rm 15:1-13",
        "1Sm 27-28",
        "Sl 70"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+15%3A1-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+70&version=ARC"
      ]
    },
    "06-11": {
      "referencias": [
        "Rm 15:14-33",
        "1Sm 29-31",
        "Sl 71"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+15%3A14-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Samuel+29-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+71&version=ARC"
      ]
    },
    "06-12": {
      "referencias": [
        "Rm 16",
        "2Sm 1",
        "Sl 72"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Romanos+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+72&version=ARC"
      ]
    },
    "06-13": {
      "referencias": [
        "Mc 1:1-20",
        "2Sm 2:1-3:1",
        "Dn 1"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+1%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+2%3A1-3%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+1&version=ARC"
      ]
    },
    "06-14": {
      "referencias": [
        "Mc 1:21-45",
        "2Sm 3:2-39",
        "Dn 2:1-23"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+1%3A21-45&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+3%3A2-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+2%3A1-23&version=ARC"
      ]
    },
    "06-15": {
      "referencias": [
        "Mc 2",
        "2Sm 4-5",
        "Dn 2:24-49"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+4-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+2%3A24-49&version=ARC"
      ]
    },
    "06-16": {
      "referencias": [
        "Mc 3:1-19",
        "2Sm 6",
        "Dn 3"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+3%3A1-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+3&version=ARC"
      ]
    },
    "06-17": {
      "referencias": [
        "Mc 3:20-35",
        "2Sm 7-8",
        "Dn 4"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+3%3A20-35&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+4&version=ARC"
      ]
    },
    "06-18": {
      "referencias": [
        "Mc 4:1-20",
        "2Sm 9-10",
        "Dn 5"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+4%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+5&version=ARC"
      ]
    },
    "06-19": {
      "referencias": [
        "Mc 4:21-41",
        "2Sm 11-12",
        "Dn 6"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+4%3A21-41&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+6&version=ARC"
      ]
    },
    "06-20": {
      "referencias": [
        "Mc 5:1-20",
        "2Sm 13",
        "Dn 7"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+5%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+7&version=ARC"
      ]
    },
    "06-21": {
      "referencias": [
        "Mc 5:21-43",
        "2Sm 14",
        "Dn 8"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+5%3A21-43&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+8&version=ARC"
      ]
    },
    "06-22": {
      "referencias": [
        "Mc 6:1-29",
        "2Sm 15",
        "Dn 9"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+6%3A1-29&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+9&version=ARC"
      ]
    },
    "06-23": {
      "referencias": [
        "Mc 6:30-56",
        "2Sm 16",
        "Dn 10:1-11:2"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+6%3A30-56&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+10%3A1-11%3A2&version=ARC"
      ]
    },
    "06-24": {
      "referencias": [
        "Mc 7:1-13",
        "2Sm 17",
        "Dn 11:2-20"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+7%3A1-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+11%3A2-20&version=ARC"
      ]
    },
    "06-25": {
      "referencias": [
        "Mc 7:14-37",
        "2Sm 18",
        "Dn 11:21-45"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+7%3A14-37&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+11%3A21-45&version=ARC"
      ]
    },
    "06-26": {
      "referencias": [
        "Mc 8:1-21",
        "2Sm 19",
        "Dn 12"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+8%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Daniel+12&version=ARC"
      ]
    },
    "06-27": {
      "referencias": [
        "Mc 8:22-9:1",
        "2Sm 20-21",
        "Os 1:1-2:1"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+8%3A22-9%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+1%3A1-2%3A1&version=ARC"
      ]
    },
    "06-28": {
      "referencias": [
        "Mc 9:2-50",
        "2Sm 22",
        "Os 2:2-23"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+9%3A2-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+2%3A2-23&version=ARC"
      ]
    },
    "06-29": {
      "referencias": [
        "Mc 10:1-31",
        "2Sm 23",
        "Os 3"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+10%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+3&version=ARC"
      ]
    },
    "06-30": {
      "referencias": [
        "Mc 10:32-52",
        "2Sm 24",
        "Os 4:1-10"
      ],
      "pagina_pdf": 6,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+10%3A32-52&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Samuel+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+4%3A1-10&version=ARC"
      ]
    },
    "07-01": {
      "referencias": [
        "Mc 11:1-14",
        "1Rs 1",
        "Os 4:11-5:3"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+11%3A1-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+4%3A11-5%3A3&version=ARC"
      ]
    },
    "07-02": {
      "referencias": [
        "Mc 11:15-33",
        "1Rs 2",
        "Os 5:4-15"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+11%3A15-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+5%3A4-15&version=ARC"
      ]
    },
    "07-03": {
      "referencias": [
        "Mc 12:1-27",
        "1Rs 3",
        "Os 6:1-7:2"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+12%3A1-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+6%3A1-7%3A2&version=ARC"
      ]
    },
    "07-04": {
      "referencias": [
        "Mc 12:28-44",
        "1Rs 4-5",
        "Os 7:3-16"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+12%3A28-44&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+4-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+7%3A3-16&version=ARC"
      ]
    },
    "07-05": {
      "referencias": [
        "Mc 13:1-13",
        "1Rs 6",
        "Os 8"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+13%3A1-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+8&version=ARC"
      ]
    },
    "07-06": {
      "referencias": [
        "Mc 13:14-37",
        "1Rs 7",
        "Os 9:1-16"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+13%3A14-37&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+9%3A1-16&version=ARC"
      ]
    },
    "07-07": {
      "referencias": [
        "Mc 14:1-31",
        "1Rs 8",
        "Os 9:17-10:15"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+14%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+9%3A17-10%3A15&version=ARC"
      ]
    },
    "07-08": {
      "referencias": [
        "Mc 14:32-72",
        "1Rs 9",
        "Os 11:1-11"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+14%3A32-72&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+11%3A1-11&version=ARC"
      ]
    },
    "07-09": {
      "referencias": [
        "Mc 15:1-20",
        "1Rs 10",
        "Os 11:12-12:14"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+15%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+11%3A12-12%3A14&version=ARC"
      ]
    },
    "07-10": {
      "referencias": [
        "Mc 15:21-47",
        "1Rs 11",
        "Os 13"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+15%3A21-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+13&version=ARC"
      ]
    },
    "07-11": {
      "referencias": [
        "Mc 16",
        "1Rs 12:1-31",
        "Os 14"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=Marcos+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+12%3A1-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Oseias+14&version=ARC"
      ]
    },
    "07-12": {
      "referencias": [
        "1Co 1:1-17",
        "1Rs 12:32-13:34",
        "Jl 1"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+1%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+12%3A32-13%3A34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Joel+1&version=ARC"
      ]
    },
    "07-13": {
      "referencias": [
        "1Co 1:18-31",
        "1Rs 14",
        "Jl 2:1-11"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+1%3A18-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Joel+2%3A1-11&version=ARC"
      ]
    },
    "07-14": {
      "referencias": [
        "1Co 2",
        "1Rs 15:1-32",
        "Jl 2:12-32"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+15%3A1-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Joel+2%3A12-32&version=ARC"
      ]
    },
    "07-15": {
      "referencias": [
        "1Co 3",
        "1Rs 15:33-16:34",
        "Jl 3"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+15%3A33-16%3A34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Joel+3&version=ARC"
      ]
    },
    "07-16": {
      "referencias": [
        "1Co 4",
        "1Rs 17",
        "Am 1"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+1&version=ARC"
      ]
    },
    "07-17": {
      "referencias": [
        "1Co 5",
        "1Rs 18",
        "Am 2:1-3:2"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+2%3A1-3%3A2&version=ARC"
      ]
    },
    "07-18": {
      "referencias": [
        "1Co 6",
        "1Rs 19",
        "Am 3:3-4:3"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+3%3A3-4%3A3&version=ARC"
      ]
    },
    "07-19": {
      "referencias": [
        "1Co 7:1-24",
        "1Rs 20",
        "Am 4:4-13"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+7%3A1-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+4%3A4-13&version=ARC"
      ]
    },
    "07-20": {
      "referencias": [
        "1Co 7:25-40",
        "1Rs 21",
        "Am 5"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+7%3A25-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+5&version=ARC"
      ]
    },
    "07-21": {
      "referencias": [
        "1Co 8",
        "1Rs 22",
        "Am 6"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Reis+22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+6&version=ARC"
      ]
    },
    "07-22": {
      "referencias": [
        "1Co 9",
        "2Rs 1-2",
        "Am 7"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+7&version=ARC"
      ]
    },
    "07-23": {
      "referencias": [
        "1Co 10",
        "2Rs 3",
        "Am 8"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+10&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+8&version=ARC"
      ]
    },
    "07-24": {
      "referencias": [
        "1Co 11:1-16",
        "2Rs 4",
        "Am 9"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+11%3A1-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Am%C3%B3s+9&version=ARC"
      ]
    },
    "07-25": {
      "referencias": [
        "1Co 11:17-34",
        "2Rs 5",
        "Ob"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+11%3A17-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Obadias+&version=ARC"
      ]
    },
    "07-26": {
      "referencias": [
        "1Co 12",
        "2Rs 6:1-7:2",
        "Jn 1"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+6%3A1-7%3A2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jonas+1&version=ARC"
      ]
    },
    "07-27": {
      "referencias": [
        "1Co 13",
        "2Rs 7:3-20",
        "Jn 2"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+7%3A3-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jonas+2&version=ARC"
      ]
    },
    "07-28": {
      "referencias": [
        "1Co 14:1-25",
        "2Rs 8",
        "Jn 3"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+14%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jonas+3&version=ARC"
      ]
    },
    "07-29": {
      "referencias": [
        "1Co 14:26-40",
        "2Rs 9",
        "Jn 4"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+14%3A26-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jonas+4&version=ARC"
      ]
    },
    "07-30": {
      "referencias": [
        "1Co 15:1-34",
        "2Rs 10",
        "Mq 1"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+15%3A1-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+1&version=ARC"
      ]
    },
    "07-31": {
      "referencias": [
        "1Co 15:35-58",
        "2Rs 11",
        "Mq 2"
      ],
      "pagina_pdf": 7,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+15%3A35-58&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+2&version=ARC"
      ]
    },
    "08-01": {
      "referencias": [
        "1Co 16",
        "2Rs 12-13",
        "Mq 3"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Cor%C3%ADntios+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+12-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+3&version=ARC"
      ]
    },
    "08-02": {
      "referencias": [
        "2Co 1:1-2:4",
        "2Rs 14",
        "Mq 4:1-5:1"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+1%3A1-2%3A4&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+4%3A1-5%3A1&version=ARC"
      ]
    },
    "08-03": {
      "referencias": [
        "2Co 2:5-3:18",
        "2Rs 15-16",
        "Mq 5:2-15"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+2%3A5-3%3A18&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+15-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+5%3A2-15&version=ARC"
      ]
    },
    "08-04": {
      "referencias": [
        "2Co 4:1-5:10",
        "2Rs 17",
        "Mq 6"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+4%3A1-5%3A10&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+6&version=ARC"
      ]
    },
    "08-05": {
      "referencias": [
        "2Co 5:11-6:13",
        "2Rs 18",
        "Mq 7"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+5%3A11-6%3A13&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Miqueias+7&version=ARC"
      ]
    },
    "08-06": {
      "referencias": [
        "2Co 6:14-7:16",
        "2Rs 19",
        "Na 1"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+6%3A14-7%3A16&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Naum+1&version=ARC"
      ]
    },
    "08-07": {
      "referencias": [
        "2Co 8",
        "2Rs 20-21",
        "Na 2"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Naum+2&version=ARC"
      ]
    },
    "08-08": {
      "referencias": [
        "2Co 9",
        "2Rs 22:1-23:34",
        "Na 3"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+22%3A1-23%3A34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Naum+3&version=ARC"
      ]
    },
    "08-09": {
      "referencias": [
        "2Co 10",
        "2Rs 23:35-24:20",
        "Hc 1"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+10&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+23%3A35-24%3A20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Habacuque+1&version=ARC"
      ]
    },
    "08-10": {
      "referencias": [
        "2Co 11",
        "2Rs 25",
        "Hc 2"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Reis+25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Habacuque+2&version=ARC"
      ]
    },
    "08-11": {
      "referencias": [
        "2Co 12",
        "1Cr 1-2",
        "Hc 3"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Habacuque+3&version=ARC"
      ]
    },
    "08-12": {
      "referencias": [
        "2Co 13",
        "1Cr 3-4",
        "Sf 1"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Cor%C3%ADntios+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Sofonias+1&version=ARC"
      ]
    },
    "08-13": {
      "referencias": [
        "Jo 1:1-18",
        "1Cr 5-6",
        "Sf 2"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+1%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Sofonias+2&version=ARC"
      ]
    },
    "08-14": {
      "referencias": [
        "Jo 1:19-34",
        "1Cr 7-8",
        "Sf 3"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+1%3A19-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Sofonias+3&version=ARC"
      ]
    },
    "08-15": {
      "referencias": [
        "Jo 1:35-51",
        "1Cr 9",
        "Ag 1-2"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+1%3A35-51&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ageu+1-2&version=ARC"
      ]
    },
    "08-16": {
      "referencias": [
        "Jo 2",
        "1Cr 10-11",
        "Zc 1"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+10-11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+1&version=ARC"
      ]
    },
    "08-17": {
      "referencias": [
        "Jo 3:1-21",
        "1Cr 12",
        "Zc 2"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+3%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+2&version=ARC"
      ]
    },
    "08-18": {
      "referencias": [
        "Jo 3:22-36",
        "1Cr 13-14",
        "Zc 3"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+3%3A22-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+13-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+3&version=ARC"
      ]
    },
    "08-19": {
      "referencias": [
        "Jo 4:1-26",
        "1Cr 15:1-16:7",
        "Zc 4"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+4%3A1-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+15%3A1-16%3A7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+4&version=ARC"
      ]
    },
    "08-20": {
      "referencias": [
        "Jo 4:27-42",
        "1Cr 16:8-43",
        "Zc 5"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+4%3A27-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+16%3A8-43&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+5&version=ARC"
      ]
    },
    "08-21": {
      "referencias": [
        "Jo 4:43-54",
        "1Cr 17",
        "Zc 6"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+4%3A43-54&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+6&version=ARC"
      ]
    },
    "08-22": {
      "referencias": [
        "Jo 5:1-18",
        "1Cr 18-19",
        "Zc 7"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+5%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+18-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+7&version=ARC"
      ]
    },
    "08-23": {
      "referencias": [
        "Jo 5:19-47",
        "1Cr 20-21",
        "Zc 8"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+5%3A19-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+20-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+8&version=ARC"
      ]
    },
    "08-24": {
      "referencias": [
        "Jo 6:1-24",
        "1Cr 22-23",
        "Zc 9"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+6%3A1-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+22-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+9&version=ARC"
      ]
    },
    "08-25": {
      "referencias": [
        "Jo 6:25-59",
        "1Cr 24",
        "Zc 10"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+6%3A25-59&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+10&version=ARC"
      ]
    },
    "08-26": {
      "referencias": [
        "Jo 6:60-71",
        "1Cr 25-26",
        "Zc 11"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+6%3A60-71&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+25-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+11&version=ARC"
      ]
    },
    "08-27": {
      "referencias": [
        "Jo 7:1-24",
        "1Cr 27-28",
        "Zc 12"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+7%3A1-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+12&version=ARC"
      ]
    },
    "08-28": {
      "referencias": [
        "Jo 7:25-52",
        "1Cr 29",
        "Zc 13"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+7%3A25-52&version=ARC",
        "https://www.biblegateway.com/passage/?search=1+Cr%C3%B4nicas+29&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+13&version=ARC"
      ]
    },
    "08-29": {
      "referencias": [
        "Jo 8:1-20",
        "2Cr 1:1-2:16",
        "Zc 14"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+8%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+1%3A1-2%3A16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Zacarias+14&version=ARC"
      ]
    },
    "08-30": {
      "referencias": [
        "Jo 8:21-47",
        "2Cr 2:17-5:1",
        "Ml 1:1-2:9"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+8%3A21-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+2%3A17-5%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Malaquias+1%3A1-2%3A9&version=ARC"
      ]
    },
    "08-31": {
      "referencias": [
        "Jo 8:48-59",
        "2Cr 5:2-14",
        "Ml 2:10-16"
      ],
      "pagina_pdf": 8,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+8%3A48-59&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+5%3A2-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Malaquias+2%3A10-16&version=ARC"
      ]
    },
    "09-01": {
      "referencias": [
        "Jo 9:1-23",
        "2Cr 6",
        "Ml 2:17-3:18"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+9%3A1-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Malaquias+2%3A17-3%3A18&version=ARC"
      ]
    },
    "09-02": {
      "referencias": [
        "Jo 9:24-41",
        "2Cr 7",
        "Ml 4"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+9%3A24-41&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Malaquias+4&version=ARC"
      ]
    },
    "09-03": {
      "referencias": [
        "Jo 10:1-21",
        "2Cr 8",
        "Sl 73"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+10%3A1-21&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+73&version=ARC"
      ]
    },
    "09-04": {
      "referencias": [
        "Jo 10:22-42",
        "2Cr 9",
        "Sl 74"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+10%3A22-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+74&version=ARC"
      ]
    },
    "09-05": {
      "referencias": [
        "Jo 11:1-27",
        "2Cr 10-11",
        "Sl 75"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+11%3A1-27&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+10-11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+75&version=ARC"
      ]
    },
    "09-06": {
      "referencias": [
        "Jo 11:28-57",
        "2Cr 12-13",
        "Sl 76"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+11%3A28-57&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+12-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+76&version=ARC"
      ]
    },
    "09-07": {
      "referencias": [
        "Jo 12:1-26",
        "2Cr 14-15",
        "Sl 77"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+12%3A1-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+14-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+77&version=ARC"
      ]
    },
    "09-08": {
      "referencias": [
        "Jo 12:27-50",
        "2Cr 16-17",
        "Sl 78:1-20"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+12%3A27-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+16-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+78%3A1-20&version=ARC"
      ]
    },
    "09-09": {
      "referencias": [
        "Jo 13:1-20",
        "2Cr 18",
        "Sl 78:21-37"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+13%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+78%3A21-37&version=ARC"
      ]
    },
    "09-10": {
      "referencias": [
        "Jo 13:21-38",
        "2Cr 19",
        "Sl 78:38-55"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+13%3A21-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+78%3A38-55&version=ARC"
      ]
    },
    "09-11": {
      "referencias": [
        "Jo 14:1-14",
        "2Cr 20:1-21:1",
        "Sl 78:56-72"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+14%3A1-14&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+20%3A1-21%3A1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+78%3A56-72&version=ARC"
      ]
    },
    "09-12": {
      "referencias": [
        "Jo 14:15-31",
        "2Cr 21:2-22:12",
        "Sl 79"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+14%3A15-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+21%3A2-22%3A12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+79&version=ARC"
      ]
    },
    "09-13": {
      "referencias": [
        "Jo 15:1-16:4",
        "2Cr 23",
        "Sl 80"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+15%3A1-16%3A4&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+80&version=ARC"
      ]
    },
    "09-14": {
      "referencias": [
        "Jo 16:4-33",
        "2Cr 24",
        "Sl 81"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+16%3A4-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+81&version=ARC"
      ]
    },
    "09-15": {
      "referencias": [
        "Jo 17",
        "2Cr 25",
        "Sl 82"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+82&version=ARC"
      ]
    },
    "09-16": {
      "referencias": [
        "Jo 18:1-18",
        "2Cr 26",
        "Sl 83"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+18%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+83&version=ARC"
      ]
    },
    "09-17": {
      "referencias": [
        "Jo 18:19-38",
        "2Cr 27-28",
        "Sl 84"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+18%3A19-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+84&version=ARC"
      ]
    },
    "09-18": {
      "referencias": [
        "Jo 18:38-19:16",
        "2Cr 29",
        "Sl 85"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+18%3A38-19%3A16&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+29&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+85&version=ARC"
      ]
    },
    "09-19": {
      "referencias": [
        "Jo 19:16-42",
        "2Cr 30",
        "Sl 86"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+19%3A16-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+86&version=ARC"
      ]
    },
    "09-20": {
      "referencias": [
        "Jo 20:1-18",
        "2Cr 31",
        "Sl 87"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+20%3A1-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+87&version=ARC"
      ]
    },
    "09-21": {
      "referencias": [
        "Jo 20:19-31",
        "2Cr 32",
        "Sl 88"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+20%3A19-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+88&version=ARC"
      ]
    },
    "09-22": {
      "referencias": [
        "Jo 21",
        "2Cr 33",
        "Sl 89:1-18"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Jo%C3%A3o+21&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+89%3A1-18&version=ARC"
      ]
    },
    "09-23": {
      "referencias": [
        "1Jo 1",
        "2Cr 34",
        "Sl 89:19-37"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Jo%C3%A3o+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+89%3A19-37&version=ARC"
      ]
    },
    "09-24": {
      "referencias": [
        "1Jo 2",
        "2Cr 35",
        "Sl 89:38-52"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Jo%C3%A3o+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+35&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+89%3A38-52&version=ARC"
      ]
    },
    "09-25": {
      "referencias": [
        "1Jo 3",
        "2Cr 36",
        "Sl 90"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Jo%C3%A3o+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=2+Cr%C3%B4nicas+36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+90&version=ARC"
      ]
    },
    "09-26": {
      "referencias": [
        "1Jo 4",
        "Ed 1-2",
        "Sl 91"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Jo%C3%A3o+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Esdras+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+91&version=ARC"
      ]
    },
    "09-27": {
      "referencias": [
        "1Jo 5",
        "Ed 3-4",
        "Sl 92"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Jo%C3%A3o+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Esdras+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+92&version=ARC"
      ]
    },
    "09-28": {
      "referencias": [
        "2Jo",
        "Ed 5-6",
        "Sl 93"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Jo%C3%A3o+&version=ARC",
        "https://www.biblegateway.com/passage/?search=Esdras+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+93&version=ARC"
      ]
    },
    "09-29": {
      "referencias": [
        "3Jo",
        "Ed 7-8",
        "Sl 94"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=3+Jo%C3%A3o+&version=ARC",
        "https://www.biblegateway.com/passage/?search=Esdras+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+94&version=ARC"
      ]
    },
    "09-30": {
      "referencias": [
        "Jd",
        "Ed 9-10",
        "Sl 95"
      ],
      "pagina_pdf": 9,
      "links": [
        "https://www.biblegateway.com/passage/?search=Judas+&version=ARC",
        "https://www.biblegateway.com/passage/?search=Esdras+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+95&version=ARC"
      ]
    },
    "10-01": {
      "referencias": [
        "Ap 1",
        "Ne 1-2",
        "Sl 96"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+96&version=ARC"
      ]
    },
    "10-02": {
      "referencias": [
        "Ap 2",
        "Ne 3",
        "Sl 97"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+97&version=ARC"
      ]
    },
    "10-03": {
      "referencias": [
        "Ap 3",
        "Ne 4",
        "Sl 98"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+98&version=ARC"
      ]
    },
    "10-04": {
      "referencias": [
        "Ap 4",
        "Ne 5:1-7:3",
        "Sl 99"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+5%3A1-7%3A3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+99&version=ARC"
      ]
    },
    "10-05": {
      "referencias": [
        "Ap 5",
        "Ne 7:4-8:12",
        "Sl 100"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+7%3A4-8%3A12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+100&version=ARC"
      ]
    },
    "10-06": {
      "referencias": [
        "Ap 6",
        "Ne 8:13-9:37",
        "Sl 101"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+8%3A13-9%3A37&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+101&version=ARC"
      ]
    },
    "10-07": {
      "referencias": [
        "Ap 7",
        "Ne 9:38-10:39",
        "Sl 102"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+9%3A38-10%3A39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+102&version=ARC"
      ]
    },
    "10-08": {
      "referencias": [
        "Ap 8",
        "Ne 11",
        "Sl 103"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+103&version=ARC"
      ]
    },
    "10-09": {
      "referencias": [
        "Ap 9",
        "Ne 12",
        "Sl 104:1-23"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+104%3A1-23&version=ARC"
      ]
    },
    "10-10": {
      "referencias": [
        "Ap 10",
        "Ne 13",
        "Sl 104:24-35"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Neemias+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+104%3A24-35&version=ARC"
      ]
    },
    "10-11": {
      "referencias": [
        "Ap 11",
        "Et 1",
        "Sl 105:1-25"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+105%3A1-25&version=ARC"
      ]
    },
    "10-12": {
      "referencias": [
        "Ap 12",
        "Et 2",
        "Sl 105:26-45"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+105%3A26-45&version=ARC"
      ]
    },
    "10-13": {
      "referencias": [
        "Ap 13",
        "Et 3-4",
        "Sl 106:1-23"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+106%3A1-23&version=ARC"
      ]
    },
    "10-14": {
      "referencias": [
        "Ap 14",
        "Et 5:1-6:13",
        "Sl 106:24-48"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+14&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+5%3A1-6%3A13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+106%3A24-48&version=ARC"
      ]
    },
    "10-15": {
      "referencias": [
        "Ap 15",
        "Et 6:14-8:17",
        "Sl 107:1-22"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+6%3A14-8%3A17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+107%3A1-22&version=ARC"
      ]
    },
    "10-16": {
      "referencias": [
        "Ap 16",
        "Et 9-10",
        "Sl 107:23-43"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ester+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+107%3A23-43&version=ARC"
      ]
    },
    "10-17": {
      "referencias": [
        "Ap 17",
        "Is 1-2",
        "Sl 108"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+108&version=ARC"
      ]
    },
    "10-18": {
      "referencias": [
        "Ap 18",
        "Is 3-4",
        "Sl 109:1-19"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+109%3A1-19&version=ARC"
      ]
    },
    "10-19": {
      "referencias": [
        "Ap 19",
        "Is 5-6",
        "Sl 109:20-31"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+109%3A20-31&version=ARC"
      ]
    },
    "10-20": {
      "referencias": [
        "Ap 20",
        "Is 7-8",
        "Sl 110"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+7-8&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+110&version=ARC"
      ]
    },
    "10-21": {
      "referencias": [
        "Ap 21-22",
        "Is 9-10",
        "Sl 111"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=Apocalipse+21-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+9-10&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+111&version=ARC"
      ]
    },
    "10-22": {
      "referencias": [
        "1Ts 1",
        "Is 11-13",
        "Sl 112"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tessalonicenses+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+11-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+112&version=ARC"
      ]
    },
    "10-23": {
      "referencias": [
        "1Ts 2:1-16",
        "Is 14-16",
        "Sl 113"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tessalonicenses+2%3A1-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+14-16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+113&version=ARC"
      ]
    },
    "10-24": {
      "referencias": [
        "1Ts 2:17-3:13",
        "Is 17-19",
        "Sl 114"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tessalonicenses+2%3A17-3%3A13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+17-19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+114&version=ARC"
      ]
    },
    "10-25": {
      "referencias": [
        "1Ts 4",
        "Is 20-22",
        "Sl 115"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tessalonicenses+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+20-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+115&version=ARC"
      ]
    },
    "10-26": {
      "referencias": [
        "1Ts 5",
        "Is 23-24",
        "Sl 116"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tessalonicenses+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+23-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+116&version=ARC"
      ]
    },
    "10-27": {
      "referencias": [
        "2Ts 1",
        "Is 25-26",
        "Sl 117"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tessalonicenses+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+25-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+117&version=ARC"
      ]
    },
    "10-28": {
      "referencias": [
        "2Ts 2",
        "Is 27-28",
        "Sl 118"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tessalonicenses+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+118&version=ARC"
      ]
    },
    "10-29": {
      "referencias": [
        "2Ts 3",
        "Is 29-30",
        "Sl 119:1-32"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tessalonicenses+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+29-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A1-32&version=ARC"
      ]
    },
    "10-30": {
      "referencias": [
        "1Tm 1",
        "Is 31-33",
        "Sl 119:33-64"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+31-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A33-64&version=ARC"
      ]
    },
    "10-31": {
      "referencias": [
        "1Tm 2",
        "Is 34-35",
        "Sl 119:65-96"
      ],
      "pagina_pdf": 10,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+34-35&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A65-96&version=ARC"
      ]
    },
    "11-01": {
      "referencias": [
        "1Tm 3",
        "Is 36-37",
        "Sl 119:97-120"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+36-37&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A97-120&version=ARC"
      ]
    },
    "11-02": {
      "referencias": [
        "1Tm 4",
        "Is 38-39",
        "Sl 119:121-144"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+38-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A121-144&version=ARC"
      ]
    },
    "11-03": {
      "referencias": [
        "1Tm 5:1-20",
        "Jr 1-2",
        "Sl 119:145-176"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+5%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+119%3A145-176&version=ARC"
      ]
    },
    "11-04": {
      "referencias": [
        "1Tm 5:21-6:21",
        "Jr 3-4",
        "Sl 120"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Tim%C3%B3teo+5%3A21-6%3A21&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+120&version=ARC"
      ]
    },
    "11-05": {
      "referencias": [
        "2Tm 1",
        "Jr 5-6",
        "Sl 121"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tim%C3%B3teo+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+5-6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+121&version=ARC"
      ]
    },
    "11-06": {
      "referencias": [
        "2Tm 2",
        "Jr 7:1-8:17",
        "Sl 122"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tim%C3%B3teo+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+7%3A1-8%3A17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+122&version=ARC"
      ]
    },
    "11-07": {
      "referencias": [
        "2Tm 3",
        "Jr 8:18-10:25",
        "Sl 123"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tim%C3%B3teo+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+8%3A18-10%3A25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+123&version=ARC"
      ]
    },
    "11-08": {
      "referencias": [
        "2Tm 4",
        "Jr 11-12",
        "Sl 124"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Tim%C3%B3teo+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+11-12&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+124&version=ARC"
      ]
    },
    "11-09": {
      "referencias": [
        "Tt 1",
        "Jr 13-15",
        "Sl 125"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tito+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+13-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+125&version=ARC"
      ]
    },
    "11-10": {
      "referencias": [
        "Tt 2",
        "Jr 16",
        "Sl 126"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tito+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+126&version=ARC"
      ]
    },
    "11-11": {
      "referencias": [
        "Tt 3",
        "Jr 17-18",
        "Sl 127"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tito+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+17-18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+127&version=ARC"
      ]
    },
    "11-12": {
      "referencias": [
        "Fm",
        "Jr 19-20",
        "Sl 128"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filemom+&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+19-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+128&version=ARC"
      ]
    },
    "11-13": {
      "referencias": [
        "Tg 1",
        "Jr 21-22",
        "Sl 129"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tiago+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+21-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+129&version=ARC"
      ]
    },
    "11-14": {
      "referencias": [
        "Tg 2",
        "Jr 23-24",
        "Sl 130"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tiago+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+23-24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+130&version=ARC"
      ]
    },
    "11-15": {
      "referencias": [
        "Tg 3",
        "Jr 25-26",
        "Sl 131"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tiago+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+25-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+131&version=ARC"
      ]
    },
    "11-16": {
      "referencias": [
        "Tg 4",
        "Jr 27-28",
        "Sl 132"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tiago+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+132&version=ARC"
      ]
    },
    "11-17": {
      "referencias": [
        "Tg 5",
        "Jr 29-30",
        "Sl 133"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=Tiago+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+29-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+133&version=ARC"
      ]
    },
    "11-18": {
      "referencias": [
        "1Pe 1",
        "Jr 31-32",
        "Sl 134"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Pedro+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+31-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+134&version=ARC"
      ]
    },
    "11-19": {
      "referencias": [
        "1Pe 2",
        "Jr 33-34",
        "Sl 135"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Pedro+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+33-34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+135&version=ARC"
      ]
    },
    "11-20": {
      "referencias": [
        "1Pe 3",
        "Jr 35-36",
        "Sl 136"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Pedro+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+35-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+136&version=ARC"
      ]
    },
    "11-21": {
      "referencias": [
        "1Pe 4",
        "Jr 37-38",
        "Sl 137"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Pedro+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+37-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+137&version=ARC"
      ]
    },
    "11-22": {
      "referencias": [
        "1Pe 5",
        "Jr 39-40",
        "Sl 138"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=1+Pedro+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+39-40&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+138&version=ARC"
      ]
    },
    "11-23": {
      "referencias": [
        "2Pe 1",
        "Jr 41-42",
        "Sl 139"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Pedro+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+41-42&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+139&version=ARC"
      ]
    },
    "11-24": {
      "referencias": [
        "2Pe 2",
        "Jr 43-44",
        "Sl 140"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Pedro+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+43-44&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+140&version=ARC"
      ]
    },
    "11-25": {
      "referencias": [
        "2Pe 3",
        "Jr 45-46",
        "Sl 141"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=2+Pedro+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+45-46&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+141&version=ARC"
      ]
    },
    "11-26": {
      "referencias": [
        "Gl 1",
        "Jr 47-48",
        "Sl 142"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+47-48&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+142&version=ARC"
      ]
    },
    "11-27": {
      "referencias": [
        "Gl 2",
        "Jr 49-50",
        "Sl 143"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+49-50&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+143&version=ARC"
      ]
    },
    "11-28": {
      "referencias": [
        "Gl 3:1-20",
        "Jr 51-52",
        "Sl 144"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+3%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Jeremias+51-52&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+144&version=ARC"
      ]
    },
    "11-29": {
      "referencias": [
        "Gl 3:21-4:20",
        "Lm 1-2",
        "Sl 145"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+3%3A21-4%3A20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lamenta%C3%A7%C3%B5es+1-2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+145&version=ARC"
      ]
    },
    "11-30": {
      "referencias": [
        "Gl 4:21-31",
        "Lm 3-4",
        "Sl 146"
      ],
      "pagina_pdf": 11,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+4%3A21-31&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lamenta%C3%A7%C3%B5es+3-4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+146&version=ARC"
      ]
    },
    "12-01": {
      "referencias": [
        "Gl 5:1-15",
        "Lm 5",
        "Sl 147"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+5%3A1-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Lamenta%C3%A7%C3%B5es+5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+147&version=ARC"
      ]
    },
    "12-02": {
      "referencias": [
        "Gl 5:16-26",
        "Ez 1",
        "Sl 148"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+5%3A16-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+148&version=ARC"
      ]
    },
    "12-03": {
      "referencias": [
        "Gl 6",
        "Ez 2-3",
        "Sl 149"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=G%C3%A1latas+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+2-3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+149&version=ARC"
      ]
    },
    "12-04": {
      "referencias": [
        "Ef 1",
        "Ez 4-5",
        "Sl 150"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+1&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+4-5&version=ARC",
        "https://www.biblegateway.com/passage/?search=Salmos+150&version=ARC"
      ]
    },
    "12-05": {
      "referencias": [
        "Ef 2",
        "Ez 6-7",
        "Is 40"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+2&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+6-7&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+40&version=ARC"
      ]
    },
    "12-06": {
      "referencias": [
        "Ef 3",
        "Ez 8-9",
        "Is 41"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+8-9&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+41&version=ARC"
      ]
    },
    "12-07": {
      "referencias": [
        "Ef 4:1-17",
        "Ez 10-11",
        "Is 42"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+4%3A1-17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+10-11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+42&version=ARC"
      ]
    },
    "12-08": {
      "referencias": [
        "Ef 4:17-32",
        "Ez 12-13",
        "Is 43"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+4%3A17-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+12-13&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+43&version=ARC"
      ]
    },
    "12-09": {
      "referencias": [
        "Ef 5:1-20",
        "Ez 14-15",
        "Is 44"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+5%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+14-15&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+44&version=ARC"
      ]
    },
    "12-10": {
      "referencias": [
        "Ef 5:21-33",
        "Ez 16",
        "Is 45"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+5%3A21-33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+16&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+45&version=ARC"
      ]
    },
    "12-11": {
      "referencias": [
        "Ef 6",
        "Ez 17",
        "Is 46"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Ef%C3%A9sios+6&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+46&version=ARC"
      ]
    },
    "12-12": {
      "referencias": [
        "Fp 1:1-11",
        "Ez 18",
        "Is 47"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+1%3A1-11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+47&version=ARC"
      ]
    },
    "12-13": {
      "referencias": [
        "Fp 1:12-30",
        "Ez 19",
        "Is 48"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+1%3A12-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+48&version=ARC"
      ]
    },
    "12-14": {
      "referencias": [
        "Fp 2:1-11",
        "Ez 20",
        "Is 49"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+2%3A1-11&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+49&version=ARC"
      ]
    },
    "12-15": {
      "referencias": [
        "Fp 2:12-30",
        "Ez 21-22",
        "Is 50"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+2%3A12-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+21-22&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+50&version=ARC"
      ]
    },
    "12-16": {
      "referencias": [
        "Fp 3",
        "Ez 23",
        "Is 51"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+3&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+51&version=ARC"
      ]
    },
    "12-17": {
      "referencias": [
        "Fp 4",
        "Ez 24",
        "Is 52"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Filipenses+4&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+24&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+52&version=ARC"
      ]
    },
    "12-18": {
      "referencias": [
        "Cl 1:1-23",
        "Ez 25-26",
        "Is 53"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Colossenses+1%3A1-23&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+25-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+53&version=ARC"
      ]
    },
    "12-19": {
      "referencias": [
        "Cl 1:24-2:19",
        "Ez 27-28",
        "Is 54"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Colossenses+1%3A24-2%3A19&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+27-28&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+54&version=ARC"
      ]
    },
    "12-20": {
      "referencias": [
        "Cl 2:20-3:17",
        "Ez 29-30",
        "Is 55"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Colossenses+2%3A20-3%3A17&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+29-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+55&version=ARC"
      ]
    },
    "12-21": {
      "referencias": [
        "Cl 3:18-4:18",
        "Ez 31-32",
        "Is 56"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Colossenses+3%3A18-4%3A18&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+31-32&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+56&version=ARC"
      ]
    },
    "12-22": {
      "referencias": [
        "Lc 1:1-25",
        "Ez 33",
        "Is 57"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+1%3A1-25&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+33&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+57&version=ARC"
      ]
    },
    "12-23": {
      "referencias": [
        "Lc 1:26-56",
        "Ez 34",
        "Is 58"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+1%3A26-56&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+34&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+58&version=ARC"
      ]
    },
    "12-24": {
      "referencias": [
        "Lc 1:57-80",
        "Ez 35-36",
        "Is 59"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+1%3A57-80&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+35-36&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+59&version=ARC"
      ]
    },
    "12-25": {
      "referencias": [
        "Lc 2:1-20",
        "Ez 37",
        "Is 60"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+2%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+37&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+60&version=ARC"
      ]
    },
    "12-26": {
      "referencias": [
        "Lc 2:21-52",
        "Ez 38-39",
        "Is 61"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+2%3A21-52&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+38-39&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+61&version=ARC"
      ]
    },
    "12-27": {
      "referencias": [
        "Lc 3:1-20",
        "Ez 40-41",
        "Is 62"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+3%3A1-20&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+40-41&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+62&version=ARC"
      ]
    },
    "12-28": {
      "referencias": [
        "Lc 3:21-38",
        "Ez 42-43",
        "Is 63"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+3%3A21-38&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+42-43&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+63&version=ARC"
      ]
    },
    "12-29": {
      "referencias": [
        "Lc 4:1-30",
        "Ez 44-45",
        "Is 64"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+4%3A1-30&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+44-45&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+64&version=ARC"
      ]
    },
    "12-30": {
      "referencias": [
        "Lc 4:31-44",
        "Ez 46-47",
        "Is 65"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+4%3A31-44&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+46-47&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+65&version=ARC"
      ]
    },
    "12-31": {
      "referencias": [
        "Lc 5:1-26",
        "Ez 48",
        "Is 66"
      ],
      "pagina_pdf": 12,
      "links": [
        "https://www.biblegateway.com/passage/?search=Lucas+5%3A1-26&version=ARC",
        "https://www.biblegateway.com/passage/?search=Ezequiel+48&version=ARC",
        "https://www.biblegateway.com/passage/?search=Isa%C3%ADas+66&version=ARC"
      ]
    }
  },
  "observacao": "29 de fevereiro não consta no documento. Referências preservadas literalmente; não são escolhidas aleatoriamente."
}
$seed$,'seed-v43') on conflict do nothing;
insert into public.pge_live_paths(path) values('dados/fontes-legitimas.json') on conflict do nothing;
insert into public.pge_documents(path,content,sha) values('dados/fontes-legitimas.json',$seed${
  "versao": 1,
  "diretriz": "A plataforma indica fontes legítimas e mantém pendentes os conteúdos cuja autorização não conseguiu verificar.",
  "avisos": {
    "pt": "Acesso gratuito à plataforma. Obras externas podem exigir assinatura, aluguel ou compra.",
    "en": "Platform access is free. External works may require a subscription, rental or purchase.",
    "es": "El acceso a la plataforma es gratuito. Las obras externas pueden requerir suscripción, alquiler o compra."
  },
  "fontes": [],
  "itens": []
}
$seed$,'seed-v43') on conflict do nothing;
create or replace function public.pge_restore_document(p_version bigint,p_expected_sha text) returns jsonb language plpgsql security definer set search_path='' as $$ declare v public.pge_document_versions;begin
 select * into v from public.pge_document_versions where id=p_version;
 if v.id is null or not public.pge_can(public.pge_document_scope(v.path)||':write') then raise exception 'permission_denied';end if;
 return public.pge_publish_documents(jsonb_build_array(jsonb_build_object('path',v.path,'content',v.content,'expected_sha',p_expected_sha)));
end;$$;
revoke all on function public.pge_can(text),public.pge_my_access(),public.pge_set_member(uuid,text,text[],boolean),public.pge_document_scope(text),public.pge_keep_version(),public.pge_validate_programs(jsonb),public.pge_restore_document(bigint,text) from public,anon,authenticated;
grant execute on function public.pge_can(text),public.pge_my_access(),public.pge_document_scope(text),public.pge_set_member(uuid,text,text[],boolean),public.pge_restore_document(bigint,text) to authenticated;

-- Images are public editorial covers only, never private participant records.
do $$ begin
 if to_regclass('storage.buckets') is not null then
  execute 'insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values(''pge-covers'',''pge-covers'',true,2097152,ARRAY[''image/jpeg'',''image/png'',''image/webp'']) on conflict(id) do nothing';
  execute 'create policy pge_cover_upload on storage.objects for insert to authenticated with check(bucket_id=''pge-covers'' and (storage.foldername(name))[1]=auth.uid()::text and exists(select 1 from public.pge_members m where m.user_id=auth.uid() and m.active and (m.role in (''superadmin'',''editor'') or exists(select 1 from unnest(m.permissions) p where p like ''content:%:write''))))';
 end if;
end;$$;
notify pgrst,'reload schema';
commit;
