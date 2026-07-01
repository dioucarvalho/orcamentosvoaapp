-- ============================================================================
-- Controle diário: permitir que o ADMIN edite/insira o registro de qualquer
-- colaborador (para corrigir lançamentos errados).
--
-- Antes: cada usuário só gravava a própria linha (user_id = auth.uid()).
-- Depois: o admin também pode inserir/atualizar a linha de qualquer usuário.
--         (a leitura de todos já era permitida à gestão)
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- ============================================================================

drop policy if exists "dia_inserir" on public.dia_extra;
create policy "dia_inserir" on public.dia_extra
  for insert with check (user_id = auth.uid() or public.meu_papel() = 'admin');

drop policy if exists "dia_atualizar" on public.dia_extra;
create policy "dia_atualizar" on public.dia_extra
  for update using (user_id = auth.uid() or public.meu_papel() = 'admin');
