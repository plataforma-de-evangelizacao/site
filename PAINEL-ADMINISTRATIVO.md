## Atualização — 3 de novembro de 2026 · textos dos vídeos

Backend **2026.11.03.4**, pacote v42. Campos de título e descrição para revisão e vídeos publicados, preservando originais, aprovação e edições nas buscas futuras. Correção do teste de aprovação incluída. Instalação e teste: **ATUALIZACAO-TITULOS-VIDEOS.md**.

# Administração da Plataforma Global de Evangelização

## Atualização automática — 3 de novembro de 2026

Versão **2026.11.03.3**. Siga **LEIA-PRIMEIRO.md**, que substitui a preparação manual de SQL e Edge Functions dos guias anteriores. Depois da autorização inicial por dois Secrets no GitHub, a guia **Tarefas administrativas** verifica versões e aplica as migrações e as funções do backend. O push de uma nova versão do backend também dispara a preparação automaticamente. O token de gestão não é recebido pelo navegador.

A atualização usa migrações versionadas e checksums, uma transação para o conjunto SQL e verificação posterior da função publicada. O backend só é marcado como instalado ao confirmar ambos. Rotinas de busca agora registram tempos reais e etapas de requisição/resposta. **TESTE-RAPIDO-ATUALIZACAO.md** lista os testes após instalar.


## Atualização — 3 de novembro de 2026

Acompanhamento por cartão com etapas e contadores reais, disparo direto protegido do GitHub, sessão preservada no F5 com dez minutos de inatividade, filtro de vídeos excluídos/arquivados, lixeira de projetos e indexação automática dos filtros audiovisuais.

Instalação e configuração: **COMECE-AQUI-INTEGRACOES.md**. Testes: **ROTEIRO-TESTES-INTEGRACOES.md**. O disparo imediato exige publicar a função Supabase `admin-dispatch` e configurar seu segredo do GitHub; arquivos do frontend sozinhos não ativam essa integração. A rotina antiga continua como recuperação. Este bloco substitui as instruções antigas sobre perder a sessão no F5 e excluir cartões de objetos definitivamente.


**Atualização:** 2 de novembro de 2026, horário de Mato Grosso.  
**Versão:** `2026.11.02-publicacao-direta`.

Esta é a referência atual do painel. Substitui o fluxo anterior em que aprovar um vídeo ou salvar um conteúdo precisava aguardar o agendamento do GitHub Actions.

## Instalação e aceitação

Siga **COMECE-AQUI-PUBLICACAO-DIRETA.md**. Depois execute **ROTEIRO-TESTES-VIDEOS-E-PROJETOS.md**, que foi preparado para testar primeiro vídeos e projetos em aproximadamente dez minutos após a instalação.

A atualização preserva seu `admin/config.json` e os Secrets existentes. O arquivo de ativação é **ATIVAR-PUBLICACAO-DIRETA.sql**, também disponível em `scripts/admin/publicacao-direta.sql`. Ele é para o mesmo projeto Supabase em que você já criou seu usuário e autorizou o UUID em `pge_admins`.

## Arquitetura atual

- O site continua hospedado no GitHub Pages.
- Metadados temporários dos vídeos continuam em `pge_videos`, com prazo de validade. A descoberta usa a API do YouTube no runner.
- Decisões do administrador são gravadas diretamente em `pge_video_decisions`. O catálogo público cruza a decisão atual com a disponibilidade e validade dos metadados.
- Conteúdos publicados pelos formulários ficam em `pge_live_documents`. O site consulta a versão publicada; quando não existe uma substituição naquele caminho, lê o arquivo original do repositório.
- A cópia administrativa em `pge_documents` recebe o conteúdo e a versão novos na mesma transação.
- O workflow administrativo sincroniza alterações autorais e decisões para os arquivos do GitHub em segundo plano. Os comandos antigos ainda são reconciliados, mas uma edição antiga não deve sobrescrever uma publicação direta mais recente.
- Parceiros e projetos possuem registros normalizados e relacionamentos em tabelas específicas.

**Publicar conteúdo** é diferente de **buscar novos conteúdos externos**. O primeiro não espera o cron. O segundo ainda usa as rotinas, filas, credenciais e quotas das integrações.

## Menus e indicadores

A visão geral coloca os indicadores antes das ações e das orientações. Os atalhos de conteúdo ficam mais abaixo e agrupados por assunto.

| Indicador | Origem e significado |
| --- | --- |
| Vídeos publicados | Mesmo catálogo público utilizado pelos visitantes. |
| Aguardando revisão | Metadados válidos com situação editorial pendente. |
| Arquivados / bloqueados | Decisões persistidas por ID. |
| Músicas cadastradas | Louvores e conteúdos musicais cadastrados; não representa músicas descobertas por uma API ainda não configurada. |
| Playlists cadastradas | Listas de links do Spotify e YouTube. |
| Artigos publicados | Entradas com texto ou link de acesso, sem contar apenas uma proposta vazia como artigo pronto. |
| Livros cadastrados | Registros ativos de livros. |
| Projetos cadastrados | Fichas e frentes de projeto cadastradas. |
| Projetos concluídos | Situação/etapa de conclusão explícita. Apenas acrescentar um link não conta automaticamente como conclusão. |
| Cursos propostos / disponíveis | Cursos e formações das fichas de projeto; disponibilidade depende do acesso cadastrado. |

