-- ============================================================================
-- CURA do timeout ao listar orçamentos (erro 57014).
--
-- Cria uma coluna "resumo" (JSONB) LEVE — só os campos da lista, SEM fotos —
-- que o banco calcula e mantém sozinho. A lista passa a ler só "resumo", sem
-- nunca tocar no JSON pesado "data" (com as fotos). Rápido e escala.
--
-- Observação técnica: uma coluna GERADA exige expressão IMMUTABLE, mas
-- jsonb_build_object é marcada STABLE pelo Postgres. Como aqui só extraímos
-- texto/jsonb (determinístico), embrulhamos numa função IMMUTABLE — que é o
-- jeito correto e seguro de contornar o erro "generation expression is not
-- immutable" (42P17).
--
-- Rode no Supabase: SQL Editor -> New query -> cole -> Run.
-- IMPORTANTE: adicionar a coluna REESCREVE a tabela uma vez (pode levar de
-- alguns segundos a alguns minutos e trava a tabela nesse período). Rode num
-- momento de pouco uso. O 'statement_timeout = 0' evita que seja cancelada.
-- ============================================================================

set statement_timeout = 0;

-- Função IMMUTABLE que monta o resumo leve a partir do JSON do orçamento.
create or replace function public._orc_resumo(d jsonb)
returns jsonb
language sql
immutable
as $$
  select jsonb_build_object(
    'status',           d->>'status',
    'versao',           d->'versao',
    'comissao',         d->'comissao',
    'motivoPerda',      d->>'motivoPerda',
    'baseId',           d->>'baseId',
    'baseNome',         d->>'baseNome',
    'owner',            d->>'owner',
    'ownerId',          d->>'ownerId',
    'createdAt',        d->>'createdAt',
    'closedAt',         d->>'closedAt',
    'cliente',          d->'cliente',
    'fornecedor',       d->>'fornecedor',
    'idOrcamento',      d->>'idOrcamento',
    'destinoTitulo',    d->'destino'->>'titulo',
    'destinoDescricao', d->'destino'->>'descricao',
    'datas',            d->'datas',
    'investimento',     d->'investimento',
    'venda',            d->'venda'
  );
$$;

alter table public.orcamentos
  add column if not exists resumo jsonb
  generated always as (public._orc_resumo(data)) stored;

-- Faz o PostgREST reconhecer a nova coluna de imediato.
notify pgrst, 'reload schema';
