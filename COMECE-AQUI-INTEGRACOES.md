# Atualização de integrações, sessão e filtros

> Guia histórico: para a versão nova, use **LEIA-PRIMEIRO.md**. A atualização automática substitui a execução manual de SQL e a publicação manual da função.

**3 de novembro de 2026 · Plataforma Global de Evangelização**

Este pacote é uma atualização sobre a versão de publicação direta (v38). A publicação/retirada de conteúdo continua usando o Supabase imediatamente. Os botões de busca passam a poder disparar o GitHub diretamente, sem esperar a rotina de 15 minutos. Isso depende de ativar uma função protegida no Supabase uma vez.

## 1. Instalar os arquivos

1. Faça uma cópia do repositório local antes de substituir os arquivos.
2. Extraia `atualizacao-integracoes-filtros.zip` dentro da pasta do repositório. Inclua `.github` e `supabase`. O ZIP não contém `admin/config.json`, `biblioteca-controle/config.json` ou suas decisões editoriais: preserve esses arquivos.
3. No SQL Editor do mesmo projeto Supabase, execute `ATUALIZAR-ACOMPANHAMENTO.sql`. É uma migração pequena para conservar o título de vídeos bloqueados enquanto seus metadados estiverem válidos. Depende de `ATIVAR-PUBLICACAO-DIRETA.sql` já instalado. Não remove projetos nem usuários.
4. Faça commit/push para `main` e espere a publicação no Pages terminar. Os workflows novos precisam estar na branch principal antes de testar o disparo.

## 2. Ativar o disparo direto (uma vez)

O navegador não pode guardar uma credencial administrativa do GitHub. A função `admin-dispatch` recebe o JWT do administrador, valida a sessão no Supabase Auth, confere `pge_admins` e só permite três rotinas fixas do repositório `plataforma-de-evangelizacao/site`.

### Credencial do GitHub

1. No GitHub, abra as configurações da sua conta → Developer settings → Personal access tokens → Fine-grained tokens → Generate new token.
2. Use o proprietário que tem acesso à organização `plataforma-de-evangelizacao`. Restrinja aos repositórios selecionados e escolha somente `site`.
3. Em Repository permissions, conceda **Actions: Read and write**. Metadata é leitura automática. Não é necessário conceder escrita em conteúdos para esta função. Se a organização pedir aprovação do token, conclua essa aprovação.
4. Escolha uma validade e guarde a credencial diretamente no Supabase, conforme abaixo. Ao vencer, renove o segredo para reativar os disparos. Não coloque o token em HTML, JSON, GitHub público ou no chat.

### Função no Supabase pelo painel

1. Abra **Edge Functions** no projeto Supabase.
2. Crie uma função chamada exatamente **`admin-dispatch`**, usando o editor. Copie o conteúdo completo de `supabase/functions/admin-dispatch/index.ts` para o arquivo de entrada.
3. Nas configurações da função, desative a verificação JWT legada da plataforma para essa função. **O código faz a autenticação explicitamente via Auth e `pge_admins` em todas as chamadas**; desativar o verificador legado não torna a operação pública. Não remova essas verificações do código.
4. Em **Edge Functions → Secrets**, crie **`GITHUB_DISPATCH_TOKEN`** com o token do GitHub. As variáveis padrão `SUPABASE_URL` e `SUPABASE_SERVICE_ROLE_KEY` são fornecidas pelo Supabase. Não altere a chave pública do site.
5. Publique a função. O domínio permitido padrão é `https://plataforma-de-evangelizacao.github.io`. Se usar domínio próprio, configure também **`ADMIN_ALLOWED_ORIGIN`** com a origem HTTPS correta (sem `/site/`); múltiplas origens podem ser separadas por vírgula.

Alternativa para quem usa Supabase CLI já instalado/autenticado, a partir do repositório:

```sh
supabase functions deploy admin-dispatch --project-ref SUA_REFERENCIA --no-verify-jwt
```

Cadastre o segredo pelo painel para não incluí-lo no histórico do terminal. O arquivo `supabase/config.toml` contém apenas a configuração da função.

## 3. Primeiro teste de busca

1. Abra `/site/admin/`, faça login e entre em **Atualizações e integrações**.
2. Clique **Buscar novos vídeos no YouTube** e confirme. O cartão deve sair de pedido recebido para fila do GitHub. Se existir um pedido antigo pendente, use **Disparar agora** no cartão desse pedido.
3. Quando o executor iniciar, aparecem etapa, chamadas usadas, limites, IDs encontrados, novos títulos, ignorados, duplicados e pendentes. O total publicado aparece depois da sincronização confirmada. Um contador sem retorno mostra `—`, não um zero inventado.
4. O painel consulta o Supabase a cada segundo enquanto há trabalho ou a guia de atualizações está aberta. A reconciliação com o GitHub ocorre aproximadamente a cada 15 segundos. Isso evita uma chamada à API do GitHub por segundo para cada botão.
5. A porcentagem usa etapas confirmadas e tarefas processadas. Não é um cronômetro nem a proporção de todos os vídeos existentes no YouTube. O total de tarefas pode crescer com paginação. O tempo restante fica sem estimativa quando não é confiável.
6. Ao concluir, os dados do painel são recarregados sem F5. Se houver um formulário com edição não salva, ele é preservado e o painel avisa para recarregar depois de salvar.

