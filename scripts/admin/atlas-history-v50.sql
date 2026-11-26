create table if not exists public.atlas_observations (
 id bigint generated always as identity primary key,
 payload jsonb not null check (jsonb_typeof(payload)='object' and payload ?& array['year','region','category','label','value','unit','source','url','qualifier','note'] and jsonb_typeof(payload->'value')='number' and (payload->>'year') ~ '^[0-9]{4}$'),
 fingerprint text generated always as (md5(payload::text)) stored unique,
 collected_at timestamptz not null default now()
);
create table if not exists public.atlas_sources (
 code text primary key, name text not null, url text not null, strategy text not null check (strategy in ('automatic','manual')), interval_days integer not null check (interval_days>0), enabled boolean not null default true
);
create table if not exists public.atlas_import_runs (
 id bigint generated always as identity primary key, source_code text not null references public.atlas_sources(code), started_at timestamptz not null default now(), finished_at timestamptz not null default now(), status text not null check(status in ('success','no_change','error')), inserted_count integer not null default 0 check(inserted_count>=0), message text not null default ''
);
alter table public.atlas_observations enable row level security;
alter table public.atlas_sources enable row level security;
alter table public.atlas_import_runs enable row level security;
revoke all on public.atlas_observations,public.atlas_sources,public.atlas_import_runs from anon,authenticated;
grant select on public.atlas_observations,public.atlas_sources,public.atlas_import_runs to anon,authenticated;
create policy atlas_read_observations on public.atlas_observations for select to anon,authenticated using (true);
create policy atlas_read_sources on public.atlas_sources for select to anon,authenticated using (true);
create policy atlas_read_runs on public.atlas_import_runs for select to anon,authenticated using (true);
insert into public.atlas_sources(code,name,url,strategy,interval_days) values
('world_bank','Banco Mundial','https://api.worldbank.org/v2','automatic',30),
('fao','FAO','https://www.fao.org/interactive/hunger-map/','manual',30),
('unicef','UNICEF','https://data.unicef.org/','manual',30),
('who','OMS','https://www.who.int/data','manual',30),
('unhcr','ACNUR','https://www.unhcr.org/refugee-statistics/','manual',7),
('unodc','UNODC','https://dataunodc.un.org/','manual',30),
('unesco','UNESCO','https://uis.unesco.org/','manual',30),
('un','ONU','https://unstats.un.org/sdgs/','manual',30),
('joshua','Joshua Project','https://joshuaproject.net/resources/datasets','manual',7)
on conflict(code) do nothing;
