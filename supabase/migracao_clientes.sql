-- ============================================================================
-- NOVO: AGENDA DE CLIENTES (cadastro reaproveitável de clientes/passageiros)
--
-- Guarda nome, nascimento, contato, etc. dos clientes já atendidos, para
-- selecionar um cliente existente numa venda futura e preencher os dados sozinho.
-- A agenda se constrói automaticamente ao salvar vendas.
--
-- Opção A — COMPARTILHADA na agência: qualquer colaborador logado pode buscar e
-- reaproveitar clientes (cliente recorrente pode ser atendido por qualquer um).
-- (Só a gestão pode excluir, para evitar perda acidental.)
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- ============================================================================

create table if not exists public.clientes (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  created_at timestamptz default now(),
  data       jsonb not null
);

alter table public.clientes enable row level security;

drop policy if exists "cli_ler" on public.clientes;
create policy "cli_ler" on public.clientes
  for select using (auth.uid() is not null);

drop policy if exists "cli_inserir" on public.clientes;
create policy "cli_inserir" on public.clientes
  for insert with check (auth.uid() is not null);

drop policy if exists "cli_atualizar" on public.clientes;
create policy "cli_atualizar" on public.clientes
  for update using (auth.uid() is not null);

drop policy if exists "cli_excluir" on public.clientes;
create policy "cli_excluir" on public.clientes
  for delete using (public.eh_gestao());

-- ============================================================================
-- FIM. Depois de rodar, ao salvar uma venda os clientes entram na agenda, e o
-- formulário de venda passa a oferecer "Buscar cliente já cadastrado".
-- ============================================================================
