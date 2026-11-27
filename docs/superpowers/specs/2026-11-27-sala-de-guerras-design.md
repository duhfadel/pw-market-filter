# Painel NewAge — subsistema **Sala de Guerras**

> Desenho aprovado em 27/11/2026, por mockup e conversa. Monta as pts da TW
> arrastando os jogadores da guild entre grupos.

## Contexto

Segundo subsistema do painel `/newageguild` (o primeiro, **Jogadores**, está no
ar — ver `2026-11-27-newageguild-jogadores-design.md`). O botão *Sala de
Guerras* já existe no menu-hub, hoje *em breve*; esta spec o ativa.

Reaproveita o **padrão de arrasto do organizador de instâncias**
(`lib/features/instancias/`): `_PegaArrasto` (pega dedicada, `LongPressDraggable`
no telemóvel, `Draggable` no rato), o grupo como `DragTarget`, e o modelo
`movendoPersonagem`/`semOGrupo` de `PlanoDeInstancias`. **Mas difere em duas
coisas** que mudam o desenho: os jogadores vêm do **roster da guild** (não
escritos à mão), e a formação é **compartilhada** (Supabase), não local.

## A tela

Alcançada pelo botão *Sala de Guerras* do menu. **Quem vê, edita e salva** — é
a casa do papel `sala_guerras`, e admin/staff_editor/staff_basico também entram
(a mesma regra que o menu já aplica: `SecaoGuild.salaGuerras` é visível a todos
os papéis). Uma sala de guerra é coordenação; não vale trancar a edição.

Duas colunas:

- **Esquerda — jogadores disponíveis.** O roster da guild (os **transcritos**)
  que **ainda não estão em nenhuma pt**, com busca por nome. Cada chip: pega de
  arrasto, ícone da classe, nome e **nível de ataque** (para montar pts
  equilibradas).
- **Direita — as pts.** Uma grade de até **20** grupos. Cada pt recebe até
  **10** jogadores. Um cartão **"+ nova pt"** cria mais (até o teto). A dica
  explica o arrasto.

## As pts (grupos)

- **1 a 10 jogadores.** Uma pt cheia (10) **recusa** o drop; o teto é do modelo,
  não só da tela.
- **Até 20 pts.** O "+ nova pt" some no teto.
- **Nome próprio**, editável (padrão `Pt N`). **Cor própria**, escolhida de uma
  paleta (as cores de `PWColors` já usadas na grade/escada servem).
- **Um jogador fica numa pt só.** Arrastá-lo para outra pt move (sai da origem);
  arrastá-lo de volta para a lista geral tira-o da formação. Largar na lista
  geral é a forma de remover.

## Os líderes

- **Vários por pt.** Cada membro tem uma **♛** à direita; tocar alterna
  líder/não-líder. Um líder desenha na **cor do grupo** (chip tingido + coroa
  acesa); um não-líder tem a coroa apagada (toque para coroar).
- A marca de líder é por **membro dentro da pt** — mover o jogador para outra pt
  **zera** o estado de líder (ele é líder *daquele* grupo, não da pessoa). Tirá-lo
  para a lista geral também zera.

## O arrasto

Reaprovar o padrão dos Instâncias:

- **Pega dedicada** (`_PegaArrasto`): `LongPressDraggable` no telemóvel (a página
  rola com o dedo; o arrasto nasce de um toque longo na pega), `Draggable` no
  rato. Só a pega arrasta — o resto do chip toca na coroa/remove.
- **A pt inteira é o `DragTarget`** (largar no grupo, não numa linha). A **lista
  geral** também é um `DragTarget` (largar lá remove da formação).
- `moverMembro` tira antes de calcular o destino, senão mover dentro do mesmo
  grupo erraria por um — a lição do `movendoPersonagem`.
- **Telemóvel:** o arrasto funciona (como nos Instâncias), mas a tela é
  densa; no estreito as pts empilham numa coluna e a lista geral vai para cima.
  É desktop-first por natureza (planeia-se a TW no computador), e o estreito é
  usável, não ótimo.

## Persistência — compartilhada, via **Salvar**

A formação é **uma só**, da guild, no Supabase. Edita-se livremente em memória
(estado do Cubit); o botão **"Salvar formação"** grava. Carregar lê a formação
salva. **Último save vence** — dois staff que salvam quase juntos, o segundo
sobrescreve; para combinar uma TW é aceitável, e a tela mostra *salvo há X por
quem*.

**Tabela `formacao_guerra`** (uma linha só, id fixo): `pts jsonb` (a lista de
grupos: `[{nome, cor, membros:[{jogador_id, lider}]}]`), `salvo_em timestamptz`,
`salvo_por uuid`, `salvo_por_email text`. RLS: leitura para staff autenticado;
escrita para staff (a mesma função `papel_do`), fechada ao anônimo. Uma linha
única porque a formação é uma só; um upsert por id conhecido.

