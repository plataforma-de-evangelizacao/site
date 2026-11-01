# Atualizar projetos e novos conteúdos

## Projetos de software

Edite **dados/projetos.json**. Encontre o objeto pelo id e atualize os campos. O arquivo é compartilhado pelos três idiomas; não crie cópias em en/es.

| Situação no arquivo | Resultado no site |
| --- | --- |
| status em-desenvolvimento e sem link | Em desenvolvimento, sem botão de acesso |
| link ou repositorio preenchido com HTTPS | Disponível e botão Acessar projeto |
| status pausado | Pausado, sem botão principal mesmo que haja link |
| status concluido/publicado/disponivel sem link | Concluído · link a informar |
| status proposta sem link | Proposta |

A regra verifica se há uma URL HTTPS no arquivo. Ela não verifica se o software está terminado, se o destino está público ou se a URL abre corretamente. Confira o destino antes de publicar. Um link de repositório pode apontar para código; um link principal pode apontar para uma demonstração. Informe somente destinos públicos que deseja divulgar. Credenciais e dados pessoais de alunos, voluntários ou beneficiários não pertencem a esses arquivos públicos.

- titulo e descricao: textos em português.
- traducoes.en e traducoes.es: titulo e descricao nos outros idiomas. Sem tradução, aparece o original.
- repositorio: endereço HTTPS real do código no GitHub.
- link: endereço principal público; tem preferência sobre repositorio.
- documentacao: endereço HTTPS de documentação pública, por exemplo no Drive.
- status: em-desenvolvimento, proposta, pausado, concluido ou disponivel.
- etapa: planejamento, prototipo ou outra descrição interna; os seis atuais estão em planejamento.
- prioridade: true para o primeiro projeto; false nos demais.
- licenca: a-definir até escolher a licença real do software.

Quando o projeto tiver código pronto para divulgar, preencha repositorio e/ou link. A ficha e a vitrine inicial mudam juntas. No momento, as três primeiras fichas formam o destaque da página inicial; a página Projetos mostra todas, com busca e filtro.

## Ideias sociais

Edite **dados/ideias-sociais.json** para artigos e palestras sobre fome, educação, IA e outros desafios. A página Ideias para o bem comum exibe essas fichas. Use titulo, descricao, traducoes, status e link com a mesma regra de disponibilidade. Esse arquivo não cria um software nem uma palestra já gravada. O planejamento editorial anterior continua em dados/planejamento.json e mantém seus próprios estados.

## Um catálogo para novos conteúdos

Edite **dados/catalogo-conteudos.json**. A lista itens começa vazia para preservar a seleção de materiais reais. Cada objeto pode ter id, tipo, titulo, descricao, status, link, documentacao e traducoes.

| tipo | Onde aparece |
| --- | --- |
| filme / desenho | Filmes, desenhos e inspiração |
| musica | Músicas e Spotify |
| artigo / estudo | Artigos e estudos bíblicos |
| livro | Livros e publicações |
| palestra / video | Palestras e ministrações |
| curso | Escola: fé e conhecimento |
| material | Biblioteca de ensino |

Sem link, o item mostra seu estado. Com HTTPS, aparece Disponível e Abrir conteúdo. Links para Drive, YouTube, GitHub e outras fontes são aceitos. A regra é a mesma dos projetos, incluindo a pausa. A interface traduzida não traduz um vídeo, uma música ou um software externo.

Os arquivos antigos de músicas, artigos, filmes e catálogos continuam operando com seus formatos anteriores. Não é preciso apagar ou migrar o acervo existente. Para novos cadastros que devem aparecer antes de estarem publicados, prefira o catálogo comum. Evite cadastrar o mesmo conteúdo nos dois formatos para não duplicá-lo. O catálogo comum não adiciona automaticamente um filme às Histórias bíblicas: essa organização continua em temas-biblicos.json e midias-biblicas.json.

Modelos sem conteúdo publicado estão na pasta modelos/. Copie o objeto para a lista itens do arquivo correspondente, atribua id único e preencha os textos. Preserve aspas, vírgulas, colchetes e chaves.

## Calendário e apresentação

- dados/leituras.json: leituras por data AAAA-MM-DD; os campos reading, prayer, reflection e song podem personalizar aquele dia.
- passagens: lista de objetos com referencia, protestante e catolica. Cada endereço deve ser HTTPS. A página inicial abre as passagens nas fontes indicadas.
- Enquanto não houver cronograma, a página identifica a passagem como sugestão editorial. Nenhuma leitura é atribuída à igreja sem o cronograma.
- A oração e o louvor seguem a mesma seleção por data no início e na página de estudo. O acervo tem 2.000 variações de orações originais por idioma; isso não significa 2.000 passagens bíblicas.
- dados/pagina-inicial.json e correspondentes en/es: apresentação e rótulos da nova vitrine.
- O fuso do calendário é o da região de Nova Bandeirantes: America/Cuiaba.

Ao editar JSON publicados, o site os relê. A prévia HTML independente é uma fotografia do acervo desta entrega e precisa ser regenerada para incorporar alterações posteriores. O conteúdo inicial em assets/vitrine.js permite abrir a prévia independente e mantém a página utilizável se um arquivo falhar; deve ser atualizado junto dos arquivos quando gerarmos uma nova entrega.

## Passos no VS Code

1. Faça Pull do repositório.
2. Edite o JSON desejado e confira a sintaxe.
3. Faça commit e Push.
4. Aguarde a publicação do Pages e recarregue o site.
5. Abra o botão e confira o destino como visitante.

Não existe consulta contínua à sua conta GitHub nem acesso ao computador de quem administra. A atualização acontece porque o JSON foi publicado junto do site. Agendamentos e sincronizações externas continuam pendentes.
