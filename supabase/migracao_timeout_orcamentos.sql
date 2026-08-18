-- ============================================================================
-- Corrige o erro 57014 ("canceling statement due to statement timeout") ao
-- carregar os orçamentos. A tabela cresceu (fotos embutidas em cada orçamento)
-- e a busca passou do tempo limite padrão (~8s), voltando vazia — por isso o
-- admin via Administração/Orçamentos/Dashboard zerados.
--
-- Aqui aumentamos o tempo limite de consulta dos papéis da API. É um alívio
-- imediato; a otimização de verdade (não trazer as fotos na lista) vem depois.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run.
-- ============================================================================

alter role authenticated set statement_timeout = '60s';
alter role anon          set statement_timeout = '60s';

-- Faz o PostgREST recarregar as configurações de imediato.
notify pgrst, 'reload config';
