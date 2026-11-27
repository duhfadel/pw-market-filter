# Painel NewAge — subsistema **Jogadores** (iteração 2)

> Desenho aprovado em 27/11/2026, por mockup e conversa. Mockup de referência:
> o artefato publicado nesta sessão (menu, lista, detalhe, adicionar/editar).

## Contexto e o que já existe (não refazer)

O painel privado `/newageguild` já está no ar (ver
`2026-11-26-registro-de-jogadores-design.md`). Já construído e publicado:

- **Auth + papéis** — Supabase Auth, `perfis(papel)`, `GuildViewModel` resolve
  Deslogado / Logado / SemAcesso; `Papel` = admin, staff_editor, staff_basico,
  sala_guerras, com `podeEditarJogadores` e `podeVerJogadores`.
- **Lista básica** — `RosterView` + `RosterViewModel`, com cadastro por
  formulário (nome + anexar print, ou digitar) e o jogador nasce `pendente`.
- **Upload do print** — para o bucket privado `prints` (máx. 512 KB).
- **A porta de transcrição no Worker** — `portalpw-cron.duhpicheth.workers.dev`,
  `/transcricao/pendentes` (lista + link assinado) e `/transcricao/apagar` (por
  id de jogador, objeto a objeto), trancada por `TRANSCRICAO_TOKEN`. A
  `service_role` nunca sai do Worker.
- **A primeira transcrição real** — o `mozaum` foi lido do print e gravado, e a
  imagem descartada, provando o fluxo ponta a ponta.

Esta iteração **evolui o subsistema Jogadores** sobre essa base. Não toca em
Sala de Guerras nem Financeiro — ver *Fora de escopo*.

## O menu (`/newageguild` vira um hub)

Hoje `/newageguild` abre direto na lista. Passa a ser um **menu** com botões,
um por subsistema:

- **Jogadores** — leva à lista (este spec).
- **Sala de Guerras** — *em breve* (subsistema próprio).
- **Financeiro** — *em breve* (subsistema próprio).

Os botões são **gated pelo papel**, com a mesma regra que o portão já usa:
`sala_guerras` só vê *Sala de Guerras*; staff e admin veem *Jogadores*. Um
botão *em breve* desenha esmaecido e não navega — a mesma honestidade do menu
de ferramentas do site (uma promessa ausente seria pior que uma marcada *em
breve*). O topo mostra o login, o papel e *sair*.

`RosterView` deixa de ser o que a rota `Tela.guild` desenha; passa a ser
alcançada de dentro do menu (navegação interna do `MaterialApp`, nunca um
`Navigator` aninhado — a regra de roteamento do site).

## Modelo de dados — duas tabelas

O princípio que decide tudo: **guardar cada transcrição como uma foto dos
números, não sobrescrever.** A imagem é lida e **descartada**; o que fica é o
retrato de atributos empilhado no tempo. Isso serve os três objetivos do dono
com um mecanismo só — *atualizar*, *ver o delta* e *ver a evolução*.

### `jogadores` (identidade + estado atual)

Já existe; ganha campos. Guarda quem é o personagem e o retrato da ficha **mais
recente** (desnormalizado, para a lista não precisar tocar em `fichas`):

