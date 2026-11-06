# Backup e restauração PGE — Python · v43

**04/11/2026 · Ubuntu 22.04 / Python 3.10+**

Este kit executa backups locais e duas cópias privadas, verifica cada arquivo e permite restaurar a PGE em **um projeto Supabase novo e um repositório novo**. Não foi executado com suas credenciais reais nesta entrega. Primeiro ensaie; só então considere o processo validado para recuperação.

Não basta baixar um SQL e torcer. Os níveis são diferentes: integridade dos arquivos, leitura do dump, restauração do banco, publicação HTTP e teste autenticado de edição. Cada um tem seu resultado próprio.

## O que fica na pasta criptografada

| Componente | Conteúdo |
|---|---|
| Código | Arquivos HEAD do site e Git bundle com todas as branches/refs acessíveis ao token |
| Banco PGE | Schema public, funções, tabelas, políticas e dados; documentos, decisões, histórico e permissões |
| Auth | Usuários e identidades para o login por e-mail/senha usado na PGE; não copia sessões ativas nem pretende migrar todos os provedores SSO/MFA de outros sistemas |
| Storage | Buckets, objetos baixados separadamente e políticas `pge_*` |
| GitHub | Configuração consultável do repo/Pages, variables e nomes de Secrets |
| Segredos | **Somente os valores previamente cadastrados no cofre local**; a API GitHub não os devolve |
| Supabase | Configuração de Auth quando o token permite; fonte da função está no repositório |
| Integridade | Manifesto autenticado, tamanho e SHA-256 de cada arquivo |

Arquivos são cifrados com Fernet e chave derivada por PBKDF2-SHA256, com salt aleatório. Arquivos grandes são fragmentados antes da criptografia, para não ultrapassar limites dos destinos. A pasta não é ZIP. Os dumps internos usam formato PostgreSQL custom, próprio para restauração e inspeção.

A frase de recuperação **não** acompanha o backup. Se perdê-la, não há recuperação da pasta. Guarde uma cópia offline e o kit Python fora do repositório público.

## 1. Preparação no Ubuntu

Copie `scripts/backup/` para uma pasta local durável. Abra o terminal nessa pasta:

```text
python3 pge_backup.py install-deps
```

Esse comando instala Git, certificados, suporte a venv e cliente PostgreSQL 17 pelo repositório oficial PGDG, além de criar `~/.pge-recovery-venv` com cryptography e PyNaCl. Usa sudo e `apt-get update`, **não executa upgrade geral** e não instala servidor PostgreSQL. Validado por inspeção para Ubuntu 22.04/24.04; a instalação apt não foi executada no seu computador durante esta entrega.

Nos próximos comandos use o Python desse ambiente:

```text
~/.pge-recovery-venv/bin/python pge_backup.py --help
```

No Windows o código usa Python e caminhos portáveis; Git e o cliente PostgreSQL precisam ser instalados pelo procedimento do Windows. Agendamento systemd é exclusivo de Linux. Não foi ensaiado em Windows nesta entrega.

`pg_dump` precisa ser igual ou mais novo que o servidor e a restauração deve ser em versão compatível. Se seu Supabase estiver no PostgreSQL 18, instale `postgresql-client-18` pelo mesmo repositório PGDG e confira `pg_dump --version`. Não use transaction pooler para dump; use conexão direta ou session pooler, conforme conectividade IPv4/IPv6 disponível.

## 2. Autorizar Google Drive sem copiar tokens pelo chat

No Google Cloud da sua conta:

1. Crie/escolha um projeto e habilite **Google Drive API**.
2. Configure a tela de consentimento OAuth com sua conta autorizada para teste.
3. Crie um OAuth Client ID do tipo **Aplicativo para computador** e baixe o JSON. Esse arquivo fica somente no computador.
4. Execute:

```text
~/.pge-recovery-venv/bin/python pge_backup.py authorize-drive --client-json /caminho/cliente-google.json
```

O navegador local abre o consentimento Google. O retorno usa 127.0.0.1, valida state e PKCE, salva o refresh token criptografado e cria uma pasta privada **PGE Backups Privados**. Escopo `drive.file`: arquivos criados ou autorizados para esse aplicativo, sem acesso geral ao Drive. Não use a pasta pública do estudo bíblico como destino de backups.

Use uma frase longa, com ao menos 16 caracteres, e repita a mesma frase no próximo configure. O arquivo padrão é `~/.config/pge-recovery/google.enc`. Um OAuth configurado em modo Testing pode ter renovação limitada; revise a configuração do seu aplicativo antes de depender de execução diária. Se consentimento for revogado ou token expirar, o script informa falha de destino e mantém o backup local.

## 3. Configurar o cofre local

```text
~/.pge-recovery-venv/bin/python pge_backup.py configure
```

