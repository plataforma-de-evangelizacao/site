-- 2026110303: independent editorial display text. Provider records remain intact.
begin;
create or replace function public.pge_public_mode() returns jsonb language sql stable security definer set search_path='' as $$ select jsonb_build_object('version',2,'direct',true,'displayEditing',true); $$;
alter table public.pge_video_decisions add column if not exists display_title text check(length(display_title)<=500);
alter table public.pge_video_decisions add column if not exists display_description text check(length(display_description)<=5000);
create or replace function public.pge_public_catalog() returns jsonb language sql stable security definer set search_path='' as $$
 with combined as (
 select v.id,v.expires_at,(v.record||jsonb_build_object('id',v.id,'url','https://www.youtube.com/watch?v='||v.id))||
 case when d.id is null then '{}'::jsonb else jsonb_build_object('aprovacao',d.decision,'categoria',coalesce(d.category,v.record->>'categoria'))||case when d.portuguese_confirmed then jsonb_build_object('idioma','pt-BR','idiomaVerificado',true) else '{}'::jsonb end end || jsonb_build_object('tituloOriginal',coalesce(v.record->>'tituloOriginal',v.record->>'titulo'),'descricaoOriginal',coalesce(v.record->>'descricaoOriginal',v.record->>'descricao'),'titulo',coalesce(d.display_title,v.record->>'tituloOriginal',v.record->>'titulo'),'descricao',coalesce(d.display_description,v.record->>'descricaoOriginal',v.record->>'descricao')) as record
 from public.pge_videos v left join public.pge_video_decisions d on d.id=v.id
 where v.expires_at>now()
 ), eligible as (
 select * from combined where record->>'aprovacao'='approved' and record->>'disponibilidade' in ('available','embed_restricted') and record->>'idiomaVerificado'='true' and record->>'idioma' like 'pt%' and record->>'categoria' in ('desenho','filme','serie') and length(coalesce(record->>'titulo',''))>0
 )
 select jsonb_build_object('versao',3,'itens',coalesce(jsonb_agg(record order by record->>'titulo'),'[]'::jsonb),'validUntil',min(expires_at)) from eligible;
$$;

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
   if op in ('category','metadata') then
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
  if item ? 'tituloExibicao' then
   if jsonb_typeof(item->'tituloExibicao') not in ('string','null') or length(coalesce(item->>'tituloExibicao',''))>500 then raise exception 'invalid_display_title'; end if;
   update public.pge_video_decisions set display_title=nullif(btrim(item->>'tituloExibicao'),'') where id=vid;
  end if;
  if item ? 'descricaoExibicao' then
   if jsonb_typeof(item->'descricaoExibicao') not in ('string','null') or length(coalesce(item->>'descricaoExibicao',''))>5000 then raise exception 'invalid_display_description'; end if;
   update public.pge_video_decisions set display_description=nullif(btrim(item->>'descricaoExibicao'),'') where id=vid;
  end if;
  audit=audit||jsonb_build_array(jsonb_build_object('id',vid,'decision',decision,'operation',op));
 end loop;
 insert into public.pge_commands(id,user_id,action,payload,status,result) values(pg_catalog.gen_random_uuid(),uid,'review_video',jsonb_build_object('items',audit,'count',jsonb_array_length(audit)),'applied','Decisão publicada imediatamente.');
 return jsonb_build_object('published',jsonb_array_length(audit));
end; $$;

notify pgrst, 'reload schema';
commit;
