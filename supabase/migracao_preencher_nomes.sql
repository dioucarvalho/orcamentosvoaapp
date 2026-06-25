-- ============================================================================
-- CORREÇÃO: preencher o NOME dos colaboradores que estão sem nome cadastrado.
--
-- Sintoma: ao abrir "Novo recado", a lista de pessoas aparecia em branco (só os
-- quadradinhos), porque a coluna "nome" do perfil dessas pessoas estava vazia.
--
-- O que este script faz: para todo perfil sem nome, usa a parte do e-mail antes
-- do "@" como nome (ex.: leticia@gmail.com -> "Leticia"). Quem já tem nome NÃO é
-- alterado. Depois, cada pessoa pode ajustar o próprio nome em "Alterar nome",
-- ou você pode editar direto na tabela "profiles" (Table Editor).
--
-- Rode no Supabase: SQL Editor -> New query -> cole isto -> Run
-- Pode rodar mais de uma vez sem problema.
-- ============================================================================

update public.profiles p
set nome = initcap(replace(split_part(u.email, '@', 1), '.', ' '))
from auth.users u
where p.id = u.id
  and (p.nome is null or btrim(p.nome) = '');

-- Conferir o resultado (opcional): mostra o nome de cada perfil.
-- select p.id, p.nome, p.role from public.profiles p order by p.nome;
