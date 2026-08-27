-- ============================================================================
-- TEMPO REAL nas VENDAS
--
-- Faz o Supabase "avisar" o navegador na hora em que uma venda é inserida/alterada,
-- para que a GESTÃO (admin/gerente) receba a notificação — e a nova conta a pagar
-- (repasse / boleto) apareça no sino — SEM precisar dar F5.
--
-- Só habilita o Realtime na tabela; NÃO muda dados nem regras de acesso (RLS).
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- ============================================================================
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'vendas'
  ) then
    alter publication supabase_realtime add table public.vendas;
  end if;
end $$;
