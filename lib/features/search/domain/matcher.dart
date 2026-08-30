import '../../../market/card_combos.dart';
import '../../../market/celestial_realm.dart';
import '../../../market/counted_items.dart';
import '../../../market/market_index.dart';
import 'item_criterion.dart';
import 'search_query.dart';

/// The characters that satisfy [query], ordered by [SearchQuery.order].
///
/// Returning nothing is a result, not a failure: "nobody on the server has a
/// +70 weapon under 500 TCC" is the most useful thing this tool can say.
List<MarketCharacter> runQuery(MarketIndex index, SearchQuery query) {
  final matches = index.characters
      .where((character) => matchesQuery(index, character, query))
      .toList();

  matches.sort(switch (query.order) {
    ResultOrder.cheapest => (a, b) => a.price.compareTo(b.price),
    ResultOrder.dearest => (a, b) => b.price.compareTo(a.price),
    ResultOrder.highestLevel => (a, b) => b.level.compareTo(a.level),
    ResultOrder.highestFame => (a, b) => b.fame.compareTo(a.fame),
    // These two tie constantly — hundreds of characters carry the same number
    // of relics, and none at all is the commonest answer of the lot. Falling
    // back to the price keeps the cheapest of an equal row on top, which is
    // the question the default order exists to answer.
    ResultOrder.mostAnecdotes => (a, b) => _byPrice(
      a,
      b,
      (b.anecdotes?.done ?? -1).compareTo(a.anecdotes?.done ?? -1),
    ),
    ResultOrder.mostOwned => (a, b) => _byPrice(
      a,
      b,
      _countedTotal(
        index,
        relicNames,
        b,
      ).compareTo(_countedTotal(index, relicNames, a)),
    ),
    // Unread sinks to the bottom of **both** directions: -1 would float to the
    // top of "menor céu" and answer the question with the crawl's progress.
    ResultOrder.highestRealm => (a, b) => _byPrice(
      a,
      b,
      _rung(b).compareTo(_rung(a)),
    ),
    ResultOrder.lowestRealm => (a, b) => _byPrice(
      a,
      b,
      _rung(a, unread: 101).compareTo(_rung(b, unread: 101)),
    ),
  });
  return matches;
}

int _rung(MarketCharacter character, {int unread = -1}) =>
    CelestialRealm.parse(character.realm)?.ordinal ?? unread;

int _byPrice(MarketCharacter a, MarketCharacter b, int primary) =>
    primary != 0 ? primary : a.price.compareTo(b.price);

/// How many of [names] a character carries, added up.
///
/// `-1` when none of them was read, so a character whose page never loaded
/// sits below one who was read and carries none. Zero is an answer; absent is
/// not.
int _countedTotal(
  MarketIndex index,
  Set<String> names,
  MarketCharacter character,
) {
  var total = -1;
  for (final name in names) {
    final itemId = index.countedItems[name];
    if (itemId == null) continue;
    final count = character.counts[itemId];
    if (count == null) continue;
    total = total < 0 ? count : total + count;
  }
  return total;
}

/// Takes the index because an item's rank lives in its name, which only the
/// index holds — an [EquippedItem] knows the id and nothing else. Copying the
/// rank onto every worn item would spare this argument and create a second
/// copy of a fact that is already written down.
bool matchesQuery(
  MarketIndex index,
  MarketCharacter character,
  SearchQuery query,
) {
  if (query.characterClass != null &&
      character.characterClass != query.characterClass) {
    return false;
  }
  if (query.cultivation != null && character.cultivation != query.cultivation) {
    return false;
  }
  if (query.minLevel != null && character.level < query.minLevel!) return false;
  if (query.maxLevel != null && character.level > query.maxLevel!) return false;
  if (query.minPrice != null && character.price < query.minPrice!) return false;
  if (query.maxPrice != null && character.price > query.maxPrice!) return false;

  if (!_matchesCards(character, query)) return false;
  if (!_matchesInventory(index, character, query)) return false;

  final wearsEachChosenItem = query.itemBySlot.entries.every(
    (wanted) => character.equipped.any(
      (item) => item.slot == wanted.key && item.itemId == wanted.value,
    ),
  );
  if (!wearsEachChosenItem) return false;

  return query.criteria.every(
    (criterion) =>
        character.equipped.any((item) => _satisfies(index, item, criterion)),
  );
}

