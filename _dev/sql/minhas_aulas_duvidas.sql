-- 25/11/2026 — Minhas Aulas: avaliação (estrelas) e dúvidas por aula
create table if not exists public.va_aval(
  email text not null,
  aula uuid not null references public.va_aulas(id) on delete cascade,
  nota int not null check (nota between 1 and 5),
  em timestamptz not null default now(),
  primary key(email, aula)
);
create table if not exists public.va_duvidas(
  id uuid primary key default gen_random_uuid(),
  email text not null default lower(coalesce(auth.jwt()->>'email','')),
  aula uuid not null references public.va_aulas(id) on delete cascade,
  texto text not null check (length(texto) between 1 and 2000),
  criada timestamptz not null default now(),
  resposta text,
  respondida timestamptz,
  lida_prof boolean not null default false,
  vista_aluno boolean not null default true
);
create index if not exists va_duvidas_aula on public.va_duvidas(aula, criada);
create index if not exists va_duvidas_email on public.va_duvidas(email);

alter table public.va_aval enable row level security;
alter table public.va_duvidas enable row level security;

drop policy if exists va_aval_le on public.va_aval;
create policy va_aval_le on public.va_aval for select to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')) or public.is_staff());
drop policy if exists va_aval_ins on public.va_aval;
create policy va_aval_ins on public.va_aval for insert to authenticated with check (email = lower(coalesce(auth.jwt()->>'email','')) and exists(select 1 from public.va_aulas a where a.id=aula and public.va_ve(a.curso)));
drop policy if exists va_aval_upd on public.va_aval;
create policy va_aval_upd on public.va_aval for update to authenticated using (email = lower(coalesce(auth.jwt()->>'email',''))) with check (email = lower(coalesce(auth.jwt()->>'email','')));

drop policy if exists va_duv_le on public.va_duvidas;
create policy va_duv_le on public.va_duvidas for select to authenticated using (email = lower(coalesce(auth.jwt()->>'email','')) or public.is_admin());
drop policy if exists va_duv_ins on public.va_duvidas;
create policy va_duv_ins on public.va_duvidas for insert to authenticated with check (email = lower(coalesce(auth.jwt()->>'email','')) and resposta is null and exists(select 1 from public.va_aulas a where a.id=aula and public.va_ve(a.curso)));
drop policy if exists va_duv_upd on public.va_duvidas;
create policy va_duv_upd on public.va_duvidas for update to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists va_duv_del on public.va_duvidas;
create policy va_duv_del on public.va_duvidas for delete to authenticated using (public.is_admin() or (email = lower(coalesce(auth.jwt()->>'email','')) and resposta is null));

grant select, insert, update, delete on public.va_aval, public.va_duvidas to authenticated;

-- aluno marca como vistas as respostas de uma aula
create or replace function public.va_vi_respostas(p_aula uuid) returns void language sql security definer set search_path=public as $$
  update public.va_duvidas set vista_aluno=true where email=lower(coalesce(auth.jwt()->>'email','')) and aula=p_aula and not vista_aluno
$$;
-- alertas: professor = dúvidas novas; aluno = respostas novas
create or replace function public.va_alertas() returns jsonb language sql stable security definer set search_path=public as $$
  select case when public.is_admin() then
    jsonb_build_object('papel','prof','n',(select count(*) from public.va_duvidas where not lida_prof),
      'ultima',(select jsonb_build_object('aula',d.aula,'titulo',a.titulo,'nome',coalesce(nullif(public.nome_curto(d.email),''),d.email))
                from public.va_duvidas d join public.va_aulas a on a.id=d.aula where not d.lida_prof order by d.criada desc limit 1))
  else
    jsonb_build_object('papel','aluno','n',(select count(*) from public.va_duvidas where email=lower(coalesce(auth.jwt()->>'email','')) and not vista_aluno),
      'ultima',(select jsonb_build_object('aula',d.aula,'titulo',a.titulo) from public.va_duvidas d join public.va_aulas a on a.id=d.aula
                where d.email=lower(coalesce(auth.jwt()->>'email','')) and not d.vista_aluno order by d.respondida desc nulls last limit 1))
  end
$$;
-- lista para o professor, com nome do aluno, aula e seção
create or replace function public.va_duvidas_prof() returns table(id uuid, email text, nome text, aula uuid, aula_titulo text, curso_titulo text, texto text, criada timestamptz, resposta text, respondida timestamptz, lida_prof boolean)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_admin() then return; end if;
  return query select d.id, d.email,
    coalesce(nullif(trim((select ae.nome from public.allowed_emails ae where ae.email=d.email)),''),(select m.nome from public.mentorados m where m.email=d.email),public.nome_curto(d.email),d.email),
    d.aula, a.titulo, c.titulo, d.texto, d.criada, d.resposta, d.respondida, d.lida_prof
  from public.va_duvidas d join public.va_aulas a on a.id=d.aula join public.va_cursos c on c.id=a.curso
  order by d.lida_prof, d.criada desc limit 500;
end $$;
-- média das estrelas por aula (professor)
create or replace function public.va_medias() returns table(aula uuid, media numeric, n bigint) language sql stable security definer set search_path=public as $$
  select aula, round(avg(nota)::numeric,1), count(*) from public.va_aval where public.is_staff() group by aula
$$;
revoke execute on function public.va_vi_respostas(uuid), public.va_alertas(), public.va_duvidas_prof(), public.va_medias() from anon, public;
grant execute on function public.va_vi_respostas(uuid), public.va_alertas(), public.va_duvidas_prof(), public.va_medias() to authenticated;
select 'ok' status;

-- 25/11 (14h45): vira fórum — alunos da aula veem dúvidas e respostas (sem e-mail, só nome curto)
create or replace function public.va_forum(p_aula uuid) returns table(id uuid, nome text, minha boolean, texto text, criada timestamptz, resposta text, respondida timestamptz, nova_resp boolean)
language plpgsql stable security definer set search_path=public as $$
declare me text := lower(coalesce(auth.jwt()->>'email',''));
begin
  if not exists(select 1 from public.va_aulas a where a.id=p_aula and public.va_ve(a.curso)) then return; end if;
  return query select d.id, coalesce(nullif(public.nome_curto(d.email),''),'Aluno'), d.email=me, d.texto, d.criada, d.resposta, d.respondida,
    (d.email=me and d.resposta is not null and not d.vista_aluno)
  from public.va_duvidas d where d.aula=p_aula order by d.criada;
end $$;
revoke execute on function public.va_forum(uuid) from anon, public;
grant execute on function public.va_forum(uuid) to authenticated;
select 'ok' status;
