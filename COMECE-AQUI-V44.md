# Instalação da v44

1. Faça um backup do repositório e do Supabase com o kit da v43. A migração apaga os registros e as decisões do acervo antigo.
2. Confira se há buscas antigas em andamento em **GitHub → Actions**. Cancele essas execuções antes da atualização para evitar concorrência com a versão anterior.
3. Extraia o ZIP sobre o repositório atual. Inclua os arquivos ocultos da pasta `.github`. Faça commit e push para `main`.
4. No GitHub Actions, acompanhe **Atualizar plataforma** e **Biblioteca e GitHub Pages**. Se a migração ainda estiver pendente, entre como superadministrador e use **Tarefas administrativas → Atualizar banco de dados**. Na primeira implantação, se a função de disparo estiver indisponível, execute o workflow **Atualizar plataforma** manualmente na branch `main`.
5. Confirme a versão `2026.11.05.1` no painel e siga o roteiro em `docs/TESTES-V44.md`.

A atualização do banco usa os Secrets existentes, incluindo `PLATFORM_DISPATCH_TOKEN` para o token de disparo. Use o guia da v43 se precisar revisar a configuração. A publicação do site e a migração do banco têm resultados separados.

A branch histórica `biblioteca-estado` e os commits antigos continuam sob sua conta. O fluxo novo usa exclusivamente o código de publicação atual. Para eliminar cópias históricas, revise primeiro sua retenção e seus backups.
