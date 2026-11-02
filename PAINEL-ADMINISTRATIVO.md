# Painel administrativo — Plataforma Global de Evangelização

O painel usa o login Supabase já configurado. Nesta atualização, ele ganha menus por assunto, gestão em lote de vídeos, bloqueios persistentes e uma central para solicitar atualizações pelo GitHub Actions. Tema claro/escuro e português, inglês e espanhol continuam disponíveis.

## Instalar esta atualização no site existente

1. Baixe `atualizacao-painel-completo.zip` e extraia na pasta local do repositório `site`. Substitua os arquivos correspondentes, mantendo as pastas `admin`, `scripts`, `tests` e `.github` nos lugares indicados no ZIP. O ZIP de atualização **não contém `admin/config.json`**, nem altera seus Secrets, usuários ou decisões editoriais atuais. Não use uma instalação antiga do painel para sobrescrever a configuração já preenchida.
2. No mesmo projeto Supabase do painel, abra **SQL Editor**, cole o conteúdo de **`scripts/admin/atualizacao-painel.sql`** e execute uma vez. A resposta esperada é `Success`. O script mantém dados, usuários e políticas RLS. Acrescenta a ação `run_sync` e impede duplicação de uma mesma atualização enquanto ela estiver em andamento. Pode ser executado novamente com segurança. Para uma instalação nova, o `schema.sql` completo já inclui isso.
3. Salve os arquivos no Git, faça commit e envie para `main`, como já faz pelo VS Code. Confirme que a pasta `.github/workflows` foi atualizada; é uma pasta oculta em alguns gerenciadores de arquivos.
4. Aguarde **Biblioteca e GitHub Pages** concluir a publicação. Depois execute **Actions → Painel administrativo → Run workflow → main** uma vez para sincronizar a lista ampliada de conteúdos do painel. Não use a opção de repetir um workflow antigo, que pode usar código antigo.
5. Abra `/site/admin/`, recarregue a página e faça login. Confira a visão geral, as listas de conteúdo e os botões de atualização. As rotinas enfileiradas no painel são processadas pelo workflow administrativo aproximadamente a cada 15 minutos; executar esse workflow manualmente antecipa o processamento.

A configuração existente usa os Secrets `YOUTUBE_API_KEY`, `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY`. Não há uma nova senha a cadastrar nem chave privada para colocar no frontend.

## O que cada menu faz

| Menu | Utilidade |
| --- | --- |
| Visão geral | Quantidades de vídeos aguardando revisão, aprovados, bloqueados e solicitações em fila; atalhos para os conteúdos. |
| Acervo de vídeos | Busca por título, canal ou ID; filtros por situação/categoria; aprovação, exclusão e mudança de categoria individual ou em lote. |
| Vídeos bloqueados | Lista dos IDs rejeitados e possibilidade de remover o bloqueio, devolvendo o vídeo à revisão. |
| Músicas e playlists | Formulário para adicionar, editar e remover títulos/links nas listas de louvores, Spotify e YouTube. |
| Livros, podcasts e materiais | Atalhos para livros, artigos, estudos, materiais, lives, catálogo e listas de links. Podcasts podem ser cadastrados nas listas Spotify/YouTube. |
| Projetos e cursos | Projetos, formações, palestras e propostas sociais. |
| Parceiros e comunidades | Cidades, contatos, instituições, celebrações e atividades. |
| Solidariedade e contas | Ações, agenda de doações e prestação de contas. |
| Leituras e orações | Leituras bíblicas, orações, reflexões, louvores e versículos. |
| Todos os conteúdos | Editor dos arquivos autorais JSON e TXT permitidos, inclusive arquivos em inglês/espanhol. |
| Atualizações e integrações | Recarregar tela, sincronizar banco administrativo, buscar vídeos e publicar o site; acompanha andamento/erros. |
| Solicitações e histórico | Decisões, lotes, mudanças de conteúdo e resultado de cada solicitação. |

Os menus organizam os dados editáveis. O painel não é um editor visual de HTML/CSS, de credenciais ou de permissões. Alterações de layout estrutural ainda precisam ser feitas no código. Um arquivo de conteúdo só muda o site nas partes que já consomem esse arquivo; o painel não cria automaticamente páginas/integrações novas ao cadastrar um campo desconhecido.

## Selecionar e aprovar os vídeos de uma vez