O script pede localmente, sem exibir valores sensíveis:

- Repositório do site e URL pública existentes.
- Repositório privado de backup, por padrão `plataforma-de-evangelizacao/backup`.
- Token GitHub de backup/recuperação com permissões para os repositórios envolvidos. Criação de repositórios/Pages, código/workflows, Actions, variables e Secrets precisam estar autorizados; um token restrito ao site antigo pode não alcançar um repositório novo.
- Connection string PostgreSQL Supabase, URL, service_role e chave pública.
- Configuração Drive, aproveitada automaticamente do `google.enc` quando presente.
- Cópias locais de `SUPABASE_ACCESS_TOKEN`, `PLATFORM_DISPATCH_TOKEN`, `YOUTUBE_API_KEY`.

O arquivo `credentials.enc` é cifrado. Em Linux, permissões 600. Não coloque esse arquivo, frase, connection string ou JSON de teste no repositório público.

O token `SUPABASE_ACCESS_TOKEN` precisa alcançar também o **projeto de recuperação**, para função/segredos e configuração Auth. Tokens restritos a um projeto não criam acesso em outro. Contas/plano e eventual cobrança de um novo projeto são decisões feitas por você no provedor; o script não cria contas nem contrata planos.

Se você tem outros Secrets, inclua-os no dicionário `github_secrets` da configuração antes de cifrar, por uma ferramenta local segura. O backup informa nomes sem valor capturado. Nenhuma API consegue recuperar depois os valores de Secrets só a partir do nome.

## 4. Testar conexões e fazer backup

```text
~/.pge-recovery-venv/bin/python pge_backup.py doctor
~/.pge-recovery-venv/bin/python pge_backup.py backup
```

`doctor` confere executáveis, repositórios, banco e acesso à pasta Drive. O repo de backup é criado privado se não existir; um destino público é recusado. Site fora do ar gera aviso e não impede salvar código/banco.

`backup` cria `~/PGE-Backups/pge-DATA-HORA`, valida a descriptografia e a leitura do dump, envia a mesma pasta ao Drive e para uma subpasta datada no GitHub privado. Cada execução mantém seu snapshot. O código do site não é publicado pelo comando de backup.

- `[OK]`: etapa confirmada.
- `[WARNING]` ou `[NOT_BACKED_UP]`: cobertura parcial/configuração que exige atenção.
- `[FAILED]`: operação ou destino falhou; retorno de processo 1.
- Saída 0 de backup com avisos não significa que Secrets ausentes foram capturados. Leia o relatório.

O relatório seguro `pge-recovery-report.json` não contém valores de credenciais. Falhas HTTP indicam provedor/status, sem expor respostas brutas. Falha de ferramenta nativa informa programa/código; confira versão e conexão. Interrompa antes de modificar destinos se uma validação falhar.

A cópia dupla não é uma transação entre provedores: se um upload falhar, o outro e o backup local são preservados, e o comando termina com falha parcial. Não apague a pasta local até resolver.

Para verificar novamente uma pasta:

```text
~/.pge-recovery-venv/bin/python pge_backup.py verify /caminho/pge-DATA-HORA
```

## 5. Rotina diária

Depois de validar uma execução real:

```text
~/.pge-recovery-venv/bin/python pge_backup.py schedule --hour 20
systemctl --user list-timers pge-backup.timer
journalctl --user -u pge-backup.service
```

Horário local do computador, uma execução por dia. O timer é persistente: se o horário passou, pode executar ao iniciar a sessão seguinte. O computador precisa estar ligado e com rede; para rodar sem sessão, configure o serviço de usuário/linger ou use um servidor que fique ligado, conforme sua administração Linux.

O agendamento grava uma chave/frase em `~/.config/pge-recovery/schedule.env` com modo 600 para permitir execução sem digitação. **Não envie esse arquivo para Drive/GitHub**. Essa conveniência não protege contra comprometimento da própria máquina. Se não quiser chave em disco, execute backup manualmente com getpass.

Para parar: `systemctl --user disable --now pge-backup.timer`.

## 6. Buscar cópia remota

Mantenha o kit e uma cópia do cofre de conexão em local seguro fora da conta principal. Sem credenciais de acesso ao Drive/GitHub não se pode baixar um backup privado automaticamente.

```text
~/.pge-recovery-venv/bin/python pge_backup.py fetch --github --output /caminho/copias
~/.pge-recovery-venv/bin/python pge_backup.py fetch --drive-folder ID_DA_PASTA_DO_SNAPSHOT --output /caminho/pge-recuperar
```

No GitHub, o resultado contém as subpastas datadas; escolha uma delas para verify/restore. No Drive, informe o ID da pasta **do snapshot**, não da pasta que contém todos os backups. Também é possível usar uma pasta já copiada localmente; não há dependência de download remoto na verificação.

