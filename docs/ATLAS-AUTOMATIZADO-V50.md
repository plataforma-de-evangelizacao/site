# Atlas Solidário — histórico e atualização V50
## Implementação
Banco de produção: tabelas atlas_observations (observações e revisões), atlas_sources (catálogo), atlas_import_runs (execuções). Migração em atlas-history-v50.sql. Políticas RLS permitem somente leitura aos papéis públicos e autenticados; escrita por ambiente de gestão autorizado. A impressão digital do JSON impede duplicação idêntica. Alteração de valor ou metadados gera nova observação, preservando a anterior. Não exponha chaves privilegiadas.
Carga inicial: 22 observações, nove fontes, uma execução. Cópia estática permanece disponível se o banco falhar.
## Atualização
Agendamento mensal, dia 1 às 07h de Cuiabá, início 01/12/2026. Banco Mundial WDI, água e saneamento, Mundo e Brasil, anos desde 2015. Validação de percentuais, nulos, território e fonte; inserção sem atualizar ou apagar registros existentes. Execução ainda não homologada. Outras fontes cadastradas como manuais até integração e direitos de uso verificados.
## Administração
admin/atlas.html exibe fontes e últimas importações, em leitura. Atualização da consulta não dispara importação. Configuração e importação via ambiente autorizado, não via navegador público.
## Atlas público
Filtros por ano, território e tema; CSV e JSON; data de coleta, fonte e aviso de fallback. Percentuais não devem ser somados a contagens de pessoas. Revisões podem coexistir; comparar mesmo indicador, unidade e definição.
## Backup e recuperação
As três tabelas integram o dump PostgreSQL completo quando o schema public é incluído. Confirmar no próximo backup: pg_restore --list do dump em formato custom, ou inspeção do dump SQL, e restaurar em ambiente isolado. Conferir contagens e políticas após restauração. Não declarar restauração homologada antes do teste. A migração é versionada; não reaplicar sobre produção existente.
## Pendências
Primeira coleta automática real; séries de outras organizações, gráficos de tendência, controles administrativos autenticados para configuração e execução manual, validação do acesso público e restauração. Não publicar registros individuais ou segredos.
