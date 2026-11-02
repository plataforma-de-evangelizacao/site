# Parceiros por cidade, unidade e comunidade

A página própria é **Parceiros e comunidades**, no endereço interno `#parceiros`. Ela pode ser aberta pela página inicial, por Explorar e por Seja nosso parceiro. O convite à colaboração continua na página `#seja-parceiro`.

O catálogo principal dessa página é **dados/rede-parceiros.json**. Cada unidade tem seu próprio ID, cidade e contatos. Os dados de Instagram, telefone e localização não são copiados de uma igreja para outra, nem de uma cidade para outra.

## O que já está cadastrado

Há três registros institucionais a propor em Nova Bandeirantes: Igreja Católica, Igreja Batista Nacional e Vicentinos. Os nomes específicos das unidades locais, endereços e canais oficiais ainda estão pendentes. Nenhum Instagram ou telefone de instituição foi inventado. As parcerias não foram marcadas como confirmadas.

As novas cidades aparecem automaticamente no seletor quando uma unidade dessa cidade é acrescentada ao JSON. Não foram criados parceiros fictícios em cidades citadas apenas como exemplos.

## Estrutura de uma unidade

O arquivo contém `versao` e uma lista `unidades`. Cada item aceita:

| Campo | Como preencher |
|---|---|
| `id` | Identificador único, como `nome-unidade-cidade`; não reutilizar entre cidades |
| `nome` | Nome específico da paróquia, igreja, associação ou unidade |
| `instituicao` | Tipo institucional, como `catolica`, `batista`, `vicentinos` ou outro identificador editorial |
| `cidade` / `uf` | Município e estado; usados no agrupamento e no filtro |
| `bairro` / `comunidade` | Identificação local quando houver |
| `zona` | `urbana`, `rural` ou `a-informar` |
| `endereco` | Endereço confirmado; deixe vazio se não foi informado |
| `instagram` | URL HTTPS completa do perfil dessa unidade, em instagram.com; não usar o perfil de outra cidade |
| `telefone` | Telefone com `+` e código do país, como formato `+55...`; espaços e parênteses podem ser usados na apresentação |
| `whatsapp` | Somente dígitos, com código do país |
| `email` | E-mail institucional ou público autorizado |
| `site` / `mapa` | URLs HTTPS opcionais |
| `status` | `a-propor`, `em-conversa`, `confirmada` ou `pausada` |
| `identificacao_local_pendente` | `true` enquanto o nome da unidade/comunidade não estiver confirmado; mude para `false` quando definido |
| `descricao` | Apresentação breve dessa unidade |
| `contribuicoes_possiveis` | Lista de contribuições a combinar, como tempo, alimentos, roupas e conhecimento |
| `agenda` | Lista opcional com `titulo`, `data`, `horario` e `local` para a própria unidade |
| `comunidades` | Comunidades/bairros/locais rurais vinculados à unidade, com dados próprios |
| `traducoes.en` / `traducoes.es` | Nome, descrição e contribuições traduzidos editorialmente |

Os dados públicos aparecem em cartões por cidade. O visitante pode filtrar cidade, buscar instituição/bairro/comunidade e expandir **Comunidades, localização e contatos**.

## Acrescentar uma comunidade vinculada

Dentro de `comunidades`, inclua um objeto com `id`, `nome`, `bairro`, `zona`, `endereco`, `instagram`, `telefone`, `whatsapp`, `email`, `site`, `mapa` e `agenda`, conforme houver dados. A cidade e a UF vêm da unidade que contém a comunidade. Os contatos não são herdados automaticamente: preencha o Instagram e o telefone corretos daquela comunidade.

A lista `agenda` usa objetos com `titulo`, `data`, `horario` e `local`. Só informe eventos confirmados. Datas e horários são exibidos como cadastrados; revise eventos vencidos ou identifique o histórico. Não há sincronização automática com redes sociais ou calendários.

## Agendas institucionais anteriores

Os três registros iniciais possuem `agenda_link` para suas páginas institucionais já preparadas. Essas páginas continuam lendo `dados/comunidades.json`. Para uma nova unidade de outra cidade, não copie um `agenda_link` que leva a uma página de Nova Bandeirantes: use o campo `agenda` do novo registro ou suas comunidades até haver uma página específica.

## Passo a passo de atualização

- Confirme nome, localização e canais com o responsável pela unidade.
- Abra `dados/rede-parceiros.json` no VS Code e acrescente o registro em `unidades`.
- Confira ID único, cidade/UF, status e contatos. Use campos vazios para o que ainda não foi informado.
- Acrescente as comunidades vinculadas, cada uma com seus canais próprios.
- Atualize traduções quando houver; nomes oficiais podem ser mantidos na língua original.
- Execute `python3 scripts/validar_site.py`.
- Faça Commit/Push. Após o GitHub Pages publicar, recarregue a página e teste os links.

O controlador `assets/partners.js` lê o arquivo ao abrir, a cada cinco minutos e ao retornar à aba. O site não faz upload, commit ou descoberta automática de perfis oficiais.

## Fontes de dados distintas

- `rede-parceiros.json`: unidades, cidades, comunidades e contatos dessa nova página.
- `parcerias.json` nos idiomas: convite geral de Seja nosso parceiro e contato com a plataforma.
- `comunidades.json`: agendas e contatos das três páginas institucionais iniciais.
- `atividades-parcerias.json`: propostas de atividades que podemos oferecer às comunidades; não confirma eventos ou parceiros.
- `parceiros.json` nos idiomas: catálogo genérico legado, preservado por compatibilidade; ele não recria os cartões da nova página por cidade.

As contribuições possíveis da nova página são editadas em cada unidade de `rede-parceiros.json`. Confirmar uma parceria não torna os locais pontos de coleta automaticamente: informe os locais combinados na agenda solidária.
