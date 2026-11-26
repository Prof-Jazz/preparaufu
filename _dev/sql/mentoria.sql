-- Mentoria individual
create table if not exists public.mentorados(
  email text primary key,
  nome text not null,
  criado timestamptz not null default now()
);
alter table public.mentorados enable row level security;

create or replace function public.is_mentorado() returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.mentorados where email = lower(coalesce(auth.jwt()->>'email','')))
$$;
create or replace function public.e_mentorado(e text) returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.mentorados where email = lower(e))
$$;
-- equipe pode ver o aluno? admin sempre; assessor só aluno das turmas
create or replace function public.staff_ve(e text) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or (public.is_assessor() and exists(select 1 from public.allowed_emails where email = lower(e)))
$$;

drop policy if exists mentorados_admin on public.mentorados;
create policy mentorados_admin on public.mentorados for all using (public.is_admin()) with check (public.is_admin());
drop policy if exists mentorados_self on public.mentorados;
create policy mentorados_self on public.mentorados for select using (email = public.eu_email());

-- acesso / login
create or replace function public.email_permitido(e text) returns boolean language sql stable security definer set search_path=public as $$
  select lower(trim(e)) = 'jesrrael.santos@gmail.com'
      or exists (select 1 from public.allowed_emails where email = lower(trim(e)))
      or exists (select 1 from public.assessores where email = lower(trim(e)))
      or exists (select 1 from public.mentorados where email = lower(trim(e)))
$$;
create or replace function public.is_allowed() returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or public.is_assessor() or public.is_mentorado()
      or exists (select 1 from public.allowed_emails where email = lower(coalesce(auth.jwt()->>'email','')))
$$;
create or replace function public.meu_papel() returns text language sql stable security definer set search_path=public as $$
  select case when public.is_admin() then 'admin' when public.is_assessor() then 'assessor'
              when exists(select 1 from public.allowed_emails where email=lower(coalesce(auth.jwt()->>'email',''))) then 'aluno'
              when public.is_mentorado() then 'mentorado' end
$$;
create or replace function public.minhas_areas() returns jsonb language sql stable security definer set search_path=public as $$
  select jsonb_build_object('turma', public.is_admin() or public.is_assessor() or exists(select 1 from public.allowed_emails where email=public.eu_email()),
                            'mentoria', public.is_admin() or public.is_mentorado(),
                            'papel', public.meu_papel())
$$;
create or replace function public.nome_curto(e text) returns text language sql stable security definer set search_path=public as $$
  with n as (select trim(coalesce((select nome from allowed_emails where email=e),(select nome from assessores where email=e),(select nome from mentorados where email=e),'')) v)
  select case when e='jesrrael.santos@gmail.com' then 'Prof. Jazz' else
    coalesce(nullif(trim(split_part((select v from n),' ',1) || ' ' ||
      coalesce(left(nullif(split_part((select v from n),' ',2),''),1)||'.','')),''), split_part(e,'@',1)) end
$$;

-- tabelas compartilhadas: o mentorado grava o próprio perfil e cronograma; assessor não vê mentorados
drop policy if exists checkup_sel on public.checkup;
create policy checkup_sel on public.checkup for select using (email = public.eu_email() or public.staff_ve(email));
drop policy if exists checkup_ins on public.checkup;
create policy checkup_ins on public.checkup for insert with check ((email = public.eu_email() and (public.is_assessoria() or public.is_mentorado())) or public.is_admin());
drop policy if exists checkup_upd on public.checkup;
create policy checkup_upd on public.checkup for update using ((email = public.eu_email() and (public.is_assessoria() or public.is_mentorado())) or public.is_admin()) with check (email = public.eu_email() or public.is_admin());
drop policy if exists crono_sel on public.cronograma;
create policy crono_sel on public.cronograma for select using (email = public.eu_email() or public.staff_ve(email));
drop policy if exists crono_upd on public.cronograma;
create policy crono_upd on public.cronograma for update using ((email = public.eu_email() and (public.is_assessoria() or public.is_mentorado())) or public.staff_ve(email)) with check (email = public.eu_email() or public.staff_ve(email));
drop policy if exists crono_ins on public.cronograma;
create policy crono_ins on public.cronograma for insert with check ((email = public.eu_email() and (public.is_assessoria() or public.is_mentorado())) or public.staff_ve(email));
drop policy if exists sessoes_ler on public.sessoes;
create policy sessoes_ler on public.sessoes for select using (email = public.eu_email() or public.staff_ve(email));
drop policy if exists plano_feito_ler on public.plano_feito;
create policy plano_feito_ler on public.plano_feito for select using (email = public.eu_email() or public.staff_ve(email));

