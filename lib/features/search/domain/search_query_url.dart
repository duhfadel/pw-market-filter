/// A search written as a query string, and read back from one.
///
/// This exists so a finding can be sent to somebody. Before it, the only thing
/// anyone could share was the site — and "there is a filter over there" is a
/// far weaker message than "here are the fourteen characters with a 70 weapon
/// under 500 TCC".
///
/// The parameters are readable on purpose rather than a single encoded blob:
/// the link pasted into a group already says what it does, which is half of
/// why anyone clicks it.
///
/// The two halves are deliberately asymmetric. Encoding writes only what was
/// asked; decoding forgives everything, because the input is a link somebody
/// saved a month ago, pointing at an item that may have left the market, in a
/// format this version may no longer write. A shared link that opens the wrong
/// filter is a disappointment; one that opens an error is a dead end.
///
/// **The attribute travels by name, and that is the whole reason [index] is
/// here.** `ItemCriterion.attributeId` is a position in
/// `MarketIndex.attributes`, and the collector hands out those positions in
/// the order it happens to meet each attribute — so two collections a week
/// apart disagree about what "attribute 0" means. A link carrying the number
/// would go on working, go on looking right, and filter by something else
/// entirely. Everything else in a query is already a stable name or a game id:
/// classes, cultivations, combos, item ids. The attribute was the one hole.
library;

import '../../../market/market_index.dart';
import 'item_criterion.dart';
import 'search_query.dart';

const _classParam = 'classe';
const _cultivationParam = 'cultivo';
const _levelParam = 'nivel';
const _priceParam = 'preco';
const _itemParam = 'item';
const _comboParam = 'carta';
const _rarityParam = 'raridade';
const _maxedParam = 'maximas';
const _criterionParam = 'c';
const _anecdoteParam = 'anedotas';
const _ownedParam = 'tem';
const _shownParam = 'mostra';

/// What `mostra` calls the anecdotes, which are the one thing it can carry
/// that is not a counted item. Reserved rather than given a parameter of its
/// own: `mostra` means "what the card prints", and two parameters for one idea
/// would be worse. No counted item can collide with it — they are all named
/// `Relíquia …` or `Chave …` in [countedItemNames].
const _anecdotesShown = 'anedotas';
const _petParam = 'mascote';
const _orderParam = 'ordem';

/// What packs the fields of one criterion into one parameter.
///
/// A tilde and not a colon, and the difference is the whole readability of a
/// shared link. `Uri` escapes a colon and escapes the percent signs of a name
/// encoded by hand, so `Nível de Ataque` came out as
/// `%3AN%25C3%25ADvel%2520de%2520Ataque%3A` — correct, and gibberish to the
/// person deciding whether to click. A tilde is left alone, so one layer of
/// escaping is enough and the browser shows `c=10~Nível de Ataque~70~0~0`.
///
/// It also cannot appear in an attribute name. If one ever did, the criterion
/// would split into six fields and be dropped — the safe direction, and not a
/// silent misreading.
const _fieldSeparator = '~';

