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
/// The collector resolves each name to the ids the market used and stores them
/// in `MarketIndex.countedItems`; nothing here is compiled into a query.
///
/// **A label can gather several names, and a name several ids.** Both are the
/// same correction: binding a label to the first id a crawl met dropped every
/// other one in silence, so its owners failed the filter with nothing on
/// screen saying why. Read a count through `MarketIndex.countOf`, never by
/// taking one id out of the list.
library;

/// The counted lines, each one a label and the page names that feed it.
///
/// **Most labels are fed by a single name, and one is not.** *Essência
/// Dracônica* is asked about as one number — how much dragon essence somebody
/// is sitting on — and the game spreads it over three names: the essence, the
/// raw essence and the chest. Counting them apart would put three lines on the
/// card for one question and make every one of them wrong as an answer to it.
///
/// The chest is in on the player's call, taken against the recommendation and
/// recorded here as his: a chest is a container and not the thing, so it
/// inflates the number against anyone who has already opened theirs. He wants
/// it counted, and it is his market.
const countedItemGroups = <String, List<String>>{
  'Relíquia Maravilha: Artefato': ['Relíquia Maravilha: Artefato'],
  'Relíquia Maravilha: Arma': ['Relíquia Maravilha: Arma'],
  'Relíquia Maravilha: Armadura': ['Relíquia Maravilha: Armadura'],
  'Chave da Sorte': ['Chave da Sorte'],
  'Essência Dracônica': [
    'Essência Dracônica',
    'Essência Dracônica Bruta',
    'Baú Essência Dracônica',
  ],
};

/// Every name worth looking for on a page — the groups, flattened.
final countedItemNames = <String>{
  for (final names in countedItemGroups.values) ...names,
};

/// The label a page name is counted under, or null when nobody asked about it.
String? countedGroupOf(String name) {
  for (final entry in countedItemGroups.entries) {
    if (entry.value.contains(name)) return entry.key;
  }
  return null;
}

/// What a grouped label says under its name, and the id its picture comes
/// from.
///
/// **Both exist because a group of one is self-explanatory and a group of
/// three is not.** *Essência Dracônica* adds up three different items, and a
/// single number with no note reads as a count of the first one — the player
/// has no way to know the raw essence and the chest are in there.
///
/// The icon is named rather than taken from `countedItems[label].first`,
/// which is **the order the crawl happened to meet them**: two collections a
/// week apart can disagree about which item a label's picture shows, with
/// nothing on screen saying the art moved. The same hazard as an attribute's
/// id, arriving through the art.
const countedItemNotes = <String, String>{
  'Essência Dracônica':
      'Soma de Essência Dracônica, Essência Dracônica Bruta e do Baú.',
};

/// The id whose sprite draws a label, when the first one met is not the one to
/// show. See [countedItemNotes] for why this is not left to the crawl.
const countedItemIcons = <String, int>{'Essência Dracônica': 50264};

/// The labels still being checked against the game, drawn with a BETA TEST
/// badge beside the name.
///
/// It is a set and not a flag on one entry because the question recurs: a
/// counted item is only ever as right as the names somebody typed, and the
/// first collection is where a misspelling or a second id shows up. Saying so
/// on screen costs one badge and buys the right to ship before the answer is
/// certain — the alternative is holding the feature back until nobody can
/// check it, which is how a name stays unverified for months.
///
/// **Take a name out of here the day its numbers have been read against a
/// character's own page.** A badge that outlives its doubt teaches visitors to
/// ignore badges, which is the same failure the *novo* date exists to avoid.
const countedItemsInTest = <String>{'Essência Dracônica'};

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

/// The name a chip can carry.
///
/// The three relics differ only in their last word and a chip is capped at
/// 190 px, so the full name followed by its number ellipsizes exactly where
/// the difference lives — *Relíquia Maravilha: Arma · 31 ou…* names no relic
/// and states no number. Dropping *Maravilha* keeps both the kind of thing and
/// the word that tells the three apart.
///
/// It is not shortened to *Arma*: a criterion on the weapon slot already
/// writes a chip beginning with that word, and the two would be one label for
/// two different questions. Everywhere with room for it — the section, the
/// card — still shows the name the game gives.
String shortCountedName(String name) => name.replaceFirst('Maravilha: ', '');
