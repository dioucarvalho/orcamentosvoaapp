-- ============================================================================
-- ADIÇÃO: armazenamento dos ANEXOS do Pós-Venda (vouchers, passagens, PDFs)
-- Os arquivos ficam no Supabase Storage (bucket "posvenda-docs"), NÃO dentro
-- do JSON das reservas — assim não pesam no salvamento contínuo.
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mesmo que os outros scripts já tenham sido executados.
-- ============================================================================

-- 1) Cria o bucket privado (só acessível por quem está logado e é gestão).
insert into storage.buckets (id, name, public)
values ('posvenda-docs', 'posvenda-docs', false)
on conflict (id) do nothing;

-- 2) Permissões (RLS) sobre os objetos do bucket.
--    Apenas administração/gerência (eh_gestao) pode enviar, ler e remover.

drop policy if exists "posvenda_docs_ler" on storage.objects;
create policy "posvenda_docs_ler" on storage.objects
  for select using ( bucket_id = 'posvenda-docs' and public.eh_gestao() );

drop policy if exists "posvenda_docs_enviar" on storage.objects;
create policy "posvenda_docs_enviar" on storage.objects
  for insert with check ( bucket_id = 'posvenda-docs' and public.eh_gestao() );

drop policy if exists "posvenda_docs_remover" on storage.objects;
create policy "posvenda_docs_remover" on storage.objects
  for delete using ( bucket_id = 'posvenda-docs' and public.eh_gestao() );
