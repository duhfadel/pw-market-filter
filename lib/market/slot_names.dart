/// The weapon. The one slot the UI singles out, because it is where the
/// difference between a 40 TCC character and a 1000 TCC one usually sits.
const weaponSlot = 10;

/// What each equipment slot is called.
///
/// The site does not label them — the paper doll only carries
/// `data-item-type="slot-10"`, and there is no `aria-label`, title or CSS rule
/// naming it anywhere on the page. These names were read off the items that
/// actually sit in each slot across all 770 characters, by the item that
/// dominates it:
///
/// | slot | what is in it |
/// |---|---|
/// | 2 | Armadura do Rei, Couraça Radiante |
/// | 3 | Armadura Perna do Rei, Calção Caçador |
/// | 4 | Cáliga do Rei, Botas Caçador |
/// | 5 | Cinto da Nuvem de Chamas, Lacre de Jade |
/// | 6 | Capa Universal, Capa da Ascensão |
/// | 7 | Braçadeiras do Rei |
/// | 8 | Coroa da Insanidade, Elmo da Luz do Pôr-do-Sol |
/// | 9 | Pingente da Nuvem de Chamas, Cubo do Destino |
/// | 10 | Dilacerador do Vento, Caçador de Estrelas |
/// | 11 | Três Estudiosos, Trompete de Ferro, Água Gentil |
/// | 16 | Conduíte do Cosmo |
/// | 17 | Astrolábio |
/// | 18, 19 | Céu Tempestuoso, Anel Real — **the same items in both**, which
/// is what identifies them as the two ring slots |
///
/// Slot 11 is the Livro divino, named by the player on 2026-08-09. The data
/// could not have given it: only 534 of 770 characters carry one, and Três
/// Estudiosos, Trompete de Ferro and Água Gentil have nothing in common that
/// says "book" to a reader who does not play. When the items do not name the
/// slot, ask — do not guess.
///
/// Slot 3 against 4 looked ambiguous because *Caneleiras* shows up in both —
/// the Coração de Leão set uses it for slot 4 while the Radiante set uses it
/// for slot 3. Counting settled it: slot 4's eight commonest items are all
/// footwear (Cáliga, Botas, Sapatos) and slot 3's are legs (Armadura Perna,
/// Calção, Perneiras, Calças, Polainas). *Caneleiras* is the game's own
/// translation being inconsistent, not the slot being unclear — which is why
/// counting across 770 characters beats reading one set's names.
const slotNames = <int, String>{
  2: 'Armadura',
  3: 'Calças',
  4: 'Botas',
  5: 'Cinto',
  6: 'Capa',
  7: 'Braçadeiras',
  8: 'Elmo',
  9: 'Colar',
  10: 'Arma',
  11: 'Livro divino',
  16: 'Conduíte',
  17: 'Astrolábio',
  18: 'Anel 1',
  19: 'Anel 2',
};

String slotLabel(int slot) => slotNames[slot] ?? 'Slot $slot';

/// How the slots are grouped on the filter panel.
///
/// The grouping is the player's, and it follows how gear is thought about
/// rather than how the site numbers it: the weapon on its own because it is
/// what decides a character's price, then the four pieces that make a set,
/// then everything else. Helm and cape sit in the third group — they are worn
/// armour but they are not part of the set bonus, and a fourth group for two
/// slots would be more structure than it earns.
/// The three groups the filter is divided into, each standing behind a real
/// item out of the collected market rather than a generic glyph.
///
/// The emblems are the commonest piece of their kind, picked by counting the
/// index: the mage's 70 attack-level weapon, the barbarian chestpiece thirty
/// characters wear, and the Cubo do Destino that two hundred do. A made-up id
/// would silently draw nothing, so `test/emblem_test.dart` pins all three
/// against the market the same way `combo_test.dart` pins the card ids.
const slotGroups = <SlotGroup>[
  SlotGroup('Arma', [10], emblem: 50194),
  SlotGroup('Set', [2, 3, 4, 7], emblem: 43661),
  SlotGroup('Acessórios', [8, 6, 5, 9, 18, 19, 11, 16, 17], emblem: 23612),
];

/// The emblem above the card filter: Kestra, the most worn S card in the
/// market. Cards are not in `index.items`, so this id lives beside the groups
/// rather than inside one.
const cardsEmblem = 41785;

class SlotGroup {
  const SlotGroup(this.title, this.slots, {required this.emblem});

  final String title;
  final List<int> slots;

  /// Item id whose picture stands for the group in the filter's header.
  final int emblem;
}