/// The query string without its leading `?`. Empty when nothing is being asked
/// and the order is the default one.
///
/// Without [index] the attribute is written as its raw number, which is only
/// good for comparing two queries written the same way — never for a link.
String encodeQuery(SearchQuery query, [MarketIndex? index]) {
  final params = <String, List<String>>{};

  void put(String key, String? value) {
    if (value != null) params[key] = [value];
  }

  put(_classParam, query.characterClass);
  put(_cultivationParam, query.cultivation);
  put(_levelParam, _encodeRange(query.minLevel, query.maxLevel));
  put(_priceParam, _encodeRange(query.minPrice, query.maxPrice));
  put(_comboParam, query.comboName);
  put(_rarityParam, query.cardRarity);
  if (query.cardsMaxed) put(_maxedParam, '1');
  if (query.minAnecdotes != null) {
    put(_anecdoteParam, query.minAnecdotes.toString());
  }

  // The counted item goes by name — the same reason the attribute does. The id
  // is this collection's, the name is the game's.
  final owned = query.minimumOwned.entries.where((e) => e.value > 0).toList();
  if (owned.isNotEmpty) {
    params[_ownedParam] = [
      for (final entry in owned) '${entry.key}$_fieldSeparator${entry.value}',
    ];
  }

  // Only what `tem` does not already carry: a minimum implies its own item is
  // shown, so writing both would say it twice.
  final shown = [
    // A minimum already implies its own item is shown; writing both would say
    // it twice.
    if (query.anecdotesOnCard && query.minAnecdotes == null) _anecdotesShown,
    ...query.shownOwned.where((name) => !query.minimumOwned.containsKey(name)),
  ];
  if (shown.isNotEmpty) params[_shownParam] = shown;

  if (query.pets.isNotEmpty) params[_petParam] = query.pets.toList();

  if (query.itemBySlot.isNotEmpty) {
    params[_itemParam] = [
      for (final entry in query.itemBySlot.entries)
        '${entry.key}$_fieldSeparator${entry.value}',
    ];
  }

  final criteria = query.criteria.where(_asks).toList();
  if (criteria.isNotEmpty) {
    params[_criterionParam] = [
      for (final c in criteria) _encodeCriterion(c, index),
    ];
  }

  if (query.order != ResultOrder.cheapest) {
    params[_orderParam] = [query.order.name];
  }

  if (params.isEmpty) return '';
  return Uri(queryParameters: params).query;
}

/// Reads what it recognises and silently drops the rest.
///
/// [index] resolves attribute names back to their positions in this
/// collection. Without it, criteria naming an attribute are dropped rather
/// than guessed at — see [_decodeCriterion].
SearchQuery decodeQuery(
  Map<String, List<String>> params, [
  MarketIndex? index,
]) {
  String? first(String key) {
    final values = params[key];
    if (values == null || values.isEmpty) return null;
    final value = values.first.trim();
    return value.isEmpty ? null : value;
  }

  final (minLevel, maxLevel) = _decodeRange(first(_levelParam));
  final (minPrice, maxPrice) = _decodeRange(first(_priceParam));

  final itemBySlot = <int, int>{};
  for (final entry in params[_itemParam] ?? const <String>[]) {
    final parts = entry.split(_fieldSeparator);
    if (parts.length != 2) continue;
    final slot = int.tryParse(parts[0]);
    final itemId = int.tryParse(parts[1]);
    if (slot != null && itemId != null) itemBySlot[slot] = itemId;
  }

  final minimumOwned = <String, int>{};
  for (final entry in params[_ownedParam] ?? const <String>[]) {
    final separator = entry.lastIndexOf(_fieldSeparator);
    if (separator <= 0) continue;
    final name = entry.substring(0, separator).trim();
    final minimum = int.tryParse(entry.substring(separator + 1));
    // Zero asks nothing, and a name this collection lacks is left for the
    // matcher to refuse — it is the only half that knows what the market has.
    if (name.isEmpty || minimum == null || minimum <= 0) continue;
    minimumOwned[name] = minimum;
  }

  final shownOwned = <String>{
    for (final name in params[_shownParam] ?? const <String>[])
      if (name.trim().isNotEmpty && name.trim() != _anecdotesShown) name.trim(),
  };
  final anecdotesOnCard = (params[_shownParam] ?? const <String>[])
      .map((v) => v.trim())
      .contains(_anecdotesShown);

  final pets = <String>{
    for (final name in params[_petParam] ?? const <String>[])
      if (name.trim().isNotEmpty) name.trim(),
  };

  final criteria = <ItemCriterion>[];
  for (final entry in params[_criterionParam] ?? const <String>[]) {
    final criterion = _decodeCriterion(entry, index);
    if (criterion != null && _asks(criterion)) criteria.add(criterion);
  }

  return SearchQuery(
    characterClass: first(_classParam),
    cultivation: first(_cultivationParam),
    minLevel: minLevel,
    maxLevel: maxLevel,
    minPrice: minPrice,
    maxPrice: maxPrice,
    itemBySlot: itemBySlot,
    comboName: first(_comboParam),
    cardRarity: first(_rarityParam),
    cardsMaxed: first(_maxedParam) == '1',
    minAnecdotes: int.tryParse(first(_anecdoteParam) ?? ''),
    minimumOwned: minimumOwned,
    shownOwned: shownOwned,
    anecdotesOnCard: anecdotesOnCard,
    pets: pets,
    criteria: criteria,
    order: _decodeOrder(first(_orderParam)),
  );
}

