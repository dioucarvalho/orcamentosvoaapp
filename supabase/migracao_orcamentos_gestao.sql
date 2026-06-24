-- ============================================================================
-- CORREÇÃO: permitir que a GESTÃO (admin/gerente) edite e exclua QUALQUER
-- orçamento, não só os próprios.
--
-- Problema corrigido: o administrador clicava em "excluir" um orçamento feito
-- por uma consultora, ele sumia da tela, mas voltava ao atualizar — porque a
-- regra antiga só deixava o DONO do orçamento apagar. O banco bloqueava a
-- exclusão silenciosamente (sem erro), mantendo a linha na nuvem.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que os outros scripts já tenham sido executados.
-- ============================================================================

-- Excluir: dono OU gestão
drop policy if exists "orc_excluir" on public.orcamentos;
create policy "orc_excluir" on public.orcamentos
  for delete using (user_id = auth.uid() or public.eh_gestao());

-- Atualizar: dono OU gestão (necessário para o admin gerenciar e para o
-- recurso "Liberar espaço" conseguir limpar fotos de orçamentos das consultoras)
drop policy if exists "orc_atualizar" on public.orcamentos;
create policy "orc_atualizar" on public.orcamentos
  for update using (user_id = auth.uid() or public.eh_gestao());
