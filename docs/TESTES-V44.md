# Roteiro de testes da v44

1. Confirme que o GitHub Pages publicou o commit da v44 e que **Tarefas administrativas** mostra `2026.11.05.1`.
2. Em **Acompanhar → Filmes**, confira os dois cartões. Abra os links, verifique as capas e compare as opções com a região da sua conta.
3. No painel, confira **Músicas e playlists**, **Palestras e lives**, **Conteúdos arquivados** e **Atualizar banco de dados**. A área de aprovação e a ação de buscar filmes devem estar ausentes.
4. Confirme no Supabase que `pge_videos` e `pge_video_decisions` estão vazias. Confira que sua playlist existente e os demais conteúdos continuam disponíveis.
5. No GitHub Actions, confirme que **Biblioteca e GitHub Pages** disponibiliza apenas a publicação do site. O workflow não deve executar busca agendada.

Verificação local realizada com PostgreSQL em memória, validador do site, testes do painel e montagem do artefato Pages. O teste da migração aplica a limpeza duas vezes, verifica as permissões e compara uma playlist e um artigo antes e depois. Repita a verificação na sua conta após publicar.
