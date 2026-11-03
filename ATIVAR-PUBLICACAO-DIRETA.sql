-- Publicação direta: execute no SQL Editor do projeto atual, após o schema original.
-- Não inclui credenciais nem altera os usuários cadastrados.
begin;
create table if not exists public.pge_live_paths(path text primary key);
insert into public.pge_live_paths(path) values
('dados/acoes.json'),
('dados/acolhimento.json'),
('dados/agenda-solidaria.json'),
('dados/artigos.json'),
('dados/atividades-parcerias.json'),
('dados/autocuidado.json'),
('dados/biblias-e-apps.json'),
('dados/biblias-pdf.json'),
('dados/biblioteca/colecoes.json'),
('dados/buscando.json'),
('dados/catalogo-conteudos.json'),
('dados/comunidades.json'),
('dados/corpo-escolhas.json'),
('dados/en/acoes.json'),
('dados/en/acolhimento.json'),
('dados/en/artigos.json'),
('dados/en/autocuidado.json'),
('dados/en/biblias-e-apps.json'),
('dados/en/biblias-pdf.json'),
('dados/en/buscando.json'),
('dados/en/catalogo.txt'),
('dados/en/corpo-escolhas.json'),
('dados/en/espirito-santidade.json'),
('dados/en/estudos.json'),
('dados/en/fe-conhecimento.json'),
('dados/en/interface.json'),
('dados/en/leituras.json'),
('dados/en/lives.json'),
('dados/en/livros.json'),
('dados/en/louvores.json'),
('dados/en/materiais-ensino.json'),
('dados/en/midias-biblicas.json'),
('dados/en/oracoes.txt'),
('dados/en/pagina-inicial.json'),
('dados/en/palestras.json'),
('dados/en/parceiros.json'),
('dados/en/parcerias.json'),
('dados/en/pausa-diaria.json'),
('dados/en/pecado.json'),
('dados/en/recursos-santidade.txt'),
('dados/en/reflexoes.txt'),
('dados/en/spotify.json'),
('dados/en/temas-biblicos.json'),
('dados/en/versiculos.json'),
('dados/en/youtube.json'),
('dados/es/acoes.json'),
('dados/es/acolhimento.json'),
('dados/es/artigos.json'),
('dados/es/autocuidado.json'),
('dados/es/biblias-e-apps.json'),
('dados/es/biblias-pdf.json'),
('dados/es/buscando.json'),
('dados/es/catalogo.txt'),
('dados/es/corpo-escolhas.json'),
('dados/es/espirito-santidade.json'),
('dados/es/estudos.json'),
('dados/es/fe-conhecimento.json'),
('dados/es/interface.json'),
('dados/es/leituras.json'),
('dados/es/lives.json'),
('dados/es/livros.json'),
('dados/es/louvores.json'),
('dados/es/materiais-ensino.json'),
('dados/es/midias-biblicas.json'),
('dados/es/oracoes.txt'),
('dados/es/pagina-inicial.json'),
('dados/es/palestras.json'),
('dados/es/parceiros.json'),
('dados/es/parcerias.json'),
('dados/es/pausa-diaria.json'),
('dados/es/pecado.json'),
('dados/es/recursos-santidade.txt'),
('dados/es/reflexoes.txt'),
('dados/es/spotify.json'),
('dados/es/temas-biblicos.json'),
('dados/es/versiculos.json'),
('dados/es/youtube.json'),
('dados/espirito-santidade.json'),
('dados/estudos.json'),
('dados/fe-conhecimento.json'),
('dados/formacoes.json'),
('dados/ideias-sociais.json'),
('dados/leituras.json'),
('dados/lives.json'),
('dados/livros.json'),
('dados/louvores.json'),
('dados/materiais-ensino.json'),
('dados/midias-biblicas.json'),
('dados/oracoes.txt'),
('dados/pagina-inicial.json'),
('dados/palestras.json'),
('dados/parceiros.json'),
('dados/parcerias.json'),
('dados/pausa-diaria.json'),
('dados/pecado.json'),
('dados/planejamento.json'),
('dados/prestacao-contas.json'),
('dados/projetos.json'),
('dados/recursos-santidade.txt'),
('dados/rede-parceiros.json'),
('dados/reflexoes.txt'),
('dados/spotify.json'),
('dados/temas-biblicos.json'),
('dados/versiculos.json'),
('dados/youtube.json') on conflict do nothing;
create table if not exists public.pge_live_documents(path text primary key references public.pge_live_paths(path),content text not null check(octet_length(content)<=1048576),sha text not null,updated_at timestamptz not null default now(),updated_by uuid references auth.users(id));
create table if not exists public.pge_video_decisions(id text primary key check(id ~ '^[A-Za-z0-9_-]{11}$'),decision text not null check(decision in ('approved','rejected','archived','pending_review')),category text check(category in ('desenho','filme','serie')),portuguese_confirmed boolean not null default false,revision bigint not null default 1,updated_at timestamptz not null default now(),updated_by uuid references auth.users(id));
alter table public.pge_live_paths enable row level security;
alter table public.pge_live_documents enable row level security;
alter table public.pge_video_decisions enable row level security;
revoke all on public.pge_live_paths,public.pge_live_documents,public.pge_video_decisions from public,anon,authenticated;
grant select on public.pge_live_paths,public.pge_live_documents,public.pge_video_decisions to authenticated;
grant all on public.pge_live_paths,public.pge_live_documents,public.pge_video_decisions to service_role;
drop policy if exists pge_live_paths_admin on public.pge_live_paths;
create policy pge_live_paths_admin on public.pge_live_paths for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_live_docs_admin on public.pge_live_documents;
create policy pge_live_docs_admin on public.pge_live_documents for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_video_decisions_admin on public.pge_video_decisions;
create policy pge_video_decisions_admin on public.pge_video_decisions for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));

