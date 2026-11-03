# Aprovação automática ativada na configuração desta atualização

A execução real enviada por Marcos confirmou a API e a descoberta: 272 vídeos novos, 273 pendentes (incluindo o teste), sem erros e sem tarefas restantes. O catálogo não mudou porque a aprovação estava desligada.

Esta atualização habilita `autoApprovalEnabled` e uma regra inicial de seleção por metadados. Não basta trocar false por true em uma lista de regras vazia. Copie também os scripts atualizados.

A regra exige título com indicação de produção audiovisual e contexto bíblico explícito, duração mínima de quatro minutos (vinte para filmes), categoria identificável e português declarado no áudio da API ou, quando não houver declaração de áudio, no título. Uma declaração de áudio em outro idioma impede a aprovação por essa regra. Trailers, análises, músicas, pregações, resumos e formatos excluídos continuam pendentes. Rejeições e bloqueios são respeitados.

Essa seleção é automática por informações declaradas na origem: não significa que o vídeo foi assistido, que a idade foi certificada ou que a adaptação foi conferida teologicamente. Nenhuma referência bíblica é inventada. Casos sem informação suficiente continuam em revisão.

Para aplicar: copie `biblioteca-controle/config.json`, `scripts/biblioteca/core.py`, `scripts/biblioteca/run.py` e `tests/biblioteca/test_core.py` para os mesmos caminhos do repositório e faça commit. O ID do vídeo de teste já informado foi preservado. Não altere Secrets nem apague a branch `biblioteca-estado`.

Depois execute **Actions → Biblioteca e GitHub Pages → Run workflow → atualizar**, em `main`. Os metadados recentes dos vídeos encontrados serão reprocessados sem repetir buscas ainda válidas. Confira o último resumo: `approvedPublic` mostra os títulos elegíveis publicados/para publicar e `pendingReview` os restantes. O deploy só está confirmado quando o job `publicar` termina com sucesso.

Validação desta atualização: 42 testes locais passaram, incluindo casos específicos de aprovação, idioma ausente/conflitante, trailer e rejeição preservada. A alteração ainda não foi aplicada ao GitHub por esta conversa; use o pacote ou os arquivos indicados.

---

# Biblioteca Bíblica Audiovisual — implementação V3

## Estado desta entrega

Código preparado e testado localmente, integrado ao catálogo do site. A chave da API não foi fornecida nem utilizada. A automação e a publicação desta versão ainda precisam ser ativadas no GitHub e verificadas com um teste real. Não há filmes fictícios publicados para preencher o catálogo.

Repositório inspecionado em 2 de novembro de 2026: `plataforma-de-evangelizacao/site`, público, branch `main`, site estático HTML/CSS/JavaScript na raiz. A pasta `.github` não existia no repositório consultado. A última execução encontrada era `pages build and deployment`, dinâmica do Pages, concluída com sucesso em `main`. A configuração administrativa exata da origem do Pages não pôde ser lida pelo conector; confira-a nos passos abaixo. Não foram alteradas configurações ou arquivos remotos nesta entrega.

A especificação V3 e seus adendos substituem as propostas anteriores de automação audiovisual. Os demais conteúdos e integrações da plataforma continuam preservados.

## Como Actions e Pages trabalham juntos

O Pages entrega os arquivos estáticos. O Actions executa Python periodicamente e gera os JSON. O visitante só lê esses JSON: buscar, filtrar e navegar não chama a YouTube Data API.

Fluxo: código e decisões editoriais em `main` → workflow diário → filas e cache → metadados da API → aprovação → catálogo público → artefato do Pages → publicação explícita.

Não basta fazer um commit com `GITHUB_TOKEN` e esperar o Pages atualizar: esse tipo de commit não dispara uma nova construção do Pages. Por isso o workflow inclui a publicação via `actions/deploy-pages`.

## Configuração no GitHub, passo a passo

