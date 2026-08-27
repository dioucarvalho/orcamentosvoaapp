-- ============================================================================
-- PADRONIZAÇÃO ÚNICA: passa TODOS os nomes de contatos já salvos para MAIÚSCULAS.
--
-- Mexe SÓ no campo "nome" de cada cliente (o resto — CPF, telefone, nascimento,
-- observações, anexos — fica intacto). É seguro rodar mais de uma vez: quem já
-- estiver em maiúsculas não é tocado.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run.
-- Observação: como esta consulta ALTERA dados (os nomes), o Supabase vai mostrar
-- o aviso de "destructive" — aqui é o comportamento desejado (é justamente o que
-- queremos: padronizar os nomes). Pode aceitar.
-- ============================================================================
update public.clientes
set data = jsonb_set(data, '{nome}', to_jsonb(upper(data->>'nome')))
where (data ? 'nome')
  and coalesce(data->>'nome','') <> ''
  and data->>'nome' <> upper(data->>'nome');
