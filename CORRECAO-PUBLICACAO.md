# Correção dos checks de publicação

3 de novembro de 2026.

Os logs do commit `4115e06f585d56df0e83a4b9120802eea9d9b605` mostram dois problemas independentes:

1. **Biblioteca:** o teste `test_auto_eligible` dependia das regras reais do catálogo. No repositório, `approvedRules` está vazio e a aprovação automática está desativada. Essa configuração é válida. O teste agora usa regras fictícias próprias, sem modificar a configuração do site. Também testa que a aprovação continua pendente quando desativada.
2. **Atualizar plataforma:** os Secrets `SUPABASE_ACCESS_TOKEN` e `PLATFORM_DISPATCH_TOKEN` chegaram vazios ao workflow. O processo interrompeu antes de atualizar o banco.

## Aplicar

1. Extraia `correcao-publicacao.zip` dentro da pasta do repositório, substituindo `tests/biblioteca/test_core.py`. Faça commit e envie para `main`. O GitHub Pages fará uma nova tentativa automaticamente.
2. Em **Settings → Secrets and variables → Actions → Repository secrets**, cadastre os dois nomes exatos: `SUPABASE_ACCESS_TOKEN` e `PLATFORM_DISPATCH_TOKEN`. Não use Repository variables. As outras chaves existentes continuam iguais.
3. Para obter o token Supabase, use Account → Access tokens, com escopo limitado ao projeto e permissões `database_migrations_write`, `edge_functions_write`, `edge_functions_secrets_write`. O token GitHub deve ser fine-grained, limitado a este repositório e ter Actions: Read and write. Veja também LEIA-PRIMEIRO.md do pacote principal.
4. Depois do envio da correção e do cadastro dos Secrets, abra **Actions → Atualizar plataforma → Run workflow → main**. Inicie uma execução nova: não repita a execução antiga de um commit anterior, pois a proteção de versão bloquearia esse código antigo.

Esta correção não inclui configurações, chaves, banco ou arquivos de conteúdo. Os 64 testes da biblioteca passaram localmente usando a configuração exata do commit que falhou. A nova execução no GitHub e a autorização inicial do backend ainda precisam ser confirmadas na sua conta.
