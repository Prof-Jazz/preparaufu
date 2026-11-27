-- 27/11/2026 — Caderno de Erros: resolver de novo (gabarito da questão + histórico de tentativas)
alter table public.caderno_erros add column if not exists gabarito text check (gabarito is null or gabarito in ('A','B','C','D','E'));
alter table public.caderno_erros add column if not exists tentativas jsonb not null default '[]'::jsonb;
update public.caderno_erros set gabarito=substring(obs from '^Gabarito ([A-E])') where gabarito is null and obs ~ '^Gabarito [A-E]';
-- aluno exemplo: gabaritos das questões fictícias (/img/exemplo/q1..q6)
update public.caderno_erros set gabarito = case img when '/img/exemplo/q1.jpg' then 'B' when '/img/exemplo/q2.jpg' then 'A' when '/img/exemplo/q3.jpg' then 'B' when '/img/exemplo/q4.jpg' then 'C' when '/img/exemplo/q5.jpg' then 'A' when '/img/exemplo/q6.jpg' then 'B' end where email='exemplo@preparaufu.com.br' and img like '/img/exemplo/%';
