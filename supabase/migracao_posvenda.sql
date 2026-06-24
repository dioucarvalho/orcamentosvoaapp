-- ============================================================================
-- ADIÇÃO: tabela "posvenda_dados" (guarda as reservas do Pós-Venda na nuvem)
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que o schema principal já tenha sido executado.
-- ============================================================================
create table if not exists public.posvenda_dados (
  id            int primary key default 1,
  dados         jsonb default '[]'::jsonb,
  atualizado_em timestamptz default now()
);
insert into public.posvenda_dados (id) values (1) on conflict (id) do nothing;

alter table public.posvenda_dados enable row level security;

drop policy if exists "posvenda_ler" on public.posvenda_dados;
create policy "posvenda_ler" on public.posvenda_dados
  for select using (public.eh_gestao());

drop policy if exists "posvenda_alterar" on public.posvenda_dados;
create policy "posvenda_alterar" on public.posvenda_dados
  for update using (public.eh_gestao());