1. Faça uma cópia da versão que está funcionando. Extraia o ZIP atualizado e copie os arquivos para o repositório no VS Code. Inclua a pasta oculta `.github/workflows` e preserve seus próprios arquivos. O `index.html` deve continuar na raiz do repositório, junto com `assets`, `dados` e `scripts`; não coloque o ZIP inteiro dentro de uma subpasta. Envie as alterações ao GitHub como você já faz.
2. Abra o repositório no GitHub, entre em **Settings → Pages → Build and deployment → Source** e selecione **GitHub Actions**. Não crie um segundo workflow de site estático: o arquivo `biblioteca.yml` já publica o site. Ele também publica alterações normais feitas em `main`.
3. Em **Settings → Actions → General**, confirme que as ações oficiais do GitHub estão permitidas. O YAML pede `contents: write` somente ao job que salva o estado; o job de publicação pede `pages: write` e `id-token: write`. Se a organização bloquear essas permissões, ajuste apenas a regra necessária com o administrador. Não remova a proteção de `main`.
4. Confirme que o ambiente **github-pages** permite publicar a partir de `main`. O workflow usa esse ambiente. Se você configurar aprovação obrigatória nesse ambiente, cada deploy precisará dessa aprovação e deixará de ser totalmente automático.
5. Antes de configurar a API, confirme que o repositório e o runner se enquadram nos recursos gratuitos. A configuração entregue usa `ubuntu-latest`, sem runner maior, sem servidor pago e sem dependências pagas. O repositório consultado é público. Não mude para um plano pago ou habilite cobrança de excedentes para usar esta solução. Se tornar o repositório privado, reveja a elegibilidade gratuita do Pages e do Actions antes de ativar.
6. Crie e configure a chave conforme a seção seguinte. Depois abra **Settings → Secrets and variables → Actions → New repository secret**. Nome: `YOUTUBE_API_KEY`. Valor: sua chave. Cole a chave somente no GitHub, nunca no chat, no JSON, em arquivos `.env` enviados ao repositório ou no JavaScript da página.
7. Em `biblioteca-controle/config.json`, preencha `smokeVideoId` com o ID de um vídeo público conhecido e pertinente. O ID tem 11 caracteres; é o valor depois de `v=` em um link normal do YouTube. Não coloque uma URL completa nesse campo. Faça commit dessa configuração.
8. Abra **Actions → Biblioteca e GitHub Pages → Run workflow**. Selecione **teste-api**. Esse modo executa apenas uma consulta `videos.list` para o ID configurado, sem buscas globais e sem publicar o catálogo. Confira o resumo do job: deve indicar `smoke: success` e `returned: true`. Só após esse resultado podemos afirmar que a API está conectada.
9. Execute manualmente o modo **atualizar**. Confira o resumo, as chamadas, os candidatos e as pendências. O workflow cria a branch operacional `biblioteca-estado`; ela não substitui nem sobrescreve `main`.
10. Revise os primeiros candidatos conforme a seção editorial. Depois faça commit das decisões em `main`. O push aplica as decisões aos metadados recentes já obtidos, sem uma busca nova desnecessária, e publica o catálogo elegível.
11. Abra o site e entre em **Filmes, desenhos e inspiração**. Confira filtros, miniaturas, leitura relacionada e o player. Verifique pelo menos um vídeo real; os testes com mocks não comprovam a reprodução daquele vídeo.
12. Depois deixe o agendamento diário ativo. Em caso de falha, leia o resumo do job e o artefato de backup. A publicação só é considerada verificada quando o job `publicar` conclui com sucesso e a versão aparece no endereço do Pages.

## Configuração gratuita no Google

1. Entre no Google Cloud Console com sua conta e crie ou escolha um projeto para esta integração. Não associe uma conta de faturamento por causa deste recurso.
2. Abra **APIs e serviços → Biblioteca**, procure **YouTube Data API v3** e habilite a API. Esta implementação usa leitura de vídeos públicos com chave de API, sem OAuth e sem dados privados de usuários. Se a sua conta/tela exigir cartão ou faturamento para continuar, pare e confira o requisito antes de aceitar qualquer opção paga.
3. Em **APIs e serviços → Credenciais**, crie uma chave. Restrinja **API restrictions** à **YouTube Data API v3**.
4. Não use restrição por HTTP referrer para essa chave: quem faz a chamada é o runner, não o navegador. Runners hospedados padrão não fornecem um único IP fixo para uma restrição simples de servidor. Não contrate runner de IP fixo. Use a restrição à API, mantenha o segredo no Actions e confira a recomendação atual do Google para sua organização.
5. Abra a página de quotas do projeto e confirme os valores reais. A documentação consultada indica, por padrão, 100 chamadas diárias de `search.list` e 10.000 unidades diárias combinadas para os demais endpoints. A configuração entregue limita cada execução a 20 buscas e 100 chamadas dos demais endpoints e aplica uma margem diária de segurança de 20%. As tentativas também são contadas. Outros sistemas usando o mesmo projeto consomem a mesma quota; o contador local não consegue conhecê-los.
6. Não solicite ampliação de quota paga. Se a quota do seu projeto for menor, reduza os valores de `dailySearchCalls`, `dailyOtherUnits`, `maxSearchCallsPerRun` e `maxOtherCallsPerRun` antes de executar. Confirme a configuração real no Console, não apenas neste arquivo.
7. Cadastre a chave como Secret e execute o teste pequeno. Não ative faturamento para corrigir erro de chave, permissão ou quota.

