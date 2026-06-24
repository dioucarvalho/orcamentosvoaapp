-- ============================================================================
-- AVV · TZ Viagens — Estrutura do banco de dados (Supabase / PostgreSQL)
--
-- COMO RODAR:
--   1) No Supabase, abra "SQL Editor" (menu lateral)
--   2) Clique em "New query"
--   3) Cole TODO este arquivo
--   4) Clique em "Run"  (deve aparecer "Success")
--
-- Pode rodar mais de uma vez sem problema (é idempotente).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1) PERFIS — guarda o PAPEL de cada usuário (admin / gerente / consultora)
-- ----------------------------------------------------------------------------
create table if not exists public.profiles (
  id        uuid primary key references auth.users(id) on delete cascade,
  nome      text,
  role      text not null default 'consultora' check (role in ('admin','gerente','consultora')),
  criado_em timestamptz default now()
);

-- Cria o perfil automaticamente quando um usuário novo é cadastrado no Auth
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nome, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', new.email), 'consultora')
  on conflict (id) do nothing;
  return new;
end; $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Funções auxiliares: papel do usuário logado
create or replace function public.meu_papel()
returns text language sql stable security definer set search_path = public as $$
  select role from public.profiles where id = auth.uid();
$$;

create or replace function public.eh_gestao()   -- true para admin ou gerente
returns boolean language sql stable security definer set search_path = public as $$
  select coalesce(public.meu_papel() in ('admin','gerente'), false);
$$;

-- ----------------------------------------------------------------------------
-- 2) ORÇAMENTOS — o objeto completo vai no campo "data" (jsonb);
--    as colunas soltas servem para filtrar/relatar no painel.
-- ----------------------------------------------------------------------------
create table if not exists public.orcamentos (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  owner_nome text,
  status     text,
  versao     int  default 1,
  created_at timestamptz default now(),
  closed_at  timestamptz,
  data       jsonb not null
);
create index if not exists orcamentos_user_idx on public.orcamentos(user_id);

-- ----------------------------------------------------------------------------
-- 3) TAREFAS (agenda)
-- ----------------------------------------------------------------------------
create table if not exists public.tarefas (
  id         text primary key,
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data       date,
  texto      text,
  done       boolean default false,
  created_at timestamptz default now()
);
create index if not exists tarefas_user_idx on public.tarefas(user_id);

-- ----------------------------------------------------------------------------
-- 4) ATIVIDADES DIÁRIAS (Controle Diário: repiques, agendamentos, etc.)
-- ----------------------------------------------------------------------------
create table if not exists public.dia_extra (
  user_id          uuid not null default auth.uid() references auth.users(id) on delete cascade,
  data             date not null,
  repiques         numeric default 0,
  agendamento      numeric default 0,
  atendimento      numeric default 0,
  orcamento_ajuste numeric default 0,
  vendas_ajuste    numeric default 0,
  comissao_ajuste  numeric default 0,
  primary key (user_id, data)
);

-- ----------------------------------------------------------------------------
-- 5) METAS — uma única linha global (mesma meta para a equipe; só admin altera)
-- ----------------------------------------------------------------------------
create table if not exists public.metas (
  id          int primary key default 1,
  agendamento numeric default 144,
  atendimento numeric default 72,
  orcamento   numeric default 72,
  vendas      numeric default 36,
  repiques    numeric default 2000,
  venda_min   numeric default 30000
);
insert into public.metas (id) values (1) on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 6) AGÊNCIA — configurações globais (logo da agência, etc.)
-- ----------------------------------------------------------------------------
create table if not exists public.agencia (
  id            int primary key default 1,
  logo          text,
  nome          text,
  atualizado_em timestamptz default now()
);
insert into public.agencia (id) values (1) on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 7) PÓS-VENDA — reservas geridas pela gerência (um único registro global)
-- ----------------------------------------------------------------------------
create table if not exists public.posvenda_dados (
  id            int primary key default 1,
  dados         jsonb default '[]'::jsonb,
  atualizado_em timestamptz default now()
);
insert into public.posvenda_dados (id) values (1) on conflict (id) do nothing;

-- ----------------------------------------------------------------------------
-- 8) VOA APP — configuração da agência (logo, nome, telefones) do app VOA
-- ----------------------------------------------------------------------------
create table if not exists public.voa_app_config (
  id            int primary key default 1,
  dados         jsonb,
  atualizado_em timestamptz default now()
);
insert into public.voa_app_config (id) values (1) on conflict (id) do nothing;

