# Títulos e descrições dos vídeos — 3 de novembro de 2026

Versão do backend: **2026.11.03.4** · pacote completo de atualização v42.

## O que muda

Em **Acervo de vídeos**, cada cartão tem **Título exibido na plataforma** e **Descrição exibida na plataforma**. O título original do YouTube fica logo abaixo do campo; a descrição original pode ser expandida. O link **Conferir vídeo no YouTube** permanece com o mesmo ID. Deixar um campo vazio restaura o texto original correspondente.

**Salvar título e descrição** grava sem aprovar: o vídeo pendente continua pendente. **Aprovar** salva os dois campos e a aprovação juntos, com a categoria e a confirmação de revisão em português. Para aprovar em lote, salve primeiro as edições individuais.

Em **Publicados no site**, os vídeos ativos também têm os campos e o botão **Salvar título e descrição**. A mudança mantém a aprovação e é publicada diretamente pelo Supabase. O visitante vê o texto novo na próxima leitura do catálogo: recarregue a página pública para conferir. Não depende da rotina do GitHub para se tornar visível. A cópia no GitHub é sincronizada depois.

As próximas consultas ao YouTube preservam os textos editoriais. Os originais continuam sendo atualizados pela API separadamente, respeitando a validade dos metadados. A edição não altera o vídeo no YouTube nem o link; ela personaliza a exibição da plataforma. Os textos do catálogo são compartilhados entre os idiomas; as etiquetas do painel estão traduzidas para português, inglês e espanhol. Não há tradução automática do texto digitado.

## Como instalar

1. Faça uma cópia da pasta local do repositório. Extraia **site-atualizado-github-v42.zip** sobre ela. Inclua as pastas `.github`, `backend`, `supabase`, `scripts`, `tests` e `admin`.
2. O pacote não contém `admin/config.json`, `biblioteca-controle/config.json`, `biblioteca-controle/fontes.json` ou `biblioteca-controle/editorial.json`: mantenha seus arquivos atuais. Não substitua a pasta inteira apagando o conteúdo existente.
3. A correção de `test_auto_eligible` já está incluída. Se ainda faltarem, cadastre os Repository Secrets **SUPABASE_ACCESS_TOKEN** e **PLATFORM_DISPATCH_TOKEN**, conforme **LEIA-PRIMEIRO.md**. Não envie os valores pelo chat.
4. Faça commit e push para `main`. Aguarde **Atualizar plataforma** e **Biblioteca e GitHub Pages** ficarem verdes. Esta versão registra uma nova migração, sem alterar os arquivos das migrações antigas.
5. Se os Secrets forem cadastrados depois do push, inicie uma nova execução: **Actions → Atualizar plataforma → Run workflow → main**.
6. No painel, abra **Tarefas administrativas → Verificar instalação**: versão esperada **2026.11.03.4**, quatro migrações registradas. Depois clique em **Recarregar painel**. A instalação ocorre pelo workflow; não é necessário copiar SQL manualmente. Até instalar a nova migração, o painel informa que a edição de textos exige atualização do backend.

## Teste rápido, em ordem

1. Escolha um vídeo pendente e confira-o pelo link do YouTube. Digite um título identificável, como `Ester — filme dublado`, somente se corresponder ao conteúdo. Escreva uma descrição correta.
2. Clique em **Salvar título e descrição**. Recarregue o painel: os campos devem continuar preenchidos e o vídeo continuar pendente.
3. Escolha a categoria, confirme a revisão em português e clique em **Aprovar**. Abra o catálogo público e recarregue: confira título, descrição e o link do vídeo.
4. Em **Publicados no site**, encontre esse vídeo, altere o título e salve. Recarregue o catálogo público: deve mostrar a nova edição, mantendo o mesmo vídeo.
5. Apague só o campo de título e salve: o título original deve voltar, mantendo a descrição editada. Apague a descrição e salve para restaurá-la também.
6. Preencha novamente e salve. Execute uma atualização normal do catálogo. Ao concluir, confira que a edição foi preservada e o original continua disponível para conferência.

## Validação desta entrega

- 81 testes Python de administração.
- 65 testes Python da biblioteca, incluindo a correção independente da configuração real de aprovação e preservação dos textos durante atualização dos metadados.
- 16 verificações PostgreSQL da edição: antes/depois da aprovação, restauração dos originais, atualização na origem, conflito de versão, limites de texto, rollback e acesso anônimo negado.
- 12 verificações PostgreSQL de manutenção e 32 da publicação direta existente.
- 7 verificações de interface em ambiente simulado, incluindo o envio dos textos pelos cartões publicados; 10 de autenticação/disparo.

A execução real no GitHub, a migração na conta Supabase e a conferência visual autenticada no site dependem da instalação deste pacote. Não foram executadas nesta conversa. Os testes locais não usam sua chave YouTube nem consomem quota.
