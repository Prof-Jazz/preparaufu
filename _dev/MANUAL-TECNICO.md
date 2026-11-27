# PREPARA UFU — Manual técnico da plataforma

Plataforma do Prof. Jazz (preparação para o vestibular da UFU). Este manual existe para que **qualquer conversa nova com o Claude** (ou qualquer pessoa técnica) entenda o site sem depender do histórico. Leia tudo antes de mexer.

- Site: **https://preparaufu.com.br** (GitHub Pages, arquivo `CNAME`, `.nojekyll`)
- Repositório: **github.com/Prof-Jazz/preparaufu** (branch `main`; o push publica em ~1 min)
- Banco de dados e login: **Supabase**, projeto `banco-questoes-ufu`, ref `ygdlbhoqyqjsqoyyfizk` (conta do Prof. Jazz, plano Pro)
- Administrador: o e-mail do Prof. Jazz (está fixo nas funções `is_admin()` e no front como `ADMIN`)
- Tudo em português do Brasil. Comunicações oficiais sem emojis.

---

## 1. Como o site é feito

- **Sem build.** Cada área é um `index.html` único (HTML + CSS + JS no mesmo arquivo), com `supabase-js` carregado da CDN.
- Chave pública do Supabase (publishable) fica no próprio HTML: é pública por natureza; **a segurança está nas regras RLS** do banco.
- Arquivos JS compartilhados em `/js/`:
  - `menu.js` — menu híbrido de todas as páginas (ver seção 4).
  - `presenca.js` — "online/estudando agora", avisos de mensagens e de dúvidas. O aviso de mensagem leva a `/estudos/#mensagens/<uid>/<nome>`, que abre direto a conversa (`abreDoHash` em estudos).
  - `estatisticas.js` — `bancoSessoes(R)`: transforma respostas do Banco de Questões em "sessões de estudo" para dashboards e Comportamento da turma.
- `versao.txt` + `var V='...'` em cada página: aviso de versão nova / recarga automática.

### Páginas

| Pasta | O que é |
|---|---|
| `/` (index.html) | Login e página de entrada (escolha entre áreas). |
| `/estudos/` | **Sala de Estudos** (cronômetro, tipos de estudo, Estudos Extras, "Hoje"), **Meu Dashboard**, **Caderno de Erros**, Dashboard dos alunos (equipe), Denúncias (admin), Ver como aluno, mensagens entre alunos. |
| `/bancodequestoes/` | **Banco de Questões UFU** 2015–2026: filtros, responder A–D (corrige na hora, grava em `banco_resp`, erro vai ao Caderno), "Minha lista" com questões de várias matérias (salva no navegador, `localStorage bqufu-lista-<email>`) para baixar em PDF/Word ou **resolver ali** ("Resolver a lista aqui", com Embaralhar), Análise de Incidência. Menu da plataforma fica no cabeçalho só aqui. |
| `/assessoria/` | Área das turmas: **Perfil de estudos**, **Cronograma Semanal** (gerador automático + edição), **Plano de Estudos** (reagendar), Dúvidas; para a equipe: Comportamento da turma, Alunos, Cadastro (liberar alunos, recursos, assessores, zerar senha), Plano da turma. |
| `/mentoria/` | Mentoria individual: o mentorado tem Início, Dashboard, Plano individual (`m_plano`), Cronograma, Encontros, Materiais próprios, Perfil, Dúvidas; o admin gerencia mentorados, cobranças, raio-x. |
| `/aulas/` | **Agenda** (aulas ao vivo da turma + planejamento do aluno, `agenda_estudos`) e **Materiais** (pastas com capa 1080×1920). |
| `/minhasaulas/` | **Minhas Aulas**: videoaulas do YouTube com player próprio (sem marca), seções com capa 1280×720, grupos renomeáveis, links "Conteúdo da aula", estrelas, fórum "Dúvidas e comentários". |
| `/img/exemplo/` | Questões fictícias usadas no aluno exemplo. |

## 2. Papéis e o que cada um acessa

