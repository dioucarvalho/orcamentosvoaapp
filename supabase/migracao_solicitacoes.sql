-- ============================================================================
-- SOLICITAÇÕES DE PERMISSÃO
--
-- Quando uma colaboradora tenta uma ação que exige permissão do administrador,
-- em vez de pedir a senha, ela envia um PEDIDO. O admin recebe no "sininho",
-- vê a descrição clara e Aprova/Reprova (com a senha, dupla proteção). Ao
-- aprovar, a própria sessão do admin executa a ação na nuvem (o payload guarda
-- os dados), então reflete no PC da colaboradora mesmo que ela feche o sistema.
--
-- Mesmo padrão da tabela "recados" (id text + Realtime). Idempotente.
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run.
-- ============================================================================

create table if not exists public.solicitacoes (
  id                text primary key,
  solicitante_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  solicitante_nome  text,                                   -- nome de quem pediu (cache)
  acao_key          text not null,                          -- tipo da ação (ex.: venda_retroativa)
  descricao         text not null,                          -- explicação clara para o admin
  payload           jsonb,                                  -- dados para executar a ação na aprovação
  status            text not null default 'pendente'
                      check (status in ('pendente','aprovada','reprovada')),
  visto             boolean default false,                  -- solicitante já viu a resposta (sino)
  criado_em         timestamptz default now(),
  resolvido_em      timestamptz,
  resolvido_por     text
);
create index if not exists solicitacoes_solicitante_idx on public.solicitacoes(solicitante_id);
create index if not exists solicitacoes_status_idx       on public.solicitacoes(status);

alter table public.solicitacoes enable row level security;

-- LER: o solicitante vê as próprias; a gestão (admin/gerente) vê todas para aprovar.
drop policy if exists "sol_ler" on public.solicitacoes;
create policy "sol_ler" on public.solicitacoes
  for select using (solicitante_id = auth.uid() or public.eh_gestao());

-- INSERIR: só posso pedir como eu mesmo (não dá para forjar o solicitante).
drop policy if exists "sol_inserir" on public.solicitacoes;
create policy "sol_inserir" on public.solicitacoes
  for insert with check (solicitante_id = auth.uid());

-- ATUALIZAR: o solicitante marca que viu a resposta; a gestão aprova/reprova.
drop policy if exists "sol_atualizar" on public.solicitacoes;
create policy "sol_atualizar" on public.solicitacoes
  for update using (solicitante_id = auth.uid() or public.eh_gestao());

-- EXCLUIR: o próprio solicitante ou a gestão podem limpar.
drop policy if exists "sol_excluir" on public.solicitacoes;
create policy "sol_excluir" on public.solicitacoes
  for delete using (solicitante_id = auth.uid() or public.eh_gestao());

-- ----------------------------------------------------------------------------
-- TEMPO REAL: inclui a tabela na publicação do Realtime (idempotente).
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'solicitacoes'
  ) then
    alter publication supabase_realtime add table public.solicitacoes;
  end if;
end $$;
