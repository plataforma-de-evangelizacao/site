# Atualizar o site sem mexer no HTML

## Publicar pela primeira vez

Extraia o ZIP e envie index.html, catalogo.txt, .nojekyll e a pasta dados COMPLETA para a raiz do repositório site. Preserve o nome dados e todos os arquivos dentro dela. Pelo computador, arraste a pasta dados na tela Add file → Upload files. Não envie só o ZIP.

Depois dessa publicação, mude somente os arquivos de conteúdo e confirme Commit changes. O GitHub Pages leva alguns minutos para publicar. A página busca os dados ao abrir, ao voltar para a aba e a cada cinco minutos enquanto estiver aberta. Nenhum serviço pago ou senha é necessário.

## Arquivo de cada seção

| Arquivo | Como preencher |
| --- | --- |
| dados/oracoes.txt | Uma oração completa por linha. Já contém as 2.000 variações. |
| dados/reflexoes.txt | Uma reflexão completa por linha. Já contém as sete atuais. |
| dados/louvores.json | Lista de objetos com titulo e link HTTPS opcional. Já contém 14 louvores. |
| dados/leituras.json | Datas AAAA-MM-DD com reading, prayer/reflection/song opcionais. Vazio, aguardando cronograma. |
| dados/lives.json | title, category, description, url, start e end. Vazio. |
| dados/spotify.json | id, title, category e tracks. Vazio. |
| dados/youtube.json | titulo e link; já contém as cinco playlists enviadas. |
| dados/palestras.json | title, date, venue, city e url. Vazio. |
| dados/versiculos.json | reference, text e translation. Vazio. |
| dados/artigos.json | titulo, autor, data, descricao, texto, link opcional. Vazio. |
| dados/estudos.json | Igual a artigos; traducao opcional para identificar a Bíblia usada. Vazio. |
| dados/livros.json | titulo, descricao e link de compra; só preencher quando houver publicação real. |
| dados/acoes.json | titulo, data, descricao, texto e link público opcional do relatório. Não enviar comprovantes sem ocultar dados pessoais. |
| dados/parceiros.json | titulo, descricao e link opcional. Já contém as duas igrejas. |
| catalogo.txt | Catálogo de filmes e desenhos; instruções no arquivo COMO-ATUALIZAR-CATALOGO.md. |

JSON é um arquivo de dados estruturados: mantenha aspas duplas, colchetes e vírgulas. Não coloque comentários no JSON. Use [] para lista vazia e {} para cronograma vazio. Os exemplos estão em EXEMPLOS-DE-PREENCHIMENTO.json e NÃO são carregados no site. Você pode enviar suas listas ao ChatGPT para produzir os arquivos corretos. Esses arquivos não são uma planilha Excel: não renomeie XLSX para JSON.

## Rotação diária

A oração muda pela data no horário de Mato Grosso. Todos veem a mesma oração na mesma data. Há um ciclo de 2.000 dias enquanto o acervo mantiver esse tamanho; se mudar a ordem ou a quantidade, a seleção também pode mudar. Não é sorteio a cada visita. O louvor e a reflexão também alternam por data. Leituras não são sorteadas: seguem somente o cronograma. Uma oração/reflexão/música específica cadastrada em leituras.json tem prioridade.

## Categorias

Lives: culto, adoracao, pregacao, beneficente, louvor, cura-libertacao.
Spotify: escuta, recomendacoes, autorais. O id é a sequência de 22 caracteres depois de /playlist/ no link do Spotify. O site já exibe as janelas após cadastrar IDs reais; sincronização com sua conta ainda exige configuração.

## Limites

O site não busca arquivos no seu PC nem escreve no GitHub. Arquivo local selecionado na prévia do catálogo não publica alterações. Para testar dados externos, use a página hospedada: o navegador pode bloquear fetch de arquivos locais ao abrir o HTML baixado. A prévia HTML tem uma pequena reserva de orações para uso local, mas o acervo completo está no TXT.

