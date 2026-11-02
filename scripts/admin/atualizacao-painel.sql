-- Execute uma vez no SQL Editor do mesmo projeto Supabase já usado pelo painel.
-- Não altera contas, dados existentes nem políticas RLS.
begin;
alter table public.pge_commands drop constraint if exists pge_commands_action_check;
alter table public.pge_commands add constraint pge_commands_action_check check(action in ('review_video','save_json','run_sync'));
create unique index if not exists pge_sync_request_open on public.pge_commands(user_id,(payload->>'target')) where action='run_sync' and status in ('pending','processing');
commit;
