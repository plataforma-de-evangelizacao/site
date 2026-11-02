# Painel administrativo da Plataforma Global de Evangelização

## O que foi entregue

Uma página própria em `admin/`, com login por e-mail e senha, revisão de vídeos, histórico de solicitações e editor dos JSON da plataforma. O rodapé do site tem o link **Administração**. Não existe senha padrão e não há comparação de senha dentro do HTML ou JavaScript.

O código foi implementado e testado localmente. **A autenticação e a comunicação real com o Supabase ainda precisam ser configuradas.** O painel entregue bloqueia o login enquanto `admin/config.json` estiver vazio. A proteção efetiva dos dados depende de executar o SQL de permissões e autorizar apenas seu usuário. Não foi criada uma conta Supabase nem definido um acesso em seu nome nesta entrega.

O GitHub Pages continua hospedando o site. Supabase Auth confere e-mail/senha; o banco aplica RLS; o GitHub Actions valida e grava os arquivos permitidos no repositório. O painel não recebe token de escrita do GitHub nem a chave da YouTube API. Não é necessário contratar um servidor tradicional.

## O que você pode fazer nesta versão

- Ver e pesquisar vídeos pendentes, aprovados, rejeitados e arquivados.
- Abrir um vídeo no YouTube, escolher sua categoria, confirmar o português e solicitar aprovação.
- Rejeitar ou arquivar um título, preservando o histórico da decisão.
- Editar projetos/cursos, parceiros, agenda solidária, prestação de contas, contato, louvores, leituras, lives, Spotify, artigos, estudos, livros, materiais, celebrações, atividades e coleções por seus JSON.
- Conferir a sintaxe do JSON antes de enviar e acompanhar se a solicitação foi gravada, entrou em conflito ou falhou.

A gestão dos demais conteúdos começa com um editor JSON organizado por área. Não há ainda formulário visual específico para cada tipo de conteúdo, upload de comprovantes, criação de novos administradores pelo painel ou editor de código/workflows. Isso evita apresentar ferramentas que ainda não existem.

## Como as alterações chegam ao site

Login → leitura dos dados autorizados → solicitação na fila privada → Actions valida o usuário e o conteúdo → commit no GitHub → execução explícita do workflow de publicação → site atualizado.

O workflow `admin.yml` verifica a fila aproximadamente a cada 15 minutos. O GitHub pode atrasar ou desativar agendas. É possível executar **Actions → Painel administrativo → Run workflow** para processar uma solicitação sem esperar o próximo horário. O painel não promete publicação instantânea.

O estado **Gravado no GitHub** confirma a alteração no código/dados, não o deploy. Confirme o job `publicar` em **Biblioteca e GitHub Pages** para saber se a mudança chegou ao site. Uma falha de deploy mantém a versão anterior no ar.

## Configurar gratuitamente

