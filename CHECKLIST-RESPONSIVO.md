# Checklist de revisão responsiva — 1/11/2026

## Problema corrigido

As quebras de linha `<br>` dos títulos eram escondidas no celular e não havia espaço textual entre as palavras. Foram incluídos espaços antes das quebras no HTML e nos textos da navegação em português, inglês e espanhol. Os títulos agora mantêm as palavras separadas em qualquer largura. Essa correção também cobre outros títulos que usam a mesma estratégia.

## Ajustes adicionais

- Cabeçalho até 480 px: marca e controles em duas linhas para impedir que os botões ultrapassem a tela.
- Botões de tema e menu com largura e altura mínimas de 44 px nessas telas.
- Nome acessível do botão Explorar preservado mesmo quando seu texto visual é escondido.
- Cards e grupos podem encolher e acomodar textos sem impor largura mínima indevida.
- Espaço de rolagem e altura máxima do menu ajustados ao cabeçalho móvel.

## Verificações realizadas

- [x] Causa do problema conferida no código-fonte e comparada ao print enviado.
- [x] Títulos dos três caminhos conferidos renderizados nos três idiomas.
- [x] Página inicial sem rolagem horizontal em larguras de iframe de 320, 360, 390, 412, 768, 1366 e 1920 pixels CSS.
- [x] Todas as 41 telas/rotas principais, incluindo as 37 seções de conteúdo, abertas e medidas em 320 e 360 pixels: sem rolagem horizontal na página.
- [x] Oito páginas principais medidas em 768 e 1366 pixels: inicial, estudo diário, escola, projeto, filmes, músicas, prestação de contas e comunidade católica.
- [x] Menu móvel aberto e fechado em 360 pixels.
- [x] Tema escuro e títulos dos cards inspecionados visualmente em tela estreita.
- [x] Arquivos, JSONs, traduções, IDs, âncoras e destinos locais validados pelo script do projeto.

As medidas foram realizadas no Chrome por iframes com larguras controladas. Isso exercita o CSS responsivo real, mas não emula um sistema Android completo nem certifica todas as interações ou conteúdos futuros. A largura útil é menor quando o navegador reserva espaço para a barra de rolagem. Ausência de overflow da página não garante que todo conteúdo expansível, tabela ou campo futuro caiba em todas as situações.

## Conferir após publicar, em aparelhos reais

- [ ] Android/Chrome: abrir o site atualizado, testar os três caminhos, Explorar, idioma e tema.
- [ ] Aumentar o tamanho da fonte do Android; verificar cabeçalho, calendário e botões.
- [ ] Girar o telefone para horizontal e vertical.
- [ ] Selecionar dias do calendário, mudar mês e conferir leitura, oração, reflexão e louvor.
- [ ] Abrir artigos e grupos expansíveis, pesquisar e filtrar catálogos.
- [ ] Conferir foco visível usando teclado e, quando possível, TalkBack.
- [ ] Testar em iPhone/Safari, ainda não disponível nesta revisão.
- [ ] TV: testar o navegador específico e navegação pelo controle remoto. Largura de 1920 px não substitui esse teste.
- [ ] Após acrescentar conteúdos reais, revisar títulos longos, capas, players e documentos externos.

## Publicar esta correção

Substitua os arquivos do pacote no repositório pelo VS Code e faça Commit/Push. Os arquivos de código alterados nesta revisão são `index.html`, `assets/platform.js` e `assets/platform.css`. O README e este checklist também foram atualizados. Não foi feito envio ao GitHub nesta revisão.

Se ainda aparecer a versão antiga, recarregue a página após a publicação. A prévia HTML é independente: publique os arquivos do ZIP, não apenas a prévia.