-- plano individual
create table if not exists public.m_plano(
  id bigserial primary key,
  email text not null,
  semana date not null,
  materia text not null,
  frente text,
  assunto text not null,
  obs text
);
create index if not exists m_plano_email on public.m_plano(email, semana);
alter table public.m_plano enable row level security;
drop policy if exists m_plano_ler on public.m_plano;
create policy m_plano_ler on public.m_plano for select using (email = public.eu_email() or public.is_admin());
drop policy if exists m_plano_admin on public.m_plano;
create policy m_plano_admin on public.m_plano for all using (public.is_admin()) with check (public.is_admin());

create table if not exists public.m_plano_feito(
  email text not null,
  item bigint not null references public.m_plano(id) on delete cascade,
  criado timestamptz not null default now(),
  primary key(email,item)
);
alter table public.m_plano_feito enable row level security;
drop policy if exists m_feito_ler on public.m_plano_feito;
create policy m_feito_ler on public.m_plano_feito for select using (email = public.eu_email() or public.is_admin());
drop policy if exists m_feito_ins on public.m_plano_feito;
create policy m_feito_ins on public.m_plano_feito for insert with check ((email = public.eu_email() and public.is_mentorado()) or public.is_admin());
drop policy if exists m_feito_del on public.m_plano_feito;
create policy m_feito_del on public.m_plano_feito for delete using (email = public.eu_email() or public.is_admin());

create or replace function public.m_copiar_plano(p_email text, p_substituir boolean) returns int
language plpgsql security definer set search_path=public as $$
declare n int; lg text;
begin
  if not public.is_admin() then raise exception 'sem permissao'; end if;
  if coalesce(p_substituir,true) then delete from m_plano where email=lower(p_email); end if;
  select coalesce(respostas->>'lingua','') into lg from checkup where email=lower(p_email);
  lg := coalesce(lg,'');
  insert into m_plano(email,semana,materia,frente,assunto,obs)
    select lower(p_email), semana, materia, frente, assunto, obs from plano_itens
    where not (materia='Inglês' and lg='Espanhol') and not (materia='Espanhol' and lg='Inglês')
    order by id;
  get diagnostics n = row_count; return n;
end $$;

-- encontros
create table if not exists public.m_encontros(
  id bigserial primary key,
  email text not null,
  data date not null,
  ini time, fim time,
  titulo text,
  link text,
  combinados text,
  criado timestamptz not null default now()
);
create index if not exists m_encontros_email on public.m_encontros(email, data);
alter table public.m_encontros enable row level security;
drop policy if exists m_enc_ler on public.m_encontros;
create policy m_enc_ler on public.m_encontros for select using (email = public.eu_email() or public.is_admin());
drop policy if exists m_enc_admin on public.m_encontros;
create policy m_enc_admin on public.m_encontros for all using (public.is_admin()) with check (public.is_admin());

-- materiais (email nulo = pasta para todos os mentorados)
create table if not exists public.m_pastas(
  id uuid primary key default gen_random_uuid(),
  email text,
  nome text not null,
  descricao text,
  criado timestamptz not null default now()
);
alter table public.m_pastas enable row level security;
drop policy if exists m_pastas_ler on public.m_pastas;
create policy m_pastas_ler on public.m_pastas for select using (public.is_admin() or (public.is_mentorado() and (email is null or email = public.eu_email())));
drop policy if exists m_pastas_admin on public.m_pastas;
create policy m_pastas_admin on public.m_pastas for all using (public.is_admin()) with check (public.is_admin());

