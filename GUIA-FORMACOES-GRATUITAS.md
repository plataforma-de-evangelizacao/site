> **v43 — 04/11/2026:** consulte primeiro `COMECE-AQUI-V43.md` e `README.md`. O texto abaixo conserva instruções e inventário de versões anteriores; a organização e política atuais estão no novo manual.

# Cursos, palestras e materiais gratuitos

Esta é uma decisão editorial de Marcos Lucas Pereira para a Plataforma Global de Evangelização. Deve acompanhar a criação e revisão dos cursos, palestras, slides, roteiros e materiais associados ao projeto.

## Regra permanente do projeto

- Os cursos e palestras oferecidos pelo projeto serão gratuitos.
- Ao final de cada curso e palestra, incluir um convite à doação voluntária para manter o projeto, suas ferramentas, materiais e ações de cuidado.
- A doação não é condição de participação, acesso ao material ou acolhimento. O convite deve ser claro e respeitoso.
- Nas apresentações, preparar um último slide com o convite e o caminho de apoio da plataforma. Em vídeos e roteiros, prever o mesmo encerramento.
- Não apresentar cursos, palestras, ferramentas ou parcerias como concluídos enquanto ainda forem propostas.

## Modelo de encerramento

“Este encontro é gratuito. Se você desejar e puder, contribua voluntariamente com a Plataforma Global de Evangelização para manter os materiais, ferramentas e ações de cuidado. Sua participação é bem-vinda com ou sem doação.”

O caminho de apoio é a página **Ajudar o próximo**, com as opções de contribuição. A configuração editorial e as versões correspondentes em português, inglês e espanhol ficam em `dados/formacoes.json`. Esse arquivo é uma referência para produzir materiais; ele não dispara mensagens ou cobranças.

## Organização atual das propostas

| Frente | Formações em planejamento |
|---|---|
| Crianças e adolescentes em acolhimento | 5 cursos |
| Casas de apoio e suas equipes | 5 cursos |
| Centros de idosos | 5 cursos |
| Formação comunitária | 5 cursos |
| Escolas, professores e alunos | 10 palestras |
| Servidores públicos e gestão municipal | 10 palestras |
| Campo, fazendas e cooperativas | 5 cursos |

Total: **45 formações propostas — 25 cursos e 20 palestras**. A página de projetos apresenta ainda 13 ferramentas/propostas editoriais, totalizando **58 cartões**. As categorias ficam abertas; busca e filtro de categoria ajudam a localizar os itens.

## Onde atualizar

O catálogo é `dados/projetos.json`.

- As quatro primeiras frentes usam `cursos_propostos` dentro do registro da frente.
- As frentes de escolas, serviço público e campo usam `formacoes_propostas`.
- Cada formação possui `id`, `tipo` (`curso` ou `palestra`), `titulo`, `descricao`, `objetivo`, `publico`, `conteudos`, `materiais`, `status`, `etapa`, `gratuito`, `link`, `documentacao` e `traducoes`.
- Preserve os IDs e mantenha `gratuito: true`. Os registros atuais estão com `status: em-desenvolvimento`, `etapa: planejamento` e links vazios.
- `conteudos` contém uma proposta inicial de módulos/assuntos. `materiais` indica o que ainda será produzido, incluindo o encerramento com doação voluntária.
- Ao preparar slides e exercícios, refine o público, a sequência, o formato e a duração com a instituição. Não há datas ou cargas horárias confirmadas por padrão.
- Preencha `link` e `documentacao` somente quando houver material real. O site oferece o acesso quando existe um destino HTTPS válido e mantém itens pausados sem acesso ativo.
- Ao publicar um curso, revise também as frases dos materiais que ainda dizem “a produzir”. A interface muda o estado pelo catálogo, mas não reescreve esses textos autorais por conta própria.
- Atualize os textos correspondentes em `traducoes.en` e `traducoes.es`; a tradução da interface não traduz o vídeo ou os slides automaticamente.

Depois de editar, execute `python3 scripts/validar_site.py` e publique o arquivo pelo GitHub. Não é necessário alterar o HTML para cadastrar uma formação dentro dessas frentes.

## Diretrizes para os materiais

- Crianças: atividades mediadas por educadores e adequadas à faixa etária; não exigir contas pessoais das crianças para acompanhar demonstrações. Escolher ferramentas e condições de uso durante o planejamento com a equipe.
- Educadores: manter objetivos pedagógicos, revisão de conteúdo e participação dos alunos no centro da proposta.
- Servidores públicos: usar exemplos e dados fictícios nas demonstrações; deixar decisões e revisão institucional com os responsáveis. Um protótipo não equivale a um sistema autorizado para uso público.
- Campo: distinguir organização e apoio por dados de recomendações técnicas especializadas. A implantação de ferramentas precisa de testes e validação com produtores e equipes técnicas.
- Pessoas idosas e casas de apoio: respeitar acessibilidade, interesses, ritmo de aprendizagem e limites dos participantes; não prometer efeitos clínicos ou terapêuticos.
- Instituições religiosas: combinar o conteúdo com cada comunidade, respeitando sua organização e doutrina.

## Continuidade da escrita

Leia este guia ao retomar um curso ou palestra. Ele está incluído no ZIP e referenciado em `AGENTS.md` e no README. Se o trabalho continuar em outro chat sem acesso ao repositório, anexe ou informe este guia para preservar a orientação de gratuidade e encerramento com doação voluntária.
