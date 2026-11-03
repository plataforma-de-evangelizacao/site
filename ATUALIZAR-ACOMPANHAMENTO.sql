-- Depois de ATIVAR-PUBLICACAO-DIRETA.sql, no mesmo Supabase.
-- Guarda o título, não o conteúdo bruto da API, para localizar bloqueios antigos.
begin;
alter table public.pge_video_decisions add column if not exists last_title text;
alter table public.pge_video_decisions add column if not exists last_title_expires_at timestamptz;
create or replace function public.pge_keep_decision_title() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
begin
 new.last_title:=coalesce((select record->>'titulo' from public.pge_videos where id=new.id and expires_at>now()),new.last_title);
 new.last_title_expires_at:=coalesce((select expires_at from public.pge_videos where id=new.id and expires_at>now()),new.last_title_expires_at);
 return new;
end; $$;
revoke all on function public.pge_keep_decision_title() from public,anon,authenticated;
drop trigger if exists pge_decision_title on public.pge_video_decisions;
create trigger pge_decision_title before insert or update on public.pge_video_decisions for each row execute function public.pge_keep_decision_title();
update public.pge_video_decisions d set last_title=v.record->>'titulo',last_title_expires_at=v.expires_at from public.pge_videos v where d.id=v.id and d.last_title is null;
commit;
