# Plataforma Global de Evangelização

Uma iniciativa cristã de Marcos Lucas Pereira, em Nova Bandeirantes (MT), para conhecer a Palavra, viver o amor e compartilhar cuidado. O acesso aos conteúdos não exige cadastro ou doação.

## O que você encontra

A página inicial apresenta os três caminhos da plataforma, o momento diário com calendário, a biblioteca, a Escola: fé e conhecimento, projetos de software, cuidado, doações e parcerias.

- Conhecer e estudar: Bíblia, santidade, estudos, disciplinas e cuidado.
- Acompanhar: YouTube, música, filmes, desenhos, palestras e publicações.
- Ajudar e participar: missão, ações, doações voluntárias e projetos de tecnologia.

## Projetos

Seis propostas de ferramentas gratuitas estão na etapa de planejamento. O primeiro projeto é Escola Aberta, voltado à gestão escolar. Os demais abrangem igrejas, transporte escolar, doações, comércio local e materiais educativos. Não há software concluído ou implantação institucional anunciada nesta versão. Licenças dos futuros códigos serão definidas em seus próprios repositórios.

Artigos e palestras sobre desafios humanitários ficam em Ideias para o bem comum, separados das ferramentas de software.

## Atualizar sem alterar o layout

| Arquivo | Finalidade |
| --- | --- |
| dados/projetos.json | Projetos de software, links, documentação e estados |
| dados/ideias-sociais.json | Propostas de artigos e palestras sobre o bem comum |
| dados/catalogo-conteudos.json | Novos filmes, músicas, artigos, cursos e outros materiais |
| dados/planejamento.json | Planejamento editorial já existente |
| dados/leituras.json | Cronograma diário da igreja; aguardando inclusão |
| dados/pagina-inicial.json | Apresentação da página inicial |

Os três catálogos novos e o planejamento compartilham estados e links em português, inglês e espanhol; os textos podem ser traduzidos nos campos traducoes. A apresentação da página inicial possui versões em dados/en/ e dados/es/. Os acervos anteriores continuam funcionando. Leia COMO-ATUALIZAR-PROJETOS-E-ACERVO.md.

## Publicar no GitHub Pages

Extraia o pacote e coloque index.html, assets, dados e os demais arquivos na pasta publicada pelo repositório existente, preservando .git e configurações próprias do GitHub. Confira as alterações no VS Code, faça commit e envie. O pacote não muda as configurações do repositório nem publica sozinho. Os caminhos relativos são compatíveis com a publicação em /site/.

Para testar localmente, abra a pasta com uma extensão de servidor local do VS Code ou use python3 -m http.server 8000 e abra http://localhost:8000. Abrir index.html diretamente usa o conteúdo inicial; atualizações dos JSON dependem de um servidor. A prévia HTML independente é fornecida separadamente.

## Estado das integrações

A atualização dos catálogos é uma leitura de arquivos estáticos do repositório publicado. Não é uma consulta automática ao estado de desenvolvimento no GitHub. A página relê os arquivos ao abrir, ao retornar à aba e a cada cinco minutos. A publicação do GitHub Pages precisa terminar antes de a alteração aparecer.

YouTube Data API, notificações de live, e-mail, WhatsApp e sincronização com Drive ainda dependem de configuração. Nenhuma credencial está incluída. O planejamento dessas integrações está em PENDENCIAS-DE-AUTOMACAO.md.

## Princípios

Consulte PRINCIPIOS-EDITORIAIS.md, GUIA-DE-TRADUCAO.md e ACOLHIMENTO-E-SEGURANCA.md. A abordagem cristã distingue conhecimento da disciplina, texto bíblico e interpretação teológica. Os serviços de acolhimento não substituem atendimento profissional.

Contato: marcoslucaspereira1@gmail.com.