- identidade: `id`, `nome`, `cla`, `classe`, `cultivo`, `limite`, `nivel`, …
- os ~25 atributos atuais (os que hoje já tem) — **a foto mais recente**.
- `status` — `pendente` | `transcrito` | `revisar` (novo valor).
- `nota` — texto curto (novo): o motivo quando `revisar` (*"print cortado,
  faltou HP"*). Nulo quando não há.
- `print_url` — o print pendente de leitura; nulo depois de lido/descartado.
- **atribuição**: `criado_por` (já tem, `default auth.uid()`),
  `atualizado_por` (novo, uid do staff da última foto) e `atualizado_em`
  (novo, data da última foto). A data **vive aqui também**, a pedido do dono,
  para a lista mostrar *"atualizado há 3 dias"* sem ir à `fichas`.

### `fichas` (histórico — uma linha por transcrição)

Nova tabela. Cada atualização bem-sucedida grava uma linha:

- `id`, `jogador_id` (FK), `criada_em`, `criado_por` (uid do staff).
- `dados` — os ~25 atributos daquele momento (JSONB, ou colunas espelhando
  `jogadores`; ver *Decisão adiada*).
- `runas` — a lista de runas daquele momento (ver *Runas*).

A ficha "atual" é simplesmente a `fichas` mais recente de cada jogador; o
`jogadores` carrega uma cópia dela para leitura barata. O **delta** do detalhe
sai de comparar as duas `fichas` mais recentes. A **evolução** ao longo do
tempo é a série inteira (dá uma linha "396 → 428 → 460" quando o dono quiser).

**RLS**: `fichas` herda a regra de `jogadores` — leitura para staff
autenticado, escrita fechada à chave publicável (quem escreve é o Worker com a
`service_role`, ou o app autenticado se a política permitir). Sem política
para o anônimo.

## A lista (tabela no largo, cartão no estreito)

- **Responsiva**, como a tabela dos Instâncias: no largo é uma tabela com
  colunas (Jogador, Limite, Nível de Ataque, HP, Nv. Defesa, Crítico, Status,
  Atualizado); no estreito vira um cartão por jogador e as colunas secundárias
  recolhem, com o nível de ataque ganhando a legenda.
- **Ícone real da classe** (`ClassIcon`, de `occu_<ocupação>.png`) no lugar de
  qualquer desenho — a ocupação vem de `ocupacoes.dart`.
- **Busca por nome** e **filtro por classe** (chips das classes presentes). Um
  **filtro de status** (pendente / revisar) entra junto — serve o "controle de
  quem subiu ficha".
- **Ordenar clicando na coluna** (Nível de Ataque, HP, Nv. Defesa, Crítico,
  …), decrescente; pendentes/revisar sem número caem para o fim.
- **Status em chip** (transcrito / pendente / revisar) e, no `revisar`, a nota
  na própria linha.
- O número que manda é o **Nível de Ataque**, em destaque — nunca uma sigla
  (`NA` foi rejeitado por não dizer nada).

A busca/filtro/ordenação é a semente do uso de **Sala de Guerras** (filtrar
pelos mais fortes); a lista já nasce preparada, mas a comparação-para-TW em si
é do outro subsistema.

## O detalhe (toca num jogador)

- Cabeçalho: ícone da classe, nome, classe · clã · nível · despertares.
- **Quem/quando atualizou** (email do staff + data), com a porta de **editar**.
- **Evolução / delta**: uma faixa *"desde a última imagem (DD/MM)"* no topo e,
  em cada atributo, o **↑/↓** contra a foto anterior (verde subiu, vermelho
  desceu, — igual). Sem foto anterior, não desenha delta (um primeiro registro
  não tem com o que comparar — a honestidade de não afirmar o que não se sabe).
- **Atributos agrupados** (Ataque / Defesa / Outros). *Quais campos aparecem
  fica a definir com o dono* — ver *Decisão adiada*.
- **Runas**: a grade dos ícones + um resumo (*"Maior nível 10 · 3 nv10 · 5
  nv9…"*).

## Adicionar / editar

- **Adicionar e editar são o mesmo gesto**: nome do personagem + anexar print.
  Editar um existente é subir uma **imagem nova**, que gera uma **foto nova** no
  histórico e atualiza o `jogadores`.
- **Correção à mão**: dá para editar um número quando a leitura erra — gera uma
  foto corrigida (ou corrige a foto mais recente; ver *Decisão adiada*),
  marcada como edição manual na atribuição.
- O print continua **lido e descartado**; o limite de 512 KB pode subir, já que
  a imagem é temporária.

## A transcrição (quem lê o print)

A leitura da ficha é feita por mim (o assistente), não por IA no servidor (isso
exigiria a API paga, recusada pelo dono). Dois gatilhos, mesmo mecanismo:

- **Sob demanda** — o dono diz *"lê os pendentes"*; eu puxo a porta do Worker,
  leio cada print pelo link assinado, gravo a foto, marco `transcrito` (ou
  `revisar`), e mando **apagar** a imagem.
- **Agendado (a cada 6h)** — um `CronCreate` dispara a transcrição
  periodicamente **enquanto a sessão viver**. É explicitamente *não durável*:
  morre ao fechar a sessão e expira em 7 dias; é uma conveniência, não um job de
  servidor. O durável-de-verdade seria a API paga, parada por decisão do dono.

Para o gatilho agendado funcionar sem depender de ferramentas que podem faltar
num disparo de fundo, a escrita dos dados deve poder ir **pelo Worker**
(`service_role`), não só pelo MCP. Ganha um endpoint `POST /transcricao/salvar`
(`{id, dados, runas, status, nota}`) que valida os campos contra uma lista
branca de colunas, grava a foto em `fichas`, atualiza `jogadores`, e — quando
`transcrito` — apaga o print. É a extensão natural da porta já no ar.

## As runas

- **Capturadas** do print: cada runa tem **família** (cor) e **nível** (forma),
  lidas pela régua que o dono ensinou (losango = 10; o resto distingue-se pelo
  símbolo do centro: 9, 8, 7…). A régua está na memória do projeto.
- **Guardadas** em cada foto (`fichas.runas`) — uma lista de `{família,
  nível}` — então entram no histórico (dá para ver *"subiu uma runa para nv10"*).
- **Mostradas** no detalhe: a grade dos ~24 ícones (reusando os ícones de runa
  que o site já tem — 10, 9, 8…), com moldura destacada no topo, mais o resumo
  por nível e o *Maior nível*.
- A leitura de runa por imagem é frágil; é a parte que mais pede o `revisar`
  quando a arte estiver ambígua.

## "Revisar" + nota, e as regras de honestidade

A regra que atravessa tudo: **nunca afirmar um dado que não se leu.**

- Um print ilegível ou incompleto **não vira `transcrito`**: fica `revisar`,
  com a `nota` dizendo o quê (*"print cortado, faltou HP e defesas"*).
- Um atributo que não se consegue ler **fica vazio** (nunca um zero inventado —
  a mesma regra do índice do mercado).
- Em dois níveis: na conversa (eu digo o que li, o que faltou, o que falhou) e
  **no jogador** (o chip `revisar` + a nota, que o staff vê na lista).
- O staff reenvia um print melhor → nova foto → sai do `revisar`.

## Atribuição (quem atualizou)

Cada foto carrega o `criado_por` (uid do staff). O `jogadores` espelha o da
foto mais recente em `atualizado_por`/`atualizado_em`, e a tela mostra o email
(ou um nome de exibição, se um dia as contas ganharem um). A lista mostra
*"atualizado há Xd · <staff>"*; o detalhe, *"atualizado em DD/MM por <email>"*.

## Segurança

- `jogadores` e `fichas`: leitura para staff autenticado, escrita fechada ao
  anônimo (sem política para a chave publicável). Provado por curl, como as
  outras tabelas.
- A porta do Worker: tudo que não é `/transcricao/*` responde 404; sem o token,
  401. O `salvar` valida colunas contra lista branca (nada de escrever coluna
  arbitrária) e o `apagar` é por id, objeto a objeto (nunca por prefixo).
- A `service_role` vive só no Worker; o `TRANSCRICAO_TOKEN` é dedicado e
  rotacionável, e não é a chave de serviço.
- Imagens são descartadas após a leitura — nada de ficha sensível acumulando.

## Testes

- **Modelo**: o round-trip de `jogadores` e `fichas` (snake_case, campos
  opcionais omitidos, `status`/`nota`), como `collected_page_test` faz para o
  índice — um codec sem teste é onde um campo morre.
- **Delta**: comparar duas fotos dá os ↑/↓/— certos, incluindo "sem foto
  anterior → sem delta".
- **Papel**: `sala_guerras` não alcança a lista pelo menu (espelha o portão).
- **Ordenação/filtro**: ordenar por coluna põe os sem-número no fim; filtrar
  por classe/status corta certo.
- **Worker**: o `salvar` recusa coluna fora da lista branca; o `apagar` por id
  inexistente não apaga nada.
- A UI ganha testes onde valem a pena, sem meta de cobertura (a regra do
  projeto).

## Decisões adiadas (de propósito, não pendências)

- **Quais campos aparecem** na lista e no detalhe — o dono refina depois
  (*"lemos todas e depois te digo o que suprimir"*). Guardamos **tudo**; a
  seleção de exibição é cosmética e muda sem migração.
- **`fichas.dados` como JSONB vs colunas** — decisão de implementação, pesada no
  plano (JSONB é flexível e barato para histórico; colunas são tipadas e
  consultáveis). Não muda o desenho.
- **Correção à mão gera foto nova vs edita a última** — a definir no plano; o
  princípio (atribuição honesta) não muda.
- **Linha do tempo da evolução** (gráfico "396 → 428 → 460") — o modelo já
  guarda os dados; a visualização é um incremento posterior. Esta iteração
  entrega só o delta-contra-a-última.
- **Subir o limite de 512 KB** — a definir; a imagem é temporária, então pode.

## Fora de escopo (subsistemas próprios, specs próprios)

- **Sala de Guerras** — montar os grupos de TW com os jogadores da guild. É o
  papel `sala_guerras`. Consome a lista deste subsistema; ganha spec próprio.
- **Financeiro** — finanças da guild. Ideia nova; a desenhar do zero.
- **Evolução como tela dedicada** — aqui ela é só o delta no detalhe; uma tela
  de histórico é incremento futuro.

## Restrições globais (do projeto)

- Flutter web + Bloc/Cubit (o ViewModel É o Bloc); `setState` só para visual
  local. Cores só de `PWColors`. UI em português; comentários/testes em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`), nunca string.
- `lib/` nunca importa `dart:io`; código de browser atrás de conditional import.
- Roteamento pertence ao `MaterialApp`; `flutter analyze` termina limpo.
- Nada de dado inventado: ausência não é zero; uma leitura que falha não vira
  afirmação.
