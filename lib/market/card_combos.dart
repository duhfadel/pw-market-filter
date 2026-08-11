/// A named set of six War Avatar cards, one per type.
///
/// **This table is hand-written, and it has to be.** The marketplace never says
/// which combo a card belongs to: every S card's tooltip prints the same
/// `Seis Soberanos da Chama da Vela (6)` line, including on a character wearing
/// thirty-four distinct S cards, so it identifies nothing. The item database
/// does not list cards at all — its categories are equipment, quests, monsters,
/// mounts, NPCs and potions.
///
/// Frequency in the market is evidence but not proof. The two entries below
/// were each found on dozens of characters, which is what separates them from
/// the thirty-nine six-card assemblies that appear exactly once and are almost
/// certainly nobody's finished set. A combo that nobody in the market has
/// completed is invisible to that method — so new ones get added here by hand,
/// one line each.
class CardCombo {
  const CardCombo({
    required this.name,
    required this.rarity,
    required this.cardIds,
  });

  final String name;

  /// `S` or `A`. Every combo found so far is of a single rarity.
  final String rarity;

  /// The six card ids. Order does not matter; membership does.
  final Set<int> cardIds;
}

/// Seeded from the 2026-08-11 collection of 830 characters.
///
/// The membership of both is exact: these are six-card sets worn by 48 and 455
/// characters, and the price gap between them is why this filter exists —
/// median 1000 TCC against 300.
///
/// **Portal de Nuema was named by its sellers, not deduced.** Eight of the 48
/// wearers put NUEMA in the character's own nickname — MS_NUEMA, MamacoNuema,
/// DIA09COMBONUEMA, ComboNuemaG17UP4 — against one of the 455 in the other
/// combo and none of the remaining 327 characters. A 17% to 0% split is not a
/// coincidence, and it matches the unopened `Arca S: Portal de Nuema` found in
/// a bag, which promises "one of the six War Avatar cards of the Portal de
/// Nuema, level S".
///
/// The second combo has no name yet. `Combo A` is a placeholder.
const cardCombos = <CardCombo>[
  CardCombo(
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
  ),
  CardCombo(
    name: 'Combo A',
    rarity: 'A',
    cardIds: {
      41883, // Imperador Locen — Destruidor
      41881, // Senhora da Noite — Batalha
      41879, // Gorath — Durabilidade
      41880, // Imperador Chigo — Alma Primordial
      41878, // Imperador Aohe — Vida Primordial
      41882, // Asa Espectral — Longevidade
    },
  ),
];
