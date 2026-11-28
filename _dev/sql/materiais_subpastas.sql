-- 28/11/2026 — Materiais: subpastas; liberação por documento (turmas); mentoria pode usar documentos das turmas sem novo upload
alter table public.pastas add column if not exists parent uuid references public.pastas(id) on delete cascade;
alter table public.arquivos add column if not exists turmas text[];
update public.arquivos f set turmas = p.turmas from public.pastas p where f.pasta = p.id and f.turmas is null;
alter table public.m_pastas add column if not exists parent uuid references public.m_pastas(id) on delete cascade;
alter table public.m_arquivos add column if not exists origem text not null default 'mentoria' check (origem in ('mentoria','materiais'));

-- pasta das turmas aparece só se tiver (nela ou nas subpastas) algum documento liberado para a turma do aluno
create or replace function public.ve_pasta(p uuid) returns boolean language sql stable security definer set search_path to 'public' as $f$
  select public.is_staff() or exists(
    with recursive arv(id) as (select p union all select c.id from public.pastas c join arv on c.parent = arv.id)
    select 1 from public.arquivos f join arv on f.pasta = arv.id where public.minha_turma() = any(coalesce(f.turmas,'{}')))
$f$;
drop policy if exists pastas_ler on public.pastas;
create policy pastas_ler on public.pastas for select to authenticated using (public.ve_pasta(id));

-- documento: vale a turma do próprio documento (ou da aula, para anexos da agenda); mentorado vê se o documento foi puxado para uma pasta da mentoria dele
create or replace function public.ve_arquivo(p text) returns boolean language sql stable security definer set search_path to 'public' as $f$
  select public.is_staff()
   or exists(select 1 from public.arquivos f left join public.aulas au on au.id = f.aula
             where f.path = p and public.minha_turma() = any(coalesce(f.turmas, au.turmas, '{}')))
   or exists(select 1 from public.m_arquivos ma where ma.path = p and ma.origem = 'materiais' and public.m_ve_pasta(ma.pasta))
$f$;