## 7. Ensaio de restauração, sem tocar na produção

Crie manualmente um **novo projeto Supabase vazio**, de versão PostgreSQL compatível. O schema public deve estar vazio; o script recusa substituir um banco já preenchido. Não use o projeto original.

Prepare localmente um JSON, protegido, chamado por exemplo `destino-teste.json`:

```json
{
  "supabase_url": "https://REFERENCIA_DO_TESTE.supabase.co",
  "supabase_service_role_key": "PREENCHER_SOMENTE_LOCALMENTE",
  "supabase_publishable_key": "PREENCHER_SOMENTE_LOCALMENTE"
}
```

Em Linux: `chmod 600 destino-teste.json`. Não publique esse arquivo.

Primeiro, apenas conferir o backup:

```text
~/.pge-recovery-venv/bin/python pge_backup.py restore /caminho/pge-DATA-HORA --target-repo SEU_OWNER/site-recuperacao-teste
```

Sem `--execute`, nada é enviado aos serviços. Depois:

```text
~/.pge-recovery-venv/bin/python pge_backup.py restore /caminho/pge-DATA-HORA --target-repo SEU_OWNER/site-recuperacao-teste --target-supabase-config /caminho/destino-teste.json --execute --test-login
```

O terminal pede a conexão PostgreSQL do **teste** e o e-mail/senha do usuário que será restaurado. Não são argumentos visíveis na linha de comando. Como alternativa para automação, existem `PGE_RESTORE_DATABASE_URL`, `PGE_TEST_EMAIL` e `PGE_TEST_PASSWORD` no ambiente local.

O comando:

1. Confere integridade de todos os arquivos e leitura do dump.
2. Protege nomes de produção, confere correspondência entre conexão PostgreSQL e referência Supabase de teste e testa acesso de gestão antes da escrita.
3. Restaura usuários/identidades, public e buckets; envia os arquivos Storage separadamente.
4. Reaplica políticas Storage PGE e atualiza URLs de capas nos documentos para o novo Supabase.
5. Cria/prepara o repo de teste; atualiza referências ao repo/URL e a configuração pública; não envia cofres/dumps para esse repo.
6. Publica a função, segredos conhecidos e Auth com URLs do teste. SMTP depende da configuração recuperada e das permissões do provedor.
7. Recria main e biblioteca-estado a partir do backup. Outras branches continuam disponíveis no bundle para recuperação manual.
8. Configura Pages e solicita publicação. Aguarda até 15 minutos, consultando HTTPS a cada dez segundos.
9. Valida página inicial, formulário administrativo e RPC pública.
10. Com `--test-login`, valida autenticação, perfil e uma escrita do mesmo conteúdo no documento de programas. Esse teste não modifica publicamente um título e não substitui conferir a interface no navegador.

Se não fornecer usuário para o teste, a saída registra **NOT_TESTED**, não afirma que o login/edição funcionaram. Um HTTP 200 isolado nunca é chamado de teste completo.

O processo não altera DNS/domínio próprio e remove CNAME apenas da cópia de teste. O teste usa a URL GitHub Pages do novo repo, não Google Sites. Chaves novas do projeto substituem as antigas na configuração.

O ambiente de teste fica preservado. Depois de conferir manualmente, apague **somente os destinos de teste**, pelos provedores. Não há limpeza destrutiva automática nem exclusão do banco original. Se uma etapa falhar, o relatório indica o último ponto; não repita sobre um banco parcialmente restaurado — use outro projeto vazio ou investigue antes.

## Limites e recuperação real

- Não é uma clonagem da conta Supabase inteira nem exportação de todas as senhas existentes em SaaS. Cobertura é o site PGE e seu login atual por e-mail.
- SMTP, domínios, OAuth de outros provedores, billing, configurações organizacionais e segredos não capturados podem precisar de reconfiguração.
- O kit protege a produção contra sobrescrita; numa perda real, restaure em destino novo e só depois migre o endereço/divulgação.
- Se perder contas e tokens, crie novas contas/autorização e adapte a configuração. A pasta local pode recuperar os dados, mas não concede acesso às contas antigas.
- Nenhum ensaio ao vivo em suas contas foi executado nesta entrega. Os testes locais cobrem criptografia, corrupção, proteção de destinos e permissões básicas de API simuladas. Instalação apt, OAuth, dump remoto, uploads, publicação e restauração real são os próximos testes na sua máquina.

Referências: [Backups Supabase](https://supabase.com/docs/guides/platform/backups), [GitHub Secrets](https://docs.github.com/en/rest/actions/secrets), [cliente PostgreSQL Ubuntu](https://www.postgresql.org/download/linux/ubuntu/), [upload Drive](https://developers.google.com/workspace/drive/api/guides/manage-uploads).