A fila do GitHub ainda pode aguardar um executor ou outro workflow em execução. Não há prazo de início garantido. Falhas do Actions, recusas de permissão, limites e ausência de confirmação aparecem no cartão, com link quando disponível. Não clique repetidamente: uma solicitação em andamento não é disparada uma segunda vez.

### Se não funcionar

- `dispatch_not_configured`/função indisponível: conclua a etapa 2. A solicitação continua pendente; use **Disparar agora** após configurar.
- `github_dispatch_403`: confira Actions: write, aprovação da organização e validade do token.
- `github_dispatch_404` ou `422`: confira se os workflows deste pacote já chegaram à `main` e se o token pertence ao repositório correto.
- Na fila do GitHub: abra o link e confira se há outra execução ocupando o grupo. Não significa que a API do YouTube já começou.
- Sem novo retorno: o painel mostra há quanto tempo recebeu a última atualização. Use **Conferir no GitHub agora**. Se o GitHub terminar sem o callback, a reconciliação atualiza o resultado.
- API sem credenciais/quota: aparece o código do problema; não aumentamos automaticamente quota ou despesas. O limite efetivo é lido da configuração existente.

## 4. Sessão ao recarregar

Entre e pressione F5: a mesma aba deve continuar autenticada. Não guardamos sua senha. A sessão e o refresh token ficam no armazenamento da aba, com renovação do token de acesso. Dez minutos sem clique, toque, teclado ou rolagem encerram a sessão. Consultas automáticas não contam como atividade. Sair apaga a sessão local e solicita encerramento ao Supabase. Um novo login sempre confere a associação em `pge_admins`.

## 5. Recuperar exclusões

- **Vídeos:** em **Publicados no site → Situação**, escolha **Excluídos e bloqueados** ou **Arquivados**. O menu também tem **Excluídos e bloqueados**. Um bloqueado volta para revisão; não é aprovado sem conferência. Um arquivado elegível pode restaurar a publicação. O ID de bloqueio permanece mesmo quando os metadados vencem; o título pode ficar indisponível sem verificação recente.
- **Projetos e outros cartões de objeto:** em **Criar ou editar projetos → Exibir conteúdos**, escolha **Lixeira — excluídos**. Use **Restaurar e publicar**. Exclusões novas são reversíveis e saem da página pública na hora.
- Itens apagados definitivamente em versões anteriores não são recriados automaticamente. Listas simples de linhas/textos continuam com edição da lista; a lixeira por cartão é para objetos estruturados.

## 6. Filtros automáticos da biblioteca

A indexação utiliza um dicionário de palavras inteiras, aliases e regras em `dados/biblioteca/regras-indexacao.json`. Título, descrição, hashtags e tags disponíveis ajudam a identificar personagens e temas. Não usa um serviço de IA pago nem uma busca externa adicional.

- `Elias — filme completo` passa a oferecer Elias, Antigo Testamento e formato de filme completo.
- `#Ester` passa a oferecer Ester. `Esterilização` não vira Ester.
- Público depende de indicação explícita. Desenho não é tratado automaticamente como seguro para crianças. A indicação não é classificação etária oficial.
- Livro bíblico exige indicação como nome + capítulo ou “livro de…”. Não inventamos capítulo/versículo a partir de um personagem.
- Série, temporada e episódio são extraídos de identificadores claros, como `Histórias de Elias S01E02` ou nome seguido de temporada/episódio. Informação ausente continua desconhecida.
- Coleções editoriais são preservadas. Grupos automáticos de personagens aparecem quando há ao menos dois vídeos relacionados.
- Filtros sem dados identificados ficam indisponíveis com explicação. A busca aceita várias palavras em qualquer ordem, e **Limpar filtros** remove combinações anteriores.
- Os cartões identificam a classificação automática e mostram quais campos foram inferidos. Decisões editoriais explícitas são preservadas. Indexação não altera a aprovação de um vídeo.

Os filtros se atualizam ao carregar o catálogo, inclusive nos vídeos que já estavam publicados, sem esperar nova busca no YouTube. O workflow também grava a classificação dos novos metadados. O desempenho depende do tamanho do catálogo e do aparelho.

## O que permanece para depois

Spotify, música, podcasts e lives têm cartões com o estado real **integração pendente**. As descobertas dessas APIs não foram ativadas nesta atualização. O cadastro manual continua funcionando. Não há execução genérica de SQL nem tradução automática nesta entrega.