create or replace function public.pge_public_mode() returns jsonb language sql stable security definer set search_path='' as $$ select jsonb_build_object('version',1,'direct',true); $$;
create or replace function public.pge_public_revision() returns text language sql stable security definer set search_path='' as $$
 select greatest(coalesce((select max(updated_at) from public.pge_live_documents),'epoch'::timestamptz),coalesce((select max(updated_at) from public.pge_video_decisions),'epoch'::timestamptz),coalesce((select max(updated_at) from public.pge_videos),'epoch'::timestamptz))::text;
$$;
create or replace function public.pge_strip_archived(v jsonb) returns jsonb language plpgsql immutable set search_path='' as $$
declare result jsonb;item jsonb;k text;val jsonb;
begin
 if jsonb_typeof(v)='array' then
  result='[]'::jsonb;
  for item in select value from jsonb_array_elements(v) loop
   if jsonb_typeof(item)='object' and item->>'_admin_hidden'='true' then continue; end if;
   result=result||jsonb_build_array(public.pge_strip_archived(item));
  end loop;
  return result;
 elsif jsonb_typeof(v)='object' then
  result='{}'::jsonb;
  for k,val in select key,value from jsonb_each(v) loop
   if k like '\_admin\_%' escape '\' then continue; end if;
   result=result||jsonb_build_object(k,public.pge_strip_archived(val));
  end loop;
  return result;
 end if;
 return v;
end; $$;
create or replace function public.pge_public_document(p_path text) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare document_row public.pge_live_documents;
begin
 select * into document_row from public.pge_live_documents where path=p_path;
 if not found then return jsonb_build_object('exists',false); end if;
 return jsonb_build_object('exists',true,'content',case when p_path like '%.json' then public.pge_strip_archived(document_row.content::jsonb)::text else document_row.content end,'revision',document_row.sha);
end; $$;
create or replace function public.pge_public_catalog() returns jsonb language sql stable security definer set search_path='' as $$
 with combined as (
 select v.id,v.expires_at,(v.record||jsonb_build_object('id',v.id,'url','https://www.youtube.com/watch?v='||v.id))||
 case when d.id is null then '{}'::jsonb else jsonb_build_object('aprovacao',d.decision,'categoria',coalesce(d.category,v.record->>'categoria'))||case when d.portuguese_confirmed then jsonb_build_object('idioma','pt-BR','idiomaVerificado',true) else '{}'::jsonb end end as record
 from public.pge_videos v left join public.pge_video_decisions d on d.id=v.id
 where v.expires_at>now()
 ), eligible as (
 select * from combined where record->>'aprovacao'='approved' and record->>'disponibilidade' in ('available','embed_restricted') and record->>'idiomaVerificado'='true' and record->>'idioma' like 'pt%' and record->>'categoria' in ('desenho','filme','serie') and length(coalesce(record->>'titulo',''))>0
 )
 select jsonb_build_object('versao',3,'itens',coalesce(jsonb_agg(record order by record->>'titulo'),'[]'::jsonb),'validUntil',min(expires_at)) from eligible;
$$;

