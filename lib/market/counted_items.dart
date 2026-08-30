/// The items the filter counts in a character's inventory.
///
/// **Names, not ids, and that is the design.** The `Chave da Sorte`'s id is
/// unknown — no character in the saved fixture carries one, and the item
/// database needs a game-context cookie before it will search — so a list of
/// ids would have to guess at it, and a guessed id yields a filter that
/// quietly matches nobody. "Nobody has one" is a believable answer, which is
/// what makes that failure invisible. A name finds the item the moment a
/// collection meets it, and `counted_items_test.dart` fails loudly for any
/// name the market never showed.
///
/// This does **not** contradict *the item name lies*. That rule is about worn
/// equipment, where three weapons share the word *Dilacerador* and give 30, 40
/// and 70 attack level — there the name does not identify the thing that
/// matters. For a consumable being counted, the name is the identity.
///
/// The collector resolves each name to the id the market used and stores it in
/// `MarketIndex.countedItems`; nothing here is compiled into a query.
library;

const countedItemNames = <String>[
  'Relíquia Maravilha: Artefato',
  'Relíquia Maravilha: Arma',
  'Relíquia Maravilha: Armadura',
  'Chave da Sorte',
];

/// The pets worth filtering on, by **id** — the exact reverse of the rule
/// above, and for a reason that only shows up on a real page.
///
/// A pet's name belongs to its owner. `38587` prints as *Ovo de Harpia* on
/// three characters and as *GabirÚ* on a fourth, because the player renamed
/// it — and `item_name`, `name` and `title` in the JSON all carry the nickname.
/// Filtering by name would therefore miss exactly the people who own one,
/// since naming the pet is what you do when you have it. The species survives
/// in the tooltip (`Espécie: Ovo de Harpia`), but the id says the same thing
/// and is already in the collector's state, so nothing has to be re-crawled.
///
/// Only the Feiticeira has combat pets, so asking for one narrows to that
/// class on its own — no rule about classes is needed anywhere.
///
/// `Hércules` is the community's name; the game calls the species *Ovo Mascote
/// Gigante Celestial*, and the class's own Hero Saga names the pet "Gigante
/// Celestial Hércules", which is what ties the two together. Neither id was
/// guessed: both were read off pages of characters on sale, and
/// `counted_items_test.dart` fails if they stop resolving.
const countedItemIds = <String, int>{'Hércules': 37905, 'Harpia': 38587};

/// The three that add up to one number. The `Chave da Sorte` is deliberately
/// not among them.
///
/// **The player's reason is that it is not the same kind of thing**, and the
/// market agrees with him twice over. Measured on 2026-08-30 across 996
/// characters, the relics behave alike — 94–98% carry them, median 16 to 21,
/// top around 120 — so their sum is a fair reading of how much somebody
/// hoarded. The key is a different animal: 57% carry one, **half of those
/// carry exactly one**, and the top reaches 2982. Adding it in stops the
/// ranking being about relics at all: the top five became people with 46
/// relics and 2982 keys, and the man with 290 relics fell out of it.
///
/// It still gets a checkbox, because printing how many somebody carries is a
/// different job from ranking by it.
const relicNames = <String>{
  'Relíquia Maravilha: Artefato',
  'Relíquia Maravilha: Arma',
  'Relíquia Maravilha: Armadura',
};

/// The names a real page has been seen to print, character for character.
///
/// The three relics are in `test/fixtures/detail_64112.html`, so one of them
/// failing to resolve is a bug in this file or in the parser and the suite
/// says so. The `Chave da Sorte` is spelled from what was asked for and has
/// never been seen in a collection: it may simply not be on sale, and a market
/// fact must not turn the suite red and stop the site deploying. The collector
/// names every unresolved counted item at the end of a run, which is where
/// that answer belongs.
///
/// Move a name in here the day a collection finds it.
const confirmedCountedItems = <String>{
  'Relíquia Maravilha: Artefato',
  'Relíquia Maravilha: Arma',
  'Relíquia Maravilha: Armadura',
};