**A formação guarda ids, não cópias.** Nome, classe e nível de ataque de cada
jogador vêm do **roster vivo** no momento de desenhar — um jogador re-transcrito
mostra o NA novo sem a formação saber. É a mesma regra do mercado: guardar a id
estável e derivar o resto.

## Honestidade e bordas

- **Um id na formação que não existe mais no roster** (jogador removido) é
  **descartado ao carregar** — nada de membro-fantasma. Se isso esvaziar uma
  pt, ela fica vazia (não some sozinha; o staff decide tirá-la).
- **Só entram na lista geral os `transcrito`** — um `pendente`/`revisar` não tem
  stats para balancear; aparece quando for lido. (Decisão a confirmar no plano:
  mostrar pendentes esmaecidos vs escondê-los; o padrão é escondê-los da sala.)
- **Salvar falha calada não existe:** um erro de rede no Salvar **tem** de
  aparecer (um `SnackBar` tipado), ao contrário do `localStorage` dos
  Instâncias — aqui o trabalho é compartilhado e um save perdido é um prejuízo
  real.

## Modelo (Dart)

Em `lib/features/guild/domain/` (ou um subpacote `guerra/`):

- `MembroGuerra({required String jogadorId, bool lider})`.
- `GrupoGuerra({required String nome, required String cor, required List<MembroGuerra> membros})`
  — com `cheio` (10), `comMembro`/`semMembro`, `alternarLider`.
- `FormacaoGuerra({required List<GrupoGuerra> grupos})` — com `moverMembro`
  (entre grupos e para fora), `comGrupo`/`semGrupo` (teto 20), `disponiveis(roster)`
  (os ids do roster não colocados), `fromJson`/`toJson`.
- Os tetos (10/20) e a unicidade (um jogador numa pt só) são **invariantes do
  modelo**, testados — não confie só na UI.

## UI

- `SalaGuerrasView` + `SalaGuerrasViewModel` (Cubit): segura a `FormacaoGuerra`
  em edição + o roster carregado; `carregar()` lê a formação + o roster;
  `salvar()` grava e emite o estado "salvo". Setters para mover, renomear,
  recolorir, alternar líder, criar/remover pt — cada um reemite.
- `FormacaoRepository.carregar() → Future<Result<FormacaoGuerra>>`,
  `salvar(FormacaoGuerra) → Future<Result<void>>`.
- Visual: o tema do painel (`PWColors`), ícones reais de classe (`ClassIcon`),
  números em Roboto. A grade de pts responsiva (`LayoutBuilder`), a lista geral
  à esquerda no largo e por cima no estreito.

## Testes

- **Modelo**: mover um membro entre grupos tira da origem e põe no destino
  (sem erro-por-um); uma pt cheia recusa; o teto de 20 pts; alternar líder; um
  id fora do roster some de `disponiveis` e ao carregar; o round-trip
  `fromJson`/`toJson`.
- **VM**: carregar junta formação + roster; salvar emite sucesso/falha tipada;
  `disponiveis` = roster transcrito menos os colocados.
- **RLS**: anônimo não lê nem escreve `formacao_guerra` (curl).
- UI onde valer a pena (sem meta de cobertura), com atenção ao overflow
  horizontal — a lição que a iteração 2 pagou duas vezes.

## Fora de escopo (acréscimos futuros)

- **Várias formações nomeadas** ("TW Sexta", "TW Sábado") — por ora uma só.
- **Mostrar quem está a ver/editar agora** (presença em tempo real) — o save
  compartilhado basta para começar.
- **Totais por pt** (soma de NA, composição por classe) — dá para medir
  equilíbrio depois; a tela já mostra o NA por membro.
- **Financeiro** — o terceiro subsistema, spec próprio.

## Restrições globais (do projeto)

- Flutter web + Bloc/Cubit (o ViewModel É o Cubit); `setState` só para visual
  local (o arrasto em curso, um diálogo). Cores só de `PWColors`. UI em
  português; comentários/testes em inglês.
- `Result<T>`, nunca lança; falha **tipada** (`GuildFailure`), nunca string.
- `lib/` nunca importa `dart:io`. Roteamento pelo `MaterialApp` (a Sala abre por
  `Navigator.push` a partir do menu, como a lista de Jogadores). `flutter
  analyze` limpo.
- Nada de dado inventado: um id sem jogador no roster não desenha membro.
- Supabase project `yadfbwsolmkcaylbxviw`; `service_role` nunca no navegador.
