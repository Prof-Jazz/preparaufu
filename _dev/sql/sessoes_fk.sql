-- 25/11/2026: sessoes.plano_item passa a aceitar itens de plano_itens (turma) e de m_plano (mentoria)
alter table public.sessoes drop constraint if exists sessoes_plano_item_fkey;

-- 25/11: detalhes da correção de simulado (questões por disciplina e tipos de erro)
alter table public.sessoes add column if not exists detalhe jsonb;
