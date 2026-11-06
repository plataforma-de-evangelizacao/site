# Testes da v43 — 04/11/2026

Backend esperado: **2026.11.04.1**. Os ensaios locais usam dados fictícios e não consomem a API YouTube. Não foram usados tokens reais nem alterada produção.

## Verificação rápida após instalar (programas e vídeos)

Use duas abas: painel e site público. Evite usar um vídeo sem procedência legítima como teste de publicação.

| Passo | Ação | Resultado esperado |
|---|---|---|
| 1 | Entrar, abrir Tarefas administrativas | Backend 2026.11.04.1 e função compatível |
| 2 | Dar F5 dentro do painel | Mostra carregamento e volta autenticado; não pisca login nem perde sessão |
| 3 | Gestão de programas → documento compartilhado | Sete programas, 19 formações, seis softwares, nove ações |
| 4 | Expandir Educação Inteligente | Duas formações e Escola Aberta nos vínculos |
| 5 | Criar programa `TESTE — remover depois`, descrição, situação e sem link | Prévia mostra campos; link vazio não vira botão público |
| 6 | Salvar e publicar | Confirmação do servidor; recarregar site mostra o novo programa |
| 7 | Alterar descrição | Site mostra a edição após nova consulta, sem esperar Actions |
| 8 | Desativar, conferir site, restaurar | Some e volta após confirmação/recarregamento |
| 9 | Excluir o teste, abrir Excluídos e bloqueados | Registro recuperável, sem apagar os programas existentes |
| 10 | Abrir vídeo de fonte oficial, trocar título/descrição | Originais preservados; exibição usa edição |
| 11 | Registrar URL legítima e evidência; aprovar sem marcar português | Aprovação permitida, sem certificar falsamente idioma |
| 12 | Conferir catálogo público | Título editado e link externo oficial; sem player de filme público |
| 13 | Arquivar vídeo publicado | Some após consulta; filtro Arquivados o encontra |
| 14 | Restaurar vídeo | Volta quando a publicação anterior e procedência permitem; bloqueados voltam para revisão |
| 15 | Selecionar dois vídeos elegíveis para aprovar | Progresso por item e total; falhas exibem motivo e ficam selecionadas |
| 16 | F5 e voltar ao site | Nenhuma edição depende de fila antiga do Actions |

Se algum passo falhar, anote o passo e baixe o relatório de Diagnóstico e problemas. Não repita exclusões em registros de produção para investigar.

## Bateria adicional

- **Conflito:** abrir o mesmo registro em duas abas. Salvar na primeira e tentar salvar na segunda deve avisar que mudou; não sobrescrever silenciosamente.
- **Fonte pendente:** um vídeo aprovado anteriormente, mas sem procedência verificada, não deve aparecer publicamente. O registro permanece no acervo.
- **URL:** buscar um vídeo por URL normal, youtu.be, ID e título. O resultado deve apontar ao mesmo ID.
- **Miniatura e prévia:** abrir Assistir aqui no painel e fechar. Filtros continuam no painel; vídeo pode recusar incorporação por decisão do autor.
- **Lote parcial:** selecionar um item elegível e outro sem fonte. O elegível confirma sucesso, o segundo informa a falha. Não deve inventar aprovação dos dois.
- **Arquivar em lote:** Arquivar selecionados retira as fichas, preservando decisões para restauração.
- **Permissões:** superadmin convida usuário personalizado apenas com leitura de programas. Ele não deve ler vídeos nem publicar documentos por requisição direta. Não teste com sua única conta de proprietário.
- **Último superadmin:** tentar desativar o último deve ser recusado.
- **Imagem:** JPEG/PNG/WebP até 2 MB; envio é separado da publicação da ficha. Arquivo maior ou outro formato deve ser recusado.
- **Parceiros:** cadastrar relação proposta não deve anunciá-la como parceria confirmada; só confirmar participação real.
- **Histórico:** editar um documento; abrir Histórico e restauração e restaurar a versão anterior. Confirmar que o documento inteiro, não somente um cartão, foi restaurado.
- **Calendário:** comparar 4 e 5 de novembro com o PDF; são referências diferentes, três por dia. Conferir 29 de fevereiro sem três referências inventadas.
- **Integração:** Diagnóstico → executar verificação. Disparar busca YouTube uma vez, conferir etapas/contadores/link da execução; botão não deve permanecer sem explicação após falha de início.
- **Indisponíveis:** usar o filtro Indisponíveis do acervo. A disponibilidade é verificada na rotina de 15 dias; uma falha de rede não deve ser confundida com exclusão do provedor.
- **Privacidade:** relatório do diagnóstico não contém tokens, senha, Authorization nem corpo completo de requisição.

## Backup: ensaio obrigatório antes de confiar na recuperação

1. Instalar dependências na máquina; autorizar Drive e configurar cofre local.
2. `doctor`: banco/GitHub/Drive acessíveis. Site indisponível é aviso, não prova de perda do banco.
3. `backup`: pasta local íntegra + GitHub privado + Drive privado, sem ignorar avisos de Secrets não capturados.
4. Baixar uma cópia de cada destino e executar `verify` nas duas.
5. Criar Supabase de teste vazio e escolher repo de teste novo.
6. Executar restore primeiro sem `--execute`; depois executar com `--execute --test-login` conforme o guia.
7. Conferir URL de teste, login e edição de programa/vídeo pelo navegador.
8. Só depois remover os destinos de teste manualmente. A produção continua protegida pelo script.

Tempo de dump/upload/Actions depende do volume e da rede. Não se promete completar um ensaio de recuperação em dez minutos.

## Resultados locais

Os detalhes de execução estão em `docs/RESULTADOS-TESTES-V43.json`. Os testes de SQL usam PostgreSQL local via PGlite, incluindo migrações, RLS e transações reais; não substituem ensaio das APIs remotas.

Prévia isolada no navegador: sete cartões e contagem 7/7; busca Negócio retorna 1/7; Educação mostra duas formações e Escola Aberta; calendário troca as três referências ao selecionar outra data; tela de login abre com seletores de idioma/tema. A prévia foi desconectada dos serviços de produção deliberadamente. O login autenticado e toda a navegação interna exigem seu backend atualizado.

Comparação automática do plano: 365 linhas do texto extraído do PDF conferidas literalmente, 1.095 referências. Página de janeiro também inspecionada visualmente.

Não executado: apt no Ubuntu do usuário, OAuth real, e-mails/SMTP, publicação Pages real, consumo de API, dump remoto, uploads Drive/GitHub e restauração na conta. Layout responsivo implementado em CSS; não houve ensaio em aparelho físico.
