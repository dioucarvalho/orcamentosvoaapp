-- ============================================================================
-- ADIÇÃO: tabela "voa_app_config" (guarda a configuração do app VOA na nuvem:
-- logo, nome da agência, telefones, e-mail, cor — preenchidos no 1º acesso)
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que o schema principal já tenha sido executado.
-- ============================================================================
create table if not exists public.voa_app_config (
  id            int primary key default 1,
  dados         jsonb,
  atualizado_em timestamptz default now()
);
insert into public.voa_app_config (id) values (1) on conflict (id) do nothing;

alter table public.voa_app_config enable row level security;

drop policy if exists "voa_app_ler" on public.voa_app_config;
create policy "voa_app_ler" on public.voa_app_config
  for select using (public.eh_gestao());

drop policy if exists "voa_app_alterar" on public.voa_app_config;
create policy "voa_app_alterar" on public.voa_app_config
  for update using (public.eh_gestao());
