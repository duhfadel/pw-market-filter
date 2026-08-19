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
