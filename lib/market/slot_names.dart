import 'index_repository.dart';
import 'market_index.dart';

/// The weapon. The one slot the UI singles out, because it is where the
/// difference between a 40 TCC character and a 1000 TCC one usually sits.
///
/// **The same number in both marketplaces, and that is a coincidence worth
/// naming rather than trusting blindly.** Measured on the 1.2.6 index
/// collected 01/10/2026, slot 10 is the weapon there too — 165 distinct
/// items, well clear of the next busiest slot's 102 — so the one constant
/// below serves both versions. Nothing else on this page does: see
/// [slotLabel] and [slotGroupsFor], which is why `CLAUDE.md`'s warning that
/// "slot numbering here does not match the standard client's" still has to be
/// obeyed everywhere a *name* is drawn, even though this one number happens
/// to agree.
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

/// 1.2.6's own slot id → name table.
///
/// **A trap `CLAUDE.md` already names: slot numbering here does not match the
/// standard client's, and it does not match 1.8.7's collector either.**
/// Assuming slot 10 means the same piece in both games would have been that
/// exact mistake — it happens to, see [weaponSlot], but nothing else here
/// does. 1.2.6 only ever fills eleven slots, 0 to 10, against 1.8.7's
/// scattered 2–19, so a shared table was never on the table.
///
/// Measured on the 01/10/2026 collection the same way the table above was —
/// by the item that dominates each slot, across 1.293 characters:
///
/// | slot | distinct items | what is in it |
/// |---|---|---|
/// | 0, 1 | 76, 78 | Anel da Estrela Cadente, Anel do Trovão Atordoante —
/// **the same items in both**, the two ring slots |
/// | 2 | 94 | Couraça do Rei Pirata, Armadura Leve de Mercenário |
/// | 3 | 102 | Calça Wu Kong, Perneira Pesada Poshan |
/// | 4 | 94 | Bota Pesada Poshan, Sandálias do Ouro Negro |
/// | 5 | 100 | Cinturão das Sete Leis, Rio Solar |
/// | 6 | 38 | Capa de Vento - C. do Tesouro, Capa do Silêncio-C. do Tesouro |
/// | 7 | 85 | Manoplas da Lua Rubra, Bracelete de Capitão |
/// | 8 | 60 | Coroa de Wu Ji, Elmo de Abalar Trovão |
/// | 9 | 83 | Amuleto em Forma de Cavalo, Colar do Espírito Vazio |
/// | 10 | 165 | Machado Horror de Sangue, Espada de Madeira Ancestral |
///
/// Every one of the eleven is unambiguous the same way 1.8.7's seven were —
/// no guessing, no fallback needed. The sparser client has no counterpart to
/// 1.8.7's Livro divino, Conduíte or Astrolábio, which is why there is no slot
/// 11, 16 or 17 here at all.
const slotNames126 = <int, String>{
  0: 'Anel 1',
  1: 'Anel 2',
  2: 'Armadura',
  3: 'Calças',
  4: 'Botas',
  5: 'Cinto',
  6: 'Capa',
  7: 'Braçadeiras',
  8: 'Elmo',
  9: 'Colar',
  10: 'Arma',
};

/// Which market [index] is open on, to choose between [slotNames] and
/// [slotNames126]. Compares `MarketIndex.server`, not a readable version
/// string — the same key `IndexRepository.pw126` and `core/rotas.dart`'s
/// `pw126` constant both resolve against, kept separate for the reason
/// `index_repository.dart` already gives: one is a file key, the other a
/// label a visitor reads.
bool isPw126(MarketIndex index) => index.server == IndexRepository.pw126;

/// What a slot is called in [index]'s own market — the two tables above,
/// chosen by [isPw126], never mixed. A slot number means a different piece of
/// gear depending on which game wrote it, so a label drawn without the index
/// is a label that might be lying.
String slotLabel(int slot, MarketIndex index) =>
    (isPw126(index) ? slotNames126 : slotNames)[slot] ?? 'Slot $slot';

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

/// [slotGroups]' own 1.2.6 counterpart — same three ideas, the ids that
/// actually exist there. Acessórios drops 11, 16 and 17 (not in this client
/// at all) and gains 0 and 1, the two ring slots 1.8.7 numbers 18 and 19.
///
/// Emblems are, again, the commonest item of their slot in the 01/10/2026
/// collection: the axe 99 characters carry, the chestpiece 83 do, and the
/// amulet 92 do.
const slotGroups126 = <SlotGroup>[
  SlotGroup('Arma', [10], emblem: 8287),
  SlotGroup('Set', [2, 3, 4, 7], emblem: 8319),
  SlotGroup('Acessórios', [8, 6, 5, 9, 0, 1], emblem: 8359),
];

/// [slotGroups] or [slotGroups126], by the same test [slotLabel] already
/// makes — one function so a panel never has to repeat the `isPw126` check
/// itself.
List<SlotGroup> slotGroupsFor(MarketIndex index) =>
    isPw126(index) ? slotGroups126 : slotGroups;

/// The emblem above the card filter: Kestra, the most worn S card in the
/// market. Cards are not in `index.items`, so this id lives beside the groups
/// rather than inside one.
///
/// 1.2.6 has no cards at all today — see `presetsFor`'s own check — so
/// nothing reads this for that market; it stays a single constant rather than
/// gaining a counterpart with no caller.
const cardsEmblem = 41785;

class SlotGroup {
  const SlotGroup(this.title, this.slots, {required this.emblem});

  final String title;
  final List<int> slots;

  /// Item id whose picture stands for the group in the filter's header.
  final int emblem;
}
