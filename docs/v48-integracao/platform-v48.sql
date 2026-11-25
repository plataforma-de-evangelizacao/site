begin;
create table if not exists public.pge_student_settings (
 id boolean primary key default true check(id),
 visible boolean not null default true,
 registration_open boolean not null default false,
 login_open boolean not null default false
);
insert into public.pge_student_settings(id) values(true) on conflict do nothing;

create table if not exists public.pge_students (
 id uuid primary key default gen_random_uuid(),
 enrollment_number uuid not null unique default gen_random_uuid(),
 name text not null check (length(btrim(name)) between 1 and 160),
 account_id uuid unique references auth.users(id) on delete set null
);
create table if not exists public.pge_student_courses (
 id uuid primary key default gen_random_uuid(),
 title text not null check(length(btrim(title)) between 1 and 160),
 program text not null check(length(btrim(program)) between 1 and 160),
 description text not null default '',
 published boolean not null default false,
 material text not null default '',
 exam text not null default ''
);
create table if not exists public.pge_student_enrollments (
 id uuid primary key default gen_random_uuid(),
 student_id uuid not null references public.pge_students(id) on delete cascade,
 course_id uuid not null references public.pge_student_courses(id) on delete cascade,
 grade numeric check(grade between 0 and 10),
 unique(student_id,course_id)
);
create table if not exists public.pge_student_requests (
 id uuid primary key default gen_random_uuid(),
 name text not null check(length(btrim(name)) between 1 and 160),
 course_id uuid not null references public.pge_student_courses(id) on delete cascade,
 received_at timestamptz not null default now()
);
create table if not exists public.pge_student_submissions (
 enrollment_id uuid primary key references public.pge_student_enrollments(id) on delete cascade,
 answer text not null check(length(btrim(answer)) between 1 and 20000),
 submitted_at timestamptz not null default now()
);

do $$
declare tbl text;
begin
 foreach tbl in array array['pge_student_settings','pge_students','pge_student_courses','pge_student_enrollments','pge_student_requests','pge_student_submissions'] loop
  execute format('alter table public.%I enable row level security',tbl);
  execute format('revoke all on public.%I from public, anon, authenticated',tbl);
  execute format('grant select, insert, update, delete on public.%I to authenticated',tbl);
  execute format('drop policy if exists student_admin on public.%I',tbl);
  execute format('create policy student_admin on public.%I for all to authenticated using (public.pge_can(''users:manage'')) with check (public.pge_can(''users:manage''))',tbl);
 end loop;
end $$;

create or replace function public.pge_student_catalog() returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object(
  'visible',s.visible,'registration_open',s.visible and s.registration_open,'login_open',s.visible and s.login_open,
  'courses',case when s.visible then coalesce((
   select jsonb_agg(jsonb_build_object('id',c.id,'title',c.title,'program',c.program,'description',c.description) order by c.title)
   from public.pge_student_courses c where c.published
  ),'[]'::jsonb) else '[]'::jsonb end)
 from public.pge_student_settings s where s.id;
$$;

create or replace function public.pge_student_request(p_name text,p_course uuid) returns void
language plpgsql security definer set search_path='' as $$
begin
 if not exists(select 1 from public.pge_student_settings where id and visible and registration_open)
 or not exists(select 1 from public.pge_student_courses where id=p_course and published) then
  raise exception 'Inscrições indisponíveis';
 end if;
 insert into public.pge_student_requests(name,course_id) values(btrim(p_name),p_course);
end $$;

create or replace function public.pge_student_portal() returns jsonb
language plpgsql stable security definer set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null or not exists(select 1 from public.pge_student_settings where id and visible and login_open) then
  raise exception 'Área do aluno indisponível';
 end if;
 select jsonb_build_object('name',s.name,'number',s.enrollment_number,'courses',coalesce((
  select jsonb_agg(jsonb_build_object('enrollment',e.id,'title',c.title,'program',c.program,
   'material',c.material,'exam',c.exam,'grade',e.grade,'submitted',sub.enrollment_id is not null) order by c.title)
  from public.pge_student_enrollments e join public.pge_student_courses c on c.id=e.course_id
  left join public.pge_student_submissions sub on sub.enrollment_id=e.id
  where e.student_id=s.id and c.published
 ),'[]'::jsonb)) into result from public.pge_students s where s.account_id=auth.uid();
 if result is null then raise exception 'Conta sem matrícula vinculada'; end if;
 return result;
end $$;

create or replace function public.pge_student_submit(p_enrollment uuid,p_answer text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not exists(select 1 from public.pge_student_settings where id and visible and login_open)
 or not exists(select 1 from public.pge_student_enrollments e
  join public.pge_students s on s.id=e.student_id join public.pge_student_courses c on c.id=e.course_id
  where e.id=p_enrollment and s.account_id=auth.uid() and c.published and btrim(c.exam)<>'') then
  raise exception 'Prova indisponível';
 end if;
 insert into public.pge_student_submissions(enrollment_id,answer) values(p_enrollment,btrim(p_answer));
end $$;

revoke all on function public.pge_student_catalog(),public.pge_student_request(text,uuid),
 public.pge_student_portal(),public.pge_student_submit(uuid,text) from public,anon,authenticated;
grant execute on function public.pge_student_catalog(),public.pge_student_request(text,uuid) to anon,authenticated;
grant execute on function public.pge_student_portal(),public.pge_student_submit(uuid,text) to authenticated;
commit;