create table if not exists public.m_arquivos(
  id uuid primary key default gen_random_uuid(),
  pasta uuid not null references public.m_pastas(id) on delete cascade,
  path text not null unique,
  nome text not null,
  tipo text, tamanho bigint,
  criado timestamptz not null default now()
);
alter table public.m_arquivos enable row level security;
create or replace function public.m_ve_pasta(p uuid) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or exists(select 1 from public.m_pastas where id=p and public.is_mentorado() and (email is null or email=public.eu_email()))
$$;
drop policy if exists m_arq_ler on public.m_arquivos;
create policy m_arq_ler on public.m_arquivos for select using (public.m_ve_pasta(pasta));
drop policy if exists m_arq_admin on public.m_arquivos;
create policy m_arq_admin on public.m_arquivos for all using (public.is_admin()) with check (public.is_admin());

insert into storage.buckets(id,name,public,file_size_limit) values ('mentoria','mentoria',false,209715200) on conflict (id) do nothing;
create or replace function public.m_ve_arquivo(p text) returns boolean language sql stable security definer set search_path=public as $$
  select public.is_admin() or exists(select 1 from public.m_arquivos a where a.path=p and public.m_ve_pasta(a.pasta))
$$;
drop policy if exists m_storage_ler on storage.objects;
create policy m_storage_ler on storage.objects for select using (bucket_id='mentoria' and public.m_ve_arquivo(name));
drop policy if exists m_storage_admin on storage.objects;
create policy m_storage_admin on storage.objects for all using (bucket_id='mentoria' and public.is_admin()) with check (bucket_id='mentoria' and public.is_admin());

-- lista para o admin
create or replace function public.m_lista() returns table(email text, nome text, criado timestamptz, cadastrado boolean, ultimo_acesso timestamptz, checkup_em timestamptz, itens bigint, feitos bigint, proximo date)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'sem permissao'; end if;
  return query select m.email, m.nome, m.criado, (u.id is not null), u.last_sign_in_at, c.atualizado_em,
    (select count(*) from m_plano p where p.email=m.email), (select count(*) from m_plano_feito f where f.email=m.email),
    (select min(e.data) from m_encontros e where e.email=m.email and e.data>=current_date)
    from mentorados m left join auth.users u on lower(u.email)=m.email left join checkup c on c.email=m.email order by m.nome;
end $$;

-- aluno exemplo da mentoria (sem login; só para o admin ver como o aluno vê)
insert into public.mentorados(email,nome) values ('exemplo.mentoria@preparaufu.com.br','Aluno Exemplo da Mentoria') on conflict do nothing;

revoke execute on function public.is_mentorado(), public.e_mentorado(text), public.staff_ve(text), public.minhas_areas(), public.m_copiar_plano(text,boolean), public.m_ve_pasta(uuid), public.m_ve_arquivo(text), public.m_lista() from anon, public;
grant execute on function public.is_mentorado(), public.e_mentorado(text), public.staff_ve(text), public.minhas_areas(), public.m_copiar_plano(text,boolean), public.m_ve_pasta(uuid), public.m_ve_arquivo(text), public.m_lista() to authenticated;
select 'ok' status;

-- (24/11) mensalidade da mentoria individual
alter table public.mentorados add column if not exists valor numeric(10,2);
alter table public.mentorados add column if not exists vencimento date;
alter table public.mentorados add column if not exists whatsapp text;
create table if not exists public.m_pagamentos(id bigserial primary key, email text not null, pago_em date not null default current_date, valor numeric(10,2), referente date, criado timestamptz not null default now());
-- RLS: admin tudo; aluno lê os próprios. m_lista devolve também valor, vencimento e whatsapp (do cadastro ou do perfil).

-- 25/11 (20h): mentoria — m_plano_remarcado (sem FK, RLS mentorado/admin) e plano_reag_hist.area ('turma'|'mentoria')