/// A criterion left at its defaults is a row being filled in, not a question.
/// Writing it into the link would share a criterion that matches everybody.
bool _asks(ItemCriterion criterion) =>
    criterion.slot != null ||
    criterion.attributeId != null ||
    criterion.minimumRefine > 0 ||
    criterion.minimumRank > 0;

String _encodeCriterion(ItemCriterion criterion, MarketIndex? index) => [
  criterion.slot?.toString() ?? '',
  _encodeAttribute(criterion.attributeId, index),
  criterion.minimum.toString(),
  criterion.minimumRefine.toString(),
  criterion.minimumRank.toString(),
].join(_fieldSeparator);

/// The attribute's name, written plainly. `Uri` does the escaping, once.
String _encodeAttribute(int? attributeId, MarketIndex? index) {
  if (attributeId == null) return '';
  if (index == null || attributeId >= index.attributes.length) {
    return attributeId.toString();
  }
  return index.attributes[attributeId];
}

ItemCriterion? _decodeCriterion(String entry, MarketIndex? index) {
  final parts = entry.split(_fieldSeparator);
  if (parts.length != 5) return null;

  final attribute = parts[1];
  if (attribute.isNotEmpty) {
    final resolved = _decodeAttribute(attribute, index);
    // The attribute was named and this collection does not have it. Dropping
    // the criterion is the honest answer: falling back to "any attribute"
    // would run a wider search under the visitor's own link, and falling back
    // to attribute zero would run a different one and call it theirs.
    if (resolved == null) return null;

    return ItemCriterion(
      slot: int.tryParse(parts[0]),
      attributeId: resolved,
      minimum: int.tryParse(parts[2]) ?? 0,
      minimumRefine: int.tryParse(parts[3]) ?? 0,
      minimumRank: int.tryParse(parts[4]) ?? 0,
    );
  }

  // An unreadable slot becomes "any", and an unreadable number becomes zero,
  // which is what "do not ask" already means for a refine and a rank.
  return ItemCriterion(
    slot: int.tryParse(parts[0]),
    minimum: int.tryParse(parts[2]) ?? 0,
    minimumRefine: int.tryParse(parts[3]) ?? 0,
    minimumRank: int.tryParse(parts[4]) ?? 0,
  );
}

/// The position this collection gives [name], or `null` if it has none.
///
/// A bare number is still read as a position, which is what keeps the two
/// index-less callers — comparing a preset against the current query — working
/// on the same terms.
int? _decodeAttribute(String name, MarketIndex? index) {
  if (index != null) {
    final position = index.attributes.indexOf(name);
    if (position >= 0) return position;
  }

  final number = int.tryParse(name);
  if (number == null) return null;
  if (index != null && number >= index.attributes.length) return null;
  return number;
}

/// `min-max`, either side allowed to be missing. `null` when neither is asked.
String? _encodeRange(int? min, int? max) {
  if (min == null && max == null) return null;
  return '${min ?? ''}-${max ?? ''}';
}

(int?, int?) _decodeRange(String? value) {
  if (value == null) return (null, null);

  final separator = value.indexOf('-');
  if (separator < 0) return (null, null);

  return (
    int.tryParse(value.substring(0, separator)),
    int.tryParse(value.substring(separator + 1)),
  );
}

ResultOrder _decodeOrder(String? name) {
  for (final order in ResultOrder.values) {
    if (order.name == name) return order;
  }
  return ResultOrder.cheapest;
}
