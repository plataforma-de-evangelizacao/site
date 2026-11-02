# Agenda de ações e doações

A página `#agenda-solidaria` aparece em Explorar, no mapa e na página inicial, junto do destaque de Tiago 1:27 e das formas de ajudar. O site é estático: um JSON publicado alimenta a página, sem servidor pago ou banco de dados externo.

## Atualizar diretamente em JSON

Abra `dados/agenda-solidaria.json`. Em `acoes`, inclua objetos conforme o exemplo estrutural abaixo, trocando todos os valores pelos dados confirmados. O exemplo não representa uma ação real e não foi cadastrado na agenda pública.

```json
{
  "id": "identificador-unico-da-acao",
  "titulo": "Título confirmado da ação",
  "status": "planejada",
  "data": "2026-12-10",
  "horario": "Horário a confirmar",
  "descricao": "O que será realizado",
  "itens_solicitados": ["Item que pode ser doado"],
  "itens_recebidos": [{"item": "Item recebido", "quantidade": 1, "unidade": "kg"}],
  "pontos_coleta": [{
    "nome": "Nome do ponto de coleta",
    "endereco": "Endereço confirmado",
    "horarios": "Dias e horários para receber doações",
    "contato": {"nome": "Responsável", "whatsapp": "", "email": ""}
  }],
  "distribuicao": {
    "local": "Onde ocorrerá a distribuição",
    "horario": "Data e horário confirmados",
    "descricao": "Como será realizada a ação e a distribuição"
  },
  "contato": {"nome": "Responsável geral", "whatsapp": "", "email": ""},
  "link": ""
}
```

- `id`: único, sem espaços. Preserve-o ao atualizar uma ação.
- `status`: `rascunho`, `planejada`, `confirmada`, `concluida` ou `cancelada`. Rascunhos não aparecem na página, mas o arquivo JSON publicado continua público; não inclua dados confidenciais.
- `data`: `AAAA-MM-DD`; horários são textos informativos, sem agendamento de mensagens.
- `itens_solicitados`: lista do que é necessário. `itens_recebidos`: quantidades já recebidas, documentadas, por item e unidade. Não misture unidades diferentes.
- `pontos_coleta`: permite vários locais com responsáveis diferentes.
- `distribuicao`: destino, horário e explicação da ação. Não exige publicar nomes de beneficiários.
- `contato`: nome e canais públicos autorizados; WhatsApp somente dígitos com código do país.
- `link`: opcional, HTTPS. Pode levar a um aviso ou material externo.
- `traducoes.en` e `traducoes.es`: opcionais, com os mesmos campos textuais para traduzir uma ação. Sem tradução editorial, as informações fornecidas permanecem em português; a interface acompanha o idioma escolhido.

Depois de salvar, execute `python3 scripts/validar_site.py` e publique por Commit/Push no GitHub. Assim que o GitHub Pages terminar a publicação, a página lê o arquivo atualizado. Ela verifica os dados ao abrir, a cada cinco minutos e ao retornar à aba; recarregue para conferir imediatamente. O JavaScript não salva alterações diretamente no GitHub pelo navegador.

## Usar Excel ou LibreOffice

Abra `modelos/agenda-solidaria.csv`. A primeira linha contém os cabeçalhos; acrescente uma ação por linha. Exporte como CSV UTF-8, preservando os nomes das colunas. Não publique a planilha com dados de teste.

Campos disponíveis: `id`, `titulo`, `status`, `data`, `horario`, `descricao`, `itens_solicitados`, `item_recebido`, `quantidade_recebida`, `unidade`, `coleta_nome`, `coleta_endereco`, `coleta_horarios`, `distribuicao_local`, `distribuicao_horario`, `distribuicao_descricao`, `contato_nome`, `whatsapp`, `email`, `link`.

Use `|` para separar vários itens solicitados, como `Arroz|Feijão|Óleo`. A importação CSV simples aceita um ponto de coleta e uma linha de recebimento por ação; para vários pontos ou vários itens recebidos, complete as listas no JSON. Não crie linhas com IDs repetidos.

Na pasta do repositório, execute:

```bash
python3 scripts/importar_agenda.py caminho/da-planilha.csv --saida dados/agenda-solidaria.json
python3 scripts/validar_site.py
```

O importador valida os registros antes de substituir o JSON por gravação atômica. Esse comando substitui a agenda pelo conteúdo completo da planilha: mantenha também as ações anteriores que deseja conservar. Ele não faz upload, commit, push nem leitura automática do Drive. Publique os arquivos alterados normalmente. O site então monta os cartões sem precisar editar HTML.

