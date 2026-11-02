# Revisão da versão — Plataforma Global de Evangelização

Data: 2 de novembro de 2026.

## Alteração desta entrega

A frase principal da página inicial passou a ser **A fé sem obras é morta.**, acompanhada apenas de **Tiago 2:26**. Não aparecem “trecho” nem “ACF” nessa referência. O subtítulo “Fé, aprendizado e cuidado”, o parágrafo de apresentação, o botão inicial, a ilustração e o destaque completo de Tiago 1:27 foram preservados. Os idiomas inglês e espanhol receberam a frase e a referência correspondentes.

## Estrutura presente e conferida

| Área | Situação desta versão |
|---|---|
| Página inicial | Frase principal atualizada, busca, biblioteca, projetos, estudo diário e convites de participação |
| Biblioteca | Cartão “Projetos: cursos e ferramentas”, com escolas, igrejas, comunidades e instituições de cuidado na apresentação |
| Projetos | 58 cartões em uma página, sem grupos expansíveis; busca, estados e links derivados dos dados |
| Cursos e ferramentas adicionais | Propostas em planejamento para acolhimento, casas de apoio, centros de idosos e formação comunitária; sem cursos anunciados como prontos |
| Solidariedade e doações | Uma página “Ajudar o próximo”, com formas de ajudar, destino pretendido dos recursos, agenda, WhatsApp e Pix |
| Agenda solidária | Fonte JSON, modelo CSV e importador local; coleta, doações recebidas, distribuição e contatos; sem ações reais inventadas |
| Parceiros | Categoria humanitária dentro de “Seja nosso parceiro”, com três instituições, contribuições possíveis e páginas institucionais preservadas |
| Celebrações, encontros e atividades | Página própria com oito propostas por instituição, respeito à organização/doutrina e links para as agendas |
| Estudo da inicial | Oração, louvor e reflexão selecionados por data; troca de mês atualiza a seleção; leituras cadastradas têm prioridade |
| Contato | Convites para iniciar conversa pelo WhatsApp, e-mail e canais sociais; número não exibido no cartão principal de contato |
| Busca | Palavras-chave, títulos e trechos do conteúdo renderizado; resultados clicáveis, sem histórico ou serviço pago |
| Idiomas | Português, inglês e espanhol; arquivos equivalentes e exceções compartilhadas conferidos |
| Temas e leitura | Tema claro/escuro, rótulos destacados e correção de palavras unidas nas quebras de linha móveis |
| Escola e estudos | Estrutura de disciplinas, conteúdos de fé, santidade, cuidado de si, corpo e escolhas preservada |
| Mídias e materiais | Estrutura de filmes/desenhos, músicas, playlists, lives, artigos, livros e materiais de ensino preservada; catálogos dependem de conteúdo real |
| Prestação de contas | Estrutura mensal, gráficos e indicadores derivados dos dados, documentos e modelo de planilha; catálogo público ainda sem registros financeiros reais |

## Verificações executadas nesta revisão

- Validação de estrutura, JSONs, idiomas, IDs, âncoras, datas e arquivos locais.
- Testes da vitrine: 13 projetos/propostas, três destaques iniciais, filtros, estados, destinos seguros e leitura fixa por data.
- Testes multilíngues: conjuntos de arquivos, IDs e valores de controle preservados e 2.000 orações em cada idioma.
- Testes de atividades: três instituições, oito propostas, links para agendas e contribuições sem duplicação.
- Testes da agenda: dados de uma ação, rascunhos ocultos, itens recebidos, locais de coleta, distribuição e contatos.
- Testes de prestação de contas: conciliação dos valores, percentuais, indicadores, histórico e rejeição de dados inconsistentes.
- Testes de estudos: conteúdos de pecado, santidade e corpo/escolhas, propostas e atualização de estados.
- Testes de contatos, catálogo educacional e links seguros.
- Testes da busca: palavras-chave, normalização de acentos/maiúsculas, múltiplos termos e ausência de resultados.
- Teste de importação CSV: campos, quantidades, coleta, contato e rejeição de status inválido.
- Conferência da frase e referência no navegador; medição da página inicial em iframe de 320 pixels CSS, sem rolagem horizontal.

Todos esses testes passaram. São testes locais e de navegador, não uma auditoria clínica, teológica, jurídica, de acessibilidade completa ou de todos os links externos.

## O que ainda depende de material ou configuração