Os contadores usam os dados carregados pelo painel. **Recarregar painel** atualiza esses dados sem disparar uma nova consulta ao YouTube. A barra acompanha cinco fontes carregadas, não simula tempo de uma busca.

## Vídeos: publicar, retirar e restaurar

Em **Acervo de vídeos**, busque pelo título, canal ou ID. Há filtros por situação/categoria, seleção individual e seleção de todos os resultados filtrados, inclusive além dos primeiros cartões exibidos. Cada aprovação em lote aceita até 300 vídeos.

A aprovação exige categoria e confirmação de revisão do conteúdo em português. Não há análise automática por assistir ao vídeo. O retorno “publicado” só aparece depois de o servidor confirmar a transação.

**Publicados no site** lê o catálogo real e oferece nome, canal, acesso, categoria, **Arquivar** e **Excluir e bloquear**.

- **Arquivar:** retira do público, preservando a decisão e a confirmação anterior. Um arquivado que estava aprovado e continua tecnicamente elegível pode voltar por **Restaurar publicação**.
- **Excluir e bloquear:** retira do público e mantém o ID rejeitado, evitando reinclusão pela descoberta. Outro upload do mesmo filme tem outro ID.
- **Remover bloqueio e revisar:** devolve um rejeitado à revisão. Ele precisa ser aprovado novamente; o desbloqueio não transforma conteúdo rejeitado em publicado automaticamente.
- **Salvar categoria:** conserva a situação editorial. Não desbloqueia nem aprova um pendente por conta própria.

O catálogo público exige aprovação, disponibilidade válida, categoria aceita, confirmação de português e metadados não vencidos. Restaurar um registro não contorna esses requisitos.

## Formulários de conteúdo

Em cada área, **Administrar conteúdo** abre os campos do arquivo correspondente. Não é necessário editar JSON manualmente. As listas oferecem busca, criação de cartão, edição, arquivamento/restauração de registros e exclusão. Os campos existentes e propriedades adicionais são preservados. IDs já existentes não são alterados quando o título muda; IDs novos são gerados automaticamente a partir do título, com sufixo para evitar colisões.

Campos comuns:

- título, nome, descrição e texto;
- objetivo, público, roteiro, principais ações e participação;
- status, etapa e prioridade;
- link público, repositório, documentação e licença;
- campos de contato e localização para parceiros;
- traduções para inglês e espanhol;
- parceiros envolvidos e situação de cada vínculo.

Use **Salvar e publicar agora** para confirmar a edição. Arquivar/excluir um cartão tem uma confirmação própria e publica o documento resultante. Se houver outras alterações abertas naquele formulário, elas fazem parte do documento que será publicado: revise os campos antes de confirmar.

Arquivos TXT de orações/reflexões usam um conteúdo por linha e são apresentados como cartões de texto. Eles podem ser criados, editados e excluídos; arquivamento por registro só se aplica a registros estruturados em JSON. O PDF das orações ainda depende do material a ser enviado.

O painel não é um editor de HTML/CSS, credenciais ou permissões. Campos novos podem ser mantidos nos dados, mas só aparecem na parte pública quando o respectivo componente os utiliza. Esta entrega acrescenta a apresentação pública de descrição detalhada, objetivo, roteiro, ações e parceiros dos projetos.

## Projetos sociais desta entrega

Os projetos abaixo foram acrescentados como propostas em planejamento, com descrição, objetivo, roteiro e principais pontos, sem parceiros presumidos:

- Recomeçar — apoio diante da dependência de álcool.
- Recomeçar — caminhos de cuidado diante das drogas.
- Roupas que acolhem — partilha com dignidade.
- Alimento e partilha — cuidado que chega à mesa.
- Mutirão solidário — tempo e trabalho pelo próximo.

São propostas comunitárias. As primeiras não anunciam tratamento clínico, grupo oficial de Alcoólicos Anônimos ou resultados terapêuticos. Cronogramas, locais e responsáveis só devem ser divulgados quando confirmados.

## Parceiros como registros e relações

A fonte autoral de instituições continua sendo `dados/rede-parceiros.json`. O banco mantém:

| Tabela | Função |
| --- | --- |
| `pge_partner_entities` | Registros dos parceiros por ID estável. |
| `pge_project_entities` | Registros dos projetos por ID estável. |
| `pge_project_partners` | Relação projeto/parceiro, situação e papel. |