-- ============================================================================
-- RLS — REGRAS DE ACESSO (a segurança de verdade, por papel)
-- ============================================================================
alter table public.profiles      enable row level security;
alter table public.orcamentos    enable row level security;
alter table public.tarefas       enable row level security;
alter table public.dia_extra     enable row level security;
alter table public.metas         enable row level security;
alter table public.agencia       enable row level security;
alter table public.posvenda_dados enable row level security;
alter table public.voa_app_config enable row level security;

-- PERFIS
drop policy if exists "perfil_ler" on public.profiles;
create policy "perfil_ler" on public.profiles
  for select using (id = auth.uid() or public.eh_gestao());
drop policy if exists "perfil_atualizar_proprio" on public.profiles;
create policy "perfil_atualizar_proprio" on public.profiles
  for update using (id = auth.uid());
drop policy if exists "perfil_admin_atualiza_qualquer" on public.profiles;
create policy "perfil_admin_atualiza_qualquer" on public.profiles
  for update using (public.meu_papel() = 'admin');

-- ORÇAMENTOS — gestão LÊ tudo; consultora lê só o dela. Escrita: só o dono.
drop policy if exists "orc_ler" on public.orcamentos;
create policy "orc_ler" on public.orcamentos
  for select using (user_id = auth.uid() or public.eh_gestao());
drop policy if exists "orc_inserir" on public.orcamentos;
create policy "orc_inserir" on public.orcamentos
  for insert with check (user_id = auth.uid());
drop policy if exists "orc_atualizar" on public.orcamentos;
create policy "orc_atualizar" on public.orcamentos
  for update using (user_id = auth.uid());
drop policy if exists "orc_excluir" on public.orcamentos;
create policy "orc_excluir" on public.orcamentos
  for delete using (user_id = auth.uid());

-- TAREFAS — mesmo padrão
drop policy if exists "tar_ler" on public.tarefas;
create policy "tar_ler" on public.tarefas
  for select using (user_id = auth.uid() or public.eh_gestao());
drop policy if exists "tar_inserir" on public.tarefas;
create policy "tar_inserir" on public.tarefas
  for insert with check (user_id = auth.uid());
drop policy if exists "tar_atualizar" on public.tarefas;
create policy "tar_atualizar" on public.tarefas
  for update using (user_id = auth.uid());
drop policy if exists "tar_excluir" on public.tarefas;
create policy "tar_excluir" on public.tarefas
  for delete using (user_id = auth.uid());

-- ATIVIDADES DIÁRIAS — mesmo padrão
drop policy if exists "dia_ler" on public.dia_extra;
create policy "dia_ler" on public.dia_extra
  for select using (user_id = auth.uid() or public.eh_gestao());
drop policy if exists "dia_inserir" on public.dia_extra;
create policy "dia_inserir" on public.dia_extra
  for insert with check (user_id = auth.uid());
drop policy if exists "dia_atualizar" on public.dia_extra;
create policy "dia_atualizar" on public.dia_extra
  for update using (user_id = auth.uid());

-- METAS — todos leem; só admin altera
drop policy if exists "metas_ler" on public.metas;
create policy "metas_ler" on public.metas
  for select using (true);
drop policy if exists "metas_admin_altera" on public.metas;
create policy "metas_admin_altera" on public.metas
  for update using (public.meu_papel() = 'admin');

-- AGÊNCIA — todos leem; qualquer usuário logado pode atualizar (logo)
drop policy if exists "agencia_ler" on public.agencia;
create policy "agencia_ler" on public.agencia
  for select using (true);
drop policy if exists "agencia_alterar" on public.agencia;
create policy "agencia_alterar" on public.agencia
  for update using (auth.uid() is not null);

-- PÓS-VENDA — só admin/gerente leem e alteram
drop policy if exists "posvenda_ler" on public.posvenda_dados;
create policy "posvenda_ler" on public.posvenda_dados
  for select using (public.eh_gestao());
drop policy if exists "posvenda_alterar" on public.posvenda_dados;
create policy "posvenda_alterar" on public.posvenda_dados
  for update using (public.eh_gestao());

-- VOA APP — só admin/gerente leem e alteram
drop policy if exists "voa_app_ler" on public.voa_app_config;
create policy "voa_app_ler" on public.voa_app_config
  for select using (public.eh_gestao());
drop policy if exists "voa_app_alterar" on public.voa_app_config;
create policy "voa_app_alterar" on public.voa_app_config
  for update using (public.eh_gestao());

-- ============================================================================
-- FIM. Depois de rodar: crie os usuários em Authentication → Users → Add user
-- e ajuste o papel de cada um na tabela "profiles" (Table Editor).
-- ============================================================================
