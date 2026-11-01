# Plataforma Global de Evangelização — pacote revisado

## Publicar no seu GitHub

1. Faça uma cópia do repositório atual antes de substituir os arquivos.
2. Extraia este ZIP. Envie **o conteúdo da pasta** para a raiz do repositório `site`, mantendo a estrutura. Não envie apenas o ZIP.
3. Substitua `index.html` e os arquivos existentes; envie também `assets/`, `dados/` e `.nojekyll`.
4. No GitHub, abra Settings → Pages e confira a publicação pela branch `main`, pasta `/ (root)`, ou mantenha o fluxo de Pages que você já utiliza.
5. Aguarde o processo de publicação terminar e abra a página, atualizando o cache se necessário.

Este pacote é estático, sem instalação e sem cobrança de API. Não configura integrações externas automaticamente. A publicação no seu repositório não foi alterada nesta revisão.

## Como navegar

A página inicial apresenta três caminhos. Cada assunto abre em sua própria visualização dentro do mesmo site; o botão Voltar do navegador funciona. Links antigos com # continuaram válidos. O menu Explorar contém busca de espaços e o mapa da plataforma reúne todas as seções.

O tema claro/escuro e o idioma ficam salvos no navegador. A navegação e o acervo atual de autoria da plataforma estão disponíveis em português, inglês e espanhol. A mudança de idioma recarrega a mesma seção e passa a ler os arquivos correspondentes. Há 2.000 variações de oração em cada idioma.

Os links externos preservam o destino e a língua do material de origem. Traduzir a descrição não traduz um vídeo, um PDF ou uma edição bíblica externa. Os títulos originais de músicas são preservados para que possam ser encontrados. O Pai-Nosso em inglês/espanhol é uma tradução editorial identificada da BLIVRE; não é apresentado como citação de uma Bíblia publicada nesses idiomas.

“Acolhimento e apoio” tem acesso visível no cabeçalho e na entrada. Inclui apoio humano, orientação para emergências, mensagem para pedir companhia, cuidados de saúde e oração opcional. Os serviços indicados são do Brasil em todos os idiomas, conforme o aviso na seção. O projeto não oferece atendimento de crise por e-mail.

## Como atualizar conteúdos

O português usa os arquivos de `dados/` e `catalogo.txt`. Inglês usa `dados/en/`; espanhol usa `dados/es/`. Edite o arquivo do idioma desejado, seguindo COMO-ATUALIZAR-CONTEUDOS.md e os exemplos. Mantenha o JSON válido e confirme a publicação no GitHub. O site relê os dados ao abrir e os principais acervos a cada cinco minutos enquanto a página está aberta; a nova introdução de Fé e conhecimento é relida ao retornar à aba após cinco minutos. A pausa diária é atualizada ao abrir e a seleção muda por data de Mato Grosso. Conteúdos já carregados podem permanecer até recarregar a página.

- `dados/fe-conhecimento.json`: disciplinas, fundamentos, perguntas e práticas.
- `dados/pausa-diaria.json`: reflexões da entrada. Cada título, texto e prática tem três traduções na ordem português, inglês, espanhol. O link bíblico atual abre em português; os links musicais abrem buscas, não reprodução automática.
- `PRINCIPIOS-EDITORIAIS.md`: orientação de conteúdo que Marcos definiu para os próximos materiais.
- `CHECKLIST.md`: o que funciona, o que aguarda conteúdo e o que precisa de integração.

A aparência e a navegação estão em `assets/platform.css` e `assets/platform.js`. `assets/faith.js` monta as disciplinas. `assets/localization.js` direciona os arquivos e traduz a interface dinâmica. `assets/support.js` monta o acolhimento. Os demais módulos estão no HTML. Consulte GUIA-DE-TRADUCAO.md e ACOLHIMENTO-E-SEGURANCA.md.

## Prévia e verificação

O HTML avulso entregue junto deste pacote é uma prévia independente. **Para publicar, use index.html e todas as pastas do ZIP**, pois é essa versão que busca os arquivos atualizados no repositório. Ao abrir arquivos locais, o navegador pode impedir a leitura dos JSON; isso não representa a publicação pelo GitHub Pages.

Veja REVISAO-DA-PLATAFORMA.md para decisões, fontes e limites dos testes. Não há monitoramento psicológico, diagnóstico ou mensagens apresentadas como se fossem falas novas de Jesus. O site não promete curar depressão nem substituir tratamento ou emergência.

## Novos estudos e próximos conteúdos

A plataforma agora reúne 35 espaços. Conhecer e estudar inclui Entender o pecado e Espírito Santo e santidade. Acompanhar inclui Próximos conteúdos. O estudo sobre pecado ganhou exemplos cotidianos e conexão com autocuidado e jejum.

Para atualizar propostas e andamento, edite somente dados/planejamento.json. Esse arquivo é compartilhado entre os idiomas; os estudos novos têm versões em dados/, dados/en/ e dados/es/. Consulte COMO-ATUALIZAR-PLANEJAMENTO.md.

## Corpo, vontade e escolhas

Na página inicial, abra Corpo, vontade e escolhas. O estudo reúne atenção, sentidos, palavras, afetos, alimentação e sexualidade em sete campos didáticos, além de emoções e aprendizagem compartilhada. A correlação é autoral e apresentada com limites claros. O acervo atual tem 16 propostas de conteúdos futuros: oito palestras, sete artigos e um livro.

## Página inicial ampliada e projetos

Abra a nova prévia. O início mostra como a plataforma funciona, momento diário com calendário, biblioteca, Escola, projetos e participação. O primeiro software proposto é Escola Aberta. Os seis projetos ainda estão em planejamento. Para atualizar estados e links, leia COMO-ATUALIZAR-PROJETOS-E-ACERVO.md. README.md apresenta o repositório.
