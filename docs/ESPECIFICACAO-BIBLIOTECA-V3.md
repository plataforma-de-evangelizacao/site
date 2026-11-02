**# PLATAFORMA GLOBAL DE EVANGELIZAÇÃO**

**## Implementação da Biblioteca Bíblica Audiovisual Automatizada — Versão 3.0**



Quero implementar uma biblioteca audiovisual automatizada no site Plataforma Global de Evangelização, atualmente hospedado no GitHub Pages.



**\*\*Esta é a especificação principal e substitui integralmente as versões anteriores.\*\***



O objetivo é reunir, organizar, pesquisar, classificar, disponibilizar e manter atualizados desenhos animados, filmes e séries bíblicas publicados no YouTube, priorizando conteúdos em português brasileiro.



O sistema deverá funcionar automaticamente após a configuração inicial, utilizando exclusivamente recursos gratuitos, sem contratação de serviços pagos.



Não quero apenas um protótipo ou documentação. Quero uma implementação funcional, segura, testada e integrada ao repositório existente.



**# 1. Requisitos financeiros obrigatórios**



A implementação deve funcionar dentro dos limites gratuitos dos serviços utilizados.



Utilizar:



\- GitHub Pages.

\- GitHub Actions, respeitando os limites gratuitos aplicáveis ao repositório.

\- YouTube Data API v3, exclusivamente dentro da quota gratuita concedida ao projeto.

\- Arquivos JSON armazenados no GitHub.

\- Ferramentas e bibliotecas gratuitas.

\- Reprodutor oficial incorporado do YouTube.



**\*\*Não habilitar faturamento, contratar planos pagos ou solicitar ampliação de quota que implique custos.\*\***



Antes de configurar qualquer serviço, verificar se ele exige cadastro de faturamento, cartão de crédito ou pagamento.



Se uma funcionalidade exigir custos, apresentar uma alternativa gratuita ou desativá-la.



A automação deverá interromper novas requisições quando atingir o orçamento interno configurado.



Não tentar contornar limites utilizando múltiplas chaves, múltiplos projetos ou mecanismos incompatíveis com as políticas dos provedores.



**# 2. Inspecionar o repositório antes de programar**



Antes de qualquer alteração:



1\. Identificar o repositório correto da plataforma.

2\. Verificar a estrutura de diretórios.

3\. Identificar a tecnologia utilizada no frontend.

4\. Verificar a configuração do GitHub Pages.

5\. Inspecionar workflows existentes.

6\. Verificar o processo atual de deploy.

7\. Identificar possíveis conflitos.

8\. Preservar funcionalidades já implementadas.



Não reconstruir o site desnecessariamente.



A nova biblioteca deverá integrar-se ao projeto existente, respeitando sua identidade visual.



**# 3. Categorias da biblioteca**



Criar três categorias principais.



**\*\*Desenhos bíblicos\*\***



\- Animações infantis.

\- Episódios bíblicos.

\- Séries animadas.

\- Filmes de animação.

\- Compilações de histórias bíblicas.



**\*\*Filmes bíblicos\*\***



\- Filmes completos.

\- Produções dramatizadas.

\- Longas-metragens.

\- Médias-metragens.

\- Adaptações de acontecimentos bíblicos.



**\*\*Séries bíblicas\*\***



\- Séries com atores.

\- Minisséries.

\- Temporadas.

\- Episódios.

\- Produções seriadas baseadas nas Escrituras.



Não confundir trailers, análises, comentários, músicas ou pregações com as obras audiovisuais.



Priorizar conteúdos em português brasileiro, com dublagem ou legendas verificadas.



**# 4. Estrutura do catálogo**



Utilizar JSON como fonte principal de dados.



Cada vídeo deverá possuir um registro único identificado pelo ID oficial do YouTube.



Campos recomendados:



\| Campo | Descrição |

\|---|---|

\| id | ID oficial do YouTube |

\| titulo | Título da obra |

\| descricao | Sinopse |

\| testamento | Antigo ou Novo |

