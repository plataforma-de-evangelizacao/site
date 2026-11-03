# Teste de aceitação — vídeos e projetos

**Versão:** 2026.11.02-publicacao-direta · **Data:** 2 de novembro de 2026, horário de Mato Grosso.

**Meta:** executar o roteiro em aproximadamente 8–10 minutos **depois** da instalação, migração SQL e sincronização inicial. Esse tempo é uma meta operacional, não garantia de rede ou de duração de análise de um vídeo. Escolha um vídeo que você já conferiu, em português e com disponibilidade válida.

Abra duas abas: **painel administrativo** e **site público**. Em cada teste, aguarde a confirmação do servidor no painel e então recarregue a página pública. Não execute Actions entre os passos de edição.

## Vídeos — aproximadamente 3 minutos

1. **Aprovar.** Em **Acervo de vídeos → Aguardando revisão**, anote o título de um vídeo já conferido. Selecione a categoria, marque a confirmação de português e clique **Aprovar**. Resultado: mensagem de decisão publicada; o vídeo aparece em **Publicados no site**.
2. **Conferir como visitante.** Na aba pública, abra **Filmes e desenhos**, recarregue e busque o mesmo título. Resultado: cartão presente, título correto e link do YouTube apontando para o mesmo vídeo. Não é necessário aguardar a rotina administrativa.
3. **Mudar categoria.** Na lista **Publicados no site**, escolha uma categoria diferente apenas para o teste e clique **Salvar categoria**. Recarregue o catálogo e use o filtro correspondente. Resultado: a categoria mudou. Volte à categoria correta depois.
4. **Arquivar.** Na lista de publicados, clique **Arquivar** e confirme. Recarregue o catálogo público. Resultado: o vídeo sumiu da exibição pública. No painel, procure em **Acervo de vídeos → Arquivados**.
5. **Restaurar a publicação.** No cartão arquivado, clique **Restaurar publicação**. Se ele estava aprovado e a confirmação de idioma foi preservada, volta a ser aprovado. Recarregue o site. Resultado: voltou. Se os metadados venceram ou o vídeo ficou indisponível, precisa de nova verificação e não deve ser anunciado como publicado.
6. **Excluir e bloquear.** Clique **Excluir e bloquear** e confirme. Recarregue o site: sumiu. Abra **Vídeos bloqueados**: o título/ID está registrado. Remover o bloqueio devolve um rejeitado à revisão, não o aprova automaticamente. Para deixá-lo publicado no final do teste, remova o bloqueio e aprove novamente após conferir.

**Resultado dos vídeos:** responda `Aprovou / Apareceu / Categoria mudou / Arquivou / Restaurou / Bloqueou`, indicando qualquer etapa que falhou.

## Projetos — aproximadamente 4 minutos

1. **Criar.** Use **Criar ou editar projetos → Criar novo projeto**. Exemplo de título temporário: **“Recomeçar — teste do painel”**. Preencha descrição, objetivo e público. O ID é gerado automaticamente. Deixe **Em desenvolvimento / Planejamento**.
2. **Detalhar.** Em **Roteiro de desenvolvimento**, crie um item com uma etapa de planejamento; em **Principais ações**, acrescente um ponto. Se desejar, preencha as traduções do título/descrição em English/Español. Sem tradução, o português aparece como alternativa.
3. **Publicar.** Clique **Salvar e publicar agora**. Abra **Projetos** no site, recarregue e pesquise o título. Resultado: um único cartão, descrição correta e detalhes acessíveis em **Conhecer o projeto e suas ações**.
4. **Editar e testar link.** No painel, localize o cartão, clique **Editar**, altere a descrição e inclua um link HTTPS que seja realmente seu ou um link da documentação do projeto. Publique. Recarregue a página pública e clique no acesso. Resultado: texto novo e destino correto. Ter um link torna o acesso disponível; o KPI de concluídos depende da situação/etapa de conclusão, não apenas de um link.
5. **Arquivar e restaurar.** Clique **Arquivar e publicar**, confirme e recarregue o site: sumiu. Marque **Mostrar conteúdos arquivados**, encontre o cartão e use **Restaurar e publicar**: voltou após recarregar.
6. **Excluir o teste.** Use **Excluir e publicar** apenas no projeto temporário e confirme. Recarregue: não deve aparecer mais. Os cinco projetos sociais reais da entrega devem continuar presentes.

**Resultado dos projetos:** responda `Criou / Apareceu / Editou / Link correto / Arquivou / Restaurou / Excluiu`.

## Parceiros — aproximadamente 1 minuto, se já houver um cadastro adequado

1. Abra um projeto em edição e expanda **Parceiros envolvidos**. Clique **Adicionar parceiro ao projeto** e escolha uma instituição cadastrada.
2. Informe o papel e deixe **Parceria a propor** ou **Em conversa** durante o teste, salvo se já houver uma confirmação real. Publique.
3. Recarregue o cartão público. Resultado: nome/cidade e papel aparecem em **Parcerias em construção**. Uma participação realmente confirmada aparece em **Parceiros envolvidos**.
4. Remova a vinculação de teste e publique. Remover a relação não deve apagar o cadastro do parceiro.

## Conferência final

- Recarregue o painel: alterações continuam salvas.
- Recarregue o site: conteúdos arquivados/excluídos não reaparecem.
- O histórico mostra títulos dos vídeos enquanto os metadados estiverem disponíveis.
- Nenhuma edição de vídeo/projeto precisou esperar a fila do Actions.
- A próxima descoberta deve ignorar IDs bloqueados. Esse último ponto é um teste posterior da rotina de busca; não é necessário iniciar uma busca global para verificar a retirada imediata do catálogo.

## Se algo falhar

Pare no primeiro erro e envie o nome do passo, a mensagem exibida e um print que não mostre senhas/chaves. Não marque a etapa como aprovada com base apenas em um workflow verde: o resultado público é que confirma o comportamento.

No navegador local com respostas de teste, foram verificados criação/publicação, arquivamento/restauração de projeto e aprovação/retirada de vídeo. A migração também passou por 29 verificações em PostgreSQL local via PGlite. **O fluxo real de autenticação/publicação no seu Supabase e GitHub ainda depende destes testes na sua conta.**