Arquivos inválidos ou indisponíveis mantêm os últimos dados carregados na aba (ou a reserva inicial); consulte o arquivo para corrigir. Não há banco privado: TODOS os arquivos enviados ao repositório público serão públicos. Não coloque senhas, tokens, pedidos de oração, telefones de visitantes nem dados privados. Não há envio de avisos nem detecção real de lives por esses arquivos; horários cadastrados só controlam o destaque. APIs do YouTube/Spotify ficam para configuração posterior.

## Histórias bíblicas e referências por vídeo

- dados/temas-biblicos.json: id, titulo, testamento (Antigo Testamento ou Novo Testamento), ordem numérica, descricao e passagens. Abraão, Moisés e Jonas foram preparados somente como temas, sem vídeos inventados.
- dados/midias-biblicas.json: lista de adaptações. tema deve corresponder ao id da história; titulo, formato (Desenho, Filme, Série, Documentário), canal, link HTTPS, descricao e passagens opcionais. Pode haver dez ou mais versões do mesmo tema.
- Cada passagem: referencia (texto legível), protestante (link HTTPS na ACF) e catolica (link HTTPS na Ave-Maria). Não marcar referência de vídeo como revisada antes de verificar o que ele narra.
- dados/biblias-e-apps.json: titulo, tipo (Site ou Aplicativo), descricao e link HTTPS oficial. Há três recursos iniciais.
- dados/leituras.json agora aceita passagens com a mesma estrutura para botões de leitura por dia. A referência em reading é exibida; os links só aparecem quando cadastrados em passagens. O PDF do cronograma ainda precisa ser fornecido.

O botão de leitura abre a Bíblia em site externo, não copia o texto integral. A escolha de edição prioriza os links da edição preferida, mas mostra a alternativa quando cadastrada. Os dois cânones são identificados como católico (73 livros) e protestante (66). Instalação ou abertura de um aplicativo depende do dispositivo. O acervo antigo catalogo.txt continua servindo conteúdos gerais; o acervo organizado por histórias usa os novos JSONs.

## PDFs para baixar
Edite dados/biblias-pdf.json: titulo, tradicao, versao, conteudo, descricao, link (PDF ou compartilhamento do Drive), fonte e creditos. Não é preciso API do Drive para links públicos. Links vazios exibem Em preparação. Confira a licença antes de hospedar uma cópia. A edição católica aguarda seleção e autorização; não há PDF católico hospedado neste pacote.

## Buscando uma vida mais próxima de Deus
A seção aparece após a abertura. Edite dados/buscando.json: introducao, temas (titulo, explicacao, abandonar, cultivar, exemplo, passagens), mandamentos, contexto_paulo, passagens_contexto e praticas (convite, pergunta, oracao, passagens). Todas as explicações são sínteses da plataforma, não citações literais. Links de cada passagem usam referencia e link HTTPS. Não inserir indicação de filme/música como se já tivesse sido revisada. A prática muda diariamente; o cronograma da igreja continua separado e intacto.

## Referências para aprofundar a santidade
Edite dados/recursos-santidade.txt. Uma linha: tema | tipo | titulo | autor/fonte | link HTTPS | descrição. Os tipos podem ser Artigo, Pregação, Palestra ou Vídeo. O resumo só deve ser apresentado como analisado se o texto/transcrição tiver sido acessado; título e miniatura não bastam. A lista inicial contém artigos, uma catequese e leituras bíblicas, não gravações de pastores inventadas. Novos materiais podem ser encaminhados ao ChatGPT para revisão e organização do TXT.
Buscando.json também controla ensinamentos_jesus, pai_nosso, vicios, vicios_nota, ambiente_nota e integridade. Mantenha autoria, licença e texto da tradução ao editar uma citação. Pecados capitais não equivalem automaticamente a pecados mortais na classificação católica.

