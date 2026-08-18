-- ============================================================================
-- CURA do timeout ao listar orçamentos (erro 57014).
--
-- Problema: a lista lê campos pequenos (cliente, destino, valor) de dentro do
-- JSON "data" — mas o Postgres precisa LER a linha inteira (com as fotos) para
-- extrair esses campos. Com a tabela grande, isso estoura o tempo limite.
--
-- Solução: uma coluna "resumo" (JSONB) LEVE, só com os campos da lista, que o
-- banco calcula e mantém sozinho (GENERATED). A lista passa a ler só "resumo",
-- sem nunca tocar nas fotos. Rápido e escala.
--
-- Rode no Supabase: SQL Editor -> New query -> cole -> Run.
-- IMPORTANTE: adicionar a coluna REESCREVE a tabela uma vez (pode levar de
-- alguns segundos a alguns minutos, e trava a tabela nesse período). Rode num
-- momento de pouco uso. O 'statement_timeout = 0' evita que seja cancelada.
-- ============================================================================

set statement_timeout = 0;

alter table public.orcamentos
  add column if not exists resumo jsonb
  generated always as (
    jsonb_build_object(
      'status',           data->>'status',
      'versao',           data->'versao',
      'comissao',         data->'comissao',
      'motivoPerda',      data->>'motivoPerda',
      'baseId',           data->>'baseId',
      'baseNome',         data->>'baseNome',
      'owner',            data->>'owner',
      'ownerId',          data->>'ownerId',
      'createdAt',        data->>'createdAt',
      'closedAt',         data->>'closedAt',
      'cliente',          data->'cliente',
      'fornecedor',       data->>'fornecedor',
      'idOrcamento',      data->>'idOrcamento',
      'destinoTitulo',    data->'destino'->>'titulo',
      'destinoDescricao', data->'destino'->>'descricao',
      'datas',            data->'datas',
      'investimento',     data->'investimento',
      'venda',            data->'venda'
    )
  ) stored;

-- Faz o PostgREST reconhecer a nova coluna de imediato.
notify pgrst, 'reload schema';