/// The anecdote progress and the counted items — the two things that come off
/// the character's own page rather than off a piece of gear.
///
/// Both refuse a character the collection has not read. An unknown must not
/// pass a filter that asks for a number: while a collection is in flight half
/// the market has no anecdotes, and reporting those as matching would answer
/// the question with the crawl's progress instead of the market's.
bool _matchesInventory(
  MarketIndex index,
  MarketCharacter character,
  SearchQuery query,
) {
  final minimum = query.minAnecdotes;
  if (minimum != null) {
    final anecdotes = character.anecdotes;
    if (anecdotes == null || anecdotes.done < minimum) return false;
  }

  final minRealm = query.minRealm;
  if (minRealm != null) {
    final realm = CelestialRealm.parse(character.realm);
    if (realm == null || realm.ordinal < minRealm) return false;
  }

  // A path that was never read is neither. Sorting an unknown into one half
  // would put it under somebody's filter without having measured it.
  if (query.path != null && character.path != query.path) return false;

  final runes = query.runes;
  if (runes != null &&
      _runesMatching(index, character, runes) < runes.minimum) {
    return false;
  }

  for (final pet in query.pets) {
    // Same rule as a counted name the collection never met: nobody has it, so
    // nobody passes. Skipping it would widen the search under the visitor's
    // own filter.
    final itemId = index.countedItems[pet];
    if (itemId == null) return false;
    if ((character.counts[itemId] ?? 0) < 1) return false;
  }

  return true;
}

/// How many of the character's runes answer [criterion].
///
/// Counted through `index.runes` rather than off the ids, because the same
/// rune exists under two item ids — Áurea 5 is both 52179 and 200359 — and
/// comparing ids would count one kind as two.
int _runesMatching(
  MarketIndex index,
  MarketCharacter character,
  RuneCriterion criterion,
) {
  var found = 0;
  for (final itemId in character.runes) {
    final kind = index.runes[itemId];
    if (kind == null) continue;
    if (kind.level < criterion.minimumLevel) continue;
    if (criterion.type != null && kind.type != criterion.type) continue;
    found++;
  }
  return found;
}

/// Cards are read off the six the character wears, never the collection.
bool _matchesCards(MarketCharacter character, SearchQuery query) {
  if (query.comboName == null &&
      query.cardRarity == null &&
      !query.cardsMaxed) {
    return true;
  }
  // No cards read means the answer is "not known", and an unknown must not
  // pass a filter that asks for something specific.
  if (character.cards.isEmpty) return false;

  if (query.cardsMaxed && !character.cards.every((c) => c.isMaxed)) {
    return false;
  }
  if (query.cardRarity != null &&
      !character.cards.every((c) => c.rarity == query.cardRarity)) {
    return false;
  }
  if (query.comboName != null) {
    final combo = cardCombos
        .where((c) => c.name == query.comboName)
        .firstOrNull;
    if (combo == null) return false;
    final worn = character.cards.map((c) => c.cardId).toSet();
    // Complete only: every card of the combo, which for a six-card set worn in
    // six slots also means nothing else.
    if (!worn.containsAll(combo.cardIds)) return false;
  }
  return true;
}

/// The worn item that satisfies [criterion], or null when none does.
///
/// The results screen uses this to say *which* piece answered a criterion. It
/// exists so the card and the filter cannot drift apart: a card naming an item
/// the filter did not accept would be worse than a card naming nothing.
///
/// When the criterion names an attribute, the item giving the most of it wins.
EquippedItem? bestMatchFor(
  MarketIndex index,
  MarketCharacter character,
  ItemCriterion criterion,
) {
  EquippedItem? best;
  var bestValue = -1;

  for (final item in character.equipped) {
    if (!_satisfies(index, item, criterion)) continue;
    final value = criterion.attributeId == null
        ? 0
        : item.attributes[criterion.attributeId] ?? 0;
    if (best == null || value > bestValue) {
      best = item;
      bestValue = value;
    }
  }
  return best;
}

/// Every condition is read off the **same** item. Checking the refine against
/// one piece and the attribute against another in the same slot would let a
/// spare vouch for the one being worn.
bool _satisfies(MarketIndex index, EquippedItem item, ItemCriterion criterion) {
  if (criterion.slot != null && item.slot != criterion.slot) return false;
  if (item.refine < criterion.minimumRefine) return false;

  if (criterion.minimumRank > 0) {
    final rank = index.items[item.itemId]?.rank ?? 0;
    if (rank < criterion.minimumRank) return false;
  }

  // No attribute chosen means the criterion is about the item itself — its
  // slot, its rank, its refine. "Any attribute above 70" would mix attack
  // level with HP and mean nothing, but "a rank 4 weapon at +11" is a real
  // question and used to be unsayable.
  if (criterion.attributeId == null) return true;

  final value = item.attributes[criterion.attributeId];
  return value != null && value >= criterion.minimum;
}