Não foi acessada sua conta Google Cloud nesta entrega; cadastro, elegibilidade da sua conta, quota real e chave ainda dependem dessa configuração.

## Arquivos e responsabilidades

| Caminho | Para que serve |
| --- | --- |
| `assets/biblioteca.js` e `.css` | Busca local, filtros combinados, cartões, paginação de 24 itens, player sob demanda e interface PT/EN/ES. |
| `dados/biblioteca/catalogo.json` | Catálogo público inicial e ponto de leitura do frontend. O workflow gera a versão efetiva a partir do estado operacional. |
| `dados/biblioteca/taxonomia.json` | 66 livros iniciais, IDs, quantidade de capítulos e destino da leitura bíblica. Extensível por revisão editorial. |
| `dados/biblioteca/colecoes.json` | Coleções temáticas, com `id`, `titulo` e lista `videos` de IDs. |
| `biblioteca-controle/config.json` | Intervalos, orçamento, guardas de indisponibilidade, cache e regras aprovadas. |
| `biblioteca-controle/fontes.json` | Consultas, canais, playlists e bloqueios. |
| `biblioteca-controle/editorial.json` | Decisões e referências conferidas por vídeo. |
| `scripts/biblioteca/core.py` | Descoberta, classificação, disponibilidade, filas, quota, auditoria e validação. |
| `scripts/biblioteca/run.py` | Orquestração, checkpoints, branch de estado, geração do site e confirmação de deploy. |
| `.github/workflows/biblioteca.yml` | Agenda diária, teste manual, testes automáticos, backup e publicação. |
| `tests/biblioteca/test_core.py` | Testes locais sem consumir quota. |

Os arquivos de configuração e os dados operacionais ficam fora do artefato do Pages. **Isso não os torna privados:** em um repositório público, as branches e os artefatos acessíveis a colaboradores/visitantes conforme as regras do GitHub não são um cofre. Não coloque dados pessoais, notas confidenciais de moderação ou credenciais nesses arquivos. O Secret é o lugar da chave.

## Filas e persistência

A branch `biblioteca-estado` guarda `estado.json` e `catalogo.json`. O estado contém `queues`, `rounds`, `cache`, `videos`, `records`, `checks`, `quota` e relatórios recentes. Cada tarefa registra identificador, operação, alvo, criação, última tentativa, tentativas, prioridade, próxima data elegível, estado e erro resumido.

As três filas são independentes. A agenda diária apenas torna novas rodadas elegíveis após 10, 15 ou 25 dias. Rodadas antigas continuam abertas enquanto houver pendências; os próximos vencimentos continuam sendo calculados. Tarefas equivalentes pendentes não são duplicadas. O processamento alterna as filas, priorizando tarefas antigas dentro de cada uma.

Quando não há rodada nova vencida, a continuação usa até 10% do orçamento por execução configurado: inicialmente 2 chamadas de busca e 10 dos outros endpoints. Não é quota adicional do Google. Há também limite de cinco minutos de processamento por execução.

Reservas de quota são salvas antes das chamadas; resultados e progresso são gravados após lotes confirmados. Cada checkpoint atualiza a branch com `force-with-lease` sobre o SHA conhecido: se outra alteração apareceu, o push falha em vez de sobrescrevê-la. A execução seguinte relê o estado remoto. A branch contém um único snapshot alcançável, sem acumular um histórico permanente de títulos e descrições da API. O código e as decisões editoriais continuam com histórico normal em `main`.

Uma tarefa deixada como `processing` por uma interrupção torna-se elegível novamente após 15 minutos. Repetir um lote é seguro por deduplicação e cache. Erros temporários usam tentativas HTTP limitadas, backoff e `Retry-After`; a tarefa fica para o dia seguinte, com limite de dez tentativas de tarefa antes de exigir investigação. Falhas permanentes ficam registradas, sem repetição infinita.

