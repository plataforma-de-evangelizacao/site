# Correção do nome do Secret — 3/11/2026

O GitHub reserva o prefixo GITHUB_ nos nomes dos Secrets. A orientação anterior estava incorreta.

1. Cadastre PLATFORM_DISPATCH_TOKEN como Repository secret, usando o token que já gerou no GitHub. Não precisa gerar outro token.
2. Mantenha SUPABASE_ACCESS_TOKEN e os outros Secrets existentes.
3. Extraia este ZIP sobre a pasta local do repositório e faça commit/push. Inclua .github/workflows/atualizar-plataforma.yml.
4. Aguarde a nova execução de Atualizar plataforma, ou inicie Actions → Atualizar plataforma → Run workflow → main.

O workflow recebe secrets.PLATFORM_DISPATCH_TOKEN e o encaminha à variável interna GITHUB_DISPATCH_TOKEN. Essa variável e o Secret de servidor do Supabase continuam válidos; a restrição é no nome do Secret cadastrado no GitHub. Não altere o código da Edge Function para essa correção. Nenhum token deve entrar em arquivo ou no chat.
