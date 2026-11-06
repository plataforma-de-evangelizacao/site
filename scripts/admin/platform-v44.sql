begin;

-- A versão 44 encerra a descoberta e a moderação do antigo acervo.
create or replace function public.pge_public_catalog()
returns jsonb language sql stable security definer set search_path=''
as $$ select jsonb_build_object('versao',3,'itens','[]'::jsonb,'validUntil',null); $$;

revoke execute on function public.pge_review_videos(jsonb) from public, anon, authenticated;
revoke insert, update on public.pge_videos, public.pge_video_decisions from service_role, authenticated, anon;

delete from public.pge_video_decisions;
delete from public.pge_videos;
delete from public.pge_commands
where action='review_video' or (action='run_sync' and payload->>'target'='video-discovery');

delete from public.pge_live_documents
where path like 'dados/biblioteca/%' or path like 'biblioteca-controle/%' or path='dados/fontes-legitimas.json';
delete from public.pge_documents
where path like 'dados/biblioteca/%' or path like 'biblioteca-controle/%' or path='dados/fontes-legitimas.json';
delete from public.pge_document_versions
where path like 'dados/biblioteca/%' or path like 'biblioteca-controle/%' or path='dados/fontes-legitimas.json';

-- Preserva artigos, músicas e outros registros do catálogo compartilhado.
update public.pge_live_documents
set content=jsonb_set(content::jsonb,'{itens}',coalesce(
    (select jsonb_agg(item order by ord)
     from jsonb_array_elements(content::jsonb->'itens') with ordinality as entries(item,ord)
     where coalesce(item->>'tipo','') not in ('filme','desenho','serie')),'[]'::jsonb))::text,
    sha=md5(content || ':v44'), updated_at=now()
where path='dados/catalogo-conteudos.json'
and jsonb_typeof(content::jsonb->'itens')='array'
and exists(select 1 from jsonb_array_elements(content::jsonb->'itens') as item
           where item->>'tipo' in ('filme','desenho','serie'));
update public.pge_documents
set content=jsonb_set(content::jsonb,'{itens}',coalesce(
    (select jsonb_agg(item order by ord)
     from jsonb_array_elements(content::jsonb->'itens') with ordinality as entries(item,ord)
     where coalesce(item->>'tipo','') not in ('filme','desenho','serie')),'[]'::jsonb))::text,
    sha=md5(content || ':v44'), updated_at=now()
where path='dados/catalogo-conteudos.json'
and jsonb_typeof(content::jsonb->'itens')='array'
and exists(select 1 from jsonb_array_elements(content::jsonb->'itens') as item
           where item->>'tipo' in ('filme','desenho','serie'));

delete from public.pge_live_paths
where path like 'dados/biblioteca/%' or path='dados/fontes-legitimas.json';

commit;