| Papel | Como o banco sabe | Acessa |
|---|---|---|
| Admin (Prof. Jazz) | `is_admin()` | Tudo. |
| Assessor(a) (ex.: Manu) | tabela `assessores`, `is_assessor()` | Comportamento, Alunos, Plano da turma, Dashboard dos alunos, Ver como aluno; mexe no Cronograma dos alunos. Não cadastra, não vê mensagens/denúncias nem mentoria. |
| Aluno Assessoria completa | `allowed_emails.assessoria = true` | Tudo das turmas: Sala, Banco, Caderno, Minhas Aulas, Agenda, Materiais, Perfil, Cronograma, Plano, Dashboard, Dúvidas. |
| Aluno Curso de Matemática | `allowed_emails.assessoria = false` | Sala, Banco, Caderno, Minhas Aulas, Agenda, Materiais. Recursos extras **só se liberados um a um** em `allowed_emails.recursos` (`plano`, `crono`, `dash`), pela aba Cadastro. |
| Mentorado (mentoria individual) | tabela `mentorados`, `is_mentorado()` | Todas as ferramentas (Sala, Banco, Caderno, Minhas Aulas, Agenda) + área própria da mentoria. Não vê aulas ao vivo nem pastas das turmas (tem as dele). |
| Aluno exemplo | `exemplo@preparaufu.com.br` | Conta fictícia para "Ver como aluno"; tem dados fictícios (`_dev/sql/exemplo_dados_ficticios.sql`). Fica fora das estatísticas da turma. |

Regras fixas do Prof. Jazz: toda melhoria para as turmas vale também para a mentoria individual; toda mudança precisa aparecer no "Ver como aluno"; testar se o aluno consegue **salvar** (RLS) antes de entregar.

## 3. Banco de dados (Supabase)

Funções-chave (SQL, `security definer`): `is_admin`, `is_assessor`, `is_staff` (admin ou assessor), `is_assessoria`, `is_mentorado`, `is_allowed`, `eu_email()`, `staff_ve(email)` (equipe pode ver aquele aluno), `meu_papel`, `minhas_areas`, `meus_recursos`, `tem_recurso(r)`, `minha_turma`, `nome_curto`, `admin_lista`, `m_lista`, `turma_ao_vivo`, `quem_online`, `ping`, mensagens (`enviar_msg`, `conversa`, `minhas_conversas`, `nao_lidas`, `bloqueio`, `denunciar`), Minhas Aulas (`va_ve`, `va_forum`, `va_alertas`, `va_duvidas_prof`, `va_medias`, `va_vi_respostas`), materiais (`ve_arquivo`, `ve_turmas`, `m_ve_pasta`, `m_ve_arquivo`), `m_copiar_plano`, `uid_aluno`.

Tabelas principais:

| Tabela | Conteúdo |
|---|---|
| `allowed_emails` | alunos liberados (`nome`, `assessoria`, `recursos text[]`). |
| `assessores`, `mentorados` | equipe e mentorados (mentorados têm valor, vencimento, WhatsApp). |
| `checkup` | Perfil de estudos (`respostas jsonb`). Perguntas novas: `horas_dia` {Seg..Dom}, `rev_tempo`. Perfis antigos são migrados no formulário (`migraPerfil`). |
| `cronograma` | blocos do Cronograma Semanal (`blocos jsonb`: `{id,d,ini,fim,tipo,k,label}` em minutos). |
| `plano_itens` / `plano_feito` / `plano_remarcado` / `plano_reag_hist` | Plano da turma, assuntos estudados, reagendamentos. |
| `m_plano` / `m_plano_feito` / `m_plano_remarcado` | Plano individual da mentoria. |
| `sessoes` | sessões da Sala de Estudos (`segundos`, `tipo`, `materia`, `questoes`, `acertos`, `erros`, `detalhe jsonb` p/ simulado e Estudos Extras). |
| `banco_resp` | respostas do Banco de Questões (`questao`, `escolha`, `correta`). |
| `caderno_erros` | Caderno de Erros (`materia`, `assunto`, `motivo`, `fonte`, `obs`, `img`, `questao`, `gabarito` A–E, `tentativas` jsonb, `revisada`). "Resolver de novo" (`resolveCad` em estudos): refaz a questão; com gabarito corrige sozinho, sem gabarito o aluno diz se acertou; acerto marca revisada; questão do Banco também grava em `banco_resp`. `img`: caminho no bucket `caderno`, `banco:q/<id>.jpg` (foto do próprio banco) ou `/img/...`. |
| `agenda_estudos` | planejamento do aluno na Agenda (`origem` manual/crono). |
| `aulas`, `pastas`, `arquivos`, `m_pastas`, `m_arquivos`, `m_encontros`, `m_pagamentos` | Agenda/Materiais das turmas e da mentoria. |
| `va_cursos`, `va_aulas`, `va_links`, `va_feito`, `va_aval`, `va_duvidas` | Minhas Aulas. |
| `presenca`, `acessos`, `mensagens`, `bloqueios`, `denuncias` | online/estudando, acessos diários, chat entre alunos. |

Buckets de arquivos: `banco` (privado: `banco.json`, `q/*.jpg`, `docx/*`), `caderno` (privado, fotos do Caderno, pasta = e-mail do aluno), `capas`, `materiais`, `mentoria`.

**Histórico do SQL aplicado:** pasta `_dev/sql/` (cada arquivo = uma mudança). **Estado exato atual** (sempre mais confiável que os arquivos), rodar no SQL Editor do Supabase:

