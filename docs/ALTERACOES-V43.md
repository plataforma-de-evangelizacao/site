# Lista de alterações e limites — v43 · 04/11/2026

## Implementado no pacote

1. Vitrine de sete programas, 19 formações, seis softwares e nove ações sociais, todos inicialmente em desenvolvimento/planejamento.
2. Capas ilustrativas consistentes, pesquisa, contadores, fichas e links opcionais.
3. Vínculos de registros únicos a múltiplos programas.
4. Inventário de 67 fichas anteriores, mapa de consolidação e documentos originais preservados.
5. Gestão visual dos novos registros, descrição, detalhes, situação, ordem, datas, links, capas e traduções.
6. Relações com parceiros cadastrados, distinguindo proposta de participação confirmada.
7. Prévia dos campos e histórico/restauração de documentos.
8. Publicados no site com busca, tipo de conteúdo e situação; pesquisa de vídeos por URL/ID/título.
9. Lixeira de objetos de conteúdo; textos removidos recuperáveis pelo histórico do documento.
10. Miniaturas e janela de prévia de vídeos no painel.
11. Edição do título e descrição de vídeos antes/depois da aprovação, preservando os originais.
12. Caixa de português opcional, sem inventar certificação de idioma.
13. Aprovação e arquivamento em lote, retorno por item, barra de processamento e falhas recuperáveis.
14. Escrita direta no Supabase para decisões e documentos, com controle de conflitos.
15. Arquivar/restaurar publicação e bloquear/desbloquear para revisão.
16. IDs bloqueados/arquivados ignorados antes da consulta de detalhes; publicados não entram como novas descobertas.
17. Relevância de candidatos por evidência no título/descrição/metadados e contagem de descartes fora do escopo; limites e revisão humana continuam.
18. Filtros de temática e produção por IA, separados do formato.
19. Filmes públicos compactos, detalhes expansíveis e link para fonte legítima externa.
20. Procedência pendente/verificada, URL e evidência; fontes sem verificação não são publicadas.
21. Sessão de 20 minutos por inatividade, persistência ao F5 e estado de carregamento inicial.
22. Diagnóstico e problemas, verificações seguras e relatório sem credenciais.
23. Acompanhamento de execução, tempos/etapas reais e erro de início não confirmado, sem porcentagem fictícia de duração.
24. Cartões de integração menores e distinção entre recarregar tela, sincronizar cópia, buscar e publicar.
25. Convites, superadmin, administrador de conteúdo e permissões personalizadas, protegidas por RPC/RLS; proteção do último superadmin.
26. Calendário fixo de 365 dias × três referências conforme o PDF, com links e acesso à pasta do material.
27. Kit Python: cofre local, backup por pasta criptografada, manifesto, checksums e verificação de corrupção.
28. Kit Python: código/Git, banco público, usuários/identidades, Storage, configurações consultáveis e Secrets conhecidos localmente.
29. Kit Python: cópias Drive/GitHub privado, obtenção OAuth Drive, instalação de dependências Ubuntu e timer diário local.
30. Kit Python: restauração em destinos separados, atualização de configuração, publicação Pages, teste HTTP e teste autenticado opcional de escrita.
31. README refeito, guia administrativo, instalação, inventário e roteiro de testes; histórico anterior conservado.
32. Migração incremental versionada com checksum; migrações antigas intactas e solicitações antigas de escrita marcadas para revisão, evitando concorrer com publicação direta.

## Dependências ou limites que não foram apresentados como concluídos

- Publicação na sua conta e execução real com seus tokens: precisam do commit e dos workflows no seu GitHub.
- Backup/restauração remotos: código entregue e testes locais feitos; ensaio real é indispensável.
- Valores antigos de Secrets que não estejam no cofre: GitHub não permite exportá-los. Não são recuperáveis magicamente.
- Criação de contas/aceite de planos e projeto Supabase de teste: configuração pelo proprietário; script não contrata nem apaga bancos automaticamente.
- Descoberta em Netflix/outros streamings e comprovação automática de direitos: não implementadas como se fossem possíveis por simples scraping. Catálogo manual de fontes legítimas disponível.
- Integrações específicas Spotify/músicas/podcasts/lives: permanecem identificadas quando não configuradas. Não foram cadastradas novas credenciais ou fontes.
- Tradução automática por API: não contratada; interface em três idiomas, campos de tradução e fallback português.
- Seis softwares funcionais: fora do escopo desta atualização; foram organizadas fichas e arquitetura de referência.
- Nova cartilha/livro editorial sugerido anteriormente: não escrito sem pedido específico.
