# Relatório de validação — 3 de novembro de 2026 (UTC)

| Verificação local | Resultado |
|---|---|
| Administração Python | 62 testes aprovados |
| Biblioteca Python | 47 testes aprovados |
| Adaptador público Node | 8 verificações aprovadas |
| PostgreSQL local via PGlite 0.5.14 | 29 verificações aprovadas |
| Dados, traduções, IDs, âncoras e arquivos | Validação aprovada |
| Vitrine de projetos, disponibilidade e carregamento JSON | Verificação aprovada |

O PostgreSQL de teste executou o esquema original e a migração, inclusive uma segunda execução. Foram exercitados acesso anônimo e usuário sem permissão, aprovação, categoria, conflitos e rollback de lote, arquivamento/restauração, bloqueio, validade de metadados, publicação/remoção de projetos e relações com parceiros. A autenticação foi simulada. Não houve acesso ao Supabase ou GitHub da sua conta.

Os testes SQL são reproduzíveis com Node 22: `npm ci --prefix tests/admin/sql-test --ignore-scripts --no-audit --no-fund` e `node tests/admin/sql-test/test.cjs`. O workflow administrativo inclui essas verificações. PGlite é dependência de teste; não é carregado no site.

## Validação pendente na instalação real

Execute COMECE-AQUI-PUBLICACAO-DIRETA.md e ROTEIRO-TESTES-VIDEOS-E-PROJETOS.md. Confirme login, permissões da conta, disponibilidade do PostgREST e leitura das alterações no site publicado. Os testes locais não comprovam esses serviços externos.

## Limites desta entrega

A migração inicial ainda é executada manualmente no SQL Editor. Não foi criado executor de SQL no painel. Descobertas externas permanecem nas rotinas existentes; integração de busca musical/Spotify/podcast/live e tradução automática não foram ativadas. Conteúdo sem tradução usa português como alternativa. PDF de orações permanece para etapa posterior.

## Segurança do pacote

O ZIP de atualização não inclui admin/config.json, configurações editoriais da busca, chaves privadas, dependências instaladas ou demonstrações de autenticação. As cinco propostas sociais são planejamento, sem afirmar implantação ou parceria oficial.
