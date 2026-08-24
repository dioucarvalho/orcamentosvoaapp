-- ============================================================================
-- Integração Vendas -> Pós-Venda: coluna de CONTROLE (linha de base).
--
-- Guarda quais vendas já existiam quando a integração foi ligada (para não criar
-- reservas retroativas de tudo). O app do Pós-Venda usa SÓ a coluna "dados" — esta
-- coluna extra "controle" não o afeta em nada.
--
-- Rode no Supabase: SQL Editor -> New query -> cole -> Run. Idempotente.
-- ============================================================================

alter table public.posvenda_dados
  add column if not exists controle jsonb default '{}'::jsonb;
