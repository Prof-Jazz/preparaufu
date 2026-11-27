-- Envio de material pelos Correios (preparaufu.com.br/envio)
-- Qualquer pessoa (sem login) pode ENVIAR o cadastro; só o administrador lê, edita e apaga.
create table if not exists public.envios (
  id bigint generated always as identity primary key,
  criado_em timestamptz not null default now(),
  tipo text not null check (tipo in ('nacional','internacional')),
  nome text not null check (char_length(nome) between 5 and 160),
  email text not null check (char_length(email) between 5 and 160),
  celular text not null check (char_length(celular) between 8 and 30),
  turma text check (char_length(turma) <= 80),
  cpf text check (char_length(cpf) <= 20),
  documento text check (char_length(documento) <= 60),
  dest_outro boolean not null default false,
  dest_nome text check (char_length(dest_nome) <= 160),
  dest_cpf text check (char_length(dest_cpf) <= 20),
  dest_celular text check (char_length(dest_celular) <= 30),
  cep text check (char_length(cep) <= 12),
  logradouro text check (char_length(logradouro) <= 200),
  numero text check (char_length(numero) <= 20),
  complemento text check (char_length(complemento) <= 120),
  bairro text check (char_length(bairro) <= 120),
  cidade text check (char_length(cidade) <= 120),
  uf text check (char_length(uf) <= 60),
  referencia text check (char_length(referencia) <= 300),
  pais text check (char_length(pais) <= 80),
  endereco1 text check (char_length(endereco1) <= 200),
  endereco2 text check (char_length(endereco2) <= 200),
  codigo_postal text check (char_length(codigo_postal) <= 20),
  observacoes text check (char_length(observacoes) <= 600),
  consentimento boolean not null default false,
  status text not null default 'pendente' check (status in ('pendente','separado','enviado','entregue','cancelado')),
  rastreio text check (char_length(rastreio) <= 60),
  enviado_em timestamptz,
  nota_admin text check (char_length(nota_admin) <= 600)
);

alter table public.envios enable row level security;

create policy envios_insere on public.envios for insert to anon, authenticated
  with check (consentimento = true and status = 'pendente' and rastreio is null and enviado_em is null and nota_admin is null);

create policy envios_admin_le on public.envios for select to authenticated using (public.is_admin());

create policy envios_admin_edita on public.envios for update to authenticated using (public.is_admin()) with check (public.is_admin());

create policy envios_admin_apaga on public.envios for delete to authenticated using (public.is_admin());

revoke all on public.envios from anon;
grant insert on public.envios to anon;
grant select, insert, update, delete on public.envios to authenticated;
