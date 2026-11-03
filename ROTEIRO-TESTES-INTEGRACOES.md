# Testes após instalar esta atualização

**3 de novembro de 2026**. Comece por `COMECE-AQUI-INTEGRACOES.md`. Não use dados reais sensíveis nos testes. Os títulos dos testes locais não são acrescentados ao site publicado.

| Ordem | Ação | Resultado esperado |
|---|---|---|
| 1 | Entrar no painel e pressionar F5 na mesma aba | A sessão continua aberta. |
| 2 | Atualizações → Recarregar painel | Barra avança pelas cinco fontes reais e termina em 100%; não faz busca no YouTube. |
| 3 | Buscar novos vídeos no YouTube | Surge pedido recebido, depois fila do GitHub; não fica aguardando o agendamento de 15 minutos quando a função está configurada. |
| 4 | Acompanhar o cartão e abrir o link do Actions | Etapas e contadores concordam com a execução; a fila do GitHub é diferente de uma consulta à API. |
| 5 | Aguardar o término da rotina | Resultado final e dados do painel se atualizam sem F5. Se houver formulário não salvo, ele é preservado. |
| 6 | Publicados → Situação → Excluídos e bloqueados | O vídeo retirado anteriormente pode ser localizado por título disponível ou ID. |
| 7 | Restaurar para revisão | Bloqueio é removido e o item vai à revisão, sem aprovação automática. |
| 8 | Criar projeto temporário; publicar; excluir | Sai do público e aparece no filtro Lixeira — excluídos. |
| 9 | Restaurar e publicar o projeto temporário | Volta ao público após confirmação. Limpe o teste ao terminar. |
| 10 | Catálogo público → Mais filtros → Personagem | Elias/Ester aparecem quando identificados nos metadados dos vídeos publicados. Selecionar deve reduzir os resultados corretamente. |
| 11 | Combinar tema, formato e busca com várias palavras; Limpar filtros | Resultados respeitam todos os filtros; limpar retorna ao catálogo. |
| 12 | Série/temporada/episódio | Valores explícitos do título são detectados; ausentes mostram Sem dados identificados. |
| 13 | Sincronizar banco do painel e Publicar no GitHub Pages | Cada cartão acompanha sua própria execução, com erro ou confirmação final reais. |

Separadamente, deixe a aba sem interação por dez minutos: deve encerrar a sessão. Durante uso ativo, ela deve permanecer aberta e renovar o token de acesso. Consultas automáticas não renovam o prazo de inatividade.

## Diagnóstico

Se uma chamada falhar, anote a etapa, o código mostrado, o horário e o link da execução. Não envie senhas, JWTs, tokens do GitHub ou chaves secretas. Uma falha de configuração não deve aparecer como sucesso/100%. Integrações musicais e de podcasts/lives ainda sem API configurada devem mostrar integração pendente.

Itens apagados definitivamente em versões anteriores não reaparecem na lixeira; para eles, a recuperação exige uma versão anterior do conteúdo. Bloqueios de vídeos são decisões persistentes por ID, disponíveis no filtro correspondente.
