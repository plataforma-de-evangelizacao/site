# Testes da atualização automática

**3 de novembro de 2026**

Após cadastrar os dois Secrets e enviar o pacote:

1. **Primeira preparação:** em Actions, confira `Atualizar plataforma`. Deve terminar verde. Se estiver vermelho, abra o passo que falhou. Códigos 401/403 apontam credencial/permissão; a mensagem não deve expor o token.
2. **Diagnóstico:** entre no painel → Tarefas administrativas → Verificar instalação. Deve mostrar pacote `2026.11.03.3`, versão instalada igual e zero migrações pendentes.
3. **Repetir:** clique Atualizar plataforma e confirme. Acompanhe etapas e link da execução. Ao terminar, continua sem migrações pendentes. Os projetos e vídeos existentes permanecem.
4. **Permissões:** sair do painel impede o disparo. Uma conta sem associação em `pge_admins` não pode consultar o diagnóstico privado nem executar a atualização.
5. **Busca:** em Atualizações e integrações, dispare novos vídeos. Diferencie a fila do GitHub das consultas ao YouTube. Quando houver respostas medidas, confira os tempos da última resposta e da média. Eles não devem avançar por uma animação.
6. **Vídeos:** aprove um material conferido; verifique o catálogo público; arquive e restaure; exclua e localize em Excluídos e bloqueados. Um bloqueado restaurado retorna à revisão.
7. **Projetos:** crie um projeto temporário, publique, envie à lixeira e restaure. Recarregue a página pública após cada confirmação. Não execute Actions entre as edições de conteúdo.
8. **Sessão:** pressione F5 durante uso normal: deve continuar autenticado. Dez minutos sem atividade devem encerrar a sessão; consultas automáticas não contam como atividade.

Em caso de falha, envie somente o código, a etapa e o link da execução. Não envie tokens, JWTs, senhas ou chaves secretas. A fila do GitHub e a velocidade da API não têm prazo de início/conclusão garantido.
