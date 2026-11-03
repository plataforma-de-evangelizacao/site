-- Backend health and version history. No client writes or generic SQL executor.
begin;
create table if not exists public.pge_backend_migrations (
 version text primary key check(version ~ '^[0-9]{10,16}$'),
 checksum text not null check(checksum ~ '^[0-9a-f]{64}$'),
 applied_at timestamptz not null default now()
);
create table if not exists public.pge_backend_status (
 id boolean primary key default true check(id),
 installed_release text,
 target_release text,
 status text not null default 'pending' check(status in ('pending','processing','ready','failed')),
 stage text,
 progress integer not null default 0 check(progress between 0 and 100),
 message text,
 run_url text,
 details jsonb not null default '{}'::jsonb,
 updated_at timestamptz not null default now()
);
alter table public.pge_backend_migrations enable row level security;
alter table public.pge_backend_status enable row level security;
revoke all on public.pge_backend_migrations,public.pge_backend_status from public,anon,authenticated;
grant select on public.pge_backend_migrations,public.pge_backend_status to authenticated;
grant all on public.pge_backend_migrations,public.pge_backend_status to service_role;
drop policy if exists pge_backend_versions_admin on public.pge_backend_migrations;
create policy pge_backend_versions_admin on public.pge_backend_migrations for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
drop policy if exists pge_backend_status_admin on public.pge_backend_status;
create policy pge_backend_status_admin on public.pge_backend_status for select to authenticated using(exists(select 1 from public.pge_admins where user_id=(select auth.uid())));
create or replace function public.pge_backend_health() returns jsonb
language plpgsql security definer set search_path='' as $$
declare state jsonb;versions jsonb;
begin
 if auth.uid() is null or not exists(select 1 from public.pge_admins where user_id=auth.uid()) then raise exception 'administrator_required'; end if;
 select to_jsonb(s)-'id' into state from public.pge_backend_status s where s.id;
 select coalesce(jsonb_agg(jsonb_build_object('version',m.version,'applied_at',m.applied_at) order by m.version),'[]'::jsonb) into versions from public.pge_backend_migrations m;
 return jsonb_build_object('state',state,'migrations',versions);
end; $$;
revoke all on function public.pge_backend_health() from public,anon,authenticated;
grant execute on function public.pge_backend_health() to authenticated;
notify pgrst,'reload schema';
commit;