create or replace function public.pge_publish_documents(p_changes jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();change jsonb;doc_path text;body text;doc_current public.pge_documents;version text;count integer=0;seen text[]='{}';
begin
 if uid is null or not exists(select 1 from public.pge_admins where user_id=uid) then raise exception 'administrator_required'; end if;
 if jsonb_typeof(p_changes) is distinct from 'array' or jsonb_array_length(p_changes) not between 1 and 3 then raise exception 'invalid_changes'; end if;
 for change in select value from jsonb_array_elements(p_changes) order by value->>'path' loop
  doc_path=change->>'path';body=change->>'content';
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

create or replace function public.pge_review_videos(p_items jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare uid uuid=auth.uid();item jsonb;video public.pge_videos;old public.pge_video_decisions;vid text;op text;decision text;category text;confirmed boolean;revision bigint;seen text[]='{}';audit jsonb='[]';
begin
 if uid is null or not exists(select 1 from public.pge_admins where user_id=uid) then raise exception 'administrator_required'; end if;
 if jsonb_typeof(p_items) is distinct from 'array' or jsonb_array_length(p_items) not between 1 and 300 then raise exception 'invalid_batch_size'; end if;
 -- Serialize concurrent decisions, including IDs with no row yet.
 perform pg_advisory_xact_lock(734129815);
 for item in select value from jsonb_array_elements(p_items) order by value->>'id' loop
  vid=item->>'id';op=coalesce(item->>'operation','review');
  if vid is null or vid !~ '^[A-Za-z0-9_-]{11}$' or vid=any(seen) then raise exception 'invalid_video_id'; end if;
  seen=array_append(seen,vid);
  select * into old from public.pge_video_decisions where id=vid;
  revision=coalesce(old.revision,0);
  if coalesce((item->>'expected_revision')::bigint,0)<>revision then raise exception 'conflict_decision_changed'; end if;
  select * into video from public.pge_videos where id=vid;
  if op='restore' then
   if old.decision is null or old.decision not in ('rejected','archived') then raise exception 'conflict_not_blocked'; end if;
   decision=case when old.decision='archived' and old.portuguese_confirmed then 'approved' else 'pending_review' end;category=old.category;confirmed=decision='approved';
  else
   if video.id is null or video.expires_at<=now() or video.sha is distinct from item->>'expected_sha' then raise exception 'conflict_video_changed'; end if;
   category=coalesce(item->>'categoria',old.category,video.record->>'categoria');
   if op='category' then
    decision=coalesce(old.decision,video.record->>'aprovacao','pending_review');
    if decision in ('rejected','archived') then raise exception 'conflict_video_blocked'; end if;
    confirmed=coalesce(old.portuguese_confirmed,false) or (video.record->>'idiomaVerificado'='true' and video.record->>'idioma' like 'pt%');
   elsif op='review' then
    decision=item->>'decision';confirmed=coalesce((item->>'portuguese_confirmed')::boolean,false);if decision='archived' then confirmed=coalesce(old.portuguese_confirmed,false) or (video.record->>'idiomaVerificado'='true' and video.record->>'idioma' like 'pt%');end if;
   else raise exception 'invalid_operation'; end if;
   if decision is null or decision not in ('approved','rejected','archived','pending_review') then raise exception 'invalid_decision'; end if;
   if (op='category' or decision='approved') and (category is null or category not in ('desenho','filme','serie')) then raise exception 'select_category'; end if;
   if decision='approved' and not coalesce(confirmed,false) then raise exception 'confirm_portuguese_first'; end if;
  end if;
  insert into public.pge_video_decisions(id,decision,category,portuguese_confirmed,revision,updated_by) values(vid,decision,case when category in ('desenho','filme','serie') then category else null end,coalesce(confirmed,false),revision+1,uid) on conflict on constraint pge_video_decisions_pkey do update set decision=excluded.decision,category=excluded.category,portuguese_confirmed=excluded.portuguese_confirmed,revision=excluded.revision,updated_at=now(),updated_by=uid;
  audit=audit||jsonb_build_array(jsonb_build_object('id',vid,'decision',decision,'operation',op));
 end loop;
 insert into public.pge_commands(id,user_id,action,payload,status,result) values(pg_catalog.gen_random_uuid(),uid,'review_video',jsonb_build_object('items',audit,'count',jsonb_array_length(audit)),'applied','Decisão publicada imediatamente.');
 return jsonb_build_object('published',jsonb_array_length(audit));
end; $$;
-- Normalized partner/project relationships, maintained from the authoring documents.
create table if not exists public.pge_partner_entities(id text primary key,record jsonb not null,updated_at timestamptz not null default now());
create table if not exists public.pge_project_entities(id text primary key,record jsonb not null,updated_at timestamptz not null default now());
create table if not exists public.pge_project_partners(project_id text references public.pge_project_entities(id) on delete cascade,partner_id text references public.pge_partner_entities(id) on delete cascade,status text not null check(status in ('a-propor','em-conversa','confirmada')),role text not null default '',primary key(project_id,partner_id));
alter table public.pge_partner_entities enable row level security;
alter table public.pge_project_entities enable row level security;
alter table public.pge_project_partners enable row level security;
revoke all on public.pge_partner_entities,public.pge_project_entities,public.pge_project_partners from public,anon,authenticated;
grant select on public.pge_partner_entities,public.pge_project_entities,public.pge_project_partners to authenticated;
grant all on public.pge_partner_entities,public.pge_project_entities,public.pge_project_partners to service_role;
drop policy if exists pge_partner_entity_admin on public.pge_partner_entities;
create policy pge_partner_entity_admin on public.pge_partner_entities for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_project_entity_admin on public.pge_project_entities;
create policy pge_project_entity_admin on public.pge_project_entities for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_project_partner_admin on public.pge_project_partners;
create policy pge_project_partner_admin on public.pge_project_partners for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
create or replace function public.pge_refresh_entities(p_path text,p_content text) returns void language plpgsql security definer set search_path='' as $$
declare item jsonb;relation jsonb;
begin
 if p_path='dados/rede-parceiros.json' then
  for item in select value from jsonb_array_elements(coalesce(p_content::jsonb->'unidades','[]')) loop
   if coalesce(item->>'id','')='' then raise exception 'invalid_partner_id'; end if;
   insert into public.pge_partner_entities(id,record) values(item->>'id',item) on conflict(id) do update set record=excluded.record,updated_at=now();
  end loop;
  delete from public.pge_partner_entities where id not in(select value->>'id' from jsonb_array_elements(coalesce(p_content::jsonb->'unidades','[]')));
 elsif p_path='dados/projetos.json' then
  for item in select value from jsonb_array_elements(coalesce(p_content::jsonb->'itens','[]')) loop
   if coalesce(item->>'id','')='' then raise exception 'invalid_project_id'; end if;
   insert into public.pge_project_entities(id,record) values(item->>'id',item) on conflict(id) do update set record=excluded.record,updated_at=now();
   delete from public.pge_project_partners where project_id=item->>'id';
   for relation in select value from jsonb_array_elements(coalesce(item->'parcerias','[]')) loop
    if not exists(select 1 from public.pge_partner_entities where id=relation->>'parceiro_id') then raise exception 'invalid_unknown_partner'; end if;
    insert into public.pge_project_partners(project_id,partner_id,status,role) values(item->>'id',relation->>'parceiro_id',coalesce(relation->>'status','a-propor'),coalesce(relation->>'papel',''));
   end loop;
  end loop;
  delete from public.pge_project_entities where id not in(select value->>'id' from jsonb_array_elements(coalesce(p_content::jsonb->'itens','[]')));
 end if;
end; $$;
create or replace function public.pge_entities_trigger() returns trigger language plpgsql security definer set search_path='' as $$ begin perform public.pge_refresh_entities(new.path,new.content); return new; end; $$;
revoke all on function public.pge_refresh_entities(text,text),public.pge_entities_trigger() from public,anon,authenticated;
drop trigger if exists pge_normalize_live_entities on public.pge_live_documents;
create trigger pge_normalize_live_entities after insert or update of content on public.pge_live_documents for each row execute function public.pge_entities_trigger();
drop trigger if exists pge_normalize_document_entities on public.pge_documents;
create trigger pge_normalize_document_entities after insert or update of content on public.pge_documents for each row execute function public.pge_entities_trigger();
do $$ declare body text;begin
 select content into body from public.pge_documents where path='dados/rede-parceiros.json'; if body is not null then perform public.pge_refresh_entities('dados/rede-parceiros.json',body); end if;
 select content into body from public.pge_documents where path='dados/projetos.json'; if body is not null then perform public.pge_refresh_entities('dados/projetos.json',body); end if;
end $$;

-- No function relies on an anonymous client to enforce permissions.
revoke all on function public.pge_public_mode(),public.pge_public_revision(),public.pge_strip_archived(jsonb),public.pge_public_document(text),public.pge_public_catalog(),public.pge_publish_documents(jsonb),public.pge_review_videos(jsonb) from public,anon,authenticated;
grant execute on function public.pge_public_mode(),public.pge_public_revision(),public.pge_public_document(text),public.pge_public_catalog() to anon,authenticated;
grant execute on function public.pge_publish_documents(jsonb),public.pge_review_videos(jsonb) to authenticated;
-- Hand pending moderation decisions to the new direct publisher. Invalid/stale batches remain for review.
do $$ declare c record;items jsonb;uid text;begin
 for c in select * from public.pge_commands where action='review_video' and status in ('pending','processing') order by created_at loop
  if not exists(select 1 from public.pge_admins where user_id=c.user_id) then continue; end if;
  begin
   perform set_config('request.jwt.claim.sub',c.user_id::text,true);
   items=case when jsonb_typeof(c.payload->'items')='array' then c.payload->'items' else jsonb_build_array(c.payload) end;
   perform public.pge_review_videos(items);
   update public.pge_commands set status='applied',result='Decisão aplicada na ativação da publicação direta.' where id=c.id;
  exception when others then
   update public.pge_commands set status='conflict',result='A publicação direta foi ativada. Recarregue e confira novamente este lote.' where id=c.id;
  end;
 end loop;
 perform set_config('request.jwt.claim.sub','',true);
end $$;
notify pgrst,'reload schema';
commit;
