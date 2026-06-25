-- ============================================================================
-- NOVO: RECADOS / TAREFAS INTERNAS DA EQUIPE (mural de avisos online)
--
-- Permite que qualquer colaborador (consultora, gerência ou admin) deixe um
-- recado/tarefa para uma ou mais pessoas. O destinatário recebe como um
-- checklist; ao concluir, o remetente é avisado de que a tarefa foi concluída.
-- Funciona em tempo real (Supabase Realtime) e não altera nada do resto.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mais de uma vez sem problema (é idempotente).
-- ============================================================================

create table if not exists public.recados (
  id              text primary key,
  de_id           uuid not null default auth.uid() references auth.users(id) on delete cascade,
  de_nome         text,                                   -- nome de quem mandou (cache)
  para_id         uuid not null references auth.users(id) on delete cascade,
  para_nome       text,                                   -- nome de quem recebe (cache)
  texto           text not null,                          -- o recado / tarefa
  status          text not null default 'pendente'
                    check (status in ('pendente','concluida')),
  lida            boolean default false,                  -- destinatário já viu (para o sino)
  concluido_visto boolean default false,                 -- remetente já viu o "concluído"
  criado_em       timestamptz default now(),
  concluido_em    timestamptz
);
create index if not exists recados_para_idx on public.recados(para_id);
create index if not exists recados_de_idx   on public.recados(de_id);

alter table public.recados enable row level security;

-- LER: só vejo o que EU mandei ou o que mandaram PARA MIM.
drop policy if exists "rec_ler" on public.recados;
create policy "rec_ler" on public.recados
  for select using (para_id = auth.uid() or de_id = auth.uid());

-- INSERIR: só posso mandar como eu mesmo (não dá para forjar o remetente).
drop policy if exists "rec_inserir" on public.recados;
create policy "rec_inserir" on public.recados
  for insert with check (de_id = auth.uid());

-- ATUALIZAR: o destinatário marca como lida/concluída; o remetente marca que
-- já viu a conclusão. (Quem mandou OU quem recebeu pode atualizar a linha.)
drop policy if exists "rec_atualizar" on public.recados;
create policy "rec_atualizar" on public.recados
  for update using (para_id = auth.uid() or de_id = auth.uid());

-- EXCLUIR: quem mandou pode apagar o próprio recado; a gestão pode apagar qualquer.
drop policy if exists "rec_excluir" on public.recados;
create policy "rec_excluir" on public.recados
  for delete using (de_id = auth.uid() or public.eh_gestao());

-- ----------------------------------------------------------------------------
-- TEMPO REAL: inclui a tabela na publicação do Realtime (de forma idempotente).
-- ----------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'recados'
  ) then
    alter publication supabase_realtime add table public.recados;
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- LISTA DE COLABORADORES: para mandar um recado, preciso enxergar os nomes da
-- equipe. Hoje a consultora só lia o próprio perfil. Liberamos a LEITURA da
-- lista de perfis (id, nome, papel) para qualquer pessoa logada — são só nomes,
-- nada sensível, e não muda nenhuma outra regra (orçamentos continuam restritos).
-- ----------------------------------------------------------------------------
drop policy if exists "perfil_ler" on public.profiles;
create policy "perfil_ler" on public.profiles
  for select using (auth.uid() is not null);

-- ============================================================================
-- FIM. Depois de rodar, o ícone de recados aparece no topo do sistema.
-- ============================================================================
