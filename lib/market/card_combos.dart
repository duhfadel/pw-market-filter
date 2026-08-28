/// A named set of War Avatar cards, at most one per type.
///
/// **This table is hand-written, and it has to be.** The marketplace never says
/// which combo a card belongs to: every S card's tooltip prints the same
/// `Seis Soberanos da Chama da Vela (6)` line, including on a character wearing
/// thirty-four distinct S cards, so it identifies nothing. The item database
/// has no card category — its sections are equipment, quests, monsters, mounts,
/// NPCs and potions.
///
/// **The marketplace names no combo at all, and that was checked to the end.**
/// Hokka's own tooltip prints `Seis Soberanos da Chama da Vela (6)` — the same
/// line every S, A and B card prints, 1142 times across fourteen pages. The
/// `(6)` is not that card's set size; it is part of a fixed string. The game
/// client shows the set in each card's description; this site does not.
///
/// Five sources fed it, in descending order of trust:
///
/// 1. **The player**, who named Nuema, Brado de Batalha and Seis Soberanos.
/// 2. **The market**, which confirmed membership: the Nuema six are worn
///    together by 48 characters and the Soberanos six by 455, against 144
///    other six-card arrangements that appear once or twice and are nobody's
///    finished set. The market also supplied the card the player left out of
///    Seis Soberanos — Imperador Locen, the missing Destruidor.
/// 3. **Id blocks plus a shared word in the name**, which is how [emissarios]
///    and [mestres] got here. Weaker, since six consecutive ids covering six
///    types happens by accident: three overlapping windows around the Emissário
///    block pass that test on their own. Only the shared word makes it more
///    than coincidence, and neither is offered by the filter.
class CardCombo {
  const CardCombo({
    required this.name,
    required this.rarity,
    required this.cardIds,
    this.note = '',
  });

  final String name;

  /// `S` or `A`. Every combo in this table happens to be of one rarity, but
  /// that is an observation and not a rule: the game's own wiki says mixed
  /// ranks are normal, so nothing may depend on it.
  final String rarity;

  /// The cards that must **all** be worn, one per type.
  ///
  /// Two, four or six — the game has sets of each, and the six slots hold one
  /// six, or a four and a two, or three twos. This used to demand six, from
  /// back when the only two known combos had six; that was our sample talking,
  /// not the game.
  final Set<int> cardIds;

  /// Shown under the name when there is something the user should know before
  /// trusting the filter.
  final String note;

  /// A size the game actually has. Anything else is a half-written entry, and
  /// filtering on it would answer "nobody" for a reason the visitor cannot
  /// see.
  bool get isComplete => const {2, 4, 6}.contains(cardIds.length);
}

/// Confirmed by the player and by 48 wearers, and named by the sellers: eight
/// of those 48 put NUEMA in the character's own nickname — MS_NUEMA,
/// MamacoNuema, DIA09COMBONUEMA — against one of the 455 Soberanos wearers and
/// none of the remaining 327 characters. Median price 1000 TCC.
const nuema = CardCombo(
  name: 'Portal de Nuema',
  rarity: 'S',
  cardIds: {
    41784, // Althea 瓦 — Destruidor
    41785, // Kestra 丝 — Batalha
    41786, // Astrid — Durabilidade
    41787, // Lorelei — Alma Primordial
    41832, // Saki 沁 — Vida Primordial
    41831, // Tensa — Longevidade
  },
);

/// The commonest build in the market by a distance: 455 characters, median 300
/// TCC. The player listed five; Imperador Locen is the Destruidor the data
/// supplied, and all 455 wear it.
const seisSoberanos = CardCombo(
  name: 'Seis Soberanos da Chama da Vela',
  rarity: 'A',
  cardIds: {
    41883, // Imperador Locen — Destruidor
    41881, // Senhora da Noite — Batalha
    41879, // Gorath — Durabilidade
    41880, // Imperador Chigo — Alma Primordial
    41878, // Imperador Aohe — Vida Primordial
    41882, // Asa Espectral — Longevidade
  },
);

/// Candidate, **not in [cardCombos]**: five of six, and the sixth cannot be
/// recovered from the market.
///
/// The player named five Generals covering five types; Durabilidade is open.
/// The A card ids run 41836 to 41905 with **no gaps**, every one is worn by
/// somebody, and none of the eleven Durabilidade cards in that range is a
/// General — so the sixth exists in the game and nobody on sale has it.
///
/// It stays off the list on the player's rule: a filter for "combo completo"
/// that can only check five cards would pass a character running the Brado
/// build with a foreign Durabilidade card, and call it complete. Add the
/// sixth id and it belongs.
const bradoDeBatalha = CardCombo(
  name: 'Brado de Batalha',
  rarity: 'A',
  cardIds: {
    41890, // General Drac. Heshan — Destruidor
    41892, // General Fur. Duanshan — Batalha
    41889, // Gen. Sombrio Ziyuan — Alma Primordial
    41888, // General Fant. Jiehun — Vida Primordial
    41891, // General Invejoso Chiya — Longevidade
  },
  note: 'falta a 6ª carta (Durabilidade)',
);

