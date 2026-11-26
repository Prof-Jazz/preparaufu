-- Turma do usuário logado: 'assessoria' ou 'matematica'
create or replace function public.minha_turma() returns text
language sql stable security definer set search_path to 'public' as $$
  select case when a.assessoria then 'assessoria' else 'matematica' end
  from public.allowed_emails a where a.email = lower(coalesce(auth.jwt()->>'email',''))
$$;

create or replace function public.ve_turmas(t text[]) returns boolean
language sql stable security definer set search_path to 'public' as $$
  select public.is_admin() or public.minha_turma() = any(t)
$$;

create table if not exists public.pastas(
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  descricao text,
  turmas text[] not null default '{assessoria,matematica}',
  ordem int not null default 0,
  criado_em timestamptz not null default now()
);

create table if not exists public.aulas(
  id uuid primary key default gen_random_uuid(),
  data date not null,
  ini time,
  fim time,
  tipo text not null default 'aula',          -- aula | revisao | simulado | prova | outro
  titulo text,
  professor text,
  link text,
  descricao text,
  turmas text[] not null default '{assessoria,matematica}',
  criado_em timestamptz not null default now(),
  atualizado_em timestamptz not null default now()
);

create table if not exists public.arquivos(
  id uuid primary key default gen_random_uuid(),
  pasta uuid references public.pastas(id) on delete cascade,
  aula uuid references public.aulas(id) on delete cascade,
  nome text not null,
  path text not null unique,
  tipo text,
  tamanho bigint,
  criado_em timestamptz not null default now(),
  constraint arquivos_um_dono check ((pasta is null) <> (aula is null))
);

create or replace function public.ve_arquivo(p text) returns boolean
language sql stable security definer set search_path to 'public' as $$
  select public.is_admin() or exists(
    select 1 from public.arquivos f
    left join public.pastas pa on pa.id = f.pasta
    left join public.aulas au on au.id = f.aula
    where f.path = p and public.minha_turma() = any(coalesce(pa.turmas, au.turmas)))
$$;

alter table public.pastas enable row level security;
alter table public.aulas enable row level security;
alter table public.arquivos enable row level security;

drop policy if exists pastas_ler on public.pastas;
drop policy if exists pastas_admin on public.pastas;
drop policy if exists aulas_ler on public.aulas;
drop policy if exists aulas_admin on public.aulas;
drop policy if exists arquivos_ler on public.arquivos;
drop policy if exists arquivos_admin on public.arquivos;

create policy pastas_ler on public.pastas for select to authenticated using (public.ve_turmas(turmas));
create policy pastas_admin on public.pastas for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy aulas_ler on public.aulas for select to authenticated using (public.ve_turmas(turmas));
create policy aulas_admin on public.aulas for all to authenticated using (public.is_admin()) with check (public.is_admin());
create policy arquivos_ler on public.arquivos for select to authenticated using (public.ve_arquivo(path));
create policy arquivos_admin on public.arquivos for all to authenticated using (public.is_admin()) with check (public.is_admin());

grant select, insert, update, delete on public.pastas, public.aulas, public.arquivos to authenticated;

-- bucket privado dos materiais (até 50 MB por arquivo)
insert into storage.buckets (id, name, public, file_size_limit)
values ('materiais','materiais', false, 52428800)
on conflict (id) do update set public = false, file_size_limit = 52428800;

drop policy if exists materiais_ler on storage.objects;
drop policy if exists materiais_admin_ins on storage.objects;
drop policy if exists materiais_admin_upd on storage.objects;
drop policy if exists materiais_admin_del on storage.objects;
create policy materiais_ler on storage.objects for select to authenticated
  using (bucket_id = 'materiais' and public.ve_arquivo(name));
create policy materiais_admin_ins on storage.objects for insert to authenticated
  with check (bucket_id = 'materiais' and public.is_admin());
create policy materiais_admin_upd on storage.objects for update to authenticated
  using (bucket_id = 'materiais' and public.is_admin());
create policy materiais_admin_del on storage.objects for delete to authenticated
  using (bucket_id = 'materiais' and public.is_admin());

-- agenda pré-marcada (calendário PREPARA UFU 2026-2027), só se ainda estiver vazia
insert into public.aulas (data, ini, fim, tipo)
select d::date, '19:00', '20:30', 'aula'
from generate_series('2026-12-07'::date, '2027-03-29'::date, interval '1 day') d
where extract(isodow from d) in (1,4)
  and not (d >= '2026-12-19' and d <= '2027-01-03')
  and d::date <> '2027-02-08'
  and not exists (select 1 from public.aulas);

insert into public.aulas (data, ini, fim, tipo, titulo)
select v.data::date, v.ini::time, v.fim::time, v.tipo, v.titulo
from (values
  ('2027-03-30','19:00','20:30','revisao','Revisão final'),
  ('2027-03-31','19:00','20:30','revisao','Revisão final'),
  ('2027-04-01','19:00','20:30','revisao','Revisão final'),
  ('2026-12-18',null,null,'simulado','Simulado PREPARA UFU 1'),
  ('2027-01-23',null,null,'simulado','Simulado PREPARA UFU 2'),
  ('2027-02-27',null,null,'simulado','Simulado PREPARA UFU 3'),
  ('2027-03-27',null,null,'simulado','Simulado PREPARA UFU 4'),
  ('2027-04-04','10:00',null,'prova','Prova UFU 2027-2 (1ª fase)')
) as v(data,ini,fim,tipo,titulo)
where not exists (select 1 from public.aulas where tipo <> 'aula');

select tipo, count(*) from public.aulas group by tipo order by tipo;
