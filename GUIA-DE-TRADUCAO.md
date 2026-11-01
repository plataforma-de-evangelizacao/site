# Tradução e organização dos idiomas

## Onde estão os arquivos

| Conteúdo | Português | Inglês | Espanhol |
| --- | --- | --- | --- |
| Orações | dados/oracoes.txt | dados/en/oracoes.txt | dados/es/oracoes.txt |
| Reflexões | dados/reflexoes.txt | dados/en/reflexoes.txt | dados/es/reflexoes.txt |
| Buscando | dados/buscando.json | dados/en/buscando.json | dados/es/buscando.json |
| Autocuidado | dados/autocuidado.json | dados/en/autocuidado.json | dados/es/autocuidado.json |
| Acolhimento | dados/acolhimento.json | dados/en/acolhimento.json | dados/es/acolhimento.json |
| Demais JSON | dados/nome.json | dados/en/nome.json | dados/es/nome.json |
| Referências | dados/recursos-santidade.txt | dados/en/recursos-santidade.txt | dados/es/recursos-santidade.txt |
| Catálogo geral | catalogo.txt | dados/en/catalogo.txt | dados/es/catalogo.txt |

A pausa diária mantém o formato com três traduções em cada registro; sua cópia em cada pasta preserva esse formato. As listas que ainda estavam vazias permanecem vazias; não foram inventados livros, palestras ou ações.

## Como a troca funciona

O idioma escolhido é registrado no navegador e no parâmetro `lang=pt`, `lang=en` ou `lang=es`. A página recarrega mantendo o assunto atual. O carregamento de arquivos locais de conteúdo passa à pasta correspondente; serviços externos permanecem intactos. Não depende de API de tradução nem de serviço pago.

Os rótulos e frases fixas dos módulos são traduzidos por assets/localization.js. Os dicionários de referência também estão em dados/en/interface.json e dados/es/interface.json. Alterar apenas esses JSON de interface não altera automaticamente o dicionário incorporado ao JavaScript: para novas frases de interface, atualize também assets/localization.js. Atualizar o acervo não exige mexer nesse código.

## Preservação de sentido

As traduções mantêm o encadeamento dos textos, exemplos, ressalvas e referências. Não pretendem demonstrar que toda palavra tem uma única equivalência em outra língua. Uma revisão humana, idealmente com conhecimento bíblico e proficiência no idioma, é recomendada antes de uso em livros ou ensino formal.

| Português | Inglês | Espanhol | Critério |
| --- | --- | --- | --- |
| Santidade | Holiness | Santidad | Vida e prática espiritual; não confundir com diagnóstico de saúde. |
| Arrependimento | Repentance | Arrepentimiento | Preservar reconhecimento do erro e mudança de direção. |
| Mansidão | Gentleness | Mansedumbre | Não traduzir como submissão à violência. |
| Vaidade da mente / criação | Futility, conforme o contexto | Vanidad, conforme o contexto | Distinguir de vaidade como exibição da aparência. |
| Próximo | Neighbour | Prójimo | Manter a dimensão ética e relacional. |
| Permanecer em Cristo | Remain in Christ | Permanecer en Cristo | Preservar a relação expressa no texto. |

O Pai-Nosso preserva todos os pedidos da BLIVRE fornecida, incluindo a doxologia. As versões inglesa e espanhola são traduções editoriais atribuídas, sob a licença da fonte, e mantêm o acesso ao português. Não foram rotuladas como WEB, KJV, Reina-Valera ou outra edição que não tenha sido citada diretamente.

Não foi baixada nem traduzida uma Bíblia integral. Os arquivos PDF, vídeos, artigos externos e canções mantêm seus conteúdos e direitos originais. Nomes próprios, nomes de obras e títulos de músicas podem continuar em português para preservar a identificação.

## Atualizar sem quebrar filtros

Os nomes dos campos JSON não mudam. IDs e categorias usados pelo sistema permanecem estáveis. Exemplos: `abraao`, `Antigo Testamento`, `Corpo`, `Protestante`, `catolica`, `escuta`. A interface apresenta os rótulos no idioma escolhido. Não traduza esses identificadores sem adaptar os módulos que os utilizam.

Mantenha o mesmo número e a mesma ordem das orações em cada idioma: a correspondência por data depende disso. Acrescente e revise os conteúdos nas três versões; publicar uma alteração em português não cria uma tradução automaticamente. Teste a troca de idioma após cada atualização.

Informações de contato, dados do Pix e URLs não são traduzidos. O idioma do site não determina o país da pessoa nem muda os números de apoio do Brasil.

## Exceção: planejamento compartilhado

`dados/planejamento.json` é um único arquivo para todos os idiomas. Os estados, formatos e links são compartilhados; os títulos e resumos têm campos de tradução. Não criar versões em en/es. Os materiais previstos continuam em português, com aviso traduzido.

Os novos estudos usam `pecado.json` e `espirito-santidade.json` em cada pasta de idioma. Os arquivos assets/sin.js, assets/plan.js e assets/spirit.js mantêm também conteúdo inicial para a prévia independente. Ao alterar o acervo publicado, o carregamento dos JSON substitui esse conteúdo inicial.

## Corpo, vontade e escolhas

corpo-escolhas.json existe nas três pastas de idioma. Os sete campos são uma organização didática autoral. Preservar a distinção entre sensação, pensamento involuntário, consentimento e ação; não traduzir como uma equivalência tradicional entre órgãos e vícios. Cocriação significa aqui aprender, criar e compartilhar para servir, sem promessa de manifestação.