- **Cronograma bíblico da igreja:** o PDF ainda precisa ser enviado, extraído e revisado para alimentar `dados/leituras.json`. Apenas publicar um PDF não preenche o calendário.
- **Ações e parceiros reais:** datas, endereços, horários, responsáveis, autorização de recebimento e parcerias precisam ser confirmados e cadastrados. Nenhuma parceria formal ou ponto de coleta foi presumido.
- **Cursos, projetos e acervo:** os projetos em planejamento precisam ser desenvolvidos; vídeos, filmes, livros, artigos, links e playlists precisam de registros reais, autorizações e revisão. A estrutura pronta não significa conteúdo já produzido.
- **Prestação de contas real:** alimentar os dados e documentos de cada mês conforme as ações ocorrerem.
- **Automação audiovisual do anexo:** o documento V3 está preservado em `docs/ESPECIFICACAO-BIBLIOTECA-AUDIOVISUAL-V3.md`; a implementação de descoberta, verificação, filas, quotas e GitHub Actions permanece pendente. Não há integração YouTube API ativa nessa entrega.
- **Avisos automáticos por e-mail/WhatsApp e sincronização da conta Spotify/Drive:** não foram ativados. Links, arquivos locais e botões de contato funcionam independentemente dessas integrações.
- **Aparelhos reais e publicação:** testar após publicar em Android, iPhone/Safari e TV, incluindo fonte ampliada, orientação da tela e controle remoto. Não houve publicação direta no GitHub nesta entrega.

## Limites importantes do funcionamento atual

A rotação diária usa acervos finitos: conteúdos podem reaparecer em outras datas e a mesma data mantém sua seleção. Não há geração infinita ou busca automática de novas orações. A leitura cadastrada do cronograma fica fixa na sua data.

A busca lê o conteúdo presente/renderizado no site; não pesquisa dentro de PDFs, vídeos ou páginas externas. Catálogos filtrados ou ainda não carregados podem limitar os itens disponíveis à busca.

Editar um JSON ou converter uma planilha exige publicar o arquivo resultante no repositório. O navegador lê os arquivos publicados; não faz commit nem altera os arquivos do GitHub sozinho.

## Conferência sugerida após subir o ZIP

- Abra a inicial e confira a nova frase e Tiago 2:26.
- Pesquise por WhatsApp, Pix, cursos e atividades.
- Abra a página de projetos e confira os 13 registros, os filtros e as propostas novas.
- Confira Ajudar o próximo, a agenda e os acessos de contato.
- Confira Parceiros, as instituições e a página de atividades.
- Selecione outra data no estudo diário e avance/volte o mês.
- Troque idioma e tema; faça a conferência também no celular.

O arquivo `README.md` contém o caminho de manutenção. `AGENDA-SOLIDARIA.md` detalha os dados da agenda e a importação CSV. Este relatório registra a situação desta entrega e suas pendências, sem declarar integrações ou materiais ainda inexistentes como concluídos.


## Ampliação posterior da mesma entrega

A página de projetos apresenta categorias abertas, com 25 propostas de cursos, 20 propostas de palestras e 13 outros projetos/iniciativas: 58 cartões. As formações incluem cinco propostas em cada uma das quatro frentes iniciais, dez palestras escolares, dez palestras para o serviço público e cinco cursos para o campo. Foram acrescentadas quatro ferramentas propostas para gestão pública, sustentabilidade e produção rural. Busca, categoria e status permitem localizar os registros.

Parceiros ganhou página própria por cidade, unidade e comunidades vinculadas, com campos independentes para Instagram, endereço e contatos em `dados/rede-parceiros.json`. Os dados atuais continuam a propor, sem contatos oficiais inventados. Essa organização substitui o agrupamento anterior como categoria interna de Seja nosso parceiro.

A regra de cursos e palestras gratuitos, com convite final à doação voluntária, está registrada em `GUIA-FORMACOES-GRATUITAS.md`, `dados/formacoes.json` e `AGENTS.md`. A biblioteca audiovisual automatizada do anexo continua pendente, assim como materiais e contatos reais.


## Favicon e verificação final

Ícone próprio da plataforma com cruz e arco: SVG, PNG 16/32 px, ICO e ícone 180 px para atalhos. As cinco referências no HTML, arquivos e dimensões foram conferidos; o preview incorpora os ícones.

Foram testados o filtro das dez palestras escolares, as dez palestras públicas, a gratuidade anunciada, as 58 fichas e os dados das 45 formações. O diretório de parceiros foi testado com duas cidades fictícias apenas no teste, perfis distintos de Instagram por unidade/comunidade e busca por comunidade rural. Esses dados de teste não foram publicados.

Inicial, projetos e parceiros foram medidos em 320 pixels CSS, sem rolagem horizontal. As versões em português, inglês e espanhol e os arquivos locais passaram na validação. O PDF e integrações externas do anexo continuam pendentes; não houve publicação automática no GitHub.
