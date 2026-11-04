/// As pedras de nível de ataque e de defesa, e o que é um conjunto completo.
///
/// **O índice guarda o id da pedra e não o nível**, e os ids não estão sequer
/// em `MarketIndex.items` — a tabela de nomes só recebe equipamento. Por isso
/// esta tabela existe, pelo mesmo motivo de `card_combos.dart`: é o que o
/// jogo sabe e o nosso ficheiro não.
///
/// **Não foi inventada: foi lida.** A página de cada personagem nomeia a
/// pedra ao lado da imagem — `Diamante do Tigre Nível de Ataque +1` — e o
/// parser lê o id da imagem e deita o texto fora. Os nove ids abaixo saíram
/// de 44 páginas do mercado real a 04/11/2026, uma a cada três segundos, e
/// `set_stones_test` crava cada um contra `web/market_index.json`: um id
/// inventado dá um filtro que não acha ninguém, e *ninguém tem este conjunto*
/// é uma resposta que parece verdadeira.
///
/// A longo prazo o certo é o parser guardar o nome, e aí esta tabela morre.
/// Isso custa uma recolha completa de duas horas e não muda o resultado hoje.
library;

/// A família de pedra: o que ela aumenta.
enum StoneKind {
  /// Nível de Ataque.
  attack,

  /// Nível de Defesa.
  defence,
}

/// Uma pedra de nível, como o jogo a nomeia.
class SetStone {
  const SetStone({
    required this.id,
    required this.name,
    required this.kind,
    required this.level,
    required this.accessory,
  });

  final int id;
  final String name;
  final StoneKind kind;

  /// O `+N` que o nome anuncia.
  final int level;

  /// `true` quando é a pedra do colar e do ornamento.
  ///
  /// **As duas famílias não são intercambiáveis**, e a arte diz isso: a Pedra
  /// do Demônio e a Pedra de Yan Luo são ambas Ataque +3 e desenham
  /// diferente. Uma não entra no lugar da outra.
  final bool accessory;
}

/// As nove que o mercado mostra.
///
/// **Faltam três células do grid, e não é falha de levantamento.** Defesa +1
/// não aparece uma única vez em 2.486 personagens, nem no equipamento nem no
/// acessório, e Ataque +1 não existe na família do acessório. Por isso
/// [setsDisponiveis] não oferece um conjunto de Defesa +1: um botão que não
/// pode dar resultado é pior do que botão nenhum.
const setStones = <SetStone>[
  SetStone(
    id: 21377,
    name: 'Diamante do Tigre',
    kind: StoneKind.attack,
    level: 1,
    accessory: false,
  ),
  SetStone(
    id: 38153,
    name: 'Pedra da Divindade',
    kind: StoneKind.attack,
    level: 2,
    accessory: false,
  ),
  SetStone(
    id: 38154,
    name: 'Pedra do Demônio',
    kind: StoneKind.attack,
    level: 3,
    accessory: false,
  ),
  SetStone(
    id: 25154,
    name: 'Jade Preciosa',
    kind: StoneKind.defence,
    level: 2,
    accessory: false,
  ),
  SetStone(
    id: 38155,
    name: 'Pedra da Serenidade',
    kind: StoneKind.defence,
    level: 3,
    accessory: false,
  ),
  SetStone(
    id: 47276,
    name: 'Pedra da Perfeição',
    kind: StoneKind.attack,
    level: 2,
    accessory: true,
  ),
  SetStone(
    id: 68155,
    name: 'Pedra de Yan Luo',
    kind: StoneKind.attack,
    level: 3,
    accessory: true,
  ),
  SetStone(
    id: 47278,
    name: 'Pedra do Soberano',
    kind: StoneKind.defence,
    level: 2,
    accessory: true,
  ),
  SetStone(
    id: 68156,
    name: 'Pedra de Montanha',
    kind: StoneKind.defence,
    level: 3,
    accessory: true,
  ),
];

/// Id da pedra para a pedra, montado uma vez.
final stoneById = {for (final p in setStones) p.id: p};

/// As cinco peças de equipamento que contam para o conjunto.
///
/// **Elmo, peito, perneira, bota e luvas — e deliberadamente não a capa nem a
/// arma**, que também aceitam estas pedras. É escolha do dono, tomada sobre a
/// medição: com as nove peças o conjunto de Ataque +3 cai de 32 pessoas para
/// 6, e de Defesa +3 de 16 para 5. Um filtro que devolve cinco numa grelha de
/// 2.486 não ensina nada a quem procura.
const equipmentSlots = {8, 2, 3, 4, 7};

/// O colar e o ornamento, que levam a outra família de pedra.
const accessorySlots = {9, 5};

/// Todas as peças que um conjunto exige.
const setSlots = {...equipmentSlots, ...accessorySlots};

/// O ícone da secção: o Diamante do Tigre.
const stoneIcon = 21377;

/// Os conjuntos que podem existir, em ordem de oferta.
///
/// Defesa +1 fica de fora porque a pedra não existe — ver [setStones].
const setsDisponiveis = <({StoneKind kind, int level})>[
  (kind: StoneKind.attack, level: 1),
  (kind: StoneKind.attack, level: 2),
  (kind: StoneKind.attack, level: 3),
  (kind: StoneKind.defence, level: 2),
  (kind: StoneKind.defence, level: 3),
];

String setLabel(StoneKind kind, int level) =>
    '${kind == StoneKind.attack ? 'Ataque' : 'Defesa'} +$level';

/// A pedra que representa o conjunto: a do equipamento.
///
/// **Um conjunto pode ter duas pedras, e esta é a das cinco peças.** Ataque
/// +3 é a Pedra do Demônio no elmo, peito, perneira, bota e luvas, e a Pedra
/// de Yan Luo no colar e no ornamento — itens diferentes, com arte
/// diferente. O chip mostra a primeira, que é a de cinco das sete peças.
///
/// **E nem sempre há duas.** Ataque +1 existe só no equipamento: não há
/// pedra de acessório nesse nível. Isso não quebra o conjunto, porque o
/// filtro é um mínimo — o colar e o ornamento entram com +2 ou +3, e o
/// mínimo das sete continua a ser 1.
SetStone equipmentStoneOf(StoneKind kind, int level) => setStones.firstWhere(
  (p) => p.kind == kind && p.level == level && !p.accessory,
);
