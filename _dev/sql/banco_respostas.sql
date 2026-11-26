-- 26/11/2026 — Banco de Questões: o aluno responde direto (A, B, C, D) e conta nas estatísticas
create table if not exists public.banco_resp(
  id uuid primary key default gen_random_uuid(),
  email text not null default lower(coalesce(auth.jwt()->>'email','')),
  questao text not null,
  materia text,
  topico text,
  subtopico text,
  escolha text not null,
  correta boolean not null,
  criado timestamptz not null default now()
);
create index if not exists banco_resp_email on public.banco_resp(email, criado);
alter table public.banco_resp enable row level security;
drop policy if exists br_le on public.banco_resp;
create policy br_le on public.banco_resp for select to authenticated using (email = public.eu_email() or public.staff_ve(email));
drop policy if exists br_ins on public.banco_resp;
create policy br_ins on public.banco_resp for insert to authenticated with check (public.is_admin() or (public.is_allowed() and email = lower(coalesce(auth.jwt()->>'email',''))));
drop policy if exists br_del on public.banco_resp;
create policy br_del on public.banco_resp for delete to authenticated using (public.is_admin() or email = lower(coalesce(auth.jwt()->>'email','')));
grant select, insert, delete on public.banco_resp to authenticated;
-- caderno: questão vinda do banco guarda a referência
alter table public.caderno_erros add column if not exists questao text;
select 'ok' status;
