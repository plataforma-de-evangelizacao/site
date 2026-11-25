# Compatibilidade V49 — 25/11/2026

Base oficial verificada: b87d7e00500d2db7a7c250c3e908763633ef8c31 (V46). Revisão visual: 397577f6d2843c82dbcba1323bbdf06025a4d789 (Sites).
A publicação paralela em /site/v49/ mantém os endereços operacionais, dados, autenticação e workflows originais. A página inicial antiga contém um link para a nova plataforma.
- Home, Projetos, Biblioteca, Atlas, Participar, Área do Aluno: interface revisada, catálogos locais e filtros. Dados de produção antigos permanecem na versão operacional.
- Administração: prévia navegável e ligação com o painel autenticado existente; nova aparência aplicada ao painel real, sem modificação de autenticação.
- Área do Aluno: 22 propostas, sete programas; código original V48 recuperado em aluno/ e materiais de integração em docs/v48-integracao/. A configuração de autenticação existente foi preservada, mas não se declara a migração ou a emissão de certificados ativada.
- O publicador permite somente a pasta pública v49 e aluno além da lista anterior. Sem alteração das credenciais; workflow administrativo inclui a suíte editorial corrigida. Não se publica a configuração de demonstração do Sites.
- README: resolvido conflito textual pré-existente.
- Pendências antes de substituir a versão operacional: reconciliar catálogos dinâmicos e links antigos; validar as RPCs de aluno e permissões no Supabase; validar a integração de matrículas e administração com ambiente de testes; somente depois promover a V49 à raiz.

## Resultado das verificações locais
- Validação estrutural da versão operacional: passou.
- Python administração: 89 testes passaram. Biblioteca: 69 testes passaram.
- PostgreSQL local: suítes base, manutenção, V43 e V44 passaram (incluindo 32, 12 e 22 verificações nas três primeiras).
- JavaScript administrativo: seis suítes passaram. O teste antigo de edição de metadados da ingestão automática foi substituído por um teste do fluxo editorial atual (`workspace.js` e `forms.js`): filtros, busca, edição de título e descrição, preservação da fonte, revisão esperada, descarte e conflito. O workflow administrativo passa a executar essa suíte também.
- Artefato Pages gerado localmente com `scripts/publicar_site.py`: páginas V49, admin e aluno presentes; referências locais das páginas V49 conferidas.
- Não houve teste de autenticação em produção, aplicação da migração V48, nem alteração no banco.
- Publicação remota: primeira tentativa de gravação recusada com HTTP 403 (sem acesso de escrita pela integração). Nenhum commit remoto criado.
