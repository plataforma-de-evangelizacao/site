# Publicação direta — instalação e primeiro teste

**Versão:** 2026.11.02-publicacao-direta · **Data:** 2 de novembro de 2026, horário de Mato Grosso.

Esta atualização transforma os dados em formulários e faz aprovações, alterações, arquivamentos e remoções serem lidos diretamente do Supabase. O GitHub continua recebendo uma cópia em segundo plano. O primeiro objetivo de validação é fechar as telas de **vídeos** e **projetos**.

## Instalar no projeto que já está funcionando

1. Extraia **`atualizacao-publicacao-direta.zip`**. Abra o arquivo **`ATIVAR-PUBLICACAO-DIRETA.sql`** que está na raiz do ZIP. No **SQL Editor do mesmo Supabase do painel**, abra uma nova consulta, cole o conteúdo e execute. Aguarde **Success**. Ele depende das tabelas originais `pge_*` já existentes. Não execute a migração em outro projeto.
2. Copie os arquivos do ZIP para a pasta local do repositório `site`, substituindo os correspondentes. Preserve a pasta oculta **`.github`**. O pacote não inclui `admin/config.json`: a URL e a chave pública que você já configurou continuam no arquivo existente. Não precisa trocar senha nem criar outro usuário.
3. Faça commit e envie para `main`. Aguarde **Biblioteca e GitHub Pages** concluir a publicação. Nesta primeira instalação, o Actions ainda é necessário para publicar o código novo; depois disso as alterações de conteúdo do painel usam a publicação direta.
4. Execute **Actions → Painel administrativo → Run workflow → main** uma vez e aguarde concluir. Isso sincroniza os campos completos dos vídeos e os documentos. Abra `/site/admin/`, recarregue a página e entre novamente.
5. Na visão geral, a mensagem esperada é **“Publicação direta de vídeos e conteúdos ativa.”** Abra **Projetos e cursos** ou o atalho **Criar ou editar projetos** e confira os cartões. Em **Acervo de vídeos**, confira os pendentes e a tela **Publicados no site**. Em seguida, siga **`ROTEIRO-TESTES-VIDEOS-E-PROJETOS.md`**.

Se o SQL não retornar Success, não continue para os testes de publicação: envie a mensagem de erro, sem senhas ou chaves. O script passou por 29 verificações em PostgreSQL local via PGlite, com autenticação simulada. Sua execução no Supabase da plataforma ainda precisa ser confirmada.

## O que é imediato

- Aprovar, mudar categoria, arquivar, restaurar e bloquear um vídeo: a decisão é salva em uma transação no banco e o catálogo público passa a consultá-la.
- Criar, editar, arquivar, restaurar ou excluir um projeto e os demais conteúdos por formulário: a versão publicada é atualizada no Supabase, sem esperar a agenda do Actions.
- Após a confirmação de publicação, recarregar a página pública lê a versão atual. Páginas abertas verificam alterações aproximadamente a cada **10 segundos**. Rede, tamanho do conteúdo e disponibilidade do Supabase influenciam o tempo; não é um prazo garantido.

## O que continua em segundo plano

- Descoberta de novos vídeos e consultas às APIs externas: continuam com as rotinas e quotas já existentes. O botão solicita a execução ao workflow; a fila administrativa pode aguardar o agendamento. Isto é diferente de publicar um conteúdo já disponível no painel.
- A cópia dos conteúdos e decisões no GitHub: sincronizada pelo workflow administrativo. Não é necessária para a visibilidade imediata, mas continua importante para histórico e recuperação.
- Busca musical, Spotify, podcasts e lives: os cadastros manuais têm formulários; as respectivas descobertas externas continuam identificadas como integrações a configurar.
- O PDF de orações ainda será tratado quando você enviar o material.

## Projetos e parceiros

Os cinco novos projetos são propostas em planejamento: apoio diante da dependência de álcool, apoio diante de outras drogas, roupas, alimentos e mutirões. Não há atendimento, parceria oficial ou implantação sendo anunciados como já existentes.

No projeto, **Parceiros envolvidos → Adicionar parceiro ao projeto** oferece as instituições cadastradas, com nome/cidade. Você informa o papel e a situação: **a propor**, **em conversa** ou **confirmada**. O site separa os parceiros confirmados das parcerias em construção. Nenhum parceiro foi vinculado automaticamente aos projetos.

## Idiomas

A interface oferece português, inglês e espanhol. Os campos de tradução de cada cartão permitem preencher os textos em inglês e espanhol. Arquivos com versões separadas de idioma são publicados em conjunto, conservando traduções existentes e sincronizando a estrutura.

**Não há serviço de tradução automática conectado.** Um texto novo sem tradução usa o português como alternativa; o painel explica que a tradução está pendente. Os cinco projetos desta entrega incluem textos preparados em inglês e espanhol. Os valores técnicos de status, links e IDs não são traduzidos.

## Como conferir o resultado

Use duas abas: uma com o painel e outra com o site público. Após clicar **Salvar e publicar agora**, aguarde a confirmação e recarregue a aba pública. Não precisa rodar um workflow entre cada edição de conteúdo. O roteiro separado lista os resultados esperados e diferencia arquivar, excluir/bloquear e restaurar.