## Disponibilidade e catálogo válido

`videos.list` é chamado em lotes de até 50 IDs, comparando IDs pedidos com IDs retornados. Uma falha de rede não transforma vídeos em removidos. Uma primeira ausência válida é suspeita e preserva o cartão anterior; uma confirmação posterior pode ocultá-lo. Se mais de 10% dos ativos de um lote sofrerem novas indisponibilidades, a guarda suspende as alterações desse lote. Em catálogos pequenos, um único vídeo pode acionar essa guarda: revise o caso antes de alterar o limite.

Vídeos com incorporação proibida podem continuar como links do YouTube; o modal oferece a alternativa sem tentar burlar a restrição. Vídeos com bloqueio para o Brasil ficam fora do catálogo público gerado. A API não garante que o player funcionará em todos os países, dispositivos e contas: erros do player exibem a alternativa externa.

Verificações sem mudanças nos dados relevantes preservam o registro público. A data técnica confirmada fica em `checks`. Um campo global `validUntil` acompanha a validade do conjunto e pode mudar em uma renovação de disponibilidade, exigida pela retenção de metadados. Isso não reescreve a ficha só para atualizar sua data. Quando o hash público não muda, não há deploy apenas por haver novas tarefas ou relatórios internos.

O YouTube exige atualização/remoção periódica de dados de API. A configuração usa 29 dias. Dados vencidos são removidos do cache, dados descritivos antigos são apagados do estado e conteúdos sem verificação recente deixam a publicação. O navegador também deixa de exibir o conjunto quando `validUntil` vence. Se o Actions parar, a solução prioriza não exibir indefinidamente metadados antigos; isso não substitui acompanhar falhas e o agendamento.

## Revisar e aprovar candidatos

A primeira busca é automática, mas a aprovação automática começa desligada. Um canal aprovado é fonte prioritária, não aprovação de todos os seus vídeos. Os candidatos ficam em `records` no estado com `aprovacao: pending_review`. Consulte a branch `biblioteca-estado`, abra `estado.json` e procure por esse estado; os relatórios mostram a quantidade.

Depois de assistir/conferir o material, acrescente uma entrada a `biblioteca-controle/editorial.json`, usando o ID real como chave. Exemplo de estrutura, **não copie o identificador de exemplo como conteúdo real**:

```json
{
  "ID_REAL_DO_VIDEO": {
    "revisado": true,
    "aprovacao": "approved",
    "categoria": "desenho",
    "idioma": "pt-BR",
    "idiomaVerificado": true,
    "publico": "família",
    "testamento": "antigo",
    "livros": ["jn"],
    "personagens": ["Jonas"],
    "temas": ["arrependimento", "misericórdia"],
    "referencias": [{"livro": "jn", "capitulo": 1, "revisada": true}]
  }
}
```

O exemplo só ilustra campos. A associação a Jonas precisa corresponder ao vídeo real. Não deduza capítulos e versículos apenas pelo título. A validação verifica livro e capítulo; a precisão dos versículos e a relação da adaptação com a passagem dependem da revisão humana. Não são inventadas sinopses: por padrão a descrição vem da fonte, e você pode substituí-la por uma descrição autoral no campo `descricao`.

Para séries, use `serieId` estável, `temporada` e `episodio` inteiros positivos. Classificações de episódios conflitantes vão para revisão. Use `formato` para distinguir episódio, curta, longa ou filme completo. Não rotule como completo um trailer ou um trecho.

Para rejeitar, use `aprovacao: rejected`. Para arquivar, `archived`. Um rejeitado não é reintroduzido por uma busca. Para reabrir de forma explícita, acrescente `reabrir: true` à decisão revisada. A fonte pode bloquear um ID em `blockedVideos` ou um canal com `blocked: true`.

Não invente idioma, legenda, dublagem, idade recomendada ou fidelidade bíblica. A publicação inicial exige idioma português verificado. A interface é traduzida, mas não traduz o áudio dos vídeos. Outros idiomas poderão ser acrescentados mediante mudança editorial explícita.

## Fontes e regras para automatizar aprovações

Em `fontes.json`, cada canal pode ter `{"id":"ID_DO_CANAL","approved":true,"blocked":false}` e cada playlist `{"id":"ID_DA_PLAYLIST","approved":true,"blocked":false}`. Canais usam a playlist de uploads; playlists usam `playlistItems.list`; só depois entram as pesquisas globais. Não cole os links antigos de playlists sem confirmar seus IDs completos.