1. Faça backup do repositório atual. Copie a atualização recebida para os mesmos caminhos e faça commit. Inclua a pasta `admin/`, os scripts/testes administrativos, os dois workflows atualizados e a alteração de empacotamento em `scripts/biblioteca/run.py`. A versão completa atualizada também inclui o link no rodapé.
2. Crie uma conta/projeto no [Supabase](https://supabase.com/) e escolha uma organização no plano **Free**. Não selecione Pro, adicionais pagos, SMS, runner pago ou serviços pagos para seguir este guia. Confirme as condições da sua conta antes de cadastrar qualquer meio de pagamento; esta implementação não habilita cobrança.
3. No **SQL Editor** do projeto, abra uma consulta, copie o conteúdo de `scripts/admin/schema.sql` e execute. O script cria tabelas específicas `pge_*`, ativa RLS e limita as permissões. Use um projeto seu, destinado a esta plataforma; não execute em banco de outra aplicação sem revisar os nomes e permissões.
4. Em **Authentication → Users**, crie seu usuário de acesso com e-mail e uma senha forte, confirmando o usuário pelo fluxo oferecido no painel do Supabase. Esse é o acesso do aplicativo, distinto da conta usada para administrar o próprio Supabase. Não envie a senha pelo chat.
5. Copie o **UUID** do usuário criado. No SQL Editor, execute, trocando apenas o exemplo pelo UUID real:

   ```sql
   insert into public.pge_admins(user_id)
   values ('UUID_REAL_DO_SEU_USUARIO')
   on conflict do nothing;
   ```

   Essa autorização é feita apenas pelo administrador do projeto. O aplicativo não oferece cadastro público de administradores. Desative novos cadastros públicos de usuários nas configurações de Auth; mesmo que uma conta comum exista, ela não tem acesso sem estar na lista `pge_admins`.
6. Nas configurações de API/Connect do projeto, obtenha a **Project URL** e a chave **publishable** (`sb_publishable_...`). Se o projeto mostrar uma chave legada `anon`, ela também pode ser usada como chave pública. Preencha `admin/config.json`:

   ```json
   {
     "supabaseUrl": "https://SEU-PROJETO.supabase.co",
     "publishableKey": "SUA_CHAVE_PUBLICAVEL",
     "siteUrl": "../"
   }
   ```

   A URL deve ser a real do projeto. A publishable/anon é pública por definição; o controle de acesso é feito pelas políticas RLS e pelo token do usuário autenticado. **Nunca coloque `service_role`, `sb_secret_...`, senha ou `YOUTUBE_API_KEY` nesse arquivo.** O painel recusa chaves reconhecidas como privadas.
7. No GitHub, em **Settings → Secrets and variables → Actions**, crie dois Secrets novos:

   | Nome | Valor |
   | --- | --- |
   | `SUPABASE_URL` | URL do seu projeto Supabase |
   | `SUPABASE_SERVICE_ROLE_KEY` | Chave secreta do projeto (`sb_secret_...`) ou a legada `service_role`, obtida nas configurações do Supabase |

   Essa chave é privilegiada, passa pelas permissões administrativas do serviço e fica somente no runner. Proteja a conta GitHub e limite colaboradores que podem alterar workflows. Não cole a chave em arquivos, prints, URLs ou no chat. O Secret `YOUTUBE_API_KEY` existente continua no lugar.
8. Confira que o workflow **Painel administrativo** tem permissão de escrita de conteúdo e de disparo de Actions, conforme o YAML. A organização pode limitar essas permissões. Não remova proteção de `main` para fazer o painel funcionar; caso a política exija PR, a gravação direta será bloqueada e precisaremos adaptar para PR.
9. Execute **Actions → Painel administrativo → Run workflow**. Sem solicitações, ele apenas sincroniza os dados atuais da branch `biblioteca-estado` e os documentos. É preciso já existir essa branch da biblioteca, que suas execuções anteriores criaram.
10. Depois da publicação da atualização, abra `https://plataforma-de-evangelizacao.github.io/site/admin/`. Entre com o e-mail/senha do usuário que você criou. Você também encontra o acesso pelo rodapé do site.
11. Confira um vídeo real, envie uma decisão e execute o workflow administrativo. Confira a solicitação no histórico e o job de publicação. Só esse teste real confirma que a autenticação, as políticas, a fila e o deploy estão conectados na sua conta.

Se uma etapa pedir faturamento obrigatório para algo além do plano Free, pare antes de contratar. O plano gratuito tem limites: a documentação consultada informa 500 MB de banco, 50 mil usuários ativos mensais e possibilidade de pausa após uma semana de inatividade. Não há garantia de disponibilidade contínua ou backups gerenciados gratuitos. Confirme os limites atuais na sua conta.

## Proteção do painel

A página de login pode ser vista publicamente, como qualquer página do Pages. As tabelas de gestão só podem ser lidas após autenticação **e** autorização como administrador. A segurança não depende de esconder a URL nem de desabilitar botões.

- Anônimos não têm permissões sobre as tabelas `pge_*`.
- Uma conta autenticada sem autorização não pode ver vídeos, documentos ou solicitações administrativas.
- Usuários do aplicativo não podem inserir a si mesmos em `pge_admins`.
- O navegador só insere solicitações com o próprio UUID; não pode marcar uma solicitação como aplicada nem editar os dados diretamente.
- O Actions consulta novamente a lista de administradores antes de aplicar cada comando. Remover alguém da lista bloqueia suas solicitações ainda pendentes.
- Somente arquivos de uma lista permitida podem ser editados. Senhas, Secrets, configuração de login, SQL e workflows ficam fora do editor.
- Há comparação de versão antes de gravar, validação de JSON/estrutura e push sem força para `main`.
- Tokens de acesso ficam apenas na memória da aba, não em `localStorage`. Recarregar a página exige novo login. O encerramento de sessão limpa os dados da tela.
- Títulos e descrições de terceiros são exibidos como texto; o painel não interpreta HTML recebido dos vídeos.
- A página recusa execução dentro de iframe, e links de vídeos externos não recebem acesso à janela do painel.

As políticas de login, recuperação de senha e limites contra tentativas repetidas são fornecidas pelo Supabase Auth. Não há gerador de senha padrão nem senha da plataforma armazenada no repositório. Para recuperar o acesso, use os mecanismos do projeto no Supabase; redefinição por e-mail depende da configuração de entrega de e-mails do serviço. SMS e configuração de SMTP pago não fazem parte desta implementação.

## Aprovar vídeos e preservar suas escolhas

Use **Revisar vídeos → Aguardando revisão**. Abra o material no YouTube e confira. Para aprovar, escolha desenho/filme/série e marque que confirmou o conteúdo em português. A decisão fica em `biblioteca-controle/editorial.json`. O processamento existente reaproveita metadados recentes; não depende de uma nova pesquisa global para aplicar uma aprovação.

Uma rejeição explícita tem precedência sobre a regra automática. Um aprovado pode continuar fora da lista pública se estiver indisponível, com bloqueio regional ou com metadados vencidos. Aprovação editorial e elegibilidade técnica são estados diferentes.

Não aprove em lote conteúdos que você não conseguiu identificar. Classificação e fidelidade bíblica não são verificadas por assistir automaticamente aos vídeos. A autorização final do administrador é uma decisão editorial, não um certificado externo.

## Edição dos arquivos de gestão

Em **Conteúdos e gestão**, escolha a área e edite o JSON. O painel conserva os nomes técnicos dos campos e IDs, pois eles já alimentam o site. Você pode acrescentar links para materiais no Drive, vídeos, músicas e outros conteúdos conforme o formato atual de cada arquivo.

**Conferir JSON** verifica a sintaxe no navegador. **Solicitar publicação** envia à fila. O Actions repete a validação no runner, verifica se a versão ainda é atual e executa o validador do site antes de gravar. Um conflito exige atualizar os dados e revisar a edição; não é resolvido sobrescrevendo alterações alheias.

O editor é para conteúdos destinados ao site público. Não coloque comprovantes bancários, dados privados de beneficiários/crianças, senhas ou informações confidenciais nos JSON. Esta versão não é um sistema privado de atendimento a beneficiários ou contabilidade bancária.

Os arquivos em inglês/espanhol continuam com seu fluxo atual: esta primeira versão lista os arquivos compartilhados e os principais de português, sem tradução automática de uma edição. O texto original e os IDs não são alterados para simular traduções.

## Filas, concorrência e recuperação

A fila `pge_commands` registra UUID, usuário, ação, dados, estado, resultado e datas. O comando entra como `pending`, pode passar a `processing` e termina como `applied`, `conflict` ou `failed`. Ao finalizar, o conteúdo completo da edição é removido da fila, preservando identificadores, caminho e resultado no histórico; a versão efetiva continua no GitHub. O UUID vai no assunto do commit; se o runner cair após um push, a execução seguinte reconhece o commit e não reaplica a edição. A publicação pode ser solicitada novamente com segurança.

Os workflows administrativo e da biblioteca compartilham o mesmo grupo de concorrência, sem cancelar uma gravação em andamento. Isso impede que ambos alterem a mesma base simultaneamente pelo fluxo fornecido. Uma alteração externa concorrente continua protegida pelo push sem força e pela checagem de versão.

O campo `applied` significa gravado no GitHub. Se o job de publicação falhar, execute **Biblioteca e GitHub Pages → publicar-site** após resolver o erro; não apague a branch de estado. Em caso de falha entre commit e atualização do histórico, execute novamente o workflow administrativo para reconciliar pelo UUID.

Para reduzir tráfego no plano gratuito, uma rodada administrativa agendada sem solicitações aplicadas não reexporta todo o acervo; a sincronização ocorre nas publicações da biblioteca, em execução administrativa manual ou após alterações aplicadas.

A lista de vídeos do painel é uma cópia temporária, com validade máxima de 29 dias desde a verificação. O frontend oculta registros vencidos e as sincronizações removem entradas vencidas do banco. É necessário manter os jobs e acompanhar falhas; pausar o projeto ou deixar a sincronização parada não é uma política de retenção. Não guarde exportações de metadados de terceiros indefinidamente. As decisões editoriais autorais e os commits no GitHub preservam a recuperação do conteúdo.

Backups gerenciados do banco não estão incluídos nesta solução gratuita. Os documentos efetivos e decisões ficam versionados no GitHub; o banco contém os snapshots de trabalho, a lista de administradores e a fila. Antes de mudanças no SQL, exporte as configurações autorais e faça backup dos arquivos do repositório. Não exporte chaves ou senhas.

## Testes realizados e o que falta verificar

22 testes administrativos locais passaram: aprovação/rejeição, confirmação de idioma, IDs e categorias inválidas, conflitos, tamanho e sintaxe de documentos, caminhos proibidos, metadados vencidos, ausência de persistência de tokens no navegador, separação do artefato público, administrador revogado, commit sem força e retomada após falha de push.

Os 42 testes da biblioteca também passaram. As políticas SQL foram inspecionadas e as interações REST foram preparadas, mas **não foram executadas contra um projeto Supabase real**. A inspeção/testes locais não comprovam que as políticas estão ativas na sua conta.

Após configurar, confira com uma janela anônima que os dados administrativos não aparecem; confirme também que um usuário autenticado fora de `pge_admins` não tem acesso. Depois teste a aprovação de um vídeo, um JSON válido, um JSON inválido, uma sessão encerrada e a publicação no Pages. Não declare o painel ativado antes dessas verificações.

## Referências oficiais

- Hospedagem estática do Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- Segurança/RLS e chaves públicas/privadas: https://supabase.com/docs/guides/database/secure-data
- Políticas por linha: https://supabase.com/docs/guides/database/postgres/row-level-security
- Autenticação e usuários: https://supabase.com/docs/guides/auth/users
- Preços e limites do plano Free: https://supabase.com/pricing
