/// A named set of War Avatar cards, at most one per type.
///
/// **This table is hand-written, and it has to be.** The marketplace never says
/// which combo a card belongs to: every S card's tooltip prints the same
/// `Seis Soberanos da Chama da Vela (6)` line, including on a character wearing
/// thirty-four distinct S cards, so it identifies nothing. The item database
/// has no card category — its sections are equipment, quests, monsters, mounts,
/// NPCs and potions.
///
/// Three sources fed it, in descending order of trust:
///
/// 1. **The player**, who named Nuema, Brado de Batalha and Seis Soberanos.
/// 2. **The market**, which confirmed membership: the Nuema six are worn
///    together by 48 characters and the Soberanos six by 455, against 144
///    other six-card arrangements that appear once or twice and are nobody's
///    finished set. The market also supplied the card the player left out of
///    Seis Soberanos — Imperador Locen, the missing Destruidor.
/// 3. **Id blocks plus a shared word in the name**, which is how [emissarios]
///    and [mestres] got here. Weaker, and marked as such in their names, since
///    six consecutive ids covering six types happens by accident: three
///    overlapping windows around the Emissário block pass that test on their
///    own. Only the shared word makes it more than coincidence.
class CardCombo {
  const CardCombo({
    required this.name,
    required this.rarity,
    required this.cardIds,
    this.note = '',
  });

  final String name;

  /// `S` or `A`. Every combo found so far is of a single rarity.
  final String rarity;

  /// The cards that must all be worn. Usually six — one per type — but
  /// [bradoDeBatalha] carries five, because its sixth is not in the market.
  final Set<int> cardIds;

  /// Shown under the name when there is something the user should know before
  /// trusting the filter.
  final String note;

  bool get isComplete => cardIds.length == 6;
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

/// Five cards, and the fifth is not an oversight to fix later.
///
/// The player named five Generals covering five types; the Durabilidade slot is
/// open. It cannot be recovered from the market: the A card ids run 41836 to
/// 41905 with **no gaps**, every one of them is worn by somebody, and none of
/// the eleven Durabilidade cards in that range is a General. So the sixth card
/// exists in the game and nobody on sale wears it — invisible from here.
///
/// Filtering on this therefore means "wears these five", which can in principle
/// admit a character running the Brado build with a foreign Durabilidade card.
/// That is the honest reading, and the note says so on screen.
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
  note: 'a sexta carta (Durabilidade) não aparece no mercado',
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

/// What the filter offers. Only combos somebody actually wears, so no option
/// in the dropdown is a dead end.
const cardCombos = <CardCombo>[nuema, seisSoberanos, bradoDeBatalha];
