-- Assessores: veem planejamento, plano, perfil, dashboard e mexem no cronograma dos alunos.
-- Não cadastram alunos, não veem mensagens nem denúncias.
create table if not exists public.assessores(
  email text primary key,
  nome text not null,
  criado timestamptz not null default now()
);
alter table public.assessores enable row level security;

create or replace function public.is_assessor() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.assessores where email = lower(coalesce(auth.jwt()->>'email','')))
$$;
create or replace function public.is_staff() returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or public.is_assessor()
$$;
create or replace function public.meu_papel() returns text language sql stable security definer set search_path=public as $$
  select case when public.is_admin() then 'admin' when public.is_assessor() then 'assessor'
              when exists(select 1 from public.allowed_emails where email=lower(coalesce(auth.jwt()->>'email',''))) then 'aluno' end
$$;

drop policy if exists assessores_admin on public.assessores;
create policy assessores_admin on public.assessores for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists assessores_staff_ler on public.assessores;
create policy assessores_staff_ler on public.assessores for select using (public.is_staff());

-- acesso e login
create or replace function public.email_permitido(e text) returns boolean language sql stable security definer set search_path=public as $$
  select lower(trim(e)) = 'jesrrael.santos@gmail.com'
      or exists (select 1 from public.allowed_emails where email = lower(trim(e)))
      or exists (select 1 from public.assessores where email = lower(trim(e)))
$$;
create or replace function public.is_allowed() returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or public.is_assessor()
      or exists (select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')))
$$;
create or replace function public.is_assessoria() returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or public.is_assessor()
      or exists (select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')) and assessoria)
$$;
create or replace function public.ve_turmas(t text[]) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_staff() or public.minha_turma() = any(t)
$$;
create or replace function public.ve_arquivo(p text) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_staff() or exists(
    select 1 from public.arquivos f left join public.pastas pa on pa.id = f.pasta left join public.aulas au on au.id = f.aula
    where f.path = p and public.minha_turma() = any(coalesce(pa.turmas, au.turmas)))
$$;
create or replace function public.nome_curto(e text) returns text language sql stable security definer set search_path=public as $$
  with n as (select trim(coalesce((select nome from allowed_emails where email=e),(select nome from assessores where email=e),'')) v)
  select case when e='jesrrael.santos@gmail.com' then 'Prof. Jazz' else
    coalesce(nullif(trim(split_part((select v from n),' ',1) || ' ' ||
      coalesce(left(nullif(split_part((select v from n),' ',2),''),1)||'.','')),''), split_part(e,'@',1)) end
$$;

-- lista de alunos: admin e assessores
create or replace function public.admin_lista() returns table(email text, nome text, created_at timestamptz, cadastrado boolean, ultimo_acesso timestamptz, assessoria boolean, checkup_em timestamptz)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_staff() then raise exception 'sem permissao'; end if;
  return query select a.email, a.nome, a.created_at, (u.id is not null), u.last_sign_in_at, a.assessoria, c.atualizado_em
    from public.allowed_emails a left join auth.users u on lower(u.email) = a.email left join public.checkup c on c.email = a.email
    order by a.created_at desc;
end $$;

-- assessores (só o admin)
create or replace function public.admin_assessores() returns table(email text, nome text, criado timestamptz, cadastrado boolean, ultimo_acesso timestamptz)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'sem permissao'; end if;
  return query select s.email, s.nome, s.criado, (u.id is not null), u.last_sign_in_at
    from public.assessores s left join auth.users u on lower(u.email)=s.email order by s.nome;
end $$;

-- políticas: leitura e cronograma para a equipe
drop policy if exists checkup_sel on public.checkup;
create policy checkup_sel on public.checkup for select using (email = lower(auth.jwt()->>'email') or public.is_staff());
drop policy if exists crono_sel on public.cronograma;
create policy crono_sel on public.cronograma for select using (email = lower(auth.jwt()->>'email') or public.is_staff());
drop policy if exists crono_upd on public.cronograma;
create policy crono_upd on public.cronograma for update using ((email = lower(auth.jwt()->>'email') and public.is_assessoria()) or public.is_staff()) with check (email = lower(auth.jwt()->>'email') or public.is_staff());
drop policy if exists crono_ins on public.cronograma;
create policy crono_ins on public.cronograma for insert with check ((email = lower(auth.jwt()->>'email') and public.is_assessoria()) or public.is_staff());
drop policy if exists sessoes_ler on public.sessoes;
create policy sessoes_ler on public.sessoes for select using (public.is_staff() or email = lower(coalesce(auth.jwt()->>'email','')));
drop policy if exists plano_feito_ler on public.plano_feito;
create policy plano_feito_ler on public.plano_feito for select using (public.is_staff() or email = lower(coalesce(auth.jwt()->>'email','')));

revoke execute on function public.is_assessor(), public.is_staff(), public.meu_papel(), public.admin_assessores() from anon, public;
grant execute on function public.is_assessor(), public.is_staff(), public.meu_papel(), public.admin_assessores(), public.admin_lista() to authenticated;
select 'ok' status;