\| livros | Livros bíblicos associados |

\| referencias | Capítulos e versículos |

\| personagens | Personagens bíblicos |

\| temas | Assuntos abordados |

\| categoria | Desenho, filme ou série |

\| formato | Curta, longa, episódio etc. |

\| publico | Infantil, juvenil, família ou adulto |

\| idioma | Idioma identificado |

\| duracao | Duração |

\| canalId | ID do canal |

\| canalNome | Nome do canal |

\| playlistId | Playlist associada |

\| serieId | Série associada |

\| temporada | Temporada |

\| episodio | Episódio |

\| url | Link do YouTube |

\| thumbnail | Miniatura oficial |

\| disponibilidade | Estado técnico |

\| aprovacao | Estado editorial |

\| ultimaVerificacao | Data da última verificação |

\| dataInclusao | Data da inclusão |

\| fonteClassificacao | Origem da classificação |



Não inventar informações ausentes.



Permitir múltiplos livros bíblicos, referências, personagens e temas para um mesmo vídeo.



Criar uma taxonomia estruturada com os 66 livros bíblicos como base inicial, permitindo extensão editorial futura.



**# 5. Arquitetura de armazenamento**



Criar uma estrutura compatível com o projeto existente.



Sugestão:



\`\`\`text

data/

&#x20; biblioteca/

&#x20;   catalogo.json

&#x20;   taxonomia.json

&#x20;   colecoes.json



&#x20; biblioteca-controle/

&#x20;   buscas.json

&#x20;   verificacoes.json

&#x20;   pendentes.json

&#x20;   rejeitados.json

&#x20;   canais.json

&#x20;   playlists.json

&#x20;   estado.json



scripts/

&#x20; biblioteca/

&#x20;   descobrir

&#x20;   verificar

&#x20;   auditar

&#x20;   classificar

&#x20;   publicar

&#x20;   quota

&#x20;   cache



.github/

&#x20; workflows/

&#x20;   biblioteca.yml

\`\`\`



Adaptar extensões e organização à linguagem escolhida.



Os arquivos de controle não devem ser publicados como dados públicos quando contiverem informações internas de moderação ou operação.



Separar claramente os dados publicados dos dados administrativos.



O catálogo público deverá ser gerado a partir dos registros aprovados e elegíveis.



**# 6. Três rotinas automatizadas**



Implementar três rotinas independentes.



**## Rotina A — Descoberta a cada 10 dias**



Objetivo: encontrar novos desenhos, filmes e séries bíblicas.



Processo:



1\. Ler o catálogo existente.

2\. Consultar o cache persistente.

3\. Verificar consultas já executadas.

4\. Identificar buscas vencidas.

5\. Priorizar canais e playlists aprovados.

6\. Pesquisar conteúdos novos.

7\. Consultar metadados dos candidatos.

8\. Eliminar IDs duplicados.

9\. Aplicar filtros de relevância.

10\. Classificar candidatos.

11\. Encaminhar casos incertos para revisão.

12\. Atualizar os registros válidos.



Não pesquisar novamente uma consulta cujo cache ainda esteja válido.



Usar buscas incrementais quando apropriado, mantendo também revisões periódicas mais amplas para não depender exclusivamente de vídeos recém-publicados.



**## Rotina B — Verificação a cada 15 dias**



Objetivo: conferir se os vídeos do catálogo continuam disponíveis.



Processo:



1\. Carregar IDs ativos.

2\. Eliminar IDs duplicados.

3\. Dividir em lotes de até 50 IDs.

4\. Consultar \`videos.list\`.

5\. Comparar os IDs solicitados e retornados.

6\. Verificar incorporação.

7\. Identificar restrições relevantes.

8\. Atualizar apenas registros modificados.

9\. Registrar verificações bem-sucedidas.

10\. Encaminhar inconsistências para confirmação.



**\*\*Regra:\*\*** se o vídeo continuar disponível e seus dados relevantes não tiverem mudado, não reescrever seu registro público.



Atualizar somente o controle interno da última verificação.



Vídeos comprovadamente indisponíveis devem sair da listagem pública, preservando o histórico.



Uma única falha de rede não autoriza remoção.



**## Rotina C — Manutenção a cada 25 dias**



Objetivo: manter a integridade e a organização da biblioteca.



Executar:



1\. Validação de JSON.

2\. Verificação de IDs duplicados.

3\. Auditoria da taxonomia.

4\. Conferência de referências bíblicas.

5\. Verificação de séries e episódios.

6\. Verificação de relacionamentos entre vídeos.

7\. Revisão de registros incompletos.

8\. Auditoria de classificações conflitantes.

9\. Limpeza segura de entradas de cache obsoletas.

10\. Verificação de falhas anteriores.

11\. Conferência de backups.

12\. Validação dos arquivos públicos.

13\. Relatório de integridade.

14\. Correção automática de problemas determinísticos.



Não corrigir automaticamente questões teológicas incertas.



**# 7. Orquestrador diário**



Criar um workflow GitHub Actions com execução diária.



Ele deverá verificar as datas das últimas execuções bem-sucedidas.



Regras:



\- Descoberta: intervalo de 10 dias.

\- Disponibilidade: intervalo de 15 dias.

\- Manutenção: intervalo de 25 dias.



Não utilizar expressões cron que tentem simular incorretamente esses intervalos.



Utilizar uma agenda diária e um controle persistente de vencimento.



Exemplo:



\`\`\`yaml

on:

&#x20; schedule:

&#x20;   \- cron: '23 6 \* \* \*'

&#x20; workflow_dispatch:

\`\`\`



Requisitos adicionais:



\- Permitir execução manual.

\- Evitar concorrência entre execuções.

\- Persistir progresso.

\- Recuperar execuções interrompidas.

\- Não marcar uma rotina malsucedida como concluída.

\- Permitir retomada após falhas.

\- Considerar atrasos do GitHub Actions.

\- Monitorar eventual desativação dos agendamentos.



Se duas rotinas vencerem no mesmo dia, executá-las sequencialmente ou de forma coordenada, sem alterações concorrentes nos mesmos arquivos.



**# 8. Cache persistente obrigatório**



O sistema deve consultar o catálogo e o cache antes de fazer qualquer pesquisa externa.



Implementar dois mecanismos distintos.



**\*\*Cache de descoberta\*\***



Guardar:



\- Termo pesquisado.

\- Parâmetros normalizados.

\- Idioma.

\- Canal ou playlist.

\- Filtros.

\- Data da última busca.

\- IDs encontrados.

\- Paginação.

\- Versão do algoritmo.

\- Data de expiração.

\- Estado da última execução.



Criar chave determinística para consultas equivalentes.



Se uma consulta ainda estiver válida, reutilizar seus resultados.



Se estiver vencida, atualizar somente o necessário.



Não repetir pesquisas apenas porque uma nova execução do GitHub Actions começou.



**\*\*Cache de vídeos\*\***



Guardar IDs conhecidos e metadados relevantes.



Antes de consultar detalhes, verificar se já foram obtidos recentemente.



Não consultar o mesmo vídeo várias vezes na mesma execução.



A verificação de disponibilidade a cada 15 dias deverá continuar funcionando independentemente do cache de descoberta.



Não utilizar o cache como justificativa para manter indefinidamente vídeos sem verificação.



**# 9. Quota gratuita e limites de chamadas**



Implementar controle centralizado de quota.



Conforme a documentação atual, considerar inicialmente:



\- \`search.list\`: até 50 resultados por chamada.

\- \`videos.list\`: até 50 IDs por chamada.

\- \`playlistItems.list\`: até 50 itens por chamada.



A documentação atual indica uma alocação padrão de até 100 chamadas diárias de \`search.list\` e 10.000 unidades diárias combinadas para outros endpoints, mas a quota real do projeto deverá ser confirmada no Google Cloud.



Esses limites podem mudar.



Configuração inicial sugerida:



\`\`\`json

{

&#x20; "discoveryIntervalDays": 10,

&#x20; "verificationIntervalDays": 15,

&#x20; "maintenanceIntervalDays": 25,

&#x20; "maxVideoIdsPerBatch": 50,

&#x20; "maxSearchResultsPerPage": 50,

&#x20; "maxSearchCallsPerRun": 20,

&#x20; "maxSearchPagesPerQuery": 2,

&#x20; "maxRetries": 3,

&#x20; "quotaSafetyMarginPercent": 20,

&#x20; "allowPaidServices": false,

&#x20; "allowAutomaticQuotaIncrease": false

}

\`\`\`



Criar orçamentos separados para buscas e demais endpoints, conforme a quota efetivamente disponível.



Não assumir que o contador local conhece requisições realizadas por outros sistemas que utilizem a mesma chave ou projeto.



Manter uma margem de segurança.



Se a quota disponível for insuficiente:



1\. Interromper novas chamadas.

2\. Preservar o catálogo.

3\. Salvar o progresso.

4\. Aguardar a próxima janela de quota.

5\. Retomar posteriormente.

6\. Registrar o motivo.



Não gerar chamadas repetitivas quando a API informar quota esgotada.



**# 10. Pesquisa otimizada por canais e playlists**



Priorizar fontes já aprovadas.



Quando possível:



\- Obter a playlist de uploads de um canal aprovado.

\- Consultar \`playlistItems.list\`.

\- Identificar vídeos novos.

\- Comparar IDs com o catálogo.

\- Consultar detalhes somente de candidatos ainda não processados ou vencidos.

\- Evitar buscas globais desnecessárias.



Não presumir que todos os vídeos de um canal aprovado são biblicamente adequados.



Criar registros de canais confiáveis, com estado editorial e data de revisão.



Permitir bloquear canais ou vídeos específicos.



Não tentar recuperar conteúdo privado por meios não autorizados.



**# 11. Verificação de disponibilidade**



Utilizar \`videos.list\` com as partes necessárias, como:



\`\`\`text

part=snippet,contentDetails,status

\`\`\`



Comparar os IDs solicitados com os retornados.



Não presumir que HTTP 200 significa que todos os vídeos estão disponíveis.



Estados sugeridos:



\- \`available\`

\- \`suspected_unavailable\`

\- \`unavailable\`

\- \`embed_restricted\`

\- \`region_restricted\`

\- \`verification_error\`

\- \`unknown\`



Se um vídeo estiver ausente:



1\. Registrar a ocorrência.

2\. Confirmar que a resposta foi válida.

3\. Diferenciar falha de lote de ausência individual.

4\. Realizar confirmação adicional quando necessário.

5\. Ocultar conteúdos comprovadamente indisponíveis.

6\. Preservar seu histórico.

7\. Evitar exclusões permanentes automáticas.



Se mais de 10% dos vídeos verificados apresentarem novas indisponibilidades na mesma execução, suspender alterações em massa e investigar.



O percentual deverá ser configurável.



**# 12. Tratamento de erros**



Implementar tratamento específico por categoria.



**\*\*Erros temporários\*\***



Exemplos: HTTP 429, 500, 502, 503, 504, timeout e falhas de rede.



Aplicar:



\- Tentativas limitadas.

\- Exponential backoff com jitter.

\- Respeito a \`Retry-After\`, quando fornecido.

\- Registro de falhas.

\- Preservação dos dados anteriores.



**\*\*Erros de autenticação\*\***



Exemplos: chave inválida, API desativada ou restrições incompatíveis.



Ação:



\- Interromper a rotina.

\- Preservar o catálogo.

\- Registrar diagnóstico.

\- Nunca registrar a chave em logs.



**\*\*Quota esgotada\*\***



\- Suspender chamadas.

\- Salvar progresso.

\- Aguardar nova janela.

\- Não marcar vídeos como indisponíveis.



**\*\*JSON inválido\*\***



\- Rejeitar a publicação.

\- Preservar a última versão válida.

\- Gerar relatório.

\- Permitir recuperação.



**\*\*Falha de commit ou deploy\*\***



\- Não sobrescrever alterações concorrentes.

\- Recarregar o estado remoto.

\- Revalidar antes de tentar novamente.

\- Preservar os dados publicados.



**# 13. Classificação e aprovação editorial**



Separar obrigatoriamente:



1\. Descoberta.

2\. Validação técnica.

3\. Classificação bíblica.

4\. Aprovação editorial.

5\. Publicação.



O sistema não deverá publicar automaticamente conteúdos cuja natureza bíblica seja duvidosa.



Criar estados:



\- \`approved\`

\- \`pending_review\`

\- \`rejected\`

\- \`unavailable\`

\- \`archived\`



Conteúdos com metadados suficientes e regras editoriais previamente aprovadas poderão seguir o fluxo automático permitido pela configuração.



Conteúdos incertos deverão aguardar revisão.



Não afirmar fidelidade bíblica ou teológica sem análise apropriada.



Não inventar referências bíblicas.



Não classificar trailers como filmes completos.



Não publicar vídeos rejeitados novamente sem autorização.



**# 14. Interface semelhante à Netflix**



Criar uma experiência visual de biblioteca audiovisual, sem copiar marcas ou elementos proprietários da Netflix.



Incluir:



\- Cards com miniaturas.

\- Busca textual instantânea.

\- Filtros combináveis.

\- Categorias por testamento.

\- Livros bíblicos.

\- Personagens.

\- Temas.

\- Faixas etárias.

\- Duração.

\- Tipo de produção.

\- Filmes completos.

\- Séries e temporadas.

\- Episódios.

\- Coleções temáticas.

\- Conteúdos adicionados recentemente.



O visitante poderá, por exemplo, selecionar:



\- Antigo Testamento.

\- Gênesis.

\- Desenhos animados.

\- Público infantil.



O site deverá mostrar apenas os conteúdos correspondentes.



Os filtros devem funcionar sobre os arquivos JSON locais, sem consumir a API do YouTube a cada pesquisa do visitante.



Implementar paginação ou carregamento progressivo para catálogos grandes.



**# 15. Reprodução dos vídeos**



Usar o player oficial incorporado do YouTube.



Não baixar ou hospedar cópias dos vídeos.



Implementar carregamento sob demanda.



Verificar incorporação quando possível.



Se o player falhar:



1\. Mostrar uma mensagem amigável.

2\. Evitar componentes quebrados.

3\. Oferecer acesso ao YouTube quando permitido.

4\. Não expor credenciais.

5\. Não modificar o catálogo diretamente no navegador.



A indisponibilidade detectada pelo visitante poderá ser registrada para verificação futura somente se houver um mecanismo seguro e apropriado.



Não depender de consultas à API a cada visita.



**# 16. Atualização segura do catálogo**



Não modificar diretamente os arquivos públicos durante o processamento.



Fluxo:



1\. Carregar a versão atual.

2\. Criar cópia de trabalho.

3\. Processar atualizações.

4\. Validar o esquema.

5\. Verificar integridade.

6\. Executar testes.

7\. Gerar catálogo público.

8\. Comparar com a versão anterior.

9\. Criar commit somente se necessário.

10\. Acionar ou confirmar o deploy.



Separar atualizações de estado operacional das alterações de conteúdo público.



Não republicar o site desnecessariamente apenas porque a data de uma verificação mudou.



Manter backups recuperáveis.



Em caso de falha, continuar servindo a última versão válida.



**# 17. Monitoramento gratuito**



Criar relatórios automáticos com:



\- Data da execução.

\- Rotina executada.

\- Duração.

\- Vídeos analisados.

\- Vídeos novos.

\- Duplicações evitadas.

\- Vídeos indisponíveis.

\- Pendências.

\- Erros.

\- Chamadas por endpoint.

\- Consumo estimado de quota.

\- Alterações publicadas.

\- Resultado final.



Utilizar inicialmente os logs e recursos gratuitos do GitHub Actions.



Se possível, implementar alertas por falha de workflow usando recursos gratuitos já disponíveis.



Não contratar serviços externos de monitoramento.



**# 18. Segurança**



Exigir:



\- Chave em GitHub Secrets.

\- Permissões mínimas do workflow.

\- Nenhuma credencial no frontend.

\- Validação dos dados da API.

\- Sanitização de conteúdo.

\- Proteção contra duplicações.

\- Proteção contra exclusões em massa.

\- Controle de concorrência.

\- Backups.

\- Testes automatizados.

\- Tratamento de falhas.

\- Separação entre catálogo público e dados administrativos.



Não publicar logs contendo informações sensíveis.



**# 19. Testes obrigatórios**



Testar, utilizando mocks sempre que possível:



1\. Catálogo vazio.

2\. Catálogo com milhares de vídeos.

3\. Vídeo novo.

4\. Vídeo já cadastrado.

5\. Vídeo duplicado.

6\. Vídeo privado.

7\. Vídeo removido.

8\. Incorporação proibida.

9\. Restrição regional.

10\. Falha de rede.

11\. HTTP 429.

12\. HTTP 403.

13\. Quota esgotada.

14\. Resposta parcialmente vazia.

15\. JSON inválido.

16\. Execução interrompida.

17\. Execuções concorrentes.

18\. Falha de commit.

19\. Falha de deploy.

20\. Classificação bíblica incerta.

21\. Vídeo rejeitado encontrado novamente.

22\. Cache válido.

23\. Cache expirado.

24\. Execução agendada perdida.

25\. Atualização sem alterações.

26\. Orçamento de API insuficiente.

27\. Ausência de credenciais.

28\. Recuperação do último catálogo válido.



Os testes automatizados não devem consumir quota real desnecessariamente.



Após a configuração, executar um teste real pequeno e controlado.



**# 20. Configuração gratuita da API**



Acompanhar-me passo a passo para:



1\. Criar um projeto no Google Cloud.

2\. Verificar requisitos de faturamento.

3\. Habilitar a YouTube Data API v3.

4\. Criar a chave de API.

5\. Restringir a chave à API necessária.

6\. Avaliar restrições de aplicação compatíveis com GitHub Actions.

7\. Conferir a quota gratuita disponível.

8\. Configurar limites de utilização.

9\. Armazenar \`YOUTUBE_API_KEY\` nos GitHub Secrets.

10\. Configurar permissões do workflow.

11\. Executar teste controlado.

12\. Verificar os logs.

13\. Conferir o catálogo gerado.

14\. Confirmar a publicação no GitHub Pages.



Não solicitar que eu envie a chave de API pelo chat.



Se o Google exigir faturamento para determinada funcionalidade, não prosseguir com ela sem apresentar uma alternativa gratuita.



**# 21. Critérios de conclusão**



Considerar a implementação concluída somente quando:



\- O catálogo estiver integrado ao site.

\- A pesquisa e os filtros funcionarem.

\- Os vídeos forem incorporados corretamente.

\- O cache persistente funcionar.

\- As duplicações forem evitadas.

\- A rotina de 10 dias funcionar.

\- A rotina de 15 dias funcionar.

\- A rotina de 25 dias funcionar.

\- O workflow diário calcular corretamente os vencimentos.

\- A quota gratuita for respeitada.

\- As falhas não corromperem o catálogo.

\- Os registros indisponíveis forem tratados com segurança.

\- As classificações incertas não forem publicadas automaticamente.

\- O GitHub Pages receber atualizações válidas.

\- Os testes forem executados.

\- A documentação estiver completa.



Não afirmar que a API está integrada antes de realizar uma chamada real bem-sucedida.



Não afirmar que o deploy está funcionando antes de verificar a publicação.



**\*\*Resultado esperado:\*\*** uma Biblioteca Bíblica Audiovisual gratuita, organizada, pesquisável, automatizada, segura e integrada à Plataforma Global de Evangelização, capaz de manter desenhos, filmes e séries bíblicas atualizados sem intervenção manual rotineira, respeitando os limites dos serviços gratuitos.



**# Adendo à especificação 3.0 — Filas persistentes e retomada automática**



Quero acrescentar uma funcionalidade obrigatória às três rotinas da Biblioteca Bíblica Audiovisual.



**\*\*Nenhuma tarefa pendente poderá ser perdida quando uma execução terminar antes de concluir todo o trabalho.\*\***



Implementar um sistema de filas persistentes com as seguintes regras:



**### 1. Filas independentes**



Criar filas para:



\- Descoberta de conteúdos — intervalo de 10 dias.

\- Verificação de disponibilidade — intervalo de 15 dias.

\- Auditoria e manutenção — intervalo de 25 dias.



Cada fila deverá preservar seu estado entre execuções do GitHub Actions.



**### 2. Prioridade para tarefas pendentes**



Quando uma rotina for executada novamente:



1\. Carregar sua fila persistente.

2\. Identificar tarefas não concluídas.

3\. Priorizar tarefas pendentes da execução anterior.

4\. Retomar do último ponto confirmado.

5\. Processar tarefas em lotes.

6\. Registrar os lotes concluídos.

7\. Salvar os itens restantes.

8\. Encerrar com segurança quando atingir o orçamento de execução.

9\. Continuar na próxima janela programada.



Não reiniciar a lista do começo.



Não repetir chamadas já concluídas e ainda válidas.



**### 3. Controle de estado por tarefa**



Cada tarefa deverá conter:



\- Identificador único.

\- Tipo de operação.

\- ID do vídeo, canal, playlist ou consulta.

\- Data de criação.

\- Data da última tentativa.

\- Número de tentativas.

\- Estado atual.

\- Prioridade.

\- Próxima data elegível.

\- Último erro, quando existir.



Estados sugeridos:



\- \`pending\`

\- \`processing\`

\- \`completed\`

\- \`retry_wait\`

\- \`failed\`

\- \`cancelled\`



Tarefas interrompidas no estado \`processing\` deverão voltar à fila após um prazo de segurança, evitando que fiquem bloqueadas permanentemente.



**### 4. Processamento em lotes**



Respeitar os limites da YouTube Data API.



Na verificação de disponibilidade, processar até 50 IDs por chamada de \`videos.list\`.



Registrar progresso somente após confirmar o processamento do lote.



Se uma execução terminar no meio de um lote, permitir sua repetição segura sem duplicar registros ou efeitos.



**### 5. Continuidade entre ciclos**



Se uma rotina não conseguir finalizar sua fila dentro do orçamento disponível, preservar os itens restantes para a próxima execução programada.



Exemplo:



\- Primeira execução: 10.000 vídeos, 3.000 verificados.

\- Segunda execução: começar pelos 7.000 pendentes.

\- Terceira execução: continuar os itens que ainda restarem.



Não descartar pendências quando o intervalo de 10, 15 ou 25 dias vencer novamente.



Novas tarefas deverão ser adicionadas sem apagar as antigas.



**### 6. Evitar crescimento infinito da fila**



Implementar deduplicação por identificador e tipo de operação.



Não adicionar novamente uma tarefa equivalente que já esteja pendente.



Quando uma rodada terminar, programar a próxima verificação dos registros conforme seu intervalo.



Se a fila crescer continuamente, utilizar uma política de prioridades que considere:



\- Tarefas antigas.

\- Falhas aguardando nova tentativa.

\- Conteúdos públicos que precisam de verificação.

\- Novos conteúdos.

\- Custo estimado em quota.



Impedir que tarefas antigas fiquem permanentemente sem processamento.



**### 7. Falhas e tentativas**



Em caso de erro temporário:



\- Preservar a tarefa.

\- Aplicar tentativas limitadas.

\- Registrar o motivo.

\- Agendar nova tentativa.

\- Não marcar como concluída.



Em caso de erro permanente:



\- Registrar a falha.

\- Encaminhar para investigação quando necessário.

\- Evitar repetição infinita.



Se a quota gratuita acabar, interromper as chamadas e preservar toda a fila restante.



**### 8. Persistência segura**



Salvar o estado das filas em armazenamento persistente no repositório ou em outro mecanismo gratuito compatível com GitHub Actions.



Não depender exclusivamente da memória ou do armazenamento temporário do runner.



Utilizar gravações atômicas, validação de esquema, controle de concorrência e backups.



Separar filas administrativas dos arquivos públicos do GitHub Pages.



**### 9. Relatórios**



Cada execução deverá informar:



\- Quantidade inicial de tarefas.

\- Quantidade processada.

\- Quantidade concluída.

\- Quantidade com erro.

\- Quantidade restante.

\- Consumo estimado de quota.

\- Previsão aproximada de ciclos necessários, considerando o ritmo atual.



**### 10. Critério obrigatório de funcionamento**



O sistema só poderá marcar uma rodada como totalmente concluída quando todas as tarefas elegíveis daquela rodada tiverem sido processadas ou encaminhadas para um estado final apropriado.



Se restarem tarefas pendentes, a rodada deverá permanecer aberta e continuar na próxima execução programada.



**\*\*Regra principal: primeiro continuar o trabalho pendente, depois iniciar tarefas novas, respeitando os limites gratuitos da API e evitando duplicações.\*\***





**# Adendo final — Processamento diário de filas pendentes**



Adicionar à especificação 3.0 da Biblioteca Bíblica Audiovisual o processamento diário opcional das filas persistentes.



O GitHub Actions deverá executar diariamente um orquestrador que:



1\. Verifique quais rotinas de 10, 15 e 25 dias estão vencidas.

2\. Consulte as filas persistentes de descoberta, verificação e manutenção.

3\. Priorize tarefas pendentes de execuções anteriores.

4\. Verifique o orçamento gratuito disponível antes de fazer requisições.

5\. Utilize uma parcela configurável da quota para reduzir o acúmulo de tarefas.

6\. Processe os vídeos em lotes de até 50 IDs nas chamadas de \`videos.list\`.

7\. Registre imediatamente o progresso confirmado em armazenamento persistente.

8\. Preserve todas as tarefas que não puderem ser concluídas.

9\. Evite adicionar novamente tarefas equivalentes que já estejam na fila.

10\. Mantenha a próxima execução programada de cada rotina, mesmo que a fila anterior ainda não tenha sido completamente processada.



**\*\*Configuração inicial recomendada:\*\***



\- Reservar até 10% do orçamento interno diário para reduzir filas atrasadas, desde que haja quota disponível.

\- Não ultrapassar os limites gratuitos.

\- Não executar pesquisas novas desnecessárias.

\- Priorizar tarefas mais antigas, respeitando também a criticidade.

\- Não permitir que uma fila impeça permanentemente o processamento das demais.

\- Manter o catálogo público funcionando com a última versão válida em caso de falha.

\- Registrar quantas tarefas foram concluídas e quantas permanecem pendentes.



A reserva de 10% é uma configuração interna, não uma quota adicional concedida pelo YouTube.



**\*\*Regra de agendamento:\*\*** os intervalos de 10, 15 e 25 dias determinam quando novas rodadas ficam elegíveis. O processamento diário serve para continuar rodadas já iniciadas, sem criar antecipadamente novas rodadas desnecessárias.



**\*\*Regra de persistência:\*\*** não considerar um lote concluído até que seu resultado e o estado correspondente estejam gravados de forma recuperável. Se uma execução falhar, a próxima deverá retomar o processamento com segurança.



**\*\*Objetivo:\*\*** permitir que a biblioteca cresça continuamente, sem perder tarefas, desperdiçar chamadas à API ou exigir intervenção manual rotineira.



E reforço uma decisão importante: não precisamos construir um backend tradicional com servidor e banco de dados pagos. O GitHub Actions funcionará como mecanismo de processamento periódico, enquanto os arquivos JSON alimentarão a biblioteca no GitHub Pages.



coomo configurar o github actions para funcionar kjunto cpom o githu pages?