1. Entre em **Acervo de vídeos** e escolha **Aguardando revisão**. Use busca ou categoria se quiser restringir o lote.
2. Marque **Selecionar todos os resultados deste filtro**. Isso inclui resultados ainda não exibidos nos primeiros 24 cartões. O painel mostra a quantidade selecionada. Alterar filtros limpa a seleção. Você também pode marcar ou desmarcar cartões individualmente.
3. Para aprovar, mantenha a categoria de cada vídeo ou escolha uma categoria para o lote. Se houver vídeos sem categoria, atribua uma antes de aprovar. O painel não inventa a categoria para completar um lote.
4. Marque a confirmação de revisão e de conteúdo em português. Clique **Aprovar selecionados** e confirme a quantidade no aviso. Cada envio aceita até **300 vídeos**; os 273 citados cabem em uma solicitação.
5. Acompanhe no histórico. O lote é validado por inteiro e gravado em um commit. Se um registro estiver desatualizado, o lote entra em conflito e nenhum item daquele lote é gravado; recarregue e revise a seleção.

**Não aprovar / bloquear selecionados** usa a mesma seleção e exige confirmação, mas não exige confirmar idioma. Entra no bloqueio persistente descrito abaixo.

**Alterar categoria dos selecionados** salva a categoria escolhida, conservando a situação editorial. Alterar categoria não equivale a aprovar um vídeo pendente nem a desbloquear um rejeitado. Cada cartão também oferece **Salvar categoria**.

A aprovação editorial não elimina exigências técnicas: vídeo indisponível, metadados vencidos ou restrição regional podem impedir a exibição pública.

## Excluir um vídeo e impedir que volte

1. Em **Acervo de vídeos**, selecione **Aprovados** ou **Todos** e procure o título, canal ou ID.
2. Clique **Excluir e bloquear** e confirme o título.
3. O Actions registra `aprovacao: rejected`, `revisado: true` e `reabrir: false` para esse ID em `biblioteca-controle/editorial.json`. Depois da publicação, o vídeo sai do catálogo.
4. A descoberta consulta esse registro antes de pedir os detalhes do vídeo. O bloqueio vence a aprovação automática e continua ativo depois que os metadados temporários são removidos. Não é apenas uma mudança visual na tela.

O bloqueio é pelo **ID do vídeo**, não por palavras do título. Se outro canal publicar o mesmo filme, o novo envio terá outro ID e poderá aparecer para revisão. O bloqueio permanece mesmo que o título original mude.

Em **Vídeos bloqueados**, procure o ID ou o título disponível e escolha **Remover bloqueio e revisar**. A remoção usa a versão do registro editorial para evitar conflito e devolve o item a `pending_review`; a aprovação automática não atropela essa revisão explícita. Se os metadados já venceram, ele só voltará à lista de revisão com título após uma descoberta/verificação que recupere seus dados. A lista de bloqueios mantém o ID mesmo sem título.

## Músicas, playlists e podcasts

Em **Músicas e playlists**, selecione a lista:

- **Louvores do dia** → `dados/louvores.json`.
- **Spotify: playlists e podcasts** → `dados/spotify.json`.
- **Playlists do YouTube** → `dados/youtube.json`.

Use o formulário para adicionar título/link, **Editar** para carregar um item no formulário ou **Excluir da lista** para removê-lo. A edição preserva campos adicionais existentes no item. Links devem usar HTTP/HTTPS. Um louvor pode ter só título; Spotify e playlists precisam de link. Cada alteração entra na mesma fila de validação e publicação. Se houver uma alteração nessa lista na fila, aguarde sua aplicação e recarregue antes de enviar outra, para evitar sobrescrever uma edição anterior.

O cadastro de links funciona agora. **A descoberta automática de músicas, playlists externas, Spotify, podcasts e lives ainda exige implementar/configurar suas rotinas e APIs.** Os botões externos correspondentes aparecem como integração a configurar. Eles não simulam uma conexão ativa. Excluir uma música hoje remove o item do arquivo; não afirma bloquear uma descoberta musical que ainda não está implementada.

## Central de atualizações

