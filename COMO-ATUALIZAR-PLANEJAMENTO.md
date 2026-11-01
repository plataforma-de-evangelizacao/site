# Próximos conteúdos: um arquivo para atualizar

O arquivo principal é **dados/planejamento.json**. Ele é compartilhado entre os três idiomas: uma alteração de estado ou link se reflete nas três interfaces. Não crie cópias desse planejamento em dados/en/ ou dados/es/.

## O que já está cadastrado

Há 16 propostas: oito palestras, sete artigos e um livro. São temas para desenvolver, não eventos confirmados, gravações realizadas ou livros disponíveis. As gravações e os materiais estão previstos em português por enquanto. Inglês e espanhol apresentam traduções dos títulos e resumos, com esse aviso.

## Estados

| Valor no arquivo | O que aparece no site |
| --- | --- |
| proposta | Proposto, na área A desenvolver |
| em-producao | Em produção, na área A desenvolver |
| gravado | Gravado, publicação pendente; apropriado para palestra |
| publicado | Publicado, na área Gravados ou publicados |

O link fica clicável quando o estado é publicado e o destino começa com HTTPS. Um material gravado, mas ainda não publicado, não exibe um botão para um link possivelmente privado.

## Como atualizar no GitHub

- Abra dados/planejamento.json no repositório e use a edição de arquivo.
- Para mudar o andamento, altere somente status no registro correspondente.
- Quando publicar, informe o link real do YouTube, artigo ou página do livro e use status publicado.
- Para acrescentar um tema, copie um objeto da lista itens e dê um id único.
- Preserve aspas, vírgulas, chaves e colchetes. Publique a alteração e aguarde a atualização do GitHub Pages.
- Abra o site ou recarregue a página. O planejamento também é relido a cada cinco minutos enquanto a página está aberta e ao retornar à aba.

## Campos

| Campo | Como preencher |
| --- | --- |
| id | Identificador único, como santidade-comunidade; não traduzir |
| formato | Palestra, Artigo ou Livro; manter esses valores |
| status | Um dos quatro valores da tabela |
| prioridade | alta ou media |
| titulo / descricao | Originais em português |
| idioma | pt: o material previsto nesta versão é em português |
| distribuicao | a-definir, gratuito ou venda |
| link | URL real HTTPS; vazio enquanto indisponível |
| traducoes | Objetos en e es com titulo e descricao |

Se um item novo não tiver traduções, o original português aparece com aviso nas interfaces estrangeiras. O site não inventa uma tradução automaticamente. Quando escrevermos um material juntos, podemos atualizar os três títulos e resumos.

A indicação venda não cria uma loja nem faz cobranças: apenas identifica a distribuição. O destino deve ser a página real do produto. Não anuncie disponibilidade antes da publicação.

O planejamento é uma vitrine de andamento. Ele não cria playlists no YouTube, não grava vídeos e não sincroniza automaticamente o arquivo separado palestras.json. Registros adicionais de palestras realizadas continuam disponíveis na seção já existente. O link publicado no planejamento já pode ser aberto diretamente por ali.

## Arquivos dos estudos novos

- dados/pecado.json: definição, idolatria, gravidade, sete vícios, exemplos, jejum, casos cotidianos e reparação.
- dados/espirito-santidade.json: Espírito Santo, fruto, santidade, dons, práticas, exemplos e oração.
- dados/en/ e dados/es/: versões correspondentes desses estudos.

Os textos são introduções autorais com referências, não substitutos para estudo teológico aprofundado. A distinção católica mortal/venial é identificada. Peso e doença não são usados como medida de pecado; jejum não é prescrito como tratamento.
