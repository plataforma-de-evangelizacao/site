# Comece por aqui — atualização v43

Data: 04/11/2026. Backend esperado: **2026.11.04.1**.

1. Faça uma cópia do repositório atual antes de enviar o pacote.
2. Extraia o ZIP e envie seus arquivos para a **raiz do repositório existente**, preservando o restante. Não crie uma pasta `dist` no repositório se o site atual já publica da raiz.
3. Este pacote não substitui `admin/config.json`, `biblioteca-controle/config.json`, `fontes.json`, `editorial.json` nem os documentos existentes em `dados/`. Somente os três novos documentos compartilhados são incluídos: programas, plano bíblico e fontes legítimas. Seus conteúdos e decisões no banco são preservados.
4. Em Settings → Secrets and variables → Actions, confirme `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_ACCESS_TOKEN`, **`PLATFORM_DISPATCH_TOKEN`** e `YOUTUBE_API_KEY`. Não crie Secret começando com `GITHUB_`.
5. Faça o commit. Em Actions acompanhe **Atualizar plataforma** e **Biblioteca e GitHub Pages**. Se necessário, execute Run workflow em Atualizar plataforma na main. Não rode migrações antigas isoladamente depois da v43.
6. Quando ambos concluírem, abra o painel. Em Tarefas administrativas confira a versão instalada. O backend deve ser atualizado junto com o frontend.
7. Faça `docs/TESTES-V43.md`. O catálogo de filmes pode ficar menor ou vazio até revisar procedência: isso é a nova política de fontes, não perda dos registros.
8. Configure o kit Python separadamente, seguindo `scripts/backup/README.md`. Ele está incluído no mesmo pacote, mas precisa de suas credenciais locais e conexão ao PostgreSQL.

Não envie senha, token de gestão, chave de serviço nem frase de recuperação pelo chat. Os testes locais passaram sem acessar sua produção; a publicação e os testes reais permanecem para sua conta.

Se algo falhar, baixe o relatório de Diagnóstico e problemas e informe a etapa/código. Não apague o banco nem reenvie uma migração com checksum alterado.