## Parcerias e ensino
Edite dados/parcerias.json para título, convite, email, whatsapp, cidade, estado, endereco, frentes, partilha e etapas. O WhatsApp deve conter DDI+DDD+número, só dígitos (Brasil começa com 55). Está vazio porque o número de contato ainda não foi informado; não foi reutilizada a chave Pix. O endereço completo também está vazio: a página indica apenas Nova Bandeirantes, Mato Grosso, e pede para combinar visitas. Não publicar endereço residencial sem intenção explícita.
Edite dados/materiais-ensino.json para incluir titulo, area, publico, formato, descricao, autor, fonte, link HTTPS e licenca. As áreas e os públicos aceitos aparecem nos filtros. O acervo começa vazio; a pasta geral do Drive não é apresentada como catálogo educacional revisado. Revise a faixa etária, a qualidade do conteúdo e os direitos antes de compartilhar. Links devem ser públicos apenas quando o material é destinado à publicação.
Os botões de contato apenas abrem e-mail/WhatsApp com rascunho; a pessoa revisa e envia. Não há envio automático nem formalização de parceria por um clique. Não preencher registros de crianças, pedidos de ajuda ou dados privados nos JSONs públicos.

## Cuidar de si
A seção no menu e depois de Buscando lê dados/autocuidado.json: titulo, introducao, nota, temas (titulo, area, explicacao, evitar, pratica, reflexao, fonte, fonte_titulo), pausa e passagem. Áreas: Corpo, Emoções, Fé, Convivência, Música e telas, Rotina, Apoio. Orientações gerais, com fontes de saúde identificadas; reflexões espirituais não são diagnósticos. Evitar prescrições, promessas de cura, condenação de gêneros musicais e associação de sofrimento ou TDAH a falta de fé. Qualquer ampliação clínica pede revisão de fonte qualificada.


## Revisão: Fé e conhecimento e pausa da entrada

`dados/fe-conhecimento.json` recebe `principio` e uma lista `disciplinas`. Cada disciplina tem `titulo`, `fundamento`, `pergunta` e `pratica`. Texto simples, sem HTML.

`dados/pausa-diaria.json` é uma lista. Cada item recebe `title`, `text` e `step` como listas de três textos na ordem PT, EN e ES; `ref` (referência), `url` (HTTPS para a passagem) e `song` (termos de busca de louvor). Confira se os três textos correspondem um ao outro. As seleções alternam pela data no horário de Mato Grosso e são iguais para todos, sem análise de emoções. Recarregue após atualizar o arquivo.

O princípio editorial está em PRINCIPIOS-EDITORIAIS.md. Leia-o antes de criar materiais sobre qualquer disciplina. Os textos fixos das páginas permanecem no HTML; a navegação e suas traduções, em assets/platform.js.


## Versão multilíngue e acolhimento

Português continua em dados/ e catalogo.txt; inglês em dados/en/; espanhol em dados/es/. Todos os arquivos atuais têm equivalentes. Ao criar um novo registro, atualize as três versões, preservando IDs, formatos, categorias de controle e correspondência das orações. Consulte GUIA-DE-TRADUCAO.md antes de editar.

O texto do apoio está em acolhimento.json em cada idioma. Os números e destinos dos botões de emergência/CVV estão também no HTML para funcionar como acesso básico sem JavaScript. Ao alterar serviços, atualize ambos e confira os links. Nunca prometa resposta imediata por e-mail ou cura pelo site.


## Pecado, santidade e propostas

Os estudos novos estão em pecado.json e espirito-santidade.json, com versões en/es. O planejamento fica exclusivamente em dados/planejamento.json para atualizar o andamento em todos os idiomas de uma vez. Leia COMO-ATUALIZAR-PLANEJAMENTO.md.

## Corpo, vontade e escolhas

A seção está em dados/corpo-escolhas.json, com versões completas em dados/en/ e dados/es/. Preserve as sete áreas, referências e campos existentes ao editar. assets/body.js contém o conteúdo inicial equivalente usado pela prévia independente; ao atualizar o texto, mantenha esse conteúdo inicial coerente. A página publicada relê os arquivos JSON.
