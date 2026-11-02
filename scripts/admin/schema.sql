-- Execute uma vez no SQL Editor do seu projeto Supabase (Free).
-- Não execute em banco alheio. Nenhuma senha ou chave deve entrar neste arquivo.
begin;
create table if not exists public.pge_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table if not exists public.pge_videos (
  id text primary key check (id ~ '^[A-Za-z0-9_-]{11}$'),
  record jsonb not null check (jsonb_typeof(record)='object'),
  sha text not null,
  expires_at timestamptz not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.pge_documents (
  path text primary key,
  content text not null check (octet_length(content)<=1048576),
  sha text not null,
  updated_at timestamptz not null default now()
);
create table if not exists public.pge_commands (
  id uuid primary key,
  user_id uuid not null references auth.users(id),
  action text not null check (action in ('review_video','save_json','run_sync')),
  payload jsonb not null check (jsonb_typeof(payload)='object' and octet_length(payload::text)<=1100000),
  status text not null default 'pending' check(status in ('pending','processing','applied','conflict','failed')),
  result text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists pge_commands_pending on public.pge_commands(status,created_at);
create index if not exists pge_videos_expiry on public.pge_videos(expires_at);
create unique index if not exists pge_video_request_open on public.pge_commands(user_id,(payload->>'id')) where action='review_video' and status in ('pending','processing');
alter table public.pge_admins enable row level security;
alter table public.pge_videos enable row level security;
alter table public.pge_documents enable row level security;
alter table public.pge_commands enable row level security;
-- Revoga permissões implícitas; somente leitura autorizada e inserção na fila.
revoke all on public.pge_admins,public.pge_videos,public.pge_documents,public.pge_commands from anon,authenticated;
grant select on public.pge_admins,public.pge_videos,public.pge_documents,public.pge_commands to authenticated;
grant insert(id,user_id,action,payload) on public.pge_commands to authenticated;
grant all on public.pge_admins,public.pge_videos,public.pge_documents,public.pge_commands to service_role;
drop policy if exists pge_admin_self on public.pge_admins;
create policy pge_admin_self on public.pge_admins for select to authenticated using(user_id=(select auth.uid()));
drop policy if exists pge_videos_read on public.pge_videos;
create policy pge_videos_read on public.pge_videos for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_documents_read on public.pge_documents;
create policy pge_documents_read on public.pge_documents for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_commands_read on public.pge_commands;
create policy pge_commands_read on public.pge_commands for select to authenticated using(user_id=(select auth.uid()) and exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_commands_insert on public.pge_commands;
create policy pge_commands_insert on public.pge_commands for insert to authenticated with check(user_id=(select auth.uid()) and status='pending' and result is null and exists(select 1 from public.pge_admins where user_id=(select auth.uid())));

alter table public.pge_commands drop constraint if exists pge_commands_action_check;
alter table public.pge_commands add constraint pge_commands_action_check check(action in ('review_video','save_json','run_sync'));
create unique index if not exists pge_sync_request_open on public.pge_commands(user_id,(payload->>'target')) where action='run_sync' and status in ('pending','processing');
commit;
-- DEPOIS de criar seu usuário em Authentication → Users, autorize o UUID real:
-- insert into public.pge_admins(user_id) values ('UUID_REAL_DO_SEU_USUARIO');
