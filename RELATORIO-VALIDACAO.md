## 3/11/2026 — edição editorial de vídeos, v42

Consulte **ATUALIZACAO-TITULOS-VIDEOS.md**: validação local de textos editoriais, publicação, conflitos e permissões; instalação real e teste visual autenticado ainda pendentes.

# Validação — atualização automática do backend

**3 de novembro de 2026 · 2026.11.03.3**

| Verificação local | Resultado |
|---|---|
| Administração Python | 81 testes aprovados |
| Biblioteca Python, incluindo medição da API | 64 testes aprovados |
| Adaptador público Node | 8 verificações aprovadas |
| Sessão por aba e inatividade Node | 7 verificações aprovadas |
| Autenticação, disparo e manutenção Node | 10 verificações aprovadas |
| Indexação automática Node | 10 verificações aprovadas |
| Marcadores, tempos medidos e duração final Node | 3 verificações aprovadas |
| PostgreSQL local — publicação, conflitos e títulos | 32 verificações aprovadas |
| PostgreSQL local — pacote de migrações e diagnóstico | 12 verificações aprovadas |
| JSONs, traduções, âncoras, arquivos, JavaScript e YAML | Verificações aprovadas |

## O que foi exercitado

O PostgreSQL local via PGlite executou o pacote SQL completo, repetiu a instalação sem duplicar versões, preservou um projeto existente, recusou checksum divergente e bloqueou pacote anterior ao histórico do banco. Conferiu também que anônimos e usuários sem autorização não consultam o diagnóstico privado, que administradores podem ler mas não escrever diretamente nesse estado, e que o serviço registra o resultado.

Os testes Python do atualizador usam transportes simulados para a Management API: endpoint fixo de migração, envio de segredos apenas servidor a servidor, multipart da função com autenticação própria, tratamento de erro sem divulgar resposta privada e confirmação posterior da versão. Uma falha ao publicar função não é tratada como instalação concluída. Pedidos de administradores revogados são recusados.

No navegador local, com respostas de teste, foram vistos a guia Tarefas administrativas, a diferença entre versão instalada e pacote, uma migração pendente, as etapas de banco/funções/verificação e a conclusão com zero pendências sem F5. As demonstrações não fazem parte do ZIP.

A medição da API distingue pedido enviado, retorno recebido e tentativa repetida. O timeout de rede não é exibido como contagem regressiva. A duração final do trabalho é congelada no instante da conclusão, em vez de continuar crescendo depois.

## O que ainda precisa ser validado na sua conta

Não alteramos seu Supabase nem seu GitHub. Cadastro inicial dos Secrets, autorização de gestão, execução da Management API, publicação real da função, login real e integração com os executores da sua organização dependem de instalar e seguir TESTE-RAPIDO-ATUALIZACAO.md. Os testes de transporte simulados não comprovam as permissões ou disponibilidade dos serviços externos.

Depois da primeira autorização, o código automatiza a aplicação das migrações e a publicação da função. Tokens expirados/revogados ainda precisam ser renovados nos Secrets. Descobertas Spotify/música/podcast/live continuam pendentes de implementação e autorização específicas.

## Documentação técnica consultada

- Management API — migrações: https://supabase.com/docs/reference/api/v1-apply-a-migration
- Publicação de função: https://supabase.com/docs/reference/api/v1-deploy-a-function
- Segredos do projeto: https://supabase.com/docs/reference/api/v1-bulk-create-secrets

O atualizador aceita somente o manifesto de versões do repositório. Não há endpoint de SQL arbitrário exposto no site e o token de gestão não é enviado ao navegador.

Correção posterior: o teste de aprovação automática foi isolado das regras reais. A biblioteca passou com a configuração do commit 4115e06f585d56df0e83a4b9120802eea9d9b605 (sem regras e com aprovação automática desativada). Isso é validação local; não confirma reexecução no GitHub.
