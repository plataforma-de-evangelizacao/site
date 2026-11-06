# Painel administrativo — v43 · 04/11/2026

## Atualização existente

Suba os arquivos do pacote na raiz do repositório, sem apagar o restante. Preserve `admin/config.json` e os arquivos de conteúdo atuais. Configure os Secrets listados no README e acompanhe **Atualizar plataforma** e **Biblioteca e GitHub Pages**. O primeiro instala a migração 2026110401 e a função; o segundo publica HTML/JS/CSS.

Depois do sucesso, abra o painel e confira em Tarefas administrativas que o backend é `2026.11.04.1`. Se o banco ainda estiver antigo, o frontend novo não terá todas as RPCs; conclua esse workflow antes do teste de login/permissões.

## Primeira instalação

1. Crie o projeto Supabase e obtenha URL e Publishable key.
2. Crie `admin/config.json` com `supabaseUrl` e `publishableKey`, a partir do exemplo. Apenas esses valores públicos.
3. Configure os Secrets no GitHub conforme o README. Execute Atualizar plataforma para instalar o backend.
4. Crie sua primeira conta em Supabase → Authentication → Users. Autorize o UUID real em `pge_admins` e `pge_members`, como superadmin. Esta autorização inicial não pode ser concedida anonimamente pelo site.
5. Configure Authentication → URL Configuration com a URL real do site e o redirecionamento `.../site/admin/`. Configure e teste a entrega de e-mails.
6. Acesse o painel e use Usuários e permissões para os próximos convites.

Exemplo de autorização **somente do primeiro proprietário**, no SQL Editor do seu projeto:

```sql
insert into public.pge_admins(user_id) values ('UUID_REAL') on conflict do nothing;
insert into public.pge_members(user_id, role, permissions, active)
values ('UUID_REAL', 'superadmin', '{}', true)
on conflict(user_id) do update set role='superadmin', active=true;
```

Substitua UUID_REAL antes de executar. Não conceda superadmin a conta desconhecida.

## Operação diária

- Visão geral: contadores e atalhos organizados.
- Gestão de programas: abrir o documento compartilhado; expandir Programas, Formações, Softwares ou Ações. Criar/editar campos e vínculos; usar prévia; salvar e publicar.
- Publicados no site: escolher tipo e situação, buscar pelo título; vídeos também aceitam ID ou URL.
- Acervo: conferir miniatura/vídeo, ajustar título/descrição/categoria e registrar procedência. Caixa de português é opcional; fonte legítima é necessária para publicação.
- Aprovação em lote: salve as edições de fonte antes, selecione e acompanhe os itens. Falhas permanecem selecionadas.
- Excluídos/bloqueados: restaurar vídeos para revisão ou publicação quando elegível; outros objetos possuem restauração de visibilidade. Textos removidos ficam no histórico do documento.
- Conteúdos do site → Histórico e restauração: restaura o documento inteiro mediante confirmação, com controle de versão concorrente.
- Diagnóstico e problemas: executar teste e baixar relatório para compartilhar, sem abrir F12.

A interface confirma publicação após resposta do banco. Descoberta externa e cópia no GitHub são assíncronas e aparecem em Atualizações e integrações. Não repita um disparo durante falha de comunicação sem conferir sua execução.

## Limites desta entrega

As APIs de músicas/Spotify/podcasts não foram configuradas com credenciais novas. O catálogo de programas está em português e possui campos de tradução. O teste real de convite depende de SMTP. As capas iniciais são ilustrações SVG. Nenhuma conta ou segredo real foi solicitado pelo chat.
