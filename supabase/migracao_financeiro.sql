-- ============================================================================
-- NOVO: MENU FINANCEIRO (somente administrador)
--
-- Controle de contas a pagar, contas a receber e saldo da agência.
-- Cada lançamento pode ser ÚNICO ou RECORRENTE (repete todo mês no dia escolhido).
-- O saldo atual fica num registro especial (id = '_saldo').
--
-- Acesso restrito a ADMIN (a regra abaixo e o menu garantem isso).
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mais de uma vez sem problema (idempotente).
-- ============================================================================

create table if not exists public.financeiro (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  tipo       text,                 -- 'pagar' | 'receber' | 'saldo'
  created_at timestamptz default now(),
  data       jsonb not null
);

alter table public.financeiro enable row level security;

-- Somente ADMIN lê e gerencia o financeiro da agência.
drop policy if exists "fin_ler" on public.financeiro;
create policy "fin_ler" on public.financeiro
  for select using (public.meu_papel() = 'admin');

drop policy if exists "fin_inserir" on public.financeiro;
create policy "fin_inserir" on public.financeiro
  for insert with check (public.meu_papel() = 'admin');

drop policy if exists "fin_atualizar" on public.financeiro;
create policy "fin_atualizar" on public.financeiro
  for update using (public.meu_papel() = 'admin');

drop policy if exists "fin_excluir" on public.financeiro;
create policy "fin_excluir" on public.financeiro
  for delete using (public.meu_papel() = 'admin');

-- ============================================================================
-- FIM. Depois de rodar, o menu "Financeiro" aparece para o administrador.
-- ============================================================================