/// Candidate, **not in [cardCombos]**: six consecutive ids, six distinct types,
/// and all six named *Emissário*. Nobody in the market wears it.
///
/// Left here because the reasoning is worth keeping and the ids are checked,
/// but off the list because an option that always returns zero is noise — and
/// because the structural argument is weak on its own: three overlapping
/// windows around this block also cover six types. Promote it if the player
/// confirms the name, or if a wearer ever appears.
const emissarios = CardCombo(
  name: 'Emissários',
  rarity: 'A',
  cardIds: {
    41862, // Emissário da Luz — Destruidor
    41866, // Emis. da Névoa — Batalha
    41864, // Emissário do Vazio — Durabilidade
    41865, // Emis. de Corona — Alma Primordial
    41863, // Emissário da Sombra — Vida Primordial
    41867, // Emis. dos Iluminados — Longevidade
  },
  note: 'nome deduzido das cartas, não confirmado',
);

/// Candidate, **not in [cardCombos]**, same reasoning as [emissarios]: six
/// consecutive ids, six types, and the six base classes. No wearers either.
const mestres = CardCombo(
  name: 'Mestres',
  rarity: 'A',
  cardIds: {
    41897, // Arqueiro Mestre — Destruidor
    41894, // Mago Mestre — Batalha
    41895, // Bárbaro Mestre — Durabilidade
    41898, // Sacerdote Mestre — Alma Primordial
    41893, // Guerreiro Mestre — Vida Primordial
    41896, // Feiticeira Mestre — Longevidade
  },
  note: 'nome deduzido das cartas, não confirmado',
);

/// What the filter offers.
///
/// Two rules, both the player's: a combo is six cards, and it only earns a
/// place here if somebody in the market wears it. The first keeps
/// "combo completo" meaning what it says; the second keeps the dropdown free
/// of options that can only ever return nothing.
/// The four cards that always travel together: eighteen characters wear all
/// four and no subset of them has a different set of owners. The player calls
/// them the Quatro Lordes; PWpedia files the same four under *Four Generals of
/// the Human*, labelled six, and lists only these four — and the market
/// agrees with the player, since those eighteen fill their two spare slots
/// with different pairs.
const quatroLordes = CardCombo(
  name: 'Quatro Lordes dos Alados',
  rarity: 'S',
  cardIds: {
    41788, // Gu Hensin — Batalha
    41789, // Lio Gianni — Destruidor
    41790, // Tsen, o Enviado do Céu — Vida Primordial
    41791, // Fen, o Vitorioso — Longevidade
  },
);

/// The pairs, and how they were pinned down.
///
/// Three sources had to agree, because no single one is enough. **The
/// marketplace names none of them** — every card, S, A or B, prints the same
/// `Seis Soberanos da Chama da Vela (6)` line, Hokka included. A Trivia PW
/// article lists which cards pair up but never names the pairs. PWpedia names
/// the sets in English and gives their members. The player supplied the
/// Portuguese.
///
/// Where the article and the market disagreed, the market won: the article
/// pairs *Cidade das Espadas* with *Cidade do Dragão*, and **no character in
/// the market wears those two together** — while Cidade Universal with Cidade
/// do Dragão is the commonest pair of all.
const observadorDoMundo = CardCombo(
  name: 'Observador do Mundo',
  rarity: 'S',
  cardIds: {41798, 41799}, // Anc. da Cidade Universal, Anc. Cidade do Dragão
);

const estrelasGemeas = CardCombo(
  name: 'Estrelas Gêmeas',
  rarity: 'S',
  cardIds: {41800, 41801}, // Iluminado, Submundo
);

const pecadoDosDeusesCaidos = CardCombo(
  name: 'O Pecado dos Deuses Caídos',
  rarity: 'S',
  cardIds: {41806, 41807}, // Tsu, Tsuan
);

const sinfoniaDoDestino = CardCombo(
  name: 'Sinfonia do Destino',
  rarity: 'S',
  cardIds: {41815, 41816}, // Ming Yueji, Chong Yun
);

const asasDePenasSagradas = CardCombo(
  name: 'Asas de Penas Sagradas',
  rarity: 'S',
  cardIds: {41819, 41820}, // Yuusa 响, Anciã das Plumas
);

const corona = CardCombo(
  name: 'Corona',
  rarity: 'S',
  cardIds: {41822, 41823}, // Ancião Star, Ancião Yashimo
);

const senhorDeTodasAsFeras = CardCombo(
  name: 'Senhor de Todas as Feras',
  rarity: 'S',
  cardIds: {41825, 41826}, // Ancião das Feras, Hokka
);

const sabio = CardCombo(
  name: 'Sábio',
  rarity: 'S',
  cardIds: {41828, 41829}, // Sábio Won, Sábio Anônimo
);

/// Biggest first, so the dropdown reads from the hardest set to the easiest.
const cardCombos = <CardCombo>[
  nuema,
  seisSoberanos,
  quatroLordes,
  observadorDoMundo,
  estrelasGemeas,
  pecadoDosDeusesCaidos,
  sinfoniaDoDestino,
  asasDePenasSagradas,
  corona,
  senhorDeTodasAsFeras,
  sabio,
];
