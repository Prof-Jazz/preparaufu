-- 25/11/2026 — recursos da Assessoria liberados por aluno do Curso de Matemática
alter table public.allowed_emails add column if not exists recursos text[] not null default '{}';
create or replace function public.meus_recursos() returns text[] language sql stable security definer set search_path=public as $$
  select case
    when public.is_admin() or public.is_assessor() or public.is_mentorado() then array['plano','crono','dash']
    when exists(select 1 from public.allowed_emails where email=lower(coalesce(auth.jwt()->>'email','')) and assessoria) then array['plano','crono','dash']
    else coalesce((select recursos from public.allowed_emails where email=lower(coalesce(auth.jwt()->>'email',''))),'{}') end
$$;
create or replace function public.tem_recurso(r text) returns boolean language sql stable security definer set search_path=public as $$
  select r = any(public.meus_recursos())
$$;
revoke execute on function public.meus_recursos(), public.tem_recurso(text) from anon, public;
grant execute on function public.meus_recursos(), public.tem_recurso(text) to authenticated;
drop policy if exists checkup_ins on public.checkup;
create policy checkup_ins on public.checkup for insert to authenticated with check (((email = eu_email()) and (is_assessoria() or is_mentorado() or tem_recurso('crono'))) or is_admin());
drop policy if exists checkup_upd on public.checkup;
create policy checkup_upd on public.checkup for update to authenticated using (((email = eu_email()) and (is_assessoria() or is_mentorado() or tem_recurso('crono'))) or is_admin()) with check ((email = eu_email()) or is_admin());
drop policy if exists crono_ins on public.cronograma;
create policy crono_ins on public.cronograma for insert to authenticated with check (((email = eu_email()) and (is_assessoria() or is_mentorado() or tem_recurso('crono'))) or staff_ve(email));
drop policy if exists crono_upd on public.cronograma;
create policy crono_upd on public.cronograma for update to authenticated using (((email = eu_email()) and (is_assessoria() or is_mentorado() or tem_recurso('crono'))) or staff_ve(email)) with check ((email = eu_email()) or staff_ve(email));
select 'ok' status;

-- 25/11 (18h20): reagendar plano de estudos
-- tabelas plano_remarcado(email,item,semana) e plano_reag_hist(id,email,snapshot) — criadas pelo editor, com RLS eu_email() or staff_ve(email)

-- 25/11 (18h55): plano_feito também para quem tem o Plano liberado
drop policy if exists plano_feito_ins on public.plano_feito;
create policy plano_feito_ins on public.plano_feito for insert to authenticated with check (is_admin() or ((is_assessoria() or tem_recurso('plano')) and email = lower(coalesce(auth.jwt()->>'email',''))));
