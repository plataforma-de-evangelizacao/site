# PGE V46 · 6 de novembro de 2026

Este ZIP é uma atualização incremental para um repositório que já recebeu a V45. Resolva qualquer merge em andamento antes de aplicar os arquivos.

1. Faça backup e confirme que a V45 já está na sua cópia local. Extraia o ZIP na raiz do repositório, preservando a estrutura das pastas.
2. Confira `git status --short` e `git diff --stat`. A atualização inclui arquivos do painel e da interface pública. Ela não contém configurações, migrações nem arquivos de dados editoriais.
3. Envie as alterações pelo fluxo normal do seu repositório e acompanhe a publicação no GitHub Pages. O backend permanece na mesma versão da V45.
4. Abra o painel e execute o roteiro abaixo com um registro de teste.

## Alterações e conferência

1. **Menu** — confirme os grupos Conteúdos e Administração. Gestão de palestras e lives fica entre programas e parceiros.
2. **Conteúdos publicados no site** — filtre por Atividades e instituições. Confira as situações Conteúdos arquivados e Conteúdos excluídos. Na lixeira, alterne entre os dois estados e restaure um item de teste.
3. **Editor** — abra uma instituição pela lista de publicados. Confira título, endereço, site, atividades propostas e contribuições possíveis. Edite um campo e descarte. Reabra e confirme o valor original. Edite novamente e publique. Confira o resultado na página pública.
4. **Seção da atividade** — na gestão do documento de Atividades, expanda a ficha da instituição e edite uma atividade proposta. Troque a instituição no seletor, publique e confirme que o item aparece no destino e saiu da origem. Teste também em inglês e espanhol para registros já traduzidos.
5. **Site público** — confira a nova introdução de Atividades e o aviso de que as iniciativas dependem de acordo. Arquive um registro de teste e recarregue a página em cada idioma.
6. **Audiovisual** — confira os filtros Animação, Filme e Série, e os links oficiais. O acesso pode depender do país e do serviço.
7. **Revisão bíblica** — verifique se a apresentação diferencia propostas de parcerias confirmadas (Êxodo 20:16) e se as novas indicações apontam a fontes oficiais, sem reproduzir capas ou vídeos de terceiros (aplicação de prudência à luz de Êxodo 20:15).

## Validação local

Validador do site, 89 testes do painel, sintaxe JavaScript e geração do artefato GitHub Pages passaram sobre uma cópia da V45 com a atualização aplicada. A publicação e as operações autenticadas no Supabase ficam para a conferência no seu ambiente.
