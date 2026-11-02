# Painel administrativo — atualização de 2 de novembro de 2026

Foi criada a página `admin/`, com autenticação preparada por e-mail/senha via Supabase Auth, políticas RLS, revisão de vídeos, histórico e editor JSON por área da plataforma. Há link Administração no rodapé. Leia **PAINEL-ADMINISTRATIVO.md** antes de ativar.

O login permanece bloqueado até configurar o projeto gratuito, executar o SQL de permissões, cadastrar e autorizar o administrador e preencher as chaves públicas/Secrets corretos. Nenhuma senha padrão foi criada; a integração real não foi testada em uma conta Supabase nesta entrega.

O Actions administrativo processa solicitações aproximadamente a cada 15 minutos; valida usuário, versão e conteúdo, grava por commit sem força e solicita a publicação. As credenciais privadas não entram no frontend. A gestão dos outros conteúdos começa por editor JSON; não são anunciados formulários visuais ou uploads que ainda não existem.

Validação: 22 testes administrativos + 42 da biblioteca passaram; interface testada com dados e sessão simulados, removidos do pacote; largura mobile de 320px sem rolagem horizontal; conferidos aprovação com confirmação, fila, histórico, JSON inválido e encerramento de sessão. Políticas SQL e credenciais reais ainda dependem da configuração e verificação na sua conta.

---

# Aprovação automática ativada na configuração desta atualização

A execução real enviada por Marcos confirmou a API e a descoberta: 272 vídeos novos, 273 pendentes (incluindo o teste), sem erros e sem tarefas restantes. O catálogo não mudou porque a aprovação estava desligada.

Esta atualização habilita `autoApprovalEnabled` e uma regra inicial de seleção por metadados. Não basta trocar false por true em uma lista de regras vazia. Copie também os scripts atualizados.

A regra exige título com indicação de produção audiovisual e contexto bíblico explícito, duração mínima de quatro minutos (vinte para filmes), categoria identificável e português declarado no áudio da API ou, quando não houver declaração de áudio, no título. Uma declaração de áudio em outro idioma impede a aprovação por essa regra. Trailers, análises, músicas, pregações, resumos e formatos excluídos continuam pendentes. Rejeições e bloqueios são respeitados.

Essa seleção é automática por informações declaradas na origem: não significa que o vídeo foi assistido, que a idade foi certificada ou que a adaptação foi conferida teologicamente. Nenhuma referência bíblica é inventada. Casos sem informação suficiente continuam em revisão.

Para aplicar: copie `biblioteca-controle/config.json`, `scripts/biblioteca/core.py`, `scripts/biblioteca/run.py` e `tests/biblioteca/test_core.py` para os mesmos caminhos do repositório e faça commit. O ID do vídeo de teste já informado foi preservado. Não altere Secrets nem apague a branch `biblioteca-estado`.

Depois execute **Actions → Biblioteca e GitHub Pages → Run workflow → atualizar**, em `main`. Os metadados recentes dos vídeos encontrados serão reprocessados sem repetir buscas ainda válidas. Confira o último resumo: `approvedPublic` mostra os títulos elegíveis publicados/para publicar e `pendingReview` os restantes. O deploy só está confirmado quando o job `publicar` termina com sucesso.

Validação desta atualização: 42 testes locais passaram, incluindo casos específicos de aprovação, idioma ausente/conflitante, trailer e rejeição preservada. A alteração ainda não foi aplicada ao GitHub por esta conversa; use o pacote ou os arquivos indicados.

---

## Biblioteca audiovisual V3 — atualização de 2 de novembro de 2026

A biblioteca agora tem processamento automatizado preparado em `.github/workflows/biblioteca.yml`, filas persistentes, cache, orçamento de API, revisão editorial, filtros e player oficial sob demanda. **Ainda não está ativada no GitHub e nenhuma chamada real foi realizada nesta entrega.**

Siga [BIBLIOTECA-AUTOMATICA.md](BIBLIOTECA-AUTOMATICA.md) para configurar Actions + Pages, cadastrar `YOUTUBE_API_KEY` nos Secrets e executar o teste controlado. Esse guia é a referência atual para o catálogo audiovisual e substitui instruções antigas que o descrevam apenas como `catalogo.txt` ou automação futura. Os outros catálogos permanecem com seus arquivos atuais.

As configurações editáveis ficam em `biblioteca-controle/`, as decisões por vídeo em `editorial.json` e os dados públicos em `dados/biblioteca/`. O estado gerado fica na branch operacional `biblioteca-estado`, separada de `main` e do artefato público do Pages. Não é um cofre: nenhuma credencial ou informação confidencial pode entrar nessa branch de repositório público.

Validação local: 35 testes automatizados sem quota, cenário de 10 mil vídeos e conferência de busca, filtros, paginação, fallback do player e celular com fixtures removidas após o teste. Teste real de API, agendamento e deploy continuam pendentes da configuração.

---

# Estado atual desta entrega — 2 de novembro de 2026

A plataforma está preparada para publicação manual no GitHub Pages. Esta visão atual substitui contagens e organizações descritas nas revisões históricas abaixo.

- Abertura: **A fé sem obras é morta. — Tiago 2:26**, sem os rótulos “trecho” ou “ACF”. O restante da apresentação foi preservado.
- Projetos: **58 cartões**, em oito categorias abertas, com busca, filtro de categoria e estado. São 25 cursos propostos, 20 palestras propostas e 13 outras ferramentas/iniciativas. Nada foi anunciado como curso já produzido.
- Formações: gratuitas, com encerramento que convida à doação voluntária. Veja **GUIA-FORMACOES-GRATUITAS.md**; a orientação também está em **AGENTS.md** e `dados/formacoes.json`.
- Parceiros: página própria por cidade, unidade e comunidades, com contatos independentes. Veja **PARCEIROS-POR-CIDADE.md**; fonte principal: `dados/rede-parceiros.json`.
- Atividades: página própria de propostas para as comunidades, respeitando organização e doutrina; não confundir com agenda confirmada.
- Ícone do navegador: `assets/favicon.svg`, PNG de 16/32 px, `favicon.ico` e ícone de 180 px para atalhos de celular. Os caminhos são relativos e funcionam em `/site/`.
- Revisão e pendências: **REVISAO-FINAL.md**. O PDF do cronograma, materiais reais, contatos oficiais e automações externas ainda dependem de envio/configuração.

## Manutenção das propostas de formação

As frentes em `dados/projetos.json` usam `cursos_propostos` ou `formacoes_propostas`. A página expande esses registros em cartões. Cada formação possui público, objetivo, três conteúdos iniciais, materiais a produzir, status, links e traduções. As sete frentes são acolhimento, casas de apoio, centros de idosos, formação comunitária, escolas, serviço público e campo. As ferramentas sem lista de formações aparecem no grupo geral de tecnologia e iniciativas comunitárias. As propostas editoriais continuam em `dados/ideias-sociais.json`.

Para cadastrar uma formação, adicione um objeto à lista da frente correspondente. Preserve IDs únicos, indique `tipo: curso` ou `tipo: palestra`, mantenha `gratuito: true` e revise os textos em português, inglês e espanhol. Use `status: em-desenvolvimento`, `etapa: planejamento` e links vazios até ter material real. Quando houver conteúdo publicado, preencha um link HTTPS e revise a descrição dos materiais; o cartão disponibiliza o acesso e troca a nota de planejamento por formação disponível. Pausar continua removendo o acesso ativo.

Para cadastrar uma nova frente, acrescente um objeto com ID, título, descrição, status e `formacoes_propostas`. A categoria é criada automaticamente pelo título da frente; traduza o título em `traducoes.en` e `traducoes.es`. Não é necessário alterar o HTML para isso.

## Rede de parceiros e contatos

Use `dados/rede-parceiros.json` para a página de parceiros por cidade. Não reutilize Instagram ou telefone de outra unidade. Os campos atuais não informados continuam vazios. As três instituições iniciais permanecem a propor, com identificação local pendente. A estrutura permite acrescentar outras cidades, bairros e comunidades rurais apenas alimentando o JSON. O manual **PARCEIROS-POR-CIDADE.md** detalha cada campo e as agendas locais.

## Ícone da plataforma

O favicon usa uma cruz dentro do arco, nas cores da plataforma. O SVG é o arquivo vetorial principal; os PNG e ICO servem como alternativas para navegadores e atalhos. Todos estão referenciados no `<head>` de `index.html` e no ZIP. A prévia independente incorpora os ícones para não depender de arquivos externos. Se o navegador ainda mostrar o ícone antigo depois da publicação, recarregue sem cache ou feche e abra a aba.

---

# Plataforma Global de Evangelização — manual completo do site

Versão de documentação: 1 de novembro de 2026. Responsável: Marcos Lucas Pereira, Nova Bandeirantes, Mato Grosso, Brasil.

Este README é o guia principal para manter a plataforma. Ele documenta o pacote desta entrega; não afirma que essa versão já foi enviada ao seu repositório ou publicada. Os arquivos podem ser mantidos com apoio do ChatGPT, pelo VS Code ou pelo editor do GitHub.

## Índice

