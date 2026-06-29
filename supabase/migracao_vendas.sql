-- ============================================================================
-- NOVO: MENU "VENDAS" — registro financeiro das vendas da agência.
--
-- Cada venda guarda valor total, categoria, fornecedor, datas, passageiros,
-- comissões (agência / fornecedor + data prevista) e vouchers (PDF no Storage).
-- Separação de acesso: cada consultor vê só as próprias vendas; gerente e admin
-- veem as de todos. A gestão também pode lançar em nome de um consultor (usado
-- quando um orçamento é marcado como vendido e a venda é pré-lançada).
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mais de uma vez sem problema (idempotente).
-- ============================================================================

create table if not exists public.vendas (
  id           text primary key,
  user_id      uuid not null default auth.uid() references auth.users(id) on delete cascade,
  owner_nome   text,
  orcamento_id text,                 -- liga à proposta de origem (evita duplicar)
  created_at   timestamptz default now(),
  data         jsonb not null        -- objeto completo da venda
);
create index if not exists vendas_user_idx on public.vendas(user_id);
create index if not exists vendas_orc_idx  on public.vendas(orcamento_id);

alter table public.vendas enable row level security;

-- LER: o consultor vê as próprias; a gestão (admin/gerente) vê todas.
drop policy if exists "vendas_ler" on public.vendas;
create policy "vendas_ler" on public.vendas
  for select using (user_id = auth.uid() or public.eh_gestao());

-- INSERIR: como eu mesmo OU a gestão (para pré-lançar em nome do consultor).
drop policy if exists "vendas_inserir" on public.vendas;
create policy "vendas_inserir" on public.vendas
  for insert with check (user_id = auth.uid() or public.eh_gestao());

-- ATUALIZAR: dono ou gestão.
drop policy if exists "vendas_atualizar" on public.vendas;
create policy "vendas_atualizar" on public.vendas
  for update using (user_id = auth.uid() or public.eh_gestao());

-- EXCLUIR: dono ou gestão.
drop policy if exists "vendas_excluir" on public.vendas;
create policy "vendas_excluir" on public.vendas
  for delete using (user_id = auth.uid() or public.eh_gestao());

-- ----------------------------------------------------------------------------
-- VOUCHERS (PDFs) — guardados no Storage (bucket privado), não no JSON.
-- ----------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('vendas-docs', 'vendas-docs', false)
on conflict (id) do nothing;

drop policy if exists "vendas_docs_ler" on storage.objects;
create policy "vendas_docs_ler" on storage.objects
  for select using ( bucket_id = 'vendas-docs' and auth.uid() is not null );

drop policy if exists "vendas_docs_enviar" on storage.objects;
create policy "vendas_docs_enviar" on storage.objects
  for insert with check ( bucket_id = 'vendas-docs' and auth.uid() is not null );

drop policy if exists "vendas_docs_remover" on storage.objects;
create policy "vendas_docs_remover" on storage.objects
  for delete using ( bucket_id = 'vendas-docs' and auth.uid() is not null );

-- ============================================================================
-- FIM. Depois de rodar, o menu "Vendas" aparece no sistema.
-- ============================================================================
