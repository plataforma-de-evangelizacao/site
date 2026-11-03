> Esta versão inclui a edição de títulos e descrições. Siga também **ATUALIZACAO-TITULOS-VIDEOS.md** para o teste dos cartões.

# Nova versão — atualização automática do backend

**3 de novembro de 2026 · versão 2026.11.03.4**

Esta é a atualização para o painel que você já usa. Substitui a instalação manual das integrações descrita nos guias anteriores. Inclui as melhorias de vídeos, projetos, lixeira, sessão, integrações e filtros.

## Uma única preparação

No GitHub do repositório `plataforma-de-evangelizacao/site`, abra **Settings → Secrets and variables → Actions → New repository secret**. Acrescente:

| Nome exato | O que cadastrar |
|---|---|
| `SUPABASE_ACCESS_TOKEN` | Token de integração da sua conta Supabase, limitado ao projeto da plataforma. Permissões: `database_migrations_write`, `edge_functions_write` e `edge_functions_secrets_write`. |
| `PLATFORM_DISPATCH_TOKEN` | Token fine-grained do GitHub, limitado ao repositório `site`, com **Actions: Read and write**. Se a organização exigir aprovação, aprove o token. |

Crie o token Supabase em **Account → Access tokens**: https://supabase.com/dashboard/account/tokens . Prefira um token com escopo limitado ao projeto, e não um token legado com acesso à conta inteira.

Esses tokens são segredos de servidor: não envie pelo chat, não coloque em arquivos e não cole no painel do site. Os Secrets `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` e `YOUTUBE_API_KEY` que você já cadastrou continuam como estão. O token de gestão fica apenas no GitHub; não é copiado para o navegador ou para a função pública.

## Subir esta versão

1. Cadastre os dois Secrets acima.
2. Extraia `site-atualizado-github-v42.zip` na pasta local do repositório, substitua os arquivos correspondentes e envie para `main`. Inclua as pastas `.github`, `backend` e `supabase`.
3. Aguarde **Atualizar plataforma** e a publicação do Pages ficarem verdes. O workflow prepara o banco, registra as migrações, configura o disparo e publica a função automaticamente. **Não precisa abrir o SQL Editor nem copiar o código de uma Edge Function.**
4. Entre no painel → **Tarefas administrativas → Verificar instalação**. A versão instalada esperada é **2026.11.03.4**. Depois, use **Atualizar plataforma** sempre que precisar aplicar/verificar o backend.

O pacote preserva `admin/config.json`, as fontes, o orçamento da busca e as decisões editoriais existentes. Não precisa trocar a senha de login ou cadastrar novamente seu usuário.

Se você cadastrar os Secrets depois de subir os arquivos, abra **Actions → Atualizar plataforma → Run workflow → main** uma vez. Essa primeira execução instala a ponte que permitirá disparar as próximas pelo site. O painel oferece links para essa preparação inicial.

## Nas próximas atualizações

Você envia os arquivos novos. Quando o pacote incluir uma nova versão do backend, o GitHub dispara a atualização automaticamente. Também pode usar **Tarefas administrativas → Atualizar plataforma**. As migrações já registradas são conferidas e ignoradas; apenas as novas são aplicadas. Se um arquivo de migração antiga tiver sido alterado, o processo interrompe com conflito de checksum, em vez de reaplicá-lo silenciosamente.

O painel mostra: pedido recebido, fila do GitHub, validação do pacote, atualização do banco, publicação das funções, verificação da integração e conclusão. A versão só aparece como instalada depois da confirmação do banco e da resposta da função publicada.

Se o banco for atualizado mas a publicação da função falhar, o painel mostra erro. Corrija a credencial/permissão indicada e use o mesmo botão novamente: as migrações já concluídas não precisam ser executadas de novo. Não há rollback automático de conteúdo. Os arquivos desta entrega preservam os dados existentes; novas migrações futuras devem manter essa compatibilidade.

## Tempos e buscas

A busca mostra etapas reais: GitHub consultando YouTube, aguardando resposta, resposta recebida, classificação e publicação. O tempo médio e o tempo da última resposta são medidos. O timeout de rede de 25 segundos por tentativa não é uma previsão do tempo total. Paginação, tentativas, limites e a fila do GitHub continuam variáveis; o painel não inventa uma contagem regressiva.

## Quando será necessária nova intervenção

Não será preciso executar SQL ou publicar funções manualmente a cada versão. Credenciais que expirarem ou forem revogadas precisam ser renovadas nos Secrets; nenhuma integração consegue renovar sozinha uma autorização revogada. Novos provedores, como Spotify, ainda precisarão da própria autorização inicial quando forem implementados.

Consulte `TESTE-RAPIDO-ATUALIZACAO.md` para conferir a instalação e `RELATORIO-VALIDACAO.md` para distinguir o que foi testado localmente do que ainda deve ser validado na sua conta.