| Botão | Efeito real |
| --- | --- |
| Recarregar painel | Busca novamente vídeos, documentos e solicitações do Supabase, sem cache HTTP e sem nova busca no YouTube. A barra mede as três fontes carregadas. |
| Atualizar banco do painel | Enfileira a sincronização dos arquivos atuais e do estado existente da biblioteca para o Supabase. Não busca vídeos novos. |
| Buscar novos vídeos no YouTube | Enfileira o workflow `biblioteca.yml`, modo `buscar-agora`, com o UUID da solicitação. Antecipa uma rodada de descoberta e renova resultados de busca completos em cache, preservando tarefas pendentes e limites de quota. |
| Atualizar informações no site | Enfileira `biblioteca.yml`, modo `publicar-site`. Reconstrói/publica o conteúdo atual, sem pesquisa global nova. |

Os percentuais são **marcos de execução**, não tempo decorrido: fila 0%, despacho 10%, testes 20%, processamento 40%, aguardando publicação 80%, conclusão 100%. Não há uma animação que promete progresso enquanto o GitHub está parado. Se o workflow falhar, a solicitação fica com erro e um link para os detalhes da execução quando disponível. O painel consulta o andamento a cada 10 segundos enquanto estiver aberto e visível. Não há notificação por e-mail/WhatsApp nesta atualização.

O workflow administrativo continua sendo o executor privilegiado: o navegador não recebe token do GitHub nem a chave do YouTube. Usuário autorizado envia apenas um destino permitido: `video-discovery`, `panel-sync` ou `site-publication`. Não é possível escolher um comando shell ou workflow arbitrário pelo formulário.

A fila pode levar aproximadamente 15 minutos para começar, além do tempo do GitHub e da API. Quotas, rede, concorrência, falha de implantação ou pausa do Supabase podem atrasar ou interromper uma atualização. O workflow administrativo reconcilia execuções já despachadas e não as dispara novamente só porque o painel foi recarregado. Se não houver confirmação de início após uma hora, ele registra a falha para que você confira o Actions antes de tentar novamente.

**Gravado no GitHub** significa que a decisão de conteúdo foi salva; a publicação é uma etapa posterior. Na central de atualização, **Site publicado e processamento concluído** só é informado depois do job de publicação e da confirmação de implantação. Uma busca sem mudança pública pode concluir sem novo deploy.

## Editor de conteúdos

Cada menu aponta os arquivos correspondentes. **Todos os conteúdos** permite localizar uma seção por nome ou caminho e editar arquivos autorais em `dados/`. JSONs preservam sua estrutura e TXT preservam o formato de texto usado na plataforma. O catálogo gerado da API, configuração de acesso, scripts, SQL e workflows ficam fora da edição.

O botão **Conferir JSON** verifica sintaxe para JSON e conteúdo não vazio para TXT. O servidor repete a validação antes de gravar, confere a versão e executa o validador do site. Conflitos não são resolvidos sobrescrevendo versões alheias. As versões efetivas permanecem no GitHub. Arquivos de idiomas diferentes devem ser editados explicitamente; esta atualização não traduz automaticamente o conteúdo de um artigo ou projeto.

## Acesso, proteção e recuperação

Login e políticas RLS anteriores continuam valendo: anônimos não leem a gestão; uma conta autenticada precisa estar em `pge_admins`; o cliente só pode criar solicitações próprias pendentes. A nova migração não amplia as permissões dessas contas. A chave privilegiada fica apenas no runner. Tokens do login ficam na memória da aba e são apagados ao sair. Recarregar a página exige entrar novamente.

Os workflows continuam compartilhando a mesma fila de concorrência, com push sem força para `main`. Arquivos de conteúdo são verificados por versão. Os IDs de comandos no commit permitem recuperar falhas após gravação. Não coloque dados privados de beneficiários, comprovantes, senhas ou chaves nos conteúdos públicos.

Para recuperar uma publicação que falhou, confira o erro no Actions, resolva-o e solicite **Atualizar informações no site**. Não apague os bloqueios editoriais ou a branch `biblioteca-estado`. Se uma conta deixar de ser administradora, seus comandos pendentes são recusados antes de gravação/despacho.

## Verificação desta entrega

Testes locais cobrem aprovação em lote, conflito atômico, confirmação de idioma, categorias, bloqueios persistentes, restauração sem metadados, proteção de caminhos, arquivos autorais, destinos permitidos de atualização e preservação de permissões. A interface foi exercitada com dados simulados locais; nenhuma conta real foi usada nesses testes.

A execução completa na sua conta depende de publicar os arquivos, aplicar a migração e testar uma solicitação real. Não foi executada a migração ou acionado o seu GitHub a partir desta entrega.
