-- ============================================================================
-- Função: data_atual_servidor()
--
-- Retorna a DATA atual (YYYY-MM-DD) no fuso de Brasília, direto do servidor.
-- Usada para TRAVAR a data da venda das consultoras no dia corrente, impedindo
-- que lancem venda retroativa/futura — inclusive alterando o relógio do PC
-- (a fonte da data é o servidor, não o computador).
--
-- Só a gestão (admin/gerente) pode escolher outra data no sistema.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- (Mesma lógica da mes_atual_servidor, só que com o dia.)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.data_atual_servidor()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT to_char(now() AT TIME ZONE 'America/Sao_Paulo', 'YYYY-MM-DD');
$$;
