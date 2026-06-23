-- ============================================================================
-- ADIÇÃO: tabela "agencia" (guarda a LOGO da agência na nuvem)
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que o schema principal já tenha sido executado.
-- ============================================================================
create table if not exists public.agencia (
  id            int primary key default 1,
  logo          text,
  nome          text,
  atualizado_em timestamptz default now()
);
insert into public.agencia (id) values (1) on conflict (id) do nothing;

alter table public.agencia enable row level security;

drop policy if exists "agencia_ler" on public.agencia;
create policy "agencia_ler" on public.agencia
  for select using (true);

drop policy if exists "agencia_alterar" on public.agencia;
create policy "agencia_alterar" on public.agencia
  for update using (auth.uid() is not null);
