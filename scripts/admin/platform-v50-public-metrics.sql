begin;
create or replace function public.pge_student_public_metrics() returns jsonb
language sql stable security definer set search_path='' as $$
 select jsonb_build_object(
  'students',(select count(distinct e.student_id) from public.pge_student_enrollments e join public.pge_student_courses c on c.id=e.course_id where c.published),
  'enrollments',(select count(*) from public.pge_student_enrollments e join public.pge_student_courses c on c.id=e.course_id where c.published),
  'courses',(select count(*) from public.pge_student_courses where published)
 );
$$;
revoke all on function public.pge_student_public_metrics() from public,anon,authenticated;
grant execute on function public.pge_student_public_metrics() to anon,authenticated;
commit;
