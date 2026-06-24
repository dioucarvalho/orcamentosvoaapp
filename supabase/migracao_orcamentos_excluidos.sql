-- ============================================================================
-- CORREÇÃO: fazer a exclusão de um orçamento se propagar para TODOS os
-- navegadores (inclusive o da consultora que o criou).
--
-- Problema corrigido: o admin excluía um orçamento e sumia para ele, mas
-- continuava aparecendo no sistema da funcionária. Pior: como o app guarda
-- uma cópia local (offline) e reenvia para a nuvem o que está só no local,
-- o orçamento apagado podia até "ressuscitar".
--
-- Solução: uma lista de exclusões (tombstones). Quando a gestão apaga um
-- orçamento, o id dele é registrado aqui. Todo navegador lê essa lista, remove
-- a própria cópia local e nunca mais reenvia o item para a nuvem.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que os outros scripts já tenham sido executados.
-- ============================================================================

create table if not exists public.orcamentos_excluidos (
  id          text primary key,           -- id do orçamento excluído
  excluido_em timestamptz default now(),
  por         uuid                         -- quem excluiu (referência ao usuário)
);

alter table public.orcamentos_excluidos enable row level security;

-- Todos os usuários logados podem LER a lista (para limpar a própria cópia local).
drop policy if exists "orcexc_ler" on public.orcamentos_excluidos;
create policy "orcexc_ler" on public.orcamentos_excluidos
  for select using (auth.uid() is not null);

-- Só a gestão (admin/gerente) pode REGISTRAR uma exclusão.
drop policy if exists "orcexc_inserir" on public.orcamentos_excluidos;
create policy "orcexc_inserir" on public.orcamentos_excluidos
  for insert with check (public.eh_gestao());
