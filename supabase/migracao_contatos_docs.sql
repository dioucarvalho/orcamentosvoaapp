-- ============================================================================
-- MENU CONTATOS — anexos de documento do cliente (RG / passaporte)
--
-- A tabela "clientes" já existe (migracao_clientes.sql). Aqui só criamos o
-- bucket PRIVADO onde ficam as fotos de identidade/passaporte (dados sensíveis),
-- com acesso apenas para usuários logados — igual aos vouchers das vendas.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run. Idempotente.
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('clientes-docs', 'clientes-docs', false)
on conflict (id) do nothing;

drop policy if exists "clientes_docs_ler" on storage.objects;
create policy "clientes_docs_ler" on storage.objects
  for select using ( bucket_id = 'clientes-docs' and auth.uid() is not null );

drop policy if exists "clientes_docs_enviar" on storage.objects;
create policy "clientes_docs_enviar" on storage.objects
  for insert with check ( bucket_id = 'clientes-docs' and auth.uid() is not null );

drop policy if exists "clientes_docs_remover" on storage.objects;
create policy "clientes_docs_remover" on storage.objects
  for delete using ( bucket_id = 'clientes-docs' and auth.uid() is not null );

-- ============================================================================
-- FIM. Depois de rodar, o anexo de documento no menu "Contatos" funciona.
-- (Se a tabela "clientes" ainda não existir, rode antes o migracao_clientes.sql.)
-- ============================================================================
