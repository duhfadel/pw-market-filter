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
  });
  return matches;
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
bool _satisfies(
  MarketIndex index,
  EquippedItem item,
  ItemCriterion criterion,
) {
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
