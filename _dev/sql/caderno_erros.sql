-- 26/11/2026 — Caderno de Erros: cada questão errada com matéria, assunto, motivo e foto opcional
create table if not exists public.caderno_erros(
  id uuid primary key default gen_random_uuid(),
  email text not null default lower(coalesce(auth.jwt()->>'email','')),
  sessao bigint references public.sessoes(id) on delete set null,
  materia text not null,
  assunto text,
  item bigint,
  motivo text check (motivo is null or motivo in ('lacuna','interpretacao','distracao','tempo')),
  fonte text,
  obs text,
  img text,
  revisada boolean not null default false,
  revisada_em timestamptz,
  criado timestamptz not null default now()
);
create index if not exists caderno_erros_email on public.caderno_erros(email, criado);
alter table public.caderno_erros enable row level security;
drop policy if exists cad_le on public.caderno_erros;
create policy cad_le on public.caderno_erros for select to authenticated using (email = public.eu_email() or public.staff_ve(email));
drop policy if exists cad_ins on public.caderno_erros;
create policy cad_ins on public.caderno_erros for insert to authenticated with check (public.is_admin() or (public.is_allowed() and email = lower(coalesce(auth.jwt()->>'email',''))));
drop policy if exists cad_upd on public.caderno_erros;
create policy cad_upd on public.caderno_erros for update to authenticated using (public.is_admin() or email = lower(coalesce(auth.jwt()->>'email',''))) with check (public.is_admin() or email = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists cad_del on public.caderno_erros;
create policy cad_del on public.caderno_erros for delete to authenticated using (public.is_admin() or email = lower(coalesce(auth.jwt()->>'email','')));
grant select, insert, update, delete on public.caderno_erros to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values ('caderno','caderno',false,6291456,array['image/jpeg','image/png','image/webp'])
  on conflict (id) do update set public=false,file_size_limit=6291456,allowed_mime_types=array['image/jpeg','image/png','image/webp'];
drop policy if exists caderno_sel on storage.objects;
create policy caderno_sel on storage.objects for select to authenticated using (bucket_id='caderno' and ((storage.foldername(name))[1] = lower(coalesce(auth.jwt()->>'email','')) or public.staff_ve((storage.foldername(name))[1])));
drop policy if exists caderno_ins on storage.objects;
create policy caderno_ins on storage.objects for insert to authenticated with check (bucket_id='caderno' and (storage.foldername(name))[1] = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists caderno_del on storage.objects;
create policy caderno_del on storage.objects for delete to authenticated using (bucket_id='caderno' and ((storage.foldername(name))[1] = lower(coalesce(auth.jwt()->>'email','')) or public.is_admin()));
select 'ok' status;
-- admin pode subir foto para o aluno exemplo
drop policy if exists caderno_ins on storage.objects;
create policy caderno_ins on storage.objects for insert to authenticated with check (bucket_id='caderno' and ((storage.foldername(name))[1] = lower(coalesce(auth.jwt()->>'email','')) or public.is_admin()));