0. [Procedimentos completos de atualização](#procedimentos-completos-mude-o-arquivo-e-confira-a-mudança-no-site)
1. [Comece aqui](#comece-aqui)
2. [Repositório privado e site público](#repositório-privado-e-site-público)
3. [Como o site está organizado](#como-o-site-está-organizado)
4. [Mapa de páginas e funções](#mapa-de-páginas-e-funções)
5. [Qual arquivo editar](#qual-arquivo-editar)
6. [Trabalhar com VS Code e Git](#trabalhar-com-vs-code-e-git)
7. [Atualização diária e cronograma](#atualização-diária-e-cronograma)
8. [Projetos de software](#projetos-de-software)
9. [Novos conteúdos com disponibilidade automática](#novos-conteúdos-com-disponibilidade-automática)
10. [Publicações, vídeos e música nos formatos anteriores](#publicações-vídeos-e-música-nos-formatos-anteriores)
11. [Parcerias, solidariedade e doações](#parcerias-solidariedade-e-doações)
12. [Idiomas](#idiomas)
13. [Alterar o visual e a navegação](#alterar-o-visual-e-a-navegação)
14. [Testar e publicar](#testar-e-publicar)
15. [Manutenção com ChatGPT](#manutenção-com-chatgpt)
16. [Problemas comuns](#problemas-comuns)
17. [Prestação de contas mensal](#prestação-de-contas-mensal-planilha-pdf-histórico-e-gráfico)
18. [Playlists por arquivo](#playlists-por-arquivo-passo-a-passo)
19. [Integrações pendentes](#integrações-pendentes)
20. [Referências e documentos complementares](#referências-e-documentos-complementares)

## Procedimentos completos: mude o arquivo e confira a mudança no site

Esta seção descreve o caminho inteiro, da edição ao resultado. Use os nomes exatos dos campos. O JSON é a fonte de conteúdo desta plataforma estática; não existe um backend privado recebendo essas alterações.

### Procedimento 1 — tirar uma palestra de A desenvolver e colocá-la em Gravados ou publicados

**Arquivo:** `dados/planejamento.json`. **Página:** Próximos conteúdos, em `#proximos-conteudos`.

1. Abra a pasta clonada do site no VS Code.
2. Faça Pull para trazer mudanças existentes no GitHub. Se houver edições locais não salvas ou um conflito, resolva antes de substituir o arquivo.
3. Abra `dados/planejamento.json` pelo explorador de arquivos do VS Code.
4. Use `Ctrl + F` para encontrar o título ou ID. Exemplo real já existente: `pecado-cotidiano`. Para Santidade na comunidade, busque o título correspondente no arquivo atual; não crie outra ficha se ela já existe.
5. Dentro daquele objeto, localize `status`. Altere somente o valor de `proposta` para `gravado` quando a gravação estiver concluída, mas o vídeo ainda não estiver publicado.
6. Preserve `id`, `formato`, `titulo`, `descricao`, prioridade e traduções. Não substitua toda a lista por um exemplo do README.
7. Salve com `Ctrl + S`.
8. Execute `python3 scripts/validar_site.py` na pasta do site. Corrija qualquer erro de aspas, vírgulas ou estrutura antes de enviar.
9. No Controle do Código-Fonte, revise a diferença. O registro correto deve mostrar a mudança de estado, sem remoções de outros itens.
10. Prepare o arquivo com `+`, faça Commit com uma mensagem como `Marca palestra como gravada` e depois Push/Sincronizar.
11. No GitHub, acompanhe o método de publicação configurado em Pages/Actions. A mudança precisa chegar ao branch e à pasta publicados.
12. Quando a publicação terminar, abra o site e Próximos conteúdos. Deixe os filtros em Todos os formatos e Todos os estados.
13. **Resultado esperado:** a ficha desaparece de A desenvolver e aparece em Gravados ou publicados como Gravado · publicação pendente. Não há botão de vídeo público ainda.

Trecho antes — mantenha o restante do objeto:

```json
"status": "proposta",
"link": ""
```

Trecho depois da gravação — mantenha o restante do objeto:

```json
"status": "gravado",
"link": ""
```

Esses trechos mostram campos de um objeto; não são arquivos JSON completos. Não cole um trecho isolado por cima de todo o arquivo.

### Procedimento 2 — publicar a palestra e habilitar o botão

1. Publique o vídeo na sua plataforma de origem e copie o endereço público correto.
2. Abra esse endereço como visitante para conferir o acesso. Um vídeo privado não fica público porque seu link foi colocado no site.
3. No mesmo objeto de `dados/planejamento.json`, mude `status` de `gravado` para `publicado`.
4. Preencha `link` com o endereço HTTPS real do vídeo.
5. Preserve todos os demais campos e registros. Salve, valide, faça Commit e Push.
6. Aguarde a implantação e recarregue Próximos conteúdos, com filtros abertos.
7. **Resultado esperado:** a ficha permanece em Gravados ou publicados, agora com estado Publicado e botão Abrir conteúdo.
8. Clique no botão e confira se abriu exatamente o vídeo certo.

Modelo de campos após publicação — substitua o endereço de exemplo por um real:

```json
"status": "publicado",
"link": "https://www.youtube.com/watch?v=COLE_O_ID_REAL"
```

Marcar como publicado sem preencher link move a ficha para o grupo finalizado, mas não inventa um botão. O registro explica que o link está pendente. Um link sem HTTPS não gera acesso. O estado `gravado` também não libera o link principal, mesmo que o campo esteja preenchido: primeiro confirme a publicação.

### Procedimento 3 — artigo ou livro no planejamento anterior

1. Abra `dados/planejamento.json` e encontre o registro pelo ID/título.
2. Para começar o trabalho, use `status: em-producao`.
3. **Resultado:** fica em A desenvolver com o andamento Em produção.
4. Quando o artigo/livro estiver publicado, use `status: publicado` e o link real do texto, PDF autorizado ou página da obra.
5. Salve, valide, faça Commit/Push e aguarde a publicação.
6. **Resultado:** sai de A desenvolver e entra em Gravados ou publicados com botão, se o link HTTPS estiver preenchido.
7. Para artigos e livros, não use gravado apenas como sinônimo de escrito. Reserve esse estado para materiais com gravação.

Mudar o andamento no planejamento não publica o conteúdo em outras plataformas e não copia o texto para outra seção do site. Se quiser o artigo completo dentro da plataforma, cadastre o texto em `artigos.json`; se quiser apenas uma ficha com link, use o catálogo comum. Evite duplicar a mesma ficha na mesma área.

### Procedimento 4 — novo filme, música, vídeo, artigo, curso ou material com estado automático

**Arquivo:** `dados/catalogo-conteudos.json`. **Destino:** a seção correspondente ao `tipo`.

1. Abra o arquivo e localize a lista `itens`.
2. Copie o objeto de `modelos/conteudo.json` para dentro dessa lista. Se já houver itens, coloque uma vírgula entre os objetos, sem vírgula depois do último.
3. Dê um `id` único; escolha `tipo` na tabela de formatos deste README.
4. Preencha título, descrição e traduções EN/ES. Use `status: em-desenvolvimento` e `link: ""` enquanto prepara o material.
5. Salve, valide e publique pelo fluxo de Commit/Push.
6. **Resultado inicial:** a ficha aparece em A desenvolver dentro da seção correspondente. Ainda não tem botão principal.
7. Quando houver publicação real, volte ao mesmo objeto e preencha o `link` HTTPS. Pode também mudar `status` para `publicado` para registrar a intenção.
8. Salve, valide, faça Commit/Push e aguarde a implantação.
9. **Resultado final:** sai de A desenvolver e aparece em Gravados, concluídos ou publicados, com botão Abrir conteúdo.
10. Clique e confira o destino. A área do site é determinada pelo tipo; o idioma não altera o destino externo.

O link funciona como sinal de disponibilidade nesse catálogo. Por compatibilidade com a regra combinada com Marcos, preencher uma URL HTTPS pode tornar a ficha disponível mesmo se o campo status ainda estiver em-desenvolvimento ou proposta. Ao publicar, atualizar também o status deixa o arquivo mais claro para manutenção. Se ainda não deseja divulgar um link, mantenha-o fora do campo principal ou use pausado.

Para uma gravação ainda não publicada, `status: gravado` coloca a ficha no grupo finalizado, mas conserva a indicação Publicação pendente e não abre um link principal. Para trabalho em produção sem link, `status: em-producao` mantém a ficha em A desenvolver. Essas regras valem para os formatos aceitos pelo catálogo comum; não é necessário mudar HTML para cada item.

### Procedimento 5 — projeto de software que ficou disponível

**Arquivo:** `dados/projetos.json`. **Página:** Projetos, em `#projetos`.

1. Localize o projeto pelo ID, como `caminho-escola`.
2. Atualize a descrição para refletir o que realmente foi desenvolvido. Não anuncie função que ainda não existe.
3. Preencha `repositorio` se o código for público. Se o código for privado, não prometa acesso público ao repositório: coloque em `link` uma demonstração ou página pública que deseja divulgar.
4. Se tiver documentação pública, preencha `documentacao` com o endereço real.
5. Atualize `status` para `disponivel` ou `concluido`, e `etapa` para uma descrição coerente. A presença do link é o que libera o acesso; um estado final sem link mostra link pendente.
6. Informe a licença escolhida quando houver uma licença real. Não usar uma licença no catálogo como substituto do arquivo LICENSE do repositório do software.
7. Salve, valide, faça Commit/Push e aguarde o Pages.
8. **Resultado:** o projeto sai de A desenvolver e entra em Gravados, concluídos ou publicados na página Projetos, com Acessar projeto. Se estiver entre os três primeiros registros, seu estado na vitrine inicial também é atualizado.
9. Verifique a demonstração, documentação e permissões como visitante.

A vitrine não recebe dados privados do software. Desenvolver o Caminho da Escola será outro trabalho: autenticação, banco restrito e fluxos de retirada não estão implementados neste site.

### Procedimento 6 — pausar, voltar ao desenvolvimento ou corrigir um endereço

Nos catálogos `projetos.json`, `catalogo-conteudos.json` e `ideias-sociais.json`:

1. Para pausar, mude `status` para `pausado`. Pode guardar o endereço no campo, mas o botão principal fica oculto.
2. Salve e publique. **Resultado:** a ficha aparece no grupo A desenvolver como Pausado, sem botão principal. Link de documentação, se cadastrado, pode continuar aparecendo; remova-o também caso precise recolher todos os destinos.
3. Para retomar sem divulgar o material, use `em-desenvolvimento` e limpe `link`/`repositorio` principais. **Resultado:** permanece em A desenvolver.
4. Para retomar com acesso público, volte a um estado compatível e preencha o link. **Resultado:** volta ao grupo disponível.
5. Para corrigir um destino, troque o endereço no mesmo registro, publique e teste o novo botão. Não crie um segundo registro só para mudar uma URL.

No planejamento anterior, os estados aceitos são os quatro próprios. Para voltar uma ficha à preparação, altere para proposta ou em-producao. Não use pausado no planejamento sem ampliar o seu controlador; use o catálogo comum para fichas que precisam desse estado.

### Procedimento 7 — atualizar as ideias para o bem comum

1. Abra `dados/ideias-sociais.json`.
2. Encontre a proposta por ID ou acrescente um objeto com ID novo, título, descrição, tipo, estado e traduções.
3. Sem link, ela aparece em A desenvolver. Com material publicado e endereço real, passa ao grupo Gravados, concluídos ou publicados com acesso.
4. Use gravado para gravação pendente ou pausado para suspender a divulgação, conforme as regras do catálogo comum.
5. Salve, valide, faça Commit/Push e confira `#ideias-sociais`.

Esse cadastro não cria um artigo, vídeo ou palestra por si. Ele acompanha o trabalho que será produzido e publicado na origem.

### Procedimento 8 — confirmar que a mudança foi publicada

1. Confira se o arquivo salvo é o arquivo da pasta clonada correta.
2. Confira se o commit contém a alteração e se o Push terminou.
3. Confira o branch e a pasta definidos em Settings → Pages ou no workflow existente.
4. Aguarde o resultado da implantação; não basta o arquivo aparecer no branch errado.
5. Abra o site e recarregue. O carregamento também ocorre ao retornar à aba e em intervalos de aproximadamente cinco minutos para esses catálogos.
6. Limpe filtros de formato, estado e busca antes de concluir que um item sumiu.
7. Encontre a ficha pelo título e confira o grupo e o botão.
8. Se continuar antiga, confira o JSON publicado pelo navegador e erros no console; execute o validador local.
9. Se a URL estiver correta mas exigir login, corrija as permissões do destino. O site não altera a privacidade de vídeos, Drive ou GitHub.

Editar o JSON é suficiente para a página mudar depois de esse JSON chegar à publicação. Não é necessário editar o HTML para cada troca de estado. A publicação na origem e a publicação do JSON são duas etapas distintas.

### Qual fluxo usar para cada conteúdo

| Conteúdo | Arquivo recomendado para acompanhar andamento | Onde muda |
| --- | --- | --- |
| Proposta editorial já existente | planejamento.json | Próximos conteúdos: A desenvolver / Gravados ou publicados |
| Software | projetos.json | Projetos: A desenvolver / Gravados, concluídos ou publicados |
| Ideia social de artigo/palestra | ideias-sociais.json | Ideias para o bem comum: os dois grupos |
| Novo filme/desenho | catalogo-conteudos.json, tipo filme/desenho | Seção de filmes: os dois grupos |
| Nova música como conteúdo publicado | catalogo-conteudos.json, tipo musica | Música: os dois grupos |
| Novo artigo/estudo com link externo | catalogo-conteudos.json, tipo artigo/estudo | Artigos e estudos: os dois grupos |
| Novo curso | catalogo-conteudos.json, tipo curso | Escola: os dois grupos |
| Novo material educativo | catalogo-conteudos.json, tipo material | Biblioteca de ensino: os dois grupos |
| Livro, vídeo ou palestra com estado | catalogo-conteudos.json, tipo livro/video/palestra | Área correspondente: os dois grupos |
| Texto completo já publicado na página | artigos.json / estudos.json | Publicações dentro da plataforma, sem ciclo de estados |
| Louvor do dia | louvores.json | Seleção por data, diferente da ficha de produção musical |
| Live programada | lives.json | Agenda/destaque pela programação, diferente de proposta de vídeo |

Os arquivos anteriores mantêm seus formatos específicos. Acrescentar status em um arquivo antigo que não o lê não cria esse comportamento. Para acompanhar propostas de qualquer formato aceito, use os catálogos de andamento indicados na tabela. A aplicação do estado é automática nos controles que realmente o suportam, sem prometer que todos os formatos antigos foram convertidos.

## Comece aqui

A plataforma reúne fé cristã, conhecimento e cuidado com o próximo. A entrada apresenta o acervo, a Escola, projetos, o momento diário, formas de ajudar, doações e possíveis parcerias. Os três caminhos principais são Conhecer e estudar, Acompanhar conteúdos e Ajudar e participar.

A hospedagem é estática: HTML, CSS, JavaScript, JSON e TXT. O navegador lê os arquivos publicados. Não há banco de dados privado, painel de autenticação, servidor de atendimento, envio automático de mensagens ou geração de conteúdo por IA durante a visita.

Para atualizar um conteúdo existente, normalmente basta editar o arquivo de dados correspondente. Para mudar estrutura, aparência ou acrescentar uma nova função, será preciso alterar HTML/CSS/JavaScript. O site não modifica os próprios arquivos nem publica no GitHub sozinho.

### Se você só quer instalar esta entrega

1. Faça uma cópia de segurança do repositório atual e confira se há alterações locais ainda não enviadas.
2. Faça Pull no VS Code para trazer mudanças do GitHub.
3. Extraia o ZIP completo desta entrega em uma pasta separada.
4. Copie seu conteúdo para a pasta publicada do repositório, preservando `.git`, arquivos próprios de configuração e workflows existentes. Compare e mescle `.gitignore` em vez de apagar regras locais já existentes.
5. O `index.html` deve ficar na raiz dessa pasta publicada, junto de `assets/`, `dados/` e `catalogo.txt`.
6. Revise as diferenças no VS Code, teste, faça commit e Push.
7. Aguarde a publicação e abra o site como visitante.

Não envie apenas o ZIP para o repositório. O navegador precisa encontrar os arquivos extraídos. Os exemplos em `modelos/` não aparecem no site até serem copiados para um catálogo carregado.

### Se você só quer atualizar um item

| Quero fazer | Abra |
| --- | --- |
| Colocar o link de um software pronto | `dados/projetos.json` |
| Cadastrar um novo artigo, filme, música ou curso com estado | `dados/catalogo-conteudos.json` |
| Alterar uma proposta social de artigo/palestra | `dados/ideias-sociais.json` |
| Alterar o planejamento editorial anterior | `dados/planejamento.json` |
| Preencher o cronograma da igreja | `dados/leituras.json` |
| Mudar a oração ou música do acervo diário | `dados/oracoes.txt` / `dados/louvores.json` |
| Alterar apresentação e convites da entrada | `dados/pagina-inicial.json` |
| Atualizar WhatsApp de parcerias | `dados/parcerias.json` e os contatos fixos indicados adiante |
| Mudar textos de uma disciplina | `dados/fe-conhecimento.json` |
| Mudar fonte, espaçamento ou cores | `assets/platform.css` |

## Repositório privado e site público

O código pode ficar em repositório privado quando a conta e o plano permitirem a publicação desejada. Isso não cria uma área privada dentro do site.

Conforme documentação oficial consultada em 1/11/2026, GitHub Free publica Pages a partir de repositórios públicos. Publicação a partir de repositórios privados depende de plano compatível, como Pro para conta pessoal ou Team/Enterprise para organizações. A assinatura do ChatGPT não é uma assinatura do GitHub. Confira o plano da conta ou organização que é dona do repositório antes de mudar sua visibilidade. No GitHub Free, tornar o repositório privado pode despublicar o Pages.

Em geral, um site Pages publicado continua acessível ao público mesmo com o repositório privado. Restringir visitantes é outra configuração, com requisitos próprios. HTML, JavaScript e dados usados pelo navegador podem ser baixados pelos visitantes. Uma URL pouco conhecida, uma seção escondida ou o campo `hidden` não são controle de acesso.

Se quiser manter o desenvolvimento privado e a publicação gratuita com repositório público, uma alternativa futura é separar o repositório privado de trabalho de um repositório público contendo apenas os arquivos destinados à publicação. Essa esteira ainda não está configurada. Não altere o método de publicação sem conferir o repositório atual.

O futuro Caminho da Escola precisará de aplicação própria, autenticação e banco restrito. Fotos de crianças, nomes de alunos, responsáveis, rotas individuais e registros de retirada não devem entrar nos JSONs do site de evangelização, mesmo que o repositório de origem seja privado.

Fontes: [Criar um site Pages](https://docs.github.com/pt/pages/getting-started-with-github-pages/creating-a-github-pages-site), [Planos do GitHub](https://docs.github.com/en/get-started/learning-about-github/githubs-plans), [Mudar a visibilidade](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility).

## Como o site está organizado

### Estrutura principal

| Local | Papel |
| --- | --- |
| `index.html` | Estrutura das páginas, conteúdo básico, símbolos ilustrativos e parte dos controladores JavaScript antigos |
| `assets/platform.css` | Tema claro/escuro, fontes, grades, navegação, calendário e ajustes responsivos |
| `assets/platform.js` | Navegação por hash, busca de espaços, mapa, três caminhos, idioma do cabeçalho e pausa editorial diária |
| `assets/localization.js` | Dicionário da interface, tradução local de rótulos e roteamento dos dados por idioma |
| `assets/accounts.js` | Prestação de contas mensal, histórico, indicadores e gráfico por categoria |
| `assets/vitrine.js` | Entrada ampliada, calendário da entrada, Escola, projetos, ideias sociais, catálogo comum e contatos da vitrine |
| `assets/faith.js` | Introduções das disciplinas em Fé e conhecimento |
| `assets/support.js` | Acolhimento e apoio |
| `assets/sin.js` | Estudo sobre pecado |
| `assets/spirit.js` | Espírito Santo e santidade |
| `assets/body.js` | Corpo, vontade e escolhas |
| `assets/plan.js` | Planejamento de palestras, artigos e livros |
| `dados/` | Acervo original português e catálogos compartilhados |
| `dados/en/` | Dados em inglês |
| `dados/es/` | Dados em espanhol |
| `catalogo.txt` | Catálogo anterior de filmes/desenhos em formato simples |
| `modelos/` | Exemplos que não são carregados automaticamente |
| `scripts/validar_site.py` | Conferência local de JSON, referências internas, arquivos e regras básicas |
| `.nojekyll`, quando presente | Desativa o processamento Jekyll na publicação estática por branch |
| `README.md` e demais `.md` | Documentação de manutenção |

### Navegação

As páginas estão no mesmo HTML e são exibidas por endereços como `#escola`, `#projetos` e `#estudo-diario`. Isso permite links diretos sem uma rota de servidor. No site hospedado no caminho `/site/`, os arquivos continuam relativos a esse caminho.

A entrada é `#inicio`. As áreas `#conhecer`, `#acompanhar` e `#participar` organizam o diretório. `#mapa-do-site` reúne todos os espaços. O botão Explorar tem busca textual pelos nomes, descrições e termos auxiliares definidos em `assets/platform.js`.

Esconder uma seção até o clique é organização visual, não proteção de dados. O HTML e os dados públicos continuam disponíveis.

### Dados e atualização

Os carregadores fazem `fetch` dos arquivos locais publicados. Diversos acervos são relidos ao abrir, ao retornar à aba e em intervalos de aproximadamente cinco minutos. Uma publicação do GitHub precisa terminar antes de o arquivo novo estar disponível. Para conferir imediatamente uma alteração, recarregue a página após a implantação.

Arquivos inválidos podem manter a versão inicial ou a última versão da aba. Isso ajuda a página a continuar aberta, mas não significa que a atualização foi aceita. Use a validação local e confira o conteúdo visível.

Os módulos mantêm conteúdo inicial para a prévia independente e para falhas de carregamento. O JSON publicado substitui esse conteúdo quando carregado. Ao produzir uma nova entrega de código, manter dados e conteúdo inicial coerentes.

## Mapa de páginas e funções

| Página | Caminho | Âncora |
| --- | --- | --- |
| Corpo, vontade e escolhas | conhecer | `#corpo-escolhas` |
| Espírito Santo e santidade | conhecer | `#espirito-santidade` |
| Próximos conteúdos: palestras, artigos e livros | acompanhar | `#proximos-conteudos` |
| Entender o pecado | conhecer | `#pecado` |
| Acolhimento e apoio | conhecer | `#acolhimento` |
| Fé e conhecimento | conhecer | `#fe-conhecimento` |
| Buscando: uma vida mais próxima de Deus | conhecer | `#buscando` |
| Estudo diário e calendário | conhecer | `#estudo-diario` |
| Cuidar de si | conhecer | `#cuidar-de-si` |
| Bíblias e aplicativos | conhecer | `#biblias` |
| Baixar a Bíblia em PDF | conhecer | `#baixar-biblia` |
| Artigos e estudos bíblicos | conhecer | `#artigos-estudos` |
| Histórias bíblicas em filmes e desenhos | conhecer | `#historias-biblicas` |
| Versículo do dia | conhecer | `#versiculo-dia` |
| Biblioteca de ensino | conhecer | `#biblioteca-ensino` |
| Playlists do YouTube | acompanhar | `#playlists` |
| Lives e encontros | acompanhar | `#lives` |
| Músicas e Spotify | acompanhar | `#musicas` |
| Filmes, desenhos e inspiração | acompanhar | `#filmes-desenhos` |
| Palestras e ministrações | acompanhar | `#palestras` |
| Materiais e redes sociais | acompanhar | `#materiais` |
| Livros e publicações | acompanhar | `#livros` |
| Nossa missão | participar | `#missao` |
| Solidariedade e cuidado | participar | `#solidariedade` |
| Doações voluntárias | participar | `#doacoes` |
| Seja nosso parceiro | participar | `#seja-parceiro` |
| Ações e prestação de contas | participar | `#transparencia` |
| Pedidos de oração | participar | `#oracao` |
| Comunidades de fé | participar | `#parceiros` |
| Sobre Marcos Lucas Pereira | participar | `#autor` |
| Onde estamos | participar | `#localizacao` |
| Contato e canais | participar | `#conecte` |
| Escola: fé e conhecimento | conhecer | `#escola` |
| Projetos: tecnologia para servir | participar | `#projetos` |
| Ideias para o bem comum (dentro de Projeto) | participar | `#ideias-sociais` |

### Sequência da entrada nesta revisão

Apresentação principal; apoio em momentos difíceis; Conheça a plataforma com explicação ampliada; três caminhos; biblioteca; Escola; projetos; momento diário; cuidar de si; ajuda material/voluntariado; missão; contribuição com QR Code; possíveis parcerias.

A entrada é uma vitrine. Ela apresenta o conteúdo e oferece acesso às áreas completas. A leitura do dia aguarda o cronograma da igreja; a sugestão editorial fica identificada enquanto ele não for incluído.

## Qual arquivo editar

Todos os nomes abaixo são literais. Não renomeie extensões nem traduza os nomes dos campos.

| Arquivo em `dados/` | Conteúdo e campos principais |
| --- | --- |
| `acoes.json` | lista; consulte os exemplos e a seção específica |
| `acolhimento.json` | nav, short, eyebrow, title, intro, now, later, urgentTitle, urgentText, emergency, country, safeTitle, safeSteps, listenTitle, listenText, call, chat, connectTitle, connectText, message, copy, copied, copyFailed, nextTitle, nextText, cards, pauseTitle, pauseText, faithTitle, prayer, faithNote, contactTitle, contactText, contactAction, careAction, privacy, sourcesTitle, sourcesText, home, homeAction |
| `artigos.json` | lista; consulte os exemplos e a seção específica |
| `autocuidado.json` | titulo, introducao, nota, temas, pausa, passagem |
| `biblias-e-apps.json` | titulo, tipo, descricao, link |
| `biblias-pdf.json` | titulo, tradicao, versao, conteudo, descricao, link, fonte, creditos |
| `buscando.json` | introducao, temas, mandamentos, contexto_paulo, passagens_contexto, praticas, ensinamentos_jesus, pai_nosso, vicios_nota, vicios, ambiente_nota, integridade |
| `catalogo-conteudos.json` | versao, itens |
| `corpo-escolhas.json` | eyebrow, title, intro, authorNote, distinctionTitle, distinctionText, areasTitle, areasIntro, noticeLabel, chooseLabel, practiceLabel, areas, willTitle, willText, willRefs, emotionsTitle, emotionsText, emotionsExample, stepsTitle, steps, stepsNote, createTitle, createText, createSteps, createRefs, sourcesTitle, sourcesText, sources, read, toFasting, toSin, toSpirit, toSupport, toPlan, fromHome, fromStudy, relationTitle, relationText, relationLink |
| `espirito-santidade.json` | eyebrow, title, intro, note, spiritTitle, spiritText, spiritMore, spiritRefs, fruitTitle, fruitText, fruitPractice, fruitRefs, holyTitle, holyText, holyMore, holyRefs, giftsTitle, giftsText, giftsRefs, pathTitle, path, examplesTitle, examplesIntro, examples, starsTitle, starsText, starsRefs, practiceTitle, practice, prayerTitle, prayer, prayerNote, read, toSin, toPlan, toSeeking, fromSeeking |
| `estudos.json` | lista; consulte os exemplos e a seção específica |
| `fe-conhecimento.json` | principio, disciplinas |
| `ideias-sociais.json` | versao, itens |
| `leituras.json` |  |
| `lives.json` | lista; consulte os exemplos e a seção específica |
| `livros.json` | lista; consulte os exemplos e a seção específica |
| `louvores.json` | titulo, link |
| `materiais-ensino.json` | lista; consulte os exemplos e a seção específica |
| `midias-biblicas.json` | lista; consulte os exemplos e a seção específica |
| `pagina-inicial.json` | how, howIntro, howSteps, library, libraryIntro, school, schoolIntro, schoolNote, openSchool, fundamentals, projects, projectsIntro, projectsNote, allProjects, ideas, ideasIntro, partners, partnersIntro, partnersNote, partnerAction, communities, donate, donateIntro, donateAction, contact, dayTitle, dayIntro, prev, next, today, week, reading, pendingReading, scheduled, prayer, prayerNote, reflection, song, listen, openPassage, developed, developing, proposal, paused, waitingLink, access, open, docs, priority, noResults, projectSearch, all, projectHelp, sharedNote, libraryItems, libraryLabel, donationPlans, donationFreedom, qrTitle, qrNote, solidarity, solidarityIntro, solidarityItems, volunteer, whatsapp, partnersTitle, partnerPending, qrAlt, allSpacesAction, solidarityMore |
| `palestras.json` | lista; consulte os exemplos e a seção específica |
| `parceiros.json` | titulo, descricao, link, status |
| `parcerias.json` | titulo, convite, email, whatsapp, cidade, estado, endereco, frentes, partilha, etapas |
| `pausa-diaria.json` | title, text, step, ref, url, song |
| `pecado.json` | eyebrow, title, intro, summaryNote, definitionTitle, definition, definitionRefs, idolatryTitle, idolatry, idolatryExample, idolatryRefs, images, imagesAction, gravityTitle, gravity, gravityNote, gravityAction, graveTitle, graveIntro, examples, causesTitle, causesIntro, causes, causesRefs, capitalTitle, capitalNote, capitalIntro, capital, fastingTitle, fasting, fastingHealth, fastingPractice, fastingRefs, fastingHealthAction, changeTitle, changeIntro, changeSteps, changeRefs, careNote, practiceLabel, virtueLabel, read, sourceLabel, sourceText, seekingLink, careLink, helpLink, studyLink, everydayTitle, everydayIntro, sceneLabel, discernLabel, actionLabel, reasonTitle, reasonText, planLink, everyday |
| `planejamento.json` | atualizado_em, itens |
| `projetos.json` | versao, itens |
| `spotify.json` | lista; consulte os exemplos e a seção específica |
| `temas-biblicos.json` | id, titulo, testamento, ordem, descricao, passagens |
| `versiculos.json` | lista; consulte os exemplos e a seção específica |
| `youtube.json` | titulo, link |

| Outros arquivos | Uso |
| --- | --- |
| `dados/oracoes.txt` | Uma oração completa por linha; seleção diária |
| `dados/reflexoes.txt` | Uma reflexão por linha; usado no calendário da página de estudo |
| `dados/recursos-santidade.txt` | tema, tipo, título, autor/fonte, link HTTPS e descrição, separados por `\|` |
| `catalogo.txt` | título, categoria, link HTTPS e descrição, separados por `\|` |
| `dados/en/catalogo.txt`, `dados/es/catalogo.txt` | Correspondentes em outros idiomas |
| `links-biblias-pdf.txt` | Lista de fontes para obter PDFs; documentação, não cronograma |

### Regras básicas de JSON

Use aspas duplas; separe itens por vírgulas; não coloque vírgula depois do último item. JSON não aceita comentários. Lista vazia é `[]`; objeto vazio é `{}`. Quebra de parágrafo dentro de um texto pode ser escrita como `\n\n`.

Não transforme um arquivo Excel em JSON apenas renomeando a extensão. Envie o material para conversão ou gere um JSON válido. Guarde o PDF original do cronograma e as fontes dos materiais para revisão posterior.

Os campos de controle são estáveis: `id`, `tipo`, `status`, `formato`, categorias e âncoras não são traduzidos. Os textos de apresentação podem ser traduzidos. Se um arquivo novo não for incluído em um carregador, o site não passa a lê-lo apenas por estar na pasta.

## Trabalhar com VS Code e Git

### Clonar uma vez

1. No GitHub, abra o repositório correto do site e copie Code → HTTPS. Use o endereço do repositório, não o endereço `github.io` do site.
2. No VS Code, use `Ctrl + Shift + P` → Git: Clone.
3. Cole o endereço, escolha uma pasta e abra a cópia clonada.
4. Se necessário, entre na conta pelo fluxo oficial do VS Code/GitHub.

No Ubuntu, se o Git estiver ausente:

```bash
sudo apt update
sudo apt install git
```

### Atualizar a cada sessão

1. Use Pull antes de editar quando houver mudanças feitas em outro computador ou pelo GitHub.
2. Edite os arquivos de dados ou copie uma entrega revisada para dentro da pasta clonada.
3. Confira Controle do Código-Fonte: entenda quais arquivos serão alterados.
4. Teste localmente e valide os dados.
5. Prepare as alterações com `+`, escreva uma mensagem e faça Commit.
6. Use Push/Sincronizar alterações.
7. Confira a execução de publicação e o resultado no site.

Se o Git pedir identificação para commit, configure seu próprio nome e e-mail de autoria. Para privacidade, pode usar o endereço noreply disponibilizado na sua conta GitHub. Não compartilhe senha ou token no chat, no README ou em arquivo de dados.

Se aparecer conflito, não escolha substituir tudo sem ler. Preserve cópia dos dois lados e revise quais mudanças pertencem à versão final. Um commit permite comparar e reverter uma mudança específica; evite apagar o histórico ou forçar Push para resolver uma dúvida de conteúdo.

## Atualização diária e cronograma

### O que muda sozinho

O calendário usa o fuso `America/Cuiaba`, correspondente à localização do projeto. A data de hoje acompanha esse fuso. Quem abre a mesma data no mesmo idioma recebe a mesma seleção; não há análise do humor nem sorteio a cada acesso.

A oração é escolhida do TXT pela data. O acervo atual tem 2.000 variações originais por idioma. A indicação numérica fica documentada aqui; o convite público é Ore conosco. Alterar ordem ou quantidade do TXT muda a correspondência dos dias. Uma oração específica do cronograma tem preferência.

O louvor vem de `louvores.json`. Sem link, o site abre uma busca pelo título no YouTube. Com link HTTPS, usa o destino cadastrado. Uma música específica do cronograma tem preferência. O título externo continua no idioma original para a busca encontrar a música correta.

A leitura bíblica não é sorteada: usa a chave da data em `leituras.json`. O arquivo continua vazio até o cronograma ser recebido e conferido. A passagem editorial mostrada antes disso não é apresentada como cronograma da igreja.

### Como inserir o PDF da igreja

1. Envie o PDF e indique a qual ano ele pertence.
2. Extraia/converta as leituras para datas completas `AAAA-MM-DD`.
3. Confira as referências, páginas ilegíveis e dias sem leitura; não preencher lacunas por adivinhação.
4. Crie os links para as passagens nas edições apropriadas.
5. Revise as reflexões e orações que devem acompanhar cada leitura.
6. Substitua `dados/leituras.json` e os correspondentes em inglês/espanhol, preservando as mesmas datas e referências.
7. Valide, publique e teste diferentes dias e meses.

Guardar o PDF no Drive ou no repositório não faz o calendário interpretá-lo automaticamente. O site lê o JSON convertido. Um novo ano precisa do seu cronograma correspondente; o site não repete o ano anterior silenciosamente.

### Modelo de um dia — somente exemplo de estrutura

A data e a leitura abaixo são exemplo técnico, não o cronograma recebido:

```json
{
  "2026-12-01": {
    "reading": "Jonas 1",
    "prayer": "Oração específica escrita e revisada para este dia.",
    "reflectionTitle": "Uma reflexão para esta leitura",
    "reflection": "Texto autoral relacionado ao capítulo, após revisão.",
    "step": "Uma atitude possível relacionada ao estudo.",
    "song": "Título real do louvor — intérprete",
    "passagens": [
      {
        "referencia": "Jonas 1",
        "protestante": "https://www.bibliaonline.com.br/acf/jn/1",
        "catolica": "https://www.bibliacatolica.com.br/biblia-ave-maria/jonas/1/"
      }
    ],
    "reflectionPassages": [
      {
        "referencia": "Jonas 1",
        "protestante": "https://www.bibliaonline.com.br/acf/jn/1"
      }
    ]
  }
}
```

`reading` é o campo necessário para um dia cadastrado; os demais personalizam o dia. `reflectionTitle`, `step` e `reflectionPassages` enriquecem a reflexão da entrada. A página de estudo já lê `prayer`, `reflection`, `song` e `passagens`; não exibe separadamente o título/passo extra da entrada.

Na entrada, a reflexão editorial, o passo e seu link formam um conjunto. Nesta revisão, ela deixa de ser sobrescrita por uma reflexão TXT independente. Com `reflection` no cronograma, o link usa `reflectionPassages`, ou, se ausente, as `passagens` daquele dia; confira se realmente sustentam a explicação. Sem referência cadastrada para a reflexão específica, o link inferior fica oculto para não apontar uma passagem sem relação.

Se o cronograma tiver leitura mas ainda não tiver reflexão própria, a reflexão editorial continua identificada como sugestão da plataforma e conserva seu próprio contexto. Não afirmar que um texto foi gerado a partir do capítulo se isso não foi feito e revisado.

A página completa de estudo conserva `reflexoes.txt` como reserva diária quando não houver reflexão específica. Por isso a reflexão editorial da entrada pode ser diferente da reflexão geral da página de estudo; a oração e o louvor continuam seguindo o mesmo cálculo por data. Para unificar o conteúdo de uma data, preencha `reflection` naquele registro.

### Alterar a pausa editorial

`dados/pausa-diaria.json` é uma lista de conjuntos com `title`, `text`, `step`, `ref`, `url` e `song`. `title`, `text` e `step` são listas na ordem português, inglês, espanhol. A referência e o endereço devem corresponder à explicação. Mantenha as versões equivalentes nas três pastas, pois o carregador muda a origem pelo idioma.

Ao acrescentar um conjunto, confira a interpretação, a referência e as traduções. Não misture uma frase de uma passagem com um botão para outra sem explicar a relação. A rotação é pela data, não uma animação que troca enquanto a pessoa lê.

## Projetos de software

São propostas de ferramentas para necessidades da comunidade. As seis fichas ainda estão em planejamento. Nenhuma descreve um sistema já implantado. O site é a vitrine; código e aplicações serão desenvolvidos em seus próprios repositórios.

| Projeto | Escopo atual |
| --- | --- |
| Escola Aberta | Organização administrativa, calendário, materiais e comunicação escolar |
| Comunidade Organizada | Agenda, voluntários e recursos de igrejas/comunidades |
| Caminho da Escola | Saída segura, retirada por responsável autorizado e comunicação com transporte/secretaria/portaria |
| Partilha Solidária | Entradas, estoque e entregas de doações |
| Negócio Simples | Estoque e tarefas de pequenos negócios |
| Acervo Comunitário | Organização de materiais educativos autorizados |

O selo Primeiro projeto foi removido. Escola Aberta permanece como proposta própria. Caminho da Escola é a ferramenta que Marcos descreveu para desenvolver primeiro: por exemplo, registrar que uma criança foi retirada pela mãe e atualizar a lista que motorista, secretaria e portaria consultam.

Esse futuro sistema deverá permitir identificação, confirmação por profissional autorizado e histórico. Celular e computador consultarão um banco restrito. Isso ainda requer definição de perfis, autorização de retirada, funcionamento sem conexão e regras de confirmação. Não é rastreamento GPS nem garantia automática de segurança. A aplicação não foi criada dentro deste site e não utiliza seus JSONs públicos para dados de crianças.

### Atualizar uma ficha

Edite `dados/projetos.json`. O campo `itens` contém os objetos. Preserve `id`; altere título, descrição, estado e links quando necessário. Os textos estrangeiros ficam em `traducoes.en` e `traducoes.es`; os links e estados são os mesmos nos três idiomas.

| Campo | Uso |
| --- | --- |
| `id` | Identificador estável |
| `titulo`, `descricao` | Apresentação em português |
| `status` | `em-desenvolvimento`, `em-producao`, `proposta`, `gravado`, `pausado`, `concluido`, `disponivel` ou `publicado` |
| `etapa` | Planejamento, protótipo ou descrição real de andamento |
| `link` | Destino principal público HTTPS |
| `repositorio` | Repositório público HTTPS, usado se link principal estiver vazio |
| `documentacao` | Documentação destinada ao público, por exemplo um link do Drive |
| `licenca` | Licença real; `a-definir` enquanto não escolhida |
| `prioridade` | Campo legado, mantido nos dados; não exibe mais selo nesta revisão |
| `traducoes` | Títulos e descrições EN/ES |

### Regra automática de disponibilidade

| Dados | Resultado |
| --- | --- |
| Sem link e em desenvolvimento | Em desenvolvimento, sem botão principal |
| Link ou repositório HTTPS preenchido | Disponível, com Acessar projeto |
| Pausado, mesmo com link | Pausado, sem botão principal |
| Concluído/publicado/disponível sem link | Concluído · link a informar |
| Proposta sem link | Proposta |

A presença de URL é uma decisão de publicação sua. O site não consulta commits nem descobre se um software ficou pronto; ele apenas lê o arquivo. Uma URL HTTPS pode estar incorreta, privada ou fora do ar: teste-a antes de anunciar disponibilidade. Não coloque o endereço de um repositório privado esperando que todos os visitantes consigam acessá-lo. Pode-se divulgar uma demonstração pública ou documentação pública enquanto o código permanece privado.

Se você quiser anunciar somente um protótipo, descreva essa condição no título/resumo antes de publicar o link. Disponível significa que há um destino publicado, não certificação de que a ferramenta está pronta para uso institucional.

## Novos conteúdos com disponibilidade automática

Para cadastros novos de vários formatos, use `dados/catalogo-conteudos.json`. Ele começa vazio, com `versao` e `itens`. O acervo anterior não foi apagado.

```json
{
  "versao": 1,
  "itens": [
    {
      "id": "estudo-generosidade",
      "tipo": "artigo",
      "titulo": "Generosidade no cotidiano",
      "descricao": "Proposta de estudo sobre partilha e cuidado.",
      "status": "em-desenvolvimento",
      "link": "",
      "traducoes": {
        "en": {"titulo": "Everyday generosity", "descricao": "A proposed study on sharing and care."},
        "es": {"titulo": "Generosidad cotidiana", "descricao": "Propuesta de estudio sobre compartir y cuidar."}
      }
    }
  ]
}
```

O exemplo não é um artigo publicado. Para torná-lo real, escreva/revise o material e preencha seu endereço.

| `tipo` | Área de exibição |
| --- | --- |
| `filme`, `desenho` | Filmes, desenhos e inspiração |
| `musica` | Músicas e Spotify |
| `artigo`, `estudo` | Artigos e estudos bíblicos |
| `livro` | Livros e publicações |
| `palestra`, `video` | Palestras e ministrações |
| `curso` | Escola: fé e conhecimento |
| `material` | Biblioteca de ensino |

A regra de disponibilidade é a mesma dos projetos, com botão Abrir conteúdo e separação entre A desenvolver e Gravados, concluídos ou publicados. O arquivo pode apontar para YouTube, Drive, GitHub e outros destinos HTTPS. Ele não baixa arquivos, não cria uma loja e não transforma um link do Drive em acesso autorizado: configure o compartilhamento real do material.

O catálogo comum exibe fichas com link externo. Ele não renderiza texto completo na página. Para artigo completo dentro da plataforma, use `artigos.json`/`estudos.json` ou desenvolva uma página específica. Um conteúdo no catálogo comum também não entra automaticamente na organização por histórias bíblicas, no hino do dia ou nas playlists do YouTube; use os arquivos próprios para essas funções.

Evite cadastrar o mesmo material no catálogo comum e no catálogo anterior da mesma seção, para não duplicar a apresentação. Os modelos de objeto em `modelos/projeto.json` e `modelos/conteudo.json` ajudam a manter a estrutura.

### Ideias sociais

`dados/ideias-sociais.json` recebe propostas de artigos e palestras sobre fome, educação, IA e outros temas de bem comum. Ele usa a mesma estrutura geral e regra de disponibilidade. É um grupo editorial dentro da página Projeto, ao lado do grupo Tecnologia para servir. As ideias são pontos de investigação; não são soluções já demonstradas ou ações em execução.

### Planejamento editorial anterior

`dados/planejamento.json` conserva seu funcionamento próprio. Os formatos são `Palestra`, `Artigo`, `Livro`; os estados são `proposta`, `em-producao`, `gravado`, `publicado`. Há filtros por formato e estado. Só `publicado` com link HTTPS mostra acesso; uma gravação ainda não publicada não gera botão.

Esse planejamento não usa a regra automática do catálogo comum. Atualizar um arquivo não sincroniza os outros catálogos. Para um material previsto nesse planejamento, mantenha o registro e seu estado ali; quando for publicar em outra seção, evite duplicar sem necessidade.

## Publicações, vídeos e música nos formatos anteriores

Os formatos anteriores continuam válidos. Eles são úteis para funções específicas. Consulte também `EXEMPLOS-DE-PREENCHIMENTO.json`, que contém exemplos e não é carregado como conteúdo real.

### Artigos e estudos completos

`artigos.json` e `estudos.json` são listas. Cada objeto tem `titulo`, `autor`, `data`, `descricao`, `texto` e `link` opcional. Em estudos, `traducao` identifica a versão bíblica usada. Use `texto` com parágrafos separados por `\n\n`. O site coloca texto na página com segurança; não interprete o campo como HTML.

### Livros

`livros.json` aceita título, descrição e link real da publicação/compra. Não preencha disponibilidade enquanto o livro não existir. O site não faz pagamento nem entrega arquivos por conta própria. Para propostas ainda em produção, use planejamento ou catálogo comum.

### Lives

`lives.json` recebe `title`, `category`, `description`, `url`, `start` e `end`. Categorias: `culto`, `adoracao`, `pregacao`, `beneficente`, `louvor`, `cura-libertacao`. Horários devem incluir fuso, por exemplo `2026-12-01T19:00:00-04:00`.

O destaque depende dos dados e horários cadastrados. Isso não detecta sozinho uma transmissão iniciada no YouTube. Para detecção real serão necessárias integração e rotina de atualização. Não anunciar que a transmissão está ativa sem conferir a origem.

### YouTube e palestras

`youtube.json` guarda `titulo` e `link` das playlists. Os cinco links foram fornecidos pelo responsável; a existência e o conteúdo das playlists devem ser conferidos no YouTube. Alterar um título no arquivo muda a apresentação, não o nome da playlist na conta.

`palestras.json` guarda `title`, `date`, `venue`, `city`, `url`. Preencha locais e datas realizados ou corretamente identificados como agenda. Um link abre o vídeo externo; não há upload ao YouTube pelo site.

### Música e Spotify

`louvores.json` é o acervo do louvor do dia: `titulo` e `link` HTTPS opcional. Ele é diferente das playlists de Spotify e do catálogo comum de conteúdos musicais.

`spotify.json` guarda playlists com `id`, `title`, `category` e `tracks`. Categorias: `escuta`, `recomendacoes`, `autorais`. O ID é a identificação da playlist no link do Spotify; `tracks` é uma lista de nomes de músicas para apresentar. A incorporação abre o conteúdo do Spotify e segue suas condições de acesso.

A página não lê automaticamente a conta particular, não conhece músicas novas adicionadas e não transforma o Spotify Premium em uma API pública. A sincronização depende de configuração futura. A tradução da interface mantém os títulos musicais originais para não prejudicar a identificação.

### Versículos

`versiculos.json` guarda `reference`, `text`, `translation`. Cadastre somente trechos com referência e edição identificadas, respeitando autorização de uso. A seleção desse espaço muda pela data. Ele é separado da leitura do cronograma e da reflexão editorial da entrada. O acervo exato de versículos ainda está em preparação.

### Filmes e desenhos

No formato TXT: `título | categoria | link HTTPS | descrição`. As categorias aceitas aparecem no seletor e no guia do catálogo. Linhas iniciadas por `#` são comentários. Importar um TXT no modo de gerenciamento mostra uma prévia local; não faz upload nem commit.

No acervo bíblico organizado:

- `temas-biblicos.json`: `id`, `titulo`, `testamento`, `ordem`, `descricao`, `passagens`.
- `midias-biblicas.json`: `tema`, `titulo`, `formato`, `canal`, `link`, `descricao`, `passagens` opcionais.
- `tema` deve corresponder ao ID cadastrado.
- `testamento`: `Antigo Testamento` ou `Novo Testamento`.
- `formato`: `Desenho`, `Filme`, `Série`, `Documentário`.
- Cada passagem pode ter `referencia`, `protestante` e `catolica`.

Abraão, Moisés e Jonas são temas iniciais. Várias adaptações podem usar o mesmo tema. Não atribua a um desenho passagens específicas sem conferir o que ele mostra. Os vídeos continuam nos sites de origem; não há cópia ou hospedagem dos filmes.

### Bíblias e PDFs

`biblias-e-apps.json` apresenta sites e aplicativos: `titulo`, `tipo`, `descricao`, `link`. `biblias-pdf.json` usa `titulo`, `tradicao`, `versao`, `conteudo`, `descricao`, `link`, `fonte`, `creditos`.

Os PDFs ficam em fontes externas ou no Drive com a permissão adequada. Ter um link para leitura não significa ter licença para redistribuir um PDF. Preserve créditos. A seção diferencia a edição protestante de 66 livros e a católica de 73. O PDF católico continua aguardando seleção e autorização; não o anunciar como disponível antes disso.

### Escola e biblioteca de ensino

A Escola e Fé e conhecimento leem `fe-conhecimento.json`: `principio` e `disciplinas`; cada disciplina tem `titulo`, `fundamento`, `pergunta`, `pratica`. As introduções já existem, mas não são cursos completos. A Escola reapresenta esse acervo e recebe futuros cursos do catálogo comum.

`materiais-ensino.json` guarda `titulo`, `area`, `publico`, `formato`, `descricao`, `autor`, `fonte`, `link`, `licenca`. Mantenha áreas e públicos compatíveis com os filtros existentes, ou altere os filtros junto da nova categoria. A pasta geral do Drive não é, por si, um catálogo de materiais revisados.

### Estudos de vida cristã

`buscando.json`, `pecado.json`, `espirito-santidade.json`, `corpo-escolhas.json` e `autocuidado.json` têm estruturas mais extensas. Ao alterar textos, preserve os campos, referências e correspondência entre idiomas. Cada módulo tem um conteúdo inicial equivalente.

Os estudos distinguem doutrina, interpretação autoral e orientação educativa. A divisão de Corpo, vontade e escolhas é uma organização didática autoral, não correspondência científica ou tradicional entre sete órgãos e sete pecados. Sensações e pensamentos involuntários não são consentimento automático. Acolhimento não deve atribuir sofrimento a falta de fé.

## Parcerias, solidariedade e doações

### Situação das comunidades

Igreja Católica, Igreja Batista Nacional e Vicentinos estão apresentados como possíveis interlocutores em Nova Bandeirantes. As parcerias ainda serão propostas; não há apoio institucional formal anunciado. Símbolos existentes são ilustrativos e não comprovam vínculo.

`parceiros.json` guarda os nomes, descrições e links; `status: a-propor` registra a condição atual. Quando uma parceria for confirmada, revisar também os textos gerais `partnersIntro`, `partnersNote` e a apresentação da página de comunidades. O rótulo geral atual é intencionalmente cauteloso; mudar só o link não confirma a parceria institucional.

`parcerias.json` contém título, convite, e-mail, WhatsApp, cidade, estado, endereço, frentes e etapas. O telefone foi incluído por autorização do responsável para receber ideias e contatos públicos. No arquivo, WhatsApp deve ser DDI+DDD+número somente com dígitos.

Há botões fixos em `index.html` e a configuração de contatos da vitrine em `assets/vitrine.js`. Ao mudar o número, atualizar esses pontos além de `parcerias.json` nos três idiomas. Procure `wa.me` no projeto para localizar os botões, mantendo o mesmo destino. Não reutilize chave Pix como telefone.

Os botões abrem o WhatsApp ou o aplicativo de e-mail; não enviam uma mensagem sozinhos. E-mail e WhatsApp de contato não são serviços de emergência nem prometem resposta imediata.

### Ajuda material e voluntariado

A página inicial tem um espaço para alimentos, roupas, calçados e mutirões. As ações são convites para organização futura: combinar itens, necessidades, responsáveis e forma de entrega antes de receber doações ou mobilizar voluntários. Não há endereço residencial, ponto de coleta, agenda de mutirão ou convênio com instituição inventados.

Atividades relacionadas a melhorias e moradia dependem de planejamento e responsáveis qualificados. A apresentação convida à conversa e não garante atendimento a quem solicitar.

### Destino pretendido das contribuições

A apresentação explica apoio principalmente a alimentos, refeições, roupas e calçados para pessoas em necessidade, com foco inicial em Nova Bandeirantes. Também pode apoiar IA, tempo de desenvolvimento e materiais da plataforma. Apoio a famílias, pessoas em situação de rua e instituições de acolhimento infantil é descrito como objetivo a organizar, não resultado já realizado.

Não há divisão percentual prometida nem prestação de contas fictícia. A área `acoes.json` permite publicar registros reais das ações e relatórios, cuidando para não expor dados pessoais e comprovantes completos.

### Pix e QR Code

O QR Code existente foi preservado, sem mudar destinatário ou payload. A entrada usa uma cópia da mesma imagem exibida na seção Doações. Não foi gerado um novo pagamento nem feita transação.

As informações de Pix, imagem e botão de cópia estão no HTML e no controlador correspondente. Ao mudar a chave ou o beneficiário, atualizar imagem e código de cópia juntos e conferir o resultado no aplicativo bancário antes de divulgar. Alterar apenas o texto ao lado do QR Code pode deixar o destino antigo na imagem.

O README não replica chave bancária nem comprovantes. As informações de doação que aparecem no site foram fornecidas pelo responsável. Os textos gerais de destino e convites ficam em `pagina-inicial.json`, com versões EN/ES.

## Idiomas

Português está em `dados/`; inglês em `dados/en/`; espanhol em `dados/es/`. A preferência é salva no navegador e pode aparecer como `?lang=pt`, `?lang=en` ou `?lang=es`. Trocar idioma recarrega a página mantendo a área escolhida.

Cinco arquivos são compartilhados e NÃO recebem cópias independentes por idioma:

- `dados/planejamento.json`
- `dados/projetos.json`
- `dados/ideias-sociais.json`
- `dados/catalogo-conteudos.json`
- `dados/prestacao-contas.json`

Nos quatro catálogos editoriais, estado e links são únicos; títulos e descrições têm traduções nos próprios registros. Na prestação de contas, os valores são únicos e os rótulos são traduzidos pelo controlador. Os demais dados mantêm arquivos correspondentes nas pastas de idioma. A interface fixa usa `assets/localization.js` e `assets/platform.js`; a nova vitrine usa também `pagina-inicial.json` e seu conteúdo inicial em `assets/vitrine.js`.

Ao atualizar um conteúdo, informe ao ChatGPT para manter original, sentido e referências nas três versões. Não traduzir nomes próprios de músicas como se fossem títulos oficiais. Não dizer que a tradução de uma descrição traduziu um vídeo, PDF ou software externo. Os contatos brasileiros de apoio continuam brasileiros nas interfaces estrangeiras.

## Alterar o visual e a navegação

### Cores e fontes

Os tokens estão no início de `assets/platform.css`: `--paper`, `--surface`, `--soft`, `--ink`, `--muted`, `--line`, `--gold`, `--accent` e outros. O bloco `:root[data-theme="dark"]` define o tema escuro. Ajuste os dois temas quando mudar uma cor.

A fonte de títulos é uma família serifada; textos e controles usam fontes do sistema. Não há necessidade de carregar uma fonte externa para o layout atual funcionar. Fonte maior, contraste e espaçamento buscam legibilidade, sem alegação de tratamento psicológico por cores.

O seletor de idiomas tem cor e fundo explícitos no campo e nas opções, inclusive em tema escuro. Menus nativos variam por sistema operacional; conferir no computador e celular usados pelo público. Preserve foco visível de teclado.

### Textos da entrada

`pagina-inicial.json` controla apresentação, biblioteca, escola, convites e participação. `assets/platform.js` controla os títulos e descrições dos três caminhos e outros rótulos gerais. `index.html` controla a ordem dos blocos. Mudar um texto no JSON não move uma seção de lugar.

### Acrescentar uma nova página

1. Criar seção em `index.html` com ID único, `data-platform-section="true"` e estado inicial consistente.
2. Registrar o ID, grupo, títulos PT/EN/ES e descrições na lista `spaces` de `assets/platform.js`.
3. Acrescentar termos de busca em `aliases`, se útil.
4. Criar carregamento de dados e versões de idioma quando houver conteúdo dinâmico.
5. Incluir os arquivos novos no pacote e no gerador da prévia independente.
6. Testar link direto, mapa, busca, troca de idioma, teclado e tema escuro.

Nunca reutilize o mesmo ID em duas seções. Não renomeie âncoras antigas sem revisar os links que apontam para elas.

## Testar e publicar

### Servidor local

Na pasta que contém `index.html`:

```bash
python3 -m http.server 8000
```

Abra `http://localhost:8000` no navegador e mantenha o terminal aberto. Pare com `Ctrl + C` quando terminar. Se já usar Live Server no VS Code, pode continuar com ele.

Abrir `index.html` diretamente por duplo clique pode impedir a leitura dos JSONs por restrições de arquivos locais. A prévia HTML independente fornecida nesta conversa já inclui o acervo desta entrega para inspeção; ela não é o arquivo que substitui sozinho todo o repositório.

### Validação local

```bash
python3 scripts/validar_site.py
```

Esse comando valida JSONs, IDs e referências internas, arquivos locais referenciados e estruturas básicas dos novos catálogos. Ele não testa links remotos, serviços externos, QR no banco, autenticação ou uma revisão teológica. Se Node.js estiver instalado e você alterar um módulo, pode também usar `node --check assets/NOME.js`.

Depois confira no navegador:

- Entrada e menu Explorar.
- Português, inglês e espanhol.
- Tema claro e escuro.
- Dia de hoje, outro dia e mudança de mês.
- Passagens e música abrindo o destino esperado.
- Projeto sem link, disponível e pausado, usando cópia local de teste.
- WhatsApp e e-mail abrindo os contatos corretos.
- Links do acervo, sem anunciar materiais inexistentes.
- Tela estreita e navegação por teclado.

Não deixe registros de teste publicados como se fossem projetos ou eventos reais. O catálogo comum desta entrega permanece vazio.

### GitHub Pages

No repositório real, confira Settings → Pages e a fonte de publicação. Ela pode ser um branch/pasta ou um workflow. Este pacote não altera workflows existentes.

Se publicar por branch, selecione o branch e a pasta que realmente contêm a entrega, como `/` ou `/docs`. Não crie uma pasta extra chamada `site-atualizado-github` entre o Pages e o `index.html`. Se usar um workflow existente, confira qual diretório ele publica antes de mover arquivos.

Fonte oficial: [Configurar publicação](https://docs.github.com/pt/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site).

### Voltar a uma versão anterior

Guarde o ZIP anterior e faça commits descritivos. Se uma atualização falhar, revise as diferenças e reverta o commit específico ou restaure os arquivos necessários. Não substitua toda a pasta por uma versão antiga sem conferir se isso apagaria conteúdo novo.

A prévia independente é uma fotografia da entrega; mudanças posteriores no repositório não atualizam o arquivo já baixado. Peça uma nova prévia ao gerar uma próxima versão.

## Manutenção com ChatGPT

### Pedido para atualizar um conteúdo

> Estou atualizando a Plataforma Global de Evangelização. Vou enviar os arquivos atuais e o conteúdo novo. Leia o README e AGENTS.md. Atualize apenas os arquivos necessários, preserve IDs e conteúdo existente, mantenha português/inglês/espanhol, indique os caminhos alterados e devolva os arquivos prontos. Não anuncie integrações ou publicações que ainda não aconteceram.

### Pedido para incorporar o cronograma

> Converta este PDF de leitura bíblica para o ano informado em dados/leituras.json. Preserve as datas e referências, sinalize trechos duvidosos sem inventar, acrescente links e produza reflexões identificadas como autorais e relacionadas a cada leitura. Mantenha as versões EN/ES e confira a correspondência entre oração, reflexão, passo e passagem.

### Pedido para um projeto

> Atualize a ficha do projeto de ID informado em dados/projetos.json. O estado real é este e os links públicos são estes. Preserve as outras fichas e traduza apenas título/descrição. Não coloque registros de alunos nem outros dados privados na vitrine.

### O que enviar para revisão de código

Envie a versão atual dos arquivos, o erro exato e a mudança desejada. Dizer apenas “atualize o site” sem fornecer o repositório acessível ou arquivos atuais pode levar a uma versão desatualizada. Uma conversa não garante acesso automático à sua pasta local ou ao seu GitHub privado.

Ao entregar arquivos para outra sessão, lembre de usar o README desta plataforma. Um README de plugin editorial pessoal é outro projeto e não deve substituir este.

## Problemas comuns

| Sintoma | Verifique |
| --- | --- |
| Mudança não aparece | Commit/Push, publicação concluída, caminho correto e recarga do navegador |
| JSON deixou de carregar | Aspas, vírgulas, estrutura, nome e pasta; execute o validador |
| Idioma mostra texto antigo | Atualização EN/ES, conteúdo inicial do módulo e dicionário fixo |
| Projeto continua em desenvolvimento | Campo link/repositorio vazio ou URL sem HTTPS; publicação do JSON |
| Projeto pausado não tem botão | Comportamento intencional do status pausado |
| Botão leva a acesso negado | Destino privado ou compartilhamento do Drive/repositório ainda restrito |
| Leitura não segue a igreja | Cronograma ainda não convertido ou data/ano sem registro |
| Música muda de nome ou busca errada | Título original no louvores.json; preferência por link oficial válido |
| Site deixou de publicar após tornar repo privado | Plano da conta/organização e requisitos do GitHub Pages |
| 404 em assets ou dados | Pasta extra ao extrair ZIP, caminhos absolutos indevidos ou arquivo não enviado |
| QR e texto divergem | Imagem/payload e chave exibida não foram atualizados juntos |
| Nome de parceiro parece confirmação | Revisar descrição, status e nota geral; ainda são propostas |
| WhatsApp antigo ainda aparece | parcerias.json nos três idiomas, index.html e vitrine.js |
| Página vazia após mudar layout | Erro de sintaxe JS ou ID removido; consultar console e restaurar o ponto alterado |

## Prestação de contas mensal: planilha, PDF, histórico e gráfico

### O que está pronto

A página Ações e prestação de contas, em `#transparencia`, recebe um relatório por mês. Ela oferece seletor de mês, entradas, despesas, saldo inicial/final, gráfico em formato de pizza/rosca por categoria, tabela de valores e percentuais, indicadores adicionais, links da planilha e do PDF e histórico dos períodos publicados.

O catálogo é `dados/prestacao-contas.json`. O controlador é `assets/accounts.js`. O arquivo é compartilhado entre os três idiomas para que os valores financeiros sejam os mesmos. Rótulos e nomes dos meses mudam com o idioma; descrições e documentos podem permanecer no idioma em que foram elaborados.

O catálogo começa com `meses: []`. Não há relatório financeiro verdadeiro publicado nesta entrega. A página não apresenta valores de exemplo como se fossem arrecadação ou gastos reais. O gráfico aparece quando um mês com despesas reais é publicado; sem despesas, a mensagem informa que não há distribuição percentual a gerar.

### Arquivos envolvidos

| Arquivo/pasta | Finalidade |
| --- | --- |
| `modelos/prestacao-contas.xlsx` | Modelo vazio, pronto para preencher uma cópia por mês |
| `scripts/importar_prestacao.py` | Conversão local XLSX → JSON, cópia de planilha e PDF opcional |
| `dados/prestacao-contas.json` | Histórico e dados que o site lê |
| `relatorios/AAAA-MM.xlsx` | Cópia da planilha mensal destinada ao download público |
| `relatorios/AAAA-MM.pdf` | Relatório PDF, quando gerado pelo comando |
| `assets/accounts.js` | Seleção de mês, totais, gráfico, tabela e KPIs |
| `dados/acoes.json` | Relatos anteriores de ações e links, separado dos dados financeiros mensais |

### Procedimento mensal completo

1. Copie `modelos/prestacao-contas.xlsx` para uma pasta de trabalho. Dê nome ao período, por exemplo `prestacao-2026-08.xlsx`. Esse nome é ilustrativo; use o mês real que estiver preparando.
2. Abra no Excel ou LibreOffice Calc. Não altere os nomes das abas `Resumo` e `Lancamentos`.
3. Na aba Resumo, preencha **C4** com o mês, no formato `AAAA-MM`, por exemplo `2026-08`.
4. Preencha **C5** com o saldo inicial real em reais. Nos meses seguintes, confira o saldo final do relatório anterior e justifique diferenças quando houver. O script não inventa ou corrige o saldo inicial.
5. Em **C8**, escreva um resumo público das ações e do período. Não inclua nomes de pessoas atendidas, identificadores bancários ou dados privados.
6. As células C6/C7 podem receber links HTTPS externos da planilha/PDF, se você usar Drive ou outro destino público. Se preferir os arquivos no próprio site, deixe esses dois campos vazios.
7. Abra a aba Lancamentos. A primeira linha de entrada é a **linha 4**. Cada linha é uma movimentação efetiva.
8. Coluna **A**: data `AAAA-MM-DD`, dentro do mês indicado em Resumo!C4.
9. Coluna **B**: `entrada` ou `despesa`, exatamente com esses valores. Use o seletor da célula.
10. Coluna **C**: categoria. Há opções como Alimentos, Roupas e calçados, Transporte, Inteligência artificial, Desenvolvimento, Materiais e educação e Outros.
11. Coluna **D**: descrição pública, suficientemente clara para explicar o lançamento, sem dados pessoais.
12. Coluna **E**: valor numérico positivo em reais. A coluna Tipo determina se é entrada ou despesa; não use número negativo para saída.
13. Não coloque fórmulas nos valores dos lançamentos. O resumo tem suas próprias fórmulas e o conversor calcula o site diretamente a partir dos registros.
14. O modelo atual tem **200 lançamentos**, nas linhas 4 a 203. Se precisar de mais, amplie as faixas das fórmulas e o limite do importador juntos antes de usar linhas extras. O script interrompe a importação para evitar resumo incompleto.
15. Volte a Resumo e confira C10 (entradas), C11 (despesas) e C12 (saldo final).
16. Para KPIs adicionais, preencha as linhas **26 a 35**, colunas **B** (nome), **C** (valor numérico), **D** (unidade). Exemplo de unidade: refeições, ações, itens. Cadastre somente números documentados e defina o que está sendo contado.
17. Salve o XLSX. Esta planilha será copiada para a pasta pública de relatórios, inclusive suas abas. Use uma cópia própria para publicação, sem informações privadas, comentários sensíveis ou conteúdo oculto.
18. Abra o terminal na pasta do site e rode a conversão, conforme o comando abaixo.
19. Revise os arquivos gerados e os totais exibidos pelo comando. A conversão não faz conciliação com o banco nem certifica os comprovantes.
20. Abra o site local e Ações e prestação de contas. O mês novo deve aparecer no seletor e no histórico. Confira gráfico, tabela, totais, KPIs e downloads.
21. Execute `python3 scripts/validar_site.py` e corrija erros.
22. Revise o JSON, a planilha e o PDF antes de fazer Commit/Push. O script não envia nada ao GitHub.
23. Depois que o Pages concluir a publicação, abra a página pública, selecione o mês e teste os downloads. Os meses anteriores continuam no histórico.

### Comando para importar a planilha

Na raiz do site, substitua o caminho pelo arquivo realmente preenchido:

```bash
python3 scripts/importar_prestacao.py "/caminho/prestacao-2026-08.xlsx"
```

Esse comando lê o modelo, valida datas/tipos/valores, inclui ou atualiza o catálogo mensal e copia a planilha para `relatorios/AAAA-MM.xlsx`. Ele não gera PDF sem a opção correspondente. O gráfico no site vem dos valores numéricos exportados para JSON, não de uma imagem estática do gráfico do Excel.

### Gerar o PDF junto da importação

O PDF opcional usa ReportLab no computador que executa o script. No Ubuntu, você pode preparar um ambiente virtual uma vez:

```bash
python3 -m venv .venv
.venv/bin/python -m pip install reportlab
```

Se o sistema informar que o módulo venv está ausente, instale o pacote de suporte ao venv para sua versão do Python. O ambiente `.venv` é local e não deve ser enviado ao repositório. O pacote desta entrega não contém esse ambiente nem instala dependências automaticamente.

Execute:

```bash
.venv/bin/python scripts/importar_prestacao.py "/caminho/prestacao-2026-08.xlsx" --pdf
```

O comando prepara a planilha pública, o JSON e `relatorios/AAAA-MM.pdf`. O relatório inclui resumo, entradas/despesas, saldo, distribuição por categoria, indicadores e lançamentos públicos. Confira o PDF antes de publicar. Ele não inclui fotos, comprovantes ou auditoria que não tenham sido fornecidos.

Você também pode preparar um PDF revisado por outro método, hospedá-lo no Drive e informar seu link em Resumo!C7 ou no campo `arquivos.pdf` do JSON. Ter um PDF em uma pasta não atualiza o site se o catálogo não apontar para ele.

### Corrigir um mês já publicado

O importador bloqueia um mês duplicado por padrão. Para corrigir deliberadamente o mesmo mês:

1. Guarde a versão anterior no histórico do Git e identifique o que será corrigido.
2. Atualize a planilha e confira seus números.
3. Execute o mesmo comando com `--substituir`, e com `--pdf` se quiser regenerar o PDF também:

```bash
.venv/bin/python scripts/importar_prestacao.py "/caminho/prestacao-2026-08.xlsx" --pdf --substituir
```

4. Confira a diferença do JSON e os arquivos do período. Os outros meses devem permanecer intactos.
5. Publique a correção com uma mensagem de commit descritiva. Se a correção for relevante para o público, explique no resumo do mês.

Não reimporte uma planilha antiga apenas para mudar o visual. A fonte de verdade financeira deve ser a versão revisada dos registros do mês.

### Fórmulas e percentuais do site

- Entradas do mês = soma dos registros de entradas.
- Despesas do mês = soma dos registros de despesas.
- Saldo final = saldo inicial + entradas − despesas.
- Percentual de categoria = despesas daquela categoria ÷ despesas totais do mês.
- O saldo não é uma fatia de despesa.
- Sem despesas, não apresentar divisão por zero ou uma pizza fictícia.
- Valores monetários são reconciliados em centavos no navegador.
- KPIs não são inferidos a partir de promessas: os valores vêm dos campos informados.

Doações de bens sem valor monetário atribuído podem ser informadas como indicadores ou relato. Não misturá-las com dinheiro sem um critério de avaliação explicitado. “Pessoas”, “famílias”, “refeições” e “entregas” não são unidades equivalentes; evite somar como se fossem.

### Estrutura do JSON mensal

Uma entrada possui `mes`, `saldo_inicial`, `resumo`, `entradas`, `despesas`, `indicadores` e `arquivos`. Cada lançamento possui `categoria`, `valor` e, no conversor, data e descrição pública. `indicadores` é uma lista de objetos `{nome, valor, unidade}`. `arquivos` recebe `planilha` e `pdf`, como links HTTPS ou caminhos relativos controlados `relatorios/AAAA-MM.xlsx` e `relatorios/AAAA-MM.pdf`.

O JSON inteiro é `{versao: 1, moeda: "BRL", meses: [...]}`, escrito com aspas conforme a sintaxe JSON. O conversor já mantém essa estrutura. Não crie arquivos EN/ES com números diferentes.

### O que significa atualização automática aqui

Depois que planilha, JSON e PDF forem preparados e publicados, o site lê o mês, atualiza gráfico e KPIs e mantém os períodos anteriores sem mudar o HTML. O gráfico é recalculado no navegador quando você troca o mês.

Neste momento não há um robô olhando uma pasta do Drive, um monitor do seu computador ou uma ação do GitHub executando o importador. Subir somente um XLSX novo sem converter/atualizar o JSON não altera o painel. Agendar essa conversão no GitHub Actions pode ser uma etapa futura, após inspecionar o repositório real.

## Playlists por arquivo: passo a passo

### Spotify

1. No Spotify, abra a playlist que deseja divulgar e copie seu link de compartilhamento.
2. O ID é a parte depois de `/playlist/`, antes de `?`, se houver parâmetros. Não use ID de música, álbum ou episódio.
3. Abra `dados/spotify.json`. Ele é uma lista e pode estar vazio como `[]`.
4. Acrescente um objeto com `id`, `title`, `category` e `tracks`. `category` deve ser `escuta`, `recomendacoes` ou `autorais`.
5. `tracks` é uma lista opcional para apresentar nomes no site. Se você escrever essa lista, terá de mantê-la; ela não é lida da sua conta automaticamente.
6. Faça versões equivalentes em `dados/en/spotify.json` e `dados/es/spotify.json`, preservando o ID. Você pode manter nomes de músicas e playlists no idioma original.
7. Salve, valide, faça Commit/Push e aguarde o Pages.
8. Abra Músicas e Spotify. A playlist deve aparecer no grupo escolhido, com a janela incorporada quando o ID for válido.
9. Confira no celular e como visitante. Playlists privadas, removidas ou com restrições podem não tocar para todos.

Quando você altera as músicas dentro de uma playlist já incorporada, o player é servido pelo Spotify e pode refletir a playlist atualizada, sujeito a cache e regras da plataforma. A lista textual `tracks` do site permanece como foi cadastrada. Salvar uma playlist de outra pessoa na sua conta não a adiciona sozinho ao JSON do site.

### YouTube

1. Abra a playlist no YouTube e copie o endereço completo, com `list=`.
2. Abra `dados/youtube.json` e acrescente ou edite o objeto com `titulo` e `link`.
3. Preserve as outras playlists e atualize os arquivos correspondentes EN/ES.
4. Salve, valide e publique por Commit/Push.
5. Abra Playlists do YouTube e teste o cartão.

O cartão abre a playlist no YouTube. A lista de vídeos dentro dela é administrada no próprio YouTube: não precisa cadastrar cada vídeo no site para a playlist externa mudar. Uma nova playlist, um novo cartão ou a detecção de live ainda precisam de cadastro ou integração futura.

Não há formulário público para visitantes alterar playlists, nem sincronização com sua conta particular. Os arquivos no repositório são o ponto de manutenção autorizado nesta versão.

## Sua apresentação e os destaques da entrada

A seção Sobre Marcos foi enriquecida com propósito, estudo das Escrituras, conteúdo acessível, desenvolvimento de ferramentas e ajuda ao próximo. São motivações e objetivos informados pelo responsável, sem formação, cargo ou realizações inventados. Os três parágrafos ficam nos campos `author1`, `author2`, `author3` de `pagina-inicial.json`, com versões EN/ES.

O destaque Cuidar de si explica corpo e rotina, emoções e convivência, oração e Palavra. Sua apresentação está em `careHomeTitle`, `careHomeIntro`, `careHighlights`. O conteúdo completo continua em `autocuidado.json`.

A biblioteca da entrada apresenta explicitamente Bíblias e aplicativos, filmes/desenhos e músicas/playlists, além dos outros espaços. As fichas estão em `libraryItems` de `pagina-inicial.json`. Ao alterar título/descrição, preserve `id` como destino de navegação.

## Biblioteca de ensino com materiais no Drive: caminho completo

**Arquivo:** `dados/materiais-ensino.json`. **Página:** Biblioteca de ensino, em `#biblioteca-ensino`.

1. Coloque o material autorizado no Google Drive e dê um nome identificável.
2. Revise o arquivo para garantir que é a versão que deseja compartilhar. Não use uma pasta com documentos privados como destino público.
3. Configure a permissão necessária no Drive para o visitante poder abrir o material. Copie o link de compartilhamento.
4. Teste o link como visitante, sem depender da sua própria sessão de proprietário. Se pedir autorização, ajuste o compartilhamento conforme sua intenção.
5. Abra `dados/materiais-ensino.json` no VS Code. A estrutura é uma lista `[]`.
6. Acrescente um objeto com título, área, público, formato, descrição e link. Nome e resumo são escritos no JSON; o site não tenta adivinhar o título lendo seu Drive.
7. Se tiver uma imagem pública de capa, informe `capa` com o endereço HTTPS direto dessa imagem. O link de uma página de visualização do Drive não é necessariamente uma URL de imagem.
8. Sem capa, o site mostra uma apresentação visual de documento. A ficha continua com título, descrição e botão. Se a imagem não carregar, aparece a apresentação de documento.
9. Atualize os registros equivalentes EN/ES, mantendo o mesmo link e a identificação do material. Os filtros dependem dos valores de área/público previstos na página.
10. Salve, valide, faça Commit/Push e espere o Pages publicar.
11. Abra a Biblioteca, limpe a busca e os filtros e confira a nova ficha. Clique em Acessar material e verifique o documento no Drive.
12. Para atualizar o mesmo material, edite o mesmo objeto. Se preservar o link no Drive, a ficha pode continuar apontando para ele; se criar um arquivo novo com outro link, substitua o endereço no JSON.

Exemplo de estrutura, a ser preenchido com um material real:

```json
[
  {
    "titulo": "Título do material",
    "area": "Filosofia",
    "publico": "Jovens",
    "formato": "PDF",
    "descricao": "Breve descrição do conteúdo e para quem ele foi preparado.",
    "autor": "Autor ou instituição responsável",
    "fonte": "Google Drive — acervo autorizado",
    "link": "https://drive.google.com/file/d/ID_REAL/view",
    "capa": "",
    "licenca": "Condições reais de uso e atribuição"
  }
]
```

O exemplo não é carregado automaticamente. Troque o ID do Drive pelo endereço real. Se precisar de outras áreas ou públicos, compare os valores com os seletores atuais; não traduza os códigos de controle de forma independente.

O site expande a lista conforme o JSON recebe novos registros. Ele não precisa ter acesso à sua conta Google. O visitante abre a origem pelo link; o site não copia o documento, não varre a pasta e não atualiza o título sozinho se o arquivo mudar de nome no Drive. Não há upload público nem gravação no seu repositório pelo visitante.

Para material que ainda está em produção e precisa aparecer antes de ter link, use `catalogo-conteudos.json` com `tipo: material`. O arquivo `materiais-ensino.json` continua destinado a materiais com link válido e oferece filtros por disciplina/público. Evite cadastrar a mesma ficha nos dois arquivos para não duplicá-la.

### Links ao final das páginas

A navegação final agora nomeia o caminho de volta, por exemplo Voltar para Conhecer e estudar. Os atalhos explicam o destino: Escolher uma data: leitura, oração e louvor; e Cuidar de si: corpo, emoções e rotina. Textos e destinos são gerados em `renderContext`, dentro de `assets/platform.js`, nos três idiomas.

## Integrações pendentes

A entrega prepara a organização por arquivos, não ativa serviços externos. Continuam pendentes:

- Inspeção do repositório real antes de alterar branch, pasta e workflows.
- GitHub Actions para validação, publicação e agendamentos, se compatível com o método escolhido.
- YouTube Data API para vídeos/lives, quotas, credenciais em Secrets e tratamento de falhas.
- Exportação revisada de materiais do Drive.
- Spotify e permissões necessárias para sincronizar playlists.
- Notificações por e-mail e WhatsApp com serviço, consentimento e limites definidos.
- Backups, logs e alertas da futura esteira.
- Desenvolvimento do Caminho da Escola em projeto separado.

Não há backend/cron nativo neste pacote estático. Não colocar API keys em JavaScript público. O catálogo não precisa de credencial GitHub para ser lido como arquivo publicado. Se um destino precisar de acesso privado, ele exige a sua própria autenticação; o site não passa permissões do proprietário aos visitantes.

## Referências e documentos complementares

- `AGENTS.md`: instruções de continuidade para revisão com assistentes.
- `PRINCIPIOS-EDITORIAIS.md`: fé cristã em diálogo com o conhecimento, rigor e dignidade.
- `GUIA-DE-TRADUCAO.md`: idiomas, referências e limitações.
- `ACOLHIMENTO-E-SEGURANCA.md`: limites e fontes do espaço de apoio.
- `CHECKLIST.md`: o que está implementado e o que falta.
- `COMO-ATUALIZAR-PROJETOS-E-ACERVO.md`: guia dos catálogos novos.
- `COMO-ATUALIZAR-PLANEJAMENTO.md`: estados próprios do planejamento anterior.
- `COMO-ATUALIZAR-CATALOGO.md`: formato TXT de filmes/desenhos.
- `EXEMPLOS-DE-PREENCHIMENTO.json`: exemplos de estruturas, sem publicação automática.
- `PENDENCIAS-DE-AUTOMACAO.md`: próxima etapa das integrações.

O presente README é a referência mais atual para a estrutura desta revisão. Em caso de divergência com uma anotação histórica, confira o código atual e atualize o documento correspondente, preservando os registros úteis de decisões.

## Última revisão da pergunta de fé

A introdução de Ciência foi alterada nos acervos PT/EN/ES e no conteúdo inicial dos módulos para: “Por que Deus criou um mundo que podemos investigar e o que a criação nos convida a reconhecer sobre Ele?”. A formulação apresenta a perspectiva de fé da plataforma. A instrução anterior que negava essa busca nessa pergunta foi retirada.

## Disciplinas, Deus no centro e acervo por formato

As dez disciplinas tiveram as perguntas revisadas para explorar Deus, criação, propósito e vida cotidiana. Matemática inclui reflexão sobre a existência de Deus; os argumentos filosóficos/teológicos a desenvolver precisam explicitar premissas e interpretação, sem se apresentar como prova experimental ou matemática quando não o forem. PRINCIPIOS-EDITORIAIS.md registra a orientação reafirmada por Marcos.

No arquivo fe-conhecimento.json de cada idioma, cada objeto da lista disciplinas agora também recebe uma lista recursos. Cada recurso possui tipo, titulo, descricao, status e link. Os tipos aceitos são Artigo, Playlist, Livro e Palestra. A página organiza esses formatos dentro da disciplina. Há uma proposta de artigo por área, claramente em desenvolvimento, sem link; os demais formatos aguardam materiais reais. Nenhum livro, playlist específica por disciplina ou gravação foi inventado.

Para publicar nessa área: localize a disciplina no JSON, acrescente o recurso no formato desejado, escreva título/descrição, informe o endereço HTTPS real e atualize as versões EN/ES. Com link e estado compatível, a ficha mostra Disponível e Abrir material. gravado mantém publicação pendente; pausado não mostra acesso. Esse acervo é específico das disciplinas e não se sincroniza sozinho com os outros catálogos.

O layout dos detalhes foi corrigido: cartões fechados não se esticam à altura do cartão aberto. Um bloco abre por vez, com nome nativo do grupo e fallback de controle. Atualizar os dados preserva a disciplina aberta pelo índice enquanto a ordem for mantida. Não reordenar silenciosamente disciplinas durante uma revisão se houver necessidade de preservar referências futuras.

## Princípio central reafirmado por Marcos

Deus é o centro e o fundamento da plataforma para compreender a criação, o conhecimento e a vida. Marcos definiu como inegociável: “Preciso de Deus para explicar todas as coisas.” As perguntas das disciplinas e as apresentações foram revisadas nessa direção, com busca de sentido e propósito em Deus. As referências bíblicas, interpretações e argumentos são identificados. Leia PRINCIPIOS-EDITORIAIS.md antes de produzir ou revisar qualquer material futuro.


## Atualização final: navegação centralizada e comunidades

### Projeto: tecnologia e ideias no mesmo lugar

A página `#projetos` chama-se **Projeto**. Possui dois grupos expansíveis: **Tecnologia para servir**, com os seis softwares propostos; e **Ideias para o bem comum**, com as três propostas editoriais já existentes. A página independente de ideias foi incorporada, sem apagar propostas. O endereço antigo `#ideias-sociais` continua funcionando: abre Projeto e expande o grupo correto. A página inicial destaca os três softwares principais e permite abrir todas as propostas.

Continue editando `dados/projetos.json` para softwares e `dados/ideias-sociais.json` para propostas editoriais. Não mova os dados para o HTML. As regras de status e link documentadas acima continuam funcionando nos dois grupos. Não é necessário criar uma página nova para cada ideia. Agrupe conteúdos relacionados antes de multiplicar páginas; preserve os links antigos quando reorganizar.

### Destaques de leitura

O início de frases com rótulos, como **Conhecer e estudar:**, recebe negrito e cor de destaque acessível nos dois temas. `assets/organization.js` aplica isso também aos textos carregados dos catálogos. O restante da frase preserva o estilo normal. Não escreva HTML nos campos JSON: use texto simples. URLs e horários não são transformados em rótulos.

### Filmes e desenhos: fim automático do aviso de preparação

A descrição da biblioteca na página inicial é reavaliada quando os catálogos carregam. Enquanto não houver um filme ou desenho acessível, aparece a mensagem de preparação. Após publicar o primeiro item com URL HTTPS válida, aparece a descrição normal do acervo. Não existe aviso permanente de atualização. Registros pausados, gravados ou apenas propostos não ativam essa mudança. Os catálogos existentes continuam sendo usados; não há necessidade de editar o HTML.

### Agendas das instituições

Há três páginas: `#comunidade-catolica`, `#comunidade-batista` e `#comunidade-vicentinos`. Elas aparecem no menu Explorar, no mapa e no resumo da página inicial. O arquivo único é **dados/comunidades.json**, compartilhado entre os idiomas. As páginas apresentam descrição, situação da parceria, agenda, formação, local e contatos. Horários e contatos estão vazios até serem confirmados; a presença da instituição não comprova parceria.

Passo a passo:

1. Obtenha e confirme os dados com a instituição. Se receber um PDF, envie-o para extrair e revisar os horários; o site não lê PDFs sozinho.
2. Abra `dados/comunidades.json` no VS Code.
3. Em `instituicoes`, encontre o `id`: `catolica`, `batista` ou `vicentinos`. Não altere esses IDs.
4. Preencha `titulo`, `descricao`, `endereco` e `contatos` quando houver informação confirmada. Em `parceria`, mantenha `a-propor` enquanto não houver acordo; use `confirmada` somente após confirmação.
5. Em `agenda`, acrescente um objeto para cada celebração, encontro ou atividade. O exemplo abaixo é apenas um MODELO e não representa um evento existente.
6. Em `formacao`, cadastre catequese, estudos e campanhas como objetos com `titulo`, `descricao` e `link` HTTPS.
7. Em `traducoes.en` e `traducoes.es`, revise título e descrição da instituição. Cada evento também pode ter `traducoes.en` e `traducoes.es` com título e descrição; os horários permanecem iguais.
8. Salve, execute `python3 scripts/validar_site.py`, faça Commit e Push para a branch de publicação.
9. Aguarde a publicação do GitHub Pages, abra as três páginas e confira texto, dia, horário e links. Os dados são carregados ao abrir a página e revistos a cada cinco minutos e ao retornar à aba. Recarregue para conferir imediatamente.

Modelo de evento para inserir em `agenda` (substitua tudo pelos dados confirmados):

```json
{
  "titulo": "NOME CONFIRMADO DA ATIVIDADE",
  "tipo": "celebracao",
  "dias_semana": [0],
  "horario": "09:00",
  "local": "LOCAL CONFIRMADO",
  "descricao": "DESCRIÇÃO CONFIRMADA",
  "link": "https://exemplo.org/evento"
}
```

`dias_semana` usa 0=domingo, 1=segunda, 2=terça, 3=quarta, 4=quinta, 5=sexta, 6=sábado. Para evento único, retire `dias_semana` e use `data` no formato `AAAA-MM-DD`. O site apresenta as datas informadas, inclusive passadas: remova eventos vencidos ou identifique-os como histórico na descrição. Não há inscrição automática, envio de alertas ou sincronização com calendários externos.

`contatos` possui `email`, `whatsapp` e `site`. WhatsApp: somente dígitos com código do país; site: HTTPS; email: endereço completo. Deixe vazio o que não foi informado. Não use o telefone pessoal de Marcos como se fosse o telefone de uma igreja.

### Arquivos desta atualização

- `assets/organization.js`: comunidades, agenda, destaque de rótulos e aviso dinâmico de filmes.
- `dados/comunidades.json`: dados compartilhados das três instituições.
- `assets/platform.js`: navegação centralizada, compatibilidade de links antigos e novas rotas.
- `assets/vitrine.js` e `dados/pagina-inicial.json`, `dados/en/pagina-inicial.json`, `dados/es/pagina-inicial.json`: textos da apresentação.
- `assets/localization.js`: mantém comunidades como arquivo compartilhado.
- `assets/platform.css`: aparência dos grupos e destaques.

O catálogo atual permanece com propostas, sem horários inventados. Integrações externas, parcerias, materiais ainda não enviados e o cronograma bíblico da igreja continuam dependendo de configuração e conteúdo reais.


## Correção de espaçamento e revisão móvel

Consulte `CHECKLIST-RESPONSIVO.md` para os resultados e as verificações em aparelhos reais ainda necessárias. Foram corrigidos os espaços em títulos com quebras de linha ocultas no celular, o cabeçalho em telas estreitas e o nome acessível do menu. A revisão usa larguras de 320 a 1920 pixels CSS no navegador; não representa certificação em Android, Safari ou TV reais. Os três arquivos de código alterados são `index.html`, `assets/platform.js` e `assets/platform.css`.


### Apresentação de projetos na página inicial

O bloco inicial chama-se **Projetos em desenvolvimento** e apresenta as categorias de propostas. Há uma única chamada: **Clique para ver todos os nossos projetos**, que abre `#projetos`. O link isolado de Ideias para o bem comum foi removido da página inicial. O grupo editorial e seus dados permanecem dentro de Projeto. Edite `projectsIntro`, `projectsUnderway` e `allProjects` em `pagina-inicial.json` nos três idiomas para alterar essa apresentação.


### WhatsApp em Contato e canais

A página `#conecte` apresenta um cartão de WhatsApp junto ao e-mail, YouTube, Instagram e Facebook. O cartão apresenta um convite para falar com o responsável, sem mostrar o número, e abre a conversa pelo endereço `wa.me` ao clicar. O envio da mensagem é feito pelo visitante no WhatsApp; o site não envia mensagens sozinho. O destino também aparece nos outros botões já existentes. Ao trocar o telefone no futuro, procure `data-contact-whatsapp` no HTML e revise `dados/parcerias.json` e suas versões de idioma para manter todos os contatos consistentes.


## Busca na página inicial

A seção **O que você procura?**, no começo da página inicial, permite buscar por assunto ou palavra-chave. Exemplos: WhatsApp, Pix, playlist e estudo diário. Digite ao menos duas letras; os resultados aparecem enquanto digita ou ao pressionar Buscar/Enter. Cada resultado contém um título clicável e um trecho do conteúdo. A busca ignora acentos e diferença entre maiúsculas e minúsculas e aceita vários termos. Os termos precisam aparecer na mesma página.

O controlador é `assets/search.js`; estilos ficam em `assets/platform.css` e a estrutura em `index.html`. A interface acompanha português, inglês e espanhol. `aliases` no controlador acrescenta palavras-chave a seções importantes, como doações/Pix e Contato/WhatsApp. Para mudar títulos específicos nos resultados, revise o mapa `titles`.

A busca usa os textos das páginas e dos catálogos que estão carregados/renderizados no navegador, inclusive as páginas internas fora da tela inicial. Ela refaz a leitura ao pesquisar e após os eventos de carregamento de conteúdo. Não utiliza serviço pago, não envia o texto pesquisado para um servidor e não salva histórico. Não lê internamente PDFs, vídeos, arquivos no Drive, páginas externas ou materiais ainda não carregados/renderizados. Catálogos filtrados podem limitar os itens presentes na página. Isso não é uma busca da internet.

Verificado: WhatsApp, Pix, playlist, santidade, busca sem resultado, clique que abre Contato e canais, normalização de acentos/caixa, vários termos e interface em três idiomas. Busca móvel medida em 320 px sem rolagem horizontal. Os testes de aparelhos reais indicados no checklist responsivo continuam necessários.


### Convites para conversar e ajudar

Os botões de WhatsApp usam a chamada “Iniciar uma conversa pelo WhatsApp” e, no cartão de Contato e canais, “Fale com o responsável pela plataforma”. O número não é exibido nesse cartão; permanece no destino do link para permitir abrir a conversa. Isso é uma escolha de apresentação, não um mecanismo de sigilo. O botão de voluntariado informa explicitamente que abre o WhatsApp. Edite `whatsapp`, `whatsappResponsible` e `volunteer` em `pagina-inicial.json` nos três idiomas para alterar os textos.


## Agenda solidária, Tiago 1:27 e calendário dinâmico

Consulte **AGENDA-SOLIDARIA.md** para o caminho completo de edição dos dados, modelo JSON, importação de CSV, publicação e funcionamento do momento diário. A agenda está em `dados/agenda-solidaria.json`; o modelo de planilha em `modelos/agenda-solidaria.csv`; o importador em `scripts/importar_agenda.py`. A página é `#agenda-solidaria`, acessível pelo menu e pela inicial.

Tiago 1:27 aparece em destaque com trecho ACF e link ao contexto. A descrição dos Vicentinos foi simplificada. A vitrine diária varia por data e agora acompanha a mudança de mês; leituras do cronograma permanecem vinculadas às datas. Bancos finitos podem repetir conteúdos; a mesma data mantém a seleção. O PDF do cronograma não foi recebido nem convertido nesta entrega.

O anexo de automação audiovisual foi preservado como especificação pendente em `docs/ESPECIFICACAO-BIBLIOTECA-AUDIOVISUAL-V3.md`. Essa automação ainda não está implementada ou ativa.


### Cor do botão de ajuda

O botão de WhatsApp em “Ajudar o próximo começa com um gesto” usa fundo dourado e texto verde escuro em ambos os temas, inclusive nos estados de link visitado, foco, hover e ativação. As cores calculadas foram conferidas no navegador nos dois temas. A agenda solidária vazia foi medida em 320 px, sem overflow da página.


## Página única Ajudar o próximo

A página inicial mescla o antigo bloco de solidariedade com o bloco de contribuição, mantendo o título “Ajudar o próximo começa com um gesto”, opções de alimentos, roupas e mutirão, resumo do destino das contribuições, WhatsApp e Pix. A chamada de detalhes abre `#solidariedade`, agora a página **Ajudar o próximo**.

Essa página reúne o que doar, ajuda que pretendemos organizar, como combinar entrega ou pedido de ajuda, destino dos recursos, as seis propostas de software, uso da IA, agenda de ações/coleta/distribuição e Pix. Os projetos continuam sendo lidos de `dados/projetos.json`; alterar o catálogo atualiza também essa apresentação. Os textos estão em `pagina-inicial.json` nos três idiomas, com chaves `giveTitle`, `giveIntro`, `giveWays`, `giveNeedsText`, `giveWhereText`, `giveMoneyText` e `giveTechnologyText`.

Os links antigos `#doacoes` e `#agenda-solidaria` continuam válidos, mas são trechos internos dessa página, e não páginas separadas no menu. `#doacoes` abre o grupo de Pix automaticamente. O QR Code e seus dados foram preservados. O resumo da inicial também mantém um acesso a esse trecho.

O cartão de agenda continua sendo alimentado por `dados/agenda-solidaria.json` e pelo importador CSV já documentado. Use `pontos_coleta`, `distribuicao` e `contato` para informar locais e responsáveis confirmados. Vicentinos e igrejas são apresentados como possibilidades de cooperação; não foram cadastrados como pontos de recebimento oficiais. A área de parcerias da página inicial permaneceu exatamente como estava. A prestação de contas financeira continua em sua página própria.

Validação: IDs e destinos locais; conteúdo das parcerias e imagem do Pix preservados; seis projetos renderizados; links antigos abrem a página única; página de ajuda em 320 px sem rolagem horizontal.


## Organização atual: Projetos em desenvolvimento

A página `#projetos` agora se chama **Projetos em desenvolvimento**. Esta organização substitui as descrições anteriores de grupos expansíveis: não existem mais os títulos intermediários “Tecnologia para servir” e “Ideias para o bem comum” nessa página. As seis propostas de software e as três propostas editoriais aparecem juntas em nove cartões, com descrição e estado de andamento. Busca e filtro atuam sobre todos os nove registros. O convite “Tem uma necessidade ou quer colaborar?” foi preservado.

A página inicial mantém os três exemplos e a chamada “Clique para ver todos os nossos projetos”. A página Ajudar o próximo explica o uso da tecnologia e aponta para os projetos, sem repetir a listagem completa. Os endereços antigos `#tecnologia-servir` e `#ideias-sociais` continuam levando à mesma página de projetos.

Os arquivos de dados são preservados: `dados/projetos.json` para softwares e `dados/ideias-sociais.json` para artigos e palestras propostos. Eles alimentam uma única listagem, sem divisões visuais. Continue seguindo as regras de status e link já documentadas. No filtro “Em desenvolvimento”, entram também propostas, produção e gravações ainda não publicadas; materiais pausados continuam pausados. Nenhuma proposta foi excluída ou marcada como pronta indevidamente.

Textos do título e da introdução: `projectsHubTitle` e `projectHubIntro`, nos três arquivos de `pagina-inicial.json`. Verificado no navegador: nove cartões, nenhum grupo expansível e pesquisa por “fome” encontra o projeto correspondente.


## Parceiros nas ações humanitárias e Tiago 1:27

O espaço `#parceiros` foi incorporado à página **Seja nosso parceiro** (`#seja-parceiro`) como categoria **Parceiros nas ações humanitárias**. Igreja Católica, Igreja Batista Nacional e Vicentinos aparecem juntos nessa categoria. As três páginas institucionais continuam disponíveis com agendas, formação e contatos, acessadas pelos cartões das instituições. Elas não são mais três opções soltas no menu ou na frente de Ajudar e participar. A navegação de retorno identifica a categoria de parceria.

O resumo da página inicial aponta para essa categoria e não repete as três instituições em uma lista de celebrações. O propósito apresentado é cooperação humanitária; a presença de uma instituição não significa adoção de sua doutrina nem confirmação de parceria formal. Os status existentes foram preservados.

Edite `dados/parceiros.json` e suas versões em inglês/espanhol para os cartões; preserve os IDs `catolica`, `batista` e `vicentinos`. As agendas e contatos continuam em `dados/comunidades.json`. Títulos e explicações: `humanitarianPartners`, `humanitarianIntro`, `humanitarianOpen` e `openCommunity` nos três arquivos `pagina-inicial.json`.

O título do acesso aos projetos permanece **Projetos em desenvolvimento**, com os nove cartões numa lista única, sem grupos expansíveis.

O destaque de Tiago 1:27 agora contém o versículo completo em português ACF, incluindo o início “A religião pura e imaculada para com Deus e Pai, é esta”. Inglês e espanhol continuam identificados como traduções editoriais, também com o início da passagem. O link para ler o capítulo foi preservado.

Verificações: três instituições agrupadas dentro de Seja nosso parceiro, links para as páginas e retorno à categoria, ausência de instituições soltas no diretório principal, título dos projetos, JSONs e traduções. Não houve confirmação de parceiros ou cadastro de horários reais nesta atualização.


## Parceiros e atividades: caminhos distintos na página inicial

O cartão de projetos em “Uma biblioteca. Muitas formas de aprender” chama-se **Projetos: cursos e ferramentas** e leva à página `#projetos`, que continua mostrando os nove projetos/propostas em lista única. Essa apresentação serve para propostas em desenvolvimento e para projetos com acesso publicado no futuro.

A inicial apresenta **Celebrações, encontros e atividades**, com acesso à nova página `#atividades`; abaixo há acessos menores a Parceiros e Seja nosso parceiro. O resumo anterior de parcerias chama-se simplesmente **Parceiros** e explica as formas de colaboração. Ele abre a categoria `#parceiros`, dentro da página Seja nosso parceiro. Não foi criada uma segunda página de parceiros.

- **Parceiros:** o que cada instituição pode contribuir, como tempo, voluntariado, alimentos, roupas, conhecimento e organização. As contribuições são possibilidades a combinar, não acordos já firmados.
- **Atividades:** o que a plataforma pode propor a cada comunidade: campanhas, mutirões, organização de materiais, agenda, voluntariado e ferramentas de software. Há oito propostas distribuídas pelas três instituições.
- **Agendas reais:** horários de celebrações e eventos continuam em `dados/comunidades.json`, nas páginas institucionais. As propostas de atividades não criam eventos confirmados.

### Atualizar as contribuições e atividades

O arquivo **dados/atividades-parcerias.json** é compartilhado pelos idiomas. O controlador `assets/activities.js` apresenta a página e acrescenta as contribuições aos cartões dos parceiros. Os nomes/descrições dos cartões continuam em `dados/parceiros.json` nos três idiomas; contatos e agendas continuam em `dados/comunidades.json`.

Em `instituicoes`, localize o registro por `id`: `catolica`, `batista` ou `vicentinos`. Preserve o ID. Os campos são:

| Campo | Uso |
|---|---|
| `titulo` | Nome da instituição |
| `contribuicoes_possiveis` | Lista de textos sobre como a instituição pode colaborar; aparece em Parceiros |
| `atividades_propostas` | Lista de propostas mostradas na página Atividades |
| `atividades_propostas[].titulo` | Nome da proposta |
| `atividades_propostas[].descricao` | O que se pretende oferecer e em que condições |
| `atividades_propostas[].projeto` | Nome opcional de software relacionado; cria acesso à página de projetos |
| `traducoes.en` / `traducoes.es` | Título, contribuições e propostas traduzidos editorialmente |

Para acrescentar uma atividade, adicione um objeto com `titulo`, `descricao` e, se houver, `projeto`, dentro de `atividades_propostas`. Para acrescentar uma forma de colaboração, adicione um texto à lista `contribuicoes_possiveis`. Revise as versões em inglês e espanhol; não há tradução remota automática. O campo `projeto` deve ser o nome de um projeto existente, sem indicar software pronto se ele ainda for proposta.

Execute `python3 scripts/validar_site.py`, salve e faça Commit/Push. Após a publicação do GitHub Pages, a página lê o arquivo ao abrir; verifica de novo a cada cinco minutos e ao retornar à aba. Recarregue para conferir imediatamente. O site não grava alterações no GitHub pelo navegador.

Respeito institucional: materiais de ensino são escolhidos/revisados pela própria comunidade conforme sua doutrina. Apoio de IA é apresentado como auxílio à organização e aos rascunhos, com revisão humana. Não foram inventadas celebrações, datas ou parcerias. O recebimento de doações e uso de espaços também precisam de confirmação.

Validação desta atualização: três idiomas, três instituições, oito propostas, contribuições sem duplicação após recarregar catálogos, links para agendas e projetos, JSONs e idiomas consistentes. Inicial, Parceiros e Atividades medidos em 320 pixels CSS sem rolagem horizontal. Testes em Android/TV reais continuam pendentes.


## Cursos e ferramentas para instituições e comunidades

A biblioteca da página inicial mantém “Uma biblioteca. Muitas formas de aprender” e apresenta também projetos de cursos e ferramentas. O cartão agora se chama **Projetos: cursos e ferramentas**, com descrição que inclui escolas, igrejas, comunidades e instituições de cuidado. Não anuncia cursos disponíveis: encaminha às propostas em desenvolvimento.

Foram acrescentados quatro registros a `dados/projetos.json`, preservando todos os projetos anteriores:

| ID | Projeto | Público/objetivo |
|---|---|---|
| `aprender-juntos` | Aprender Juntos | Cursos e materiais para instituições de acolhimento de crianças e adolescentes, incluindo orfanatos |
| `cuidado-em-rede` | Cuidado em Rede | Organização de voluntários, materiais e doações para casas de apoio |
| `viver-e-aprender` | Viver e Aprender | Oficinas e materiais para centros de idosos |
| `formacao-comunitaria` | Formação Comunitária | Cursos e ferramentas para escolas, igrejas e comunidades |

A listagem reúne agora **13 cartões**: dez propostas de ferramentas/cursos em `dados/projetos.json` e três propostas editoriais em `dados/ideias-sociais.json`. Os novos itens usam `status: em-desenvolvimento`, `etapa: planejamento` e links vazios. Não há curso, software ou implantação concluídos anunciados nesses quatro registros.

Para desenvolver uma proposta, mantenha seu ID, revise descrição e etapa e preencha o link somente quando houver um destino real. As regras de status/link continuam funcionando; nenhum estado dos projetos anteriores foi alterado. Preserve as traduções em `traducoes.en` e `traducoes.es`. O acervo da inicial continua destacando os três primeiros projetos, com acesso à página completa.

Os cursos deverão ser definidos com educadores, cuidadores, equipes e participantes; a proposta respeita idade, necessidades, acessibilidade, organização e doutrina de cada instituição quando aplicável. As parcerias e ofertas de atividades permanecem propostas a combinar.


## Frase de abertura e revisão desta versão

A abertura da inicial é **A fé sem obras é morta.**, com a referência **Tiago 2:26**, sem os rótulos “trecho” ou “ACF”. O restante da apresentação foi preservado. Os textos ficam em `welcomeTitle` e `welcomeRef` de `assets/platform.js`, nos três idiomas; o HTML contém o texto inicial de fallback.

Consulte `REVISAO-FINAL.md` para o resumo do que está presente, testes executados e pendências de conteúdo/configuração. Não confundir as estruturas preparadas com integrações externas ativas.

## Painel ampliado: menus, lotes, bloqueios e atualizações

A versão atual organiza a administração por assunto. Vídeos podem ser aprovados/não aprovados em lotes de até 300, ter categorias alteradas e ser excluídos com bloqueio persistente por ID em `biblioteca-controle/editorial.json`. A confirmação editorial continua necessária para aprovar. O bloqueio não depende da permanência de metadados temporários.

Músicas e playlists têm cadastro/edição/exclusão por formulário. Livros, materiais, projetos, cursos, parceiros, solidariedade e momentos diários têm menus que abrem os respectivos arquivos autorais. O editor admite JSON e TXT; não altera credenciais, scripts ou workflows. As integrações externas de música/Spotify/podcasts/lives estão identificadas como pendentes, enquanto os links manuais já podem ser mantidos.

**Instalação na versão existente:** extraia `atualizacao-painel-completo.zip`, mantendo o seu `admin/config.json`. Execute uma vez `scripts/admin/atualizacao-painel.sql` no SQL Editor do Supabase. Publique o código e rode manualmente o workflow administrativo para sincronizar a lista ampliada de conteúdos. Os Secrets existentes são preservados.

A guia **Atualizações e integrações** distingue recarregar a tela, sincronizar o banco administrativo, descobrir vídeos pelo YouTube e publicar o site. Solicitações usam `run_sync`; o runner despacha apenas destinos permitidos e o workflow informa etapas reais e erros. A fila é processada aproximadamente a cada 15 minutos. Confira o caminho completo de uso, instalação e recuperação em **PAINEL-ADMINISTRATIVO.md**, que é a referência atual para o painel e substitui instruções anteriores sobre suas funções.
