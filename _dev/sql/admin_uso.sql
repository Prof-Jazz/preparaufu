-- 27/11/2026 — uso do Supabase para o painel do administrador (Comportamento da turma)
create or replace function public.admin_uso() returns jsonb language sql stable security definer set search_path=public as $f$
 select case when not public.is_admin() then null else jsonb_build_object(
 'db', pg_database_size(current_database()),
 'arquivos', (select coalesce(sum((metadata->>'size')::bigint),0) from storage.objects),
 'buckets', (select jsonb_object_agg(bucket_id, s) from (select bucket_id, sum((metadata->>'size')::bigint) s from storage.objects group by bucket_id) x),
 'usuarios', (select count(*) from auth.users),
 'fotos_caderno', (select count(*) from storage.objects where bucket_id='caderno'),
 'fotos_vencidas', (select count(*) from public.caderno_erros where img like '%@%' and criado < now()-interval '60 days')) end $f$;
grant execute on function public.admin_uso() to authenticated;
