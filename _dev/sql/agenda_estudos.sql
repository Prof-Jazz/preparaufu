-- 25/11/2026 — Agenda: o aluno planeja os próprios horários de estudo (matéria, assunto do plano e duração)
create table if not exists public.agenda_estudos(
  id uuid primary key default gen_random_uuid(),
  email text not null default lower(coalesce(auth.jwt()->>'email','')),
  data date not null,
  ini time not null,
  dur int not null check (dur between 5 and 720),
  materia text not null,
  assunto text,
  item bigint,
  feito boolean not null default false,
  criado timestamptz not null default now()
);
create index if not exists agenda_estudos_email_data on public.agenda_estudos(email, data);
alter table public.agenda_estudos enable row level security;
drop policy if exists ag_est_le on public.agenda_estudos;
create policy ag_est_le on public.agenda_estudos for select to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')) or public.is_staff());
drop policy if exists ag_est_ins on public.agenda_estudos;
create policy ag_est_ins on public.agenda_estudos for insert to authenticated with check (email = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists ag_est_upd on public.agenda_estudos;
create policy ag_est_upd on public.agenda_estudos for update to authenticated using (email = lower(coalesce(auth.jwt()->>'email',''))) with check (email = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists ag_est_del on public.agenda_estudos;
create policy ag_est_del on public.agenda_estudos for delete to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')));
grant select, insert, update, delete on public.agenda_estudos to authenticated;
select 'ok' status;

-- 25/11 (15h45): origem do bloco (manual | crono) e equipe pode apagar
alter table public.agenda_estudos add column if not exists origem text not null default 'manual';
drop policy if exists ag_est_del on public.agenda_estudos;
create policy ag_est_del on public.agenda_estudos for delete to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')) or public.is_staff());