A pesquisa inicial tem três consultas gerais. Você pode adicionar consultas por personagem ou história. Cada consulta tem cache e no máximo duas páginas por rodada. O cache inclui parâmetros normalizados, algoritmo, expiração, IDs e paginação. As buscas gerais usam relevância para também encontrar produções antigas, sem depender só da data de publicação.

Quando houver um padrão editorial realmente conferido, você pode habilitar `autoApprovalEnabled` e criar `approvedRules`. Cada regra precisa de `approved: true`, `id`, `channelId`, `titlePattern` e os campos editoriais seguros, como `categoria`, `idioma`, `idiomaVerificado` e `publico`. Evite padrões amplos como `.*`: use uma série/título já revisado. Regras aprovam apenas a combinação prevista e não preenchem referências bíblicas desconhecidas. Filmes incertos continuam pendentes. Avaliar canais e definir essas regras ainda depende de você.

## Backup, falhas e recuperação

O workflow cria um artefato `biblioteca-backup-NÚMERO` com retenção de sete dias, contendo o estado, catálogo e relatório. Somente os arquivos públicos permitidos entram no Pages; filas e controles não entram. O backup não é uma hospedagem permanente dos metadados do YouTube.

Se o processamento ou JSON falhar, o deploy não é iniciado e o site continua com a última versão válida publicada. Se o deploy falhar, o estado fica sem confirmação de publicação; a execução diária seguinte tenta publicar novamente o hash pendente. A confirmação só é gravada após sucesso do `deploy-pages`.

Se o push do estado falhar por concorrência, a execução para; não força uma substituição cega e a próxima execução recarrega o remoto. Se a branch operacional for protegida contra esse fluxo, ajuste a política apenas dessa branch, preservando as regras de `main`. Não apague a branch para tentar resolver uma falha.

Para recuperar um snapshot: baixe o artefato recente de uma execução bem-sucedida, descompacte os dois JSON em `.biblioteca-runtime/`, valide com os testes e com `validate_state`, confira que os dados não estão vencidos e faça a recuperação da branch operacional com comparação do SHA atual. Essa recuperação avançada não deve ser feita copiando `estado.json` para `dados/` nem publicando o backup inteiro. Se precisar, peça acompanhamento antes de substituir o estado remoto.

Acompanhe **Actions** e habilite as notificações de falhas nas preferências do GitHub se desejar. Em repositórios públicos, o GitHub pode desativar agendamentos após 60 dias sem atividade. Um workflow desativado não consegue avisar sobre a própria inatividade; confira a aba Actions periodicamente e reative quando necessário. Não há serviço externo de monitoramento contratado.

## Testes e limites da verificação

Execute localmente:

```bash
python3 -m unittest discover -s tests/biblioteca -v
node --check assets/biblioteca.js
```

Os testes usam respostas simuladas e Git local temporário, sem chave e sem consumir a quota. Incluem catálogo vazio, 10 mil vídeos, IDs duplicados, privado/removido, incorporação, região, rede, 429/403/quota, resposta inválida, JSON inválido, recuperação de tarefa, concorrência real em branch local, cache, cronograma perdido, registro sem alteração, orçamento, ausência de chave, retenção e separação do artefato público.

A simulação não confirma permissões do seu GitHub, elegibilidade da sua conta Google, funcionamento real do agendamento, sucesso do deploy ou reprodução de um título real. Essas etapas continuam pendentes até a configuração e o teste real. A implementação não habilita faturamento, não aumenta quotas, não acessa conteúdo privado e não envia e-mails ou mensagens de WhatsApp.

## Fontes oficiais conferidas

- GitHub Pages com workflow: https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages
- Escolher a origem do Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
- Token e disparo de workflows: https://docs.github.com/en/actions/concepts/security/github_token
- Agenda e desativação: https://docs.github.com/en/actions/how-tos/manage-workflow-runs/disable-and-enable-workflows
- Limites do Actions: https://docs.github.com/en/actions/reference/limits
- Começar com a API: https://developers.google.com/youtube/data/getting-started
- Quotas: https://developers.google.com/youtube/data/determine_quota_cost
- Armazenamento e atualização de dados: https://developers.google.com/youtube/terms/developer-policies