## Relação com outras páginas

Esta é a agenda operacional de ações, coletas e distribuição. A prestação de contas financeira continua em `dados/prestacao-contas.json`; são informações diferentes. As agendas das igrejas permanecem em `dados/comunidades.json`. Não foi inventada parceria institucional.

## Momento diário

Na página inicial, mudar o dia ou o mês altera a data usada na seleção de orações, hinos e reflexão. O mesmo dia volta a apresentar a mesma seleção. Como os acervos são finitos, materiais podem reaparecer em outras datas; não há geração infinita nem pesquisa online automática. Amplie `oracoes.txt`, `louvores.json` e `pausa-diaria.json` para aumentar a variedade. A reflexão, o passo e sua referência bíblica continuam associados na entrada de `pausa-diaria.json`.

As orações e os hinos não são mais fixados por campos do cronograma na vitrine inicial. Leituras em `dados/leituras.json`, por data, têm prioridade e ficam fiéis ao cronograma da igreja. Onde não há leitura cadastrada, aparece a referência sugerida pela reflexão do dia, identificada como escolha editorial. O PDF ainda precisa ser enviado e convertido/revisado para preencher `leituras.json`; apenas subir um PDF não preenche o calendário automaticamente.

A rotação depende da data escolhida, não de recarregar aleatoriamente o site. Os testes confirmaram navegação entre dias passados/futuros e troca de mês; a leitura cadastrada em um teste continuou fixa.

## Destaque bíblico

Tiago 1:27 ganhou destaque na página inicial, com o versículo completo na ACF e link ao capítulo: https://www.bibliaonline.com.br/acf/tg/1. Inglês e espanhol apresentam traduções editoriais da passagem, identificadas; não se apresentam como citações de uma edição bíblica publicada nesses idiomas.

## Especificação audiovisual anexada

O documento anexado, preservado em `docs/ESPECIFICACAO-BIBLIOTECA-AUDIOVISUAL-V3.md`, trata de uma automação independente e ampla: YouTube API, filas persistentes, quotas e GitHub Actions. Ele está guardado como especificação pendente. Nenhuma API, chave, workflow de descoberta, verificação ou manutenção dessa especificação foi ativado nesta atualização. A agenda solidária funciona por JSON/CSV independentemente disso.


## Página única Ajudar o próximo

A página inicial mescla o antigo bloco de solidariedade com o bloco de contribuição, mantendo o título “Ajudar o próximo começa com um gesto”, opções de alimentos, roupas e mutirão, resumo do destino das contribuições, WhatsApp e Pix. A chamada de detalhes abre `#solidariedade`, agora a página **Ajudar o próximo**.

Essa página reúne o que doar, ajuda que pretendemos organizar, como combinar entrega ou pedido de ajuda, destino dos recursos, as seis propostas de software, uso da IA, agenda de ações/coleta/distribuição e Pix. Os projetos continuam sendo lidos de `dados/projetos.json`; alterar o catálogo atualiza também essa apresentação. Os textos estão em `pagina-inicial.json` nos três idiomas, com chaves `giveTitle`, `giveIntro`, `giveWays`, `giveNeedsText`, `giveWhereText`, `giveMoneyText` e `giveTechnologyText`.

Os links antigos `#doacoes` e `#agenda-solidaria` continuam válidos, mas são trechos internos dessa página, e não páginas separadas no menu. `#doacoes` abre o grupo de Pix automaticamente. O QR Code e seus dados foram preservados. O resumo da inicial também mantém um acesso a esse trecho.

O cartão de agenda continua sendo alimentado por `dados/agenda-solidaria.json` e pelo importador CSV já documentado. Use `pontos_coleta`, `distribuicao` e `contato` para informar locais e responsáveis confirmados. Vicentinos e igrejas são apresentados como possibilidades de cooperação; não foram cadastrados como pontos de recebimento oficiais. A área de parcerias da página inicial permaneceu exatamente como estava. A prestação de contas financeira continua em sua página própria.

Validação: IDs e destinos locais; conteúdo das parcerias e imagem do Pix preservados; seis projetos renderizados; links antigos abrem a página única; página de ajuda em 320 px sem rolagem horizontal.


Atualização: a página Ajudar o próximo mantém o texto explicativo sobre IA e um link para **Projetos em desenvolvimento**. A lista completa de softwares e propostas editoriais fica somente nessa página de projetos; a página inicial mantém três exemplos.
