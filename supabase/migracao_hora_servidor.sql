-- ============================================================================
-- Função: mes_atual_servidor()
--
-- Retorna o mês atual (YYYY-MM) no fuso de Brasília, direto do servidor.
-- Usada para validar se uma venda está sendo lançada no mês corrente,
-- impedindo que funcionários burlem a restrição alterando o relógio do PC.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.mes_atual_servidor()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT to_char(now() AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM');
$$;