```sql
-- funções
select pg_get_functiondef(p.oid) from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.prokind='f' order by p.proname;
-- regras de acesso (RLS)
select tablename, policyname, cmd, qual, with_check from pg_policies where schemaname in ('public','storage') order by tablename, policyname;
-- colunas
select table_name, column_name, data_type from information_schema.columns where table_schema='public' order by table_name, ordinal_position;
```

### Testar permissões como um aluno (sem login)
Dentro de um `do $$ ... $$`: `perform set_config('request.jwt.claims', json_build_object('email','EMAIL','role','authenticated')::text, true); perform set_config('role','authenticated',true);` faça a consulta/insert dentro de `begin ... raise exception 'desfaz'; exception when others then ... end;` (desfaz a gravação) e volte com `set_config('role','postgres',true)`.

## 4. Menu híbrido (`/js/menu.js`)

- Lateral com abas **Estudar · Organizar · Progresso · Equipe** (Equipe só para admin/assessora; some no "Ver como aluno"). Recolhível (« / »). No celular vira gaveta (☰). No Banco de Questões o menu vai para o cabeçalho (botões com lista).
- Itens apontam para `pagina/#hash`; dentro da página o item **clica na aba que a página já tem** (`btn`), por isso cada página mantém seus botões de aba (escondidos com `.mn-esc`). Para incluir uma área nova: adicionar `I('Grupo','icone','Nome','/pasta/#hash','pasta','idDoBotao')` em `itens()`.
- Papel lido por RPC e guardado 10 min em `sessionStorage` (`bqufu-menu-<email>`).

## 5. Regras do Cronograma Semanal (gerador `gerar` / `gerar0`, em assessoria e mentoria — manter iguais)

- Ordem de prioridade: Matemática > Física > Química > Biologia > História > Geografia > Língua Portuguesa > Literatura > Filosofia > Sociologia > Língua estrangeira (`ORDP`).
- Difíceis/muito difíceis primeiro (exatas na frente), depois peso no curso.
- Matemática nunca menos vezes que Física ou Química; Biologia logo depois das exatas; Matemática e Física no mesmo dia só em último recurso; no máximo 2 exatas por dia.
- **Redação sempre 1×/semana com 1h30**, garantida logo após a 1ª rodada das exatas.
- Toda matéria pelo menos 1×; se faltar tempo, reduz repetições e avisa; se o tempo livre real (trabalho/escola/aulas) for curto, tenta blocos de 1h antes de deixar matéria de fora.
- Revisão diária seg–sáb; domingo = simulado/provas antigas. Aulas ao vivo do PREPARA (seg e qui 18h45–20h45) bloqueadas.

## 6. Publicar e testar

```bash
git clone https://github.com/Prof-Jazz/preparaufu && cd preparaufu
python3 _dev/ferramentas/versao.py .            # atualiza a versão (obrigatório antes de cada commit)
git add -A && git -c user.name=Prof-Jazz commit -m "..." && git push origin HEAD:main
```
- Não usar `-c user.email` (bloqueado pelo plugin de privacidade).
- Teste local: `python3 -m http.server 8765` na raiz + Playwright/Chrome, trocando o supabase-js pelo simulador `_dev/ferramentas/mock_supabase.js` (`window.__RPC` sobrescreve RPCs, `window.__EMAIL` define o usuário, `window.__DB` guarda as tabelas).
- SQL no Supabase: SQL Editor no navegador integrado (conta do Prof. Jazz).

## 7. Padrões visuais do Prof. Jazz
- Etiquetas/cartões de menu sempre em grade de colunas, do mesmo tamanho e alinhados.
- Gosta de análises visuais (cartões, gráficos, painéis).
- Sem emojis em comunicações oficiais.
- Identidade: azul `#3A8CCB`, amarelo `#DDDD24`/`#F2C811`, verde `#1BAF7A`, laranja `#EB6834`, grafite; logos em `/bancodequestoes/logo/`.

## 8. Histórico resumido (nov./2026)
22/11 site no ar (banco + assessoria) · 23/11 Aulas e materiais, Cronograma Semanal · 24/11 Sala de Estudos, mensagens, mentoria individual, assessores · 25/11 Minhas Aulas, Agenda com cronograma, recursos por aluno do Curso, reagendar plano, Estudos Extras, regras do gerador · 26/11 Caderno de Erros, menu híbrido, Banco com resposta direta (conta como estudo), aluno exemplo com dados fictícios, auditoria de permissões, migração de perfis antigos, resolver a Minha lista no Banco · 27/11 resolver de novo no Caderno de Erros (cartões compactos, 3 por linha).
