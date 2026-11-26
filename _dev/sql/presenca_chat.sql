-- Presença ("estudando agora") e mensagens entre alunos
create table if not exists public.presenca(
  email text primary key,
  uid uuid not null default gen_random_uuid() unique,
  nome text,
  visto timestamptz not null default now(),
  estudando boolean not null default false,
  materia text, tipo text, desde timestamptz,
  oculto boolean not null default false
);
alter table public.presenca enable row level security;

create table if not exists public.mensagens(
  id bigserial primary key,
  de text not null, para text not null,
  texto text not null check (char_length(texto) between 1 and 500),
  criada timestamptz not null default now(),
  lida boolean not null default false
);
create index if not exists mensagens_par on public.mensagens(para, lida);
create index if not exists mensagens_de on public.mensagens(de, para, criada);
alter table public.mensagens enable row level security;

create or replace function public.eu_email() returns text language sql stable as $$ select lower(coalesce(auth.jwt()->>'email','')) $$;

create or replace function public.nome_curto(e text) returns text language sql stable security definer set search_path=public as $$
  select case when e='jesrrael.santos@gmail.com' then 'Prof. Jazz' else
    coalesce(nullif(trim(
      split_part(trim(coalesce((select nome from allowed_emails where email=e),'')),' ',1) || ' ' ||
      coalesce(left(nullif(split_part(trim(coalesce((select nome from allowed_emails where email=e),'')),' ',2),''),1)||'.','')
    ),''), split_part(e,'@',1)) end
$$;

create or replace function public.ping(p_estudando boolean, p_materia text, p_tipo text, p_desde timestamptz)
returns void language plpgsql security definer set search_path=public as $$
declare e text := public.eu_email();
begin
  if not public.is_allowed() then return; end if;
  insert into presenca(email,nome,visto,estudando,materia,tipo,desde)
  values (e, public.nome_curto(e), now(), coalesce(p_estudando,false), left(p_materia,60), left(p_tipo,60), p_desde)
  on conflict (email) do update set nome=excluded.nome, visto=now(), estudando=excluded.estudando,
    materia=excluded.materia, tipo=excluded.tipo, desde=excluded.desde;
end $$;

create or replace function public.set_oculto(p boolean) returns void language sql security definer set search_path=public as $$
  update presenca set oculto=coalesce(p,false) where email=public.eu_email() and public.is_allowed();
$$;

create or replace function public.quem_online()
returns table(uid uuid, nome text, estudando boolean, materia text, tipo text, desde timestamptz, eu boolean, oculto boolean)
language sql stable security definer set search_path=public as $$
  select p.uid, p.nome, p.estudando, p.materia, p.tipo, p.desde, p.email=public.eu_email(), p.oculto
  from presenca p
  where public.is_allowed() and p.visto > now() - interval '3 minutes'
    and (not p.oculto or p.email=public.eu_email())
  order by p.estudando desc, p.desde nulls last, p.nome;
$$;

create or replace function public.meu_estado() returns table(uid uuid, oculto boolean)
language sql stable security definer set search_path=public as $$
  select uid, oculto from presenca where email=public.eu_email() and public.is_allowed();
$$;

create or replace function public.enviar_msg(p_para uuid, p_texto text) returns void
language plpgsql security definer set search_path=public as $$
declare e text := public.eu_email(); d text; t text := trim(coalesce(p_texto,''));
begin
  if not public.is_allowed() then raise exception 'sem permissao'; end if;
  select email into d from presenca where uid=p_para;
  if d is null or d=e then raise exception 'destinatario invalido'; end if;
  if char_length(t)<1 or char_length(t)>500 then raise exception 'mensagem vazia ou longa demais'; end if;
  if (select count(*) from mensagens where de=e and criada>now()-interval '1 minute')>=20 then raise exception 'muitas mensagens: espere um pouco'; end if;
  insert into mensagens(de,para,texto) values (e,d,t);
end $$;

create or replace function public.conversa(p_com uuid)
returns table(id bigint, minha boolean, texto text, criada timestamptz)
language plpgsql security definer set search_path=public as $$
declare e text := public.eu_email(); o text;
begin
  if not public.is_allowed() then return; end if;
  select email into o from presenca where uid=p_com;
  if o is null then return; end if;
  update mensagens set lida=true where para=e and de=o and not lida;
  return query select m.id, m.de=e, m.texto, m.criada from mensagens m
    where (m.de=e and m.para=o) or (m.de=o and m.para=e) order by m.criada desc limit 200;
end $$;

create or replace function public.minhas_conversas()
returns table(uid uuid, nome text, ultima text, quando timestamptz, nao_lidas bigint, online boolean, estudando boolean)
language sql stable security definer set search_path=public as $$
  with e as (select public.eu_email() em),
  m as (select case when de=(select em from e) then para else de end outro, texto, criada, (para=(select em from e) and not lida) nl
        from mensagens where public.is_allowed() and (de=(select em from e) or para=(select em from e))),
  g as (select outro, max(criada) quando, count(*) filter (where nl) nao_lidas from m group by outro)
  select p.uid, p.nome, (select texto from m where m.outro=g.outro order by criada desc limit 1), g.quando, g.nao_lidas,
         p.visto > now()-interval '3 minutes', p.estudando and p.visto > now()-interval '3 minutes'
  from g join presenca p on p.email=g.outro order by g.quando desc;
$$;

create or replace function public.nao_lidas() returns bigint language sql stable security definer set search_path=public as $$
  select count(*) from mensagens where para=public.eu_email() and not lida and public.is_allowed();
$$;

-- moderação: o Prof. Jazz vê todas as conversas
create or replace function public.admin_mensagens(p_limite int default 300)
returns table(id bigint, de text, de_nome text, para text, para_nome text, texto text, criada timestamptz)
language plpgsql stable security definer set search_path=public as $$
begin
  if not public.is_admin() then raise exception 'sem permissao'; end if;
  return query select m.id, m.de, public.nome_curto(m.de), m.para, public.nome_curto(m.para), m.texto, m.criada
    from mensagens m order by m.criada desc limit p_limite;
end $$;

grant execute on function public.ping(boolean,text,text,timestamptz), public.set_oculto(boolean), public.quem_online(), public.meu_estado(),
  public.enviar_msg(uuid,text), public.conversa(uuid), public.minhas_conversas(), public.nao_lidas(), public.admin_mensagens(int) to authenticated;
revoke execute on function public.ping(boolean,text,text,timestamptz), public.set_oculto(boolean), public.quem_online(), public.meu_estado(),
  public.enviar_msg(uuid,text), public.conversa(uuid), public.minhas_conversas(), public.nao_lidas(), public.admin_mensagens(int) from anon;

select 'ok' as status;

-- (24/11) conversas privadas: admin_mensagens removida; bloqueios, denúncias (snapshot só da conversa denunciada) e admin_denuncias/admin_resolver.

-- (24/11) acessos diários: tabela acessos(email,dia,primeiro,ultimo), gravada pelo ping; leitura staff_ve. Retroalimentada com last_sign_in_at e dias com sessões.
