-- 25/11/2026 — Minhas Aulas (videoaulas do YouTube por curso)
create table if not exists public.va_cursos(
  id uuid primary key default gen_random_uuid(),
  titulo text not null,
  descricao text,
  capa text,
  turmas text[] not null default array['assessoria','matematica','mentoria'],
  ordem int not null default 0,
  criado timestamptz not null default now()
);
create table if not exists public.va_aulas(
  id uuid primary key default gen_random_uuid(),
  curso uuid not null references public.va_cursos(id) on delete cascade,
  modulo text,
  titulo text not null,
  video text,
  descricao text,
  ordem int not null default 0,
  criado timestamptz not null default now()
);
create index if not exists va_aulas_curso on public.va_aulas(curso, ordem);
create table if not exists public.va_links(
  id uuid primary key default gen_random_uuid(),
  aula uuid not null references public.va_aulas(id) on delete cascade,
  nome text not null,
  url text not null,
  ordem int not null default 0
);
create index if not exists va_links_aula on public.va_links(aula, ordem);
create table if not exists public.va_feito(
  email text not null,
  aula uuid not null references public.va_aulas(id) on delete cascade,
  em timestamptz not null default now(),
  primary key(email, aula)
);

create or replace function public.va_ve(c uuid) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_staff() or exists(select 1 from public.va_cursos x where x.id=c and (
    public.minha_turma() = any(x.turmas) or (public.is_mentorado() and 'mentoria' = any(x.turmas))))
$$;
revoke execute on function public.va_ve(uuid) from anon, public;
grant execute on function public.va_ve(uuid) to authenticated;

alter table public.va_cursos enable row level security;
alter table public.va_aulas enable row level security;
alter table public.va_links enable row level security;
alter table public.va_feito enable row level security;

drop policy if exists va_cursos_le on public.va_cursos;
create policy va_cursos_le on public.va_cursos for select to authenticated using (public.va_ve(id));
drop policy if exists va_cursos_adm on public.va_cursos;
create policy va_cursos_adm on public.va_cursos for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists va_aulas_le on public.va_aulas;
create policy va_aulas_le on public.va_aulas for select to authenticated using (public.va_ve(curso));
drop policy if exists va_aulas_adm on public.va_aulas;
create policy va_aulas_adm on public.va_aulas for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists va_links_le on public.va_links;
create policy va_links_le on public.va_links for select to authenticated using (exists(select 1 from public.va_aulas a where a.id=aula and public.va_ve(a.curso)));
drop policy if exists va_links_adm on public.va_links;
create policy va_links_adm on public.va_links for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists va_feito_le on public.va_feito;
create policy va_feito_le on public.va_feito for select to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')) or public.is_staff());
drop policy if exists va_feito_ins on public.va_feito;
create policy va_feito_ins on public.va_feito for insert to authenticated with check (email = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists va_feito_del on public.va_feito;
create policy va_feito_del on public.va_feito for delete to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')));

grant select, insert, update, delete on public.va_cursos, public.va_aulas, public.va_links, public.va_feito to authenticated;

select policyname, cmd, qual from pg_policies where schemaname='storage' and tablename='objects' and (qual ilike '%capas%' or with_check ilike '%capas%');

-- 25/11: leitura do bucket capas pelo admin (upload/troca de capa)
create policy capas_admin_sel on storage.objects for select to authenticated using (bucket_id = 'capas' and public.is_admin());