Ao publicar os documentos, gatilhos atualizam essas tabelas na mesma transação. Um vínculo precisa referenciar um parceiro existente. Renomear o parceiro mantém o vínculo porque o identificador permanece. Remover um vínculo não remove a instituição. Remover a instituição elimina suas relações normalizadas; o site não exibe nomes sem cadastro correspondente. Antes de republicar um projeto com referência antiga, remova ou substitua a referência no formulário.

A seleção mostra nome, cidade e comunidade. Cada vínculo tem `a-propor`, `em-conversa` ou `confirmada`, além do papel. A página pública distingue **Parceiros envolvidos** de **Parcerias em construção**. Não foi criada automaticamente uma parceria com igreja, prefeitura, Vicentinos ou grupo de apoio.

## Idiomas e traduções

A interface conserva português, inglês e espanhol. Cartões com título/nome oferecem uma seção de traduções para inglês/espanhol. Nos arquivos com variantes separadas, a publicação inclui as versões correspondentes em uma transação de até três documentos. Campos compartilhados, IDs e links são sincronizados; traduções antigas de textos inalterados são reaproveitadas.

**Não foi contratado nem conectado um tradutor automático.** Textos novos sem tradução usam português como alternativa e permanecem pendentes. O formulário informa isso. Não se deve afirmar que um texto foi traduzido apenas porque a estrutura foi sincronizada. Os cinco projetos desta entrega incluem os textos principais em inglês e espanhol.

## Segurança da publicação direta

As funções de gravação são `pge_publish_documents` e `pge_review_videos`. Ambas verificam `auth.uid()` e a presença em `pge_admins` no servidor. Seus parâmetros não permitem escolher SQL, caminhos de segurança ou um comando shell.

- Escrita direta nas tabelas novas é revogada para os clientes.
- RLS está habilitado, com leitura de gestão somente para administradores autorizados.
- Anônimos recebem acesso apenas às funções públicas de leitura sanitizada, como o catálogo de aprovados e documentos publicados.
- A lista de caminhos editáveis é explícita; `admin/config.json`, scripts, workflows e Secrets não pertencem à lista.
- Tamanho, formato básico, versão e relações são conferidos. Uma edição concorrente gera conflito e deve ser recarregada; não sobrescreve silenciosamente outra edição.
- Lotes de vídeos e conjuntos de até três documentos são transacionais.
- A chave pública continua no frontend; a chave privilegiada permanece no runner.
- O token de login continua apenas na memória da aba, sem persistência em armazenamento do navegador.
- Campos de terceiros são renderizados como texto, não como HTML executável.

O catálogo público não expõe os pendentes, rejeitados ou arquivados. Metadados vencidos não voltam ao público apenas por uma restauração. Os bloqueios persistem por ID mesmo após a limpeza de metadados.

O adaptador público usa requisições sem cache HTTP e verifica revisões a cada dez segundos. Em falha do serviço de conteúdo, apresenta indisponibilidade em vez de retornar silenciosamente um documento antigo que poderia republicar um item retirado. A disponibilidade do Supabase passa a ser relevante para a leitura dinâmica.

## Sincronização e recuperação

`hydrate_live` lê as versões publicadas antes de o processador da biblioteca classificar itens e antes de o workflow administrativo copiar conteúdo para o GitHub. Assim, a descoberta respeita decisões diretas e a exportação de documentos não sobrescreve uma edição do painel com um arquivo antigo.

O backup no GitHub continua sem push forçado para `main`. Caso a organização exija PR, essa cópia poderá falhar até adaptação do fluxo; a publicação direta no banco permanece separada. Não remova uma proteção de branch para contornar uma falha.

Não edite manualmente no GitHub um arquivo que já possui uma versão direta esperando que ele ganhe precedência: a versão publicada no Supabase é a referência atual. Faça a alteração pelo painel ou planeje uma migração explícita de volta aos arquivos. Isso evita duas fontes concorrentes.

Antes de reverter o código para uma versão antiga, sincronize e confira a cópia do conteúdo no GitHub; do contrário, uma versão antiga do frontend pode não conhecer as alterações diretas. Não apague as tabelas ou os bloqueios para tentar corrigir uma falha de interface.

## Validação e limites da entrega

Foram executados testes locais Python de administração/biblioteca, verificações do adaptador público em Node e a validação dos dados/âncoras. A interface foi exercitada com um backend simulado: projeto criado por formulário apareceu no site; arquivar o retirou; restaurar o devolveu; aprovar um vídeo o tornou público e excluir/bloquear o retirou.

**A migração foi executada em PostgreSQL local via PGlite, com 29 verificações aprovadas**, incluindo políticas de acesso, publicação, remoção, conflitos e relações entre projetos e parceiros. A autenticação foi simulada nesses testes. Não alteramos seu Supabase: Auth, PostgREST e a publicação real ainda precisam ser validados pelo roteiro na sua conta.

Músicas, Spotify, podcasts e lives continuam com seus cadastros manuais; suas descobertas externas específicas precisam de configuração futura. Buscas novas pelo YouTube continuam com fila/quotas. Upload de PDF, análise do PDF das orações, notificações e tradução automática não foram ativados nesta atualização.
