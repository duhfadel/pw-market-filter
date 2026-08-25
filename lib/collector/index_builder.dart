import '../market/counted_items.dart';
import '../market/market_index.dart';
import 'detail_parser.dart';
import 'listing_parser.dart';

/// How an attribute listed more than once on the same item becomes one number.
///
/// The rule is about the game, not about parsing, which is why it lives here
/// and not in the reader: with the occurrences kept in the collector's state
/// file, changing a rule is a rebuild in seconds rather than a fresh crawl of
/// all 771 pages.
enum AttributeRule {
  /// The bonuses stack. `HP +500`, `+150`, `+150` is an item giving 800 HP.
  total,

  /// The largest line is the real one and the rest are minor rolls beside it.
  /// A weapon reading `Nível de Ataque +70` and then `+1` is a 70 — the extra
  /// point does not make it a different, better weapon, and calling it 71 puts
  /// it above every genuine 70 in the list.
  principal,
}

/// Attributes that do not stack. Everything absent from this map totals.
const attributeRules = <String, AttributeRule>{
  'Nível de Ataque': AttributeRule.principal,
  'Nível de Defesa': AttributeRule.principal,
  'Nível de Guarda': AttributeRule.principal,
};

int reduceAttribute(String name, List<int> occurrences) =>
    switch (attributeRules[name] ?? AttributeRule.total) {
      AttributeRule.total => occurrences.fold(0, (a, b) => a + b),
      AttributeRule.principal => occurrences.reduce((a, b) => a > b ? a : b),
    };

/// Turns what the parsers read into the index the app consumes.
///
/// This is where attribute names stop being strings and become positions in a
/// shared vocabulary, where item names stop repeating once per wearer, and
/// where [attributeRules] turns a list of occurrences into one number.
class IndexBuilder {
  IndexBuilder({required this.server, required this.collectedAt});

  final String server;
  final DateTime collectedAt;

  final _attributeIds = <String, int>{};
  final _items = <int, MarketItem>{};
  final _characters = <MarketCharacter>[];

  /// Filled as the collection meets each name. See [countedItemNames] for why
  /// the resolution runs this way round rather than from a table of ids.
  final _countedIds = <String, int>{};

  /// The count maps of every character whose inventory was read, held so
  /// [build] can finish them.
  ///
  /// They cannot be finished on the way in: a name is resolved the first time
  /// the crawl meets it, so a character read before anyone was seen carrying
  /// the relic does not yet know the id to write a zero under. These are the
  /// same map objects the characters hold, so filling them here fills theirs.
  final _readCounts = <Map<int, int>>[];

  /// Adds one character. [items] is what the detail page yielded; a character
  /// whose page failed to load is simply never added.
  void add(
    ListingCard card,
    List<ParsedItem> items, {
    String sex = '',
    List<ParsedCard> cards = const [],
    ParsedAnecdotes? anecdotes,
    List<ParsedStack> inventory = const [],
  }) {
    _characters.add(
      MarketCharacter(
        roleId: card.roleId,
        name: card.name,
        characterClass: card.characterClass,
        occupation: card.occupation,
        level: card.level,
        price: card.price,
        fame: card.fame,
        cultivation: card.cultivation,
        sex: sex,
        anecdotes: anecdotes == null
            ? null
            : Anecdotes(done: anecdotes.done, total: anecdotes.total),
        counts: _countsIn(inventory),
        equipped: items.map(_convert).toList(growable: false),
        cards: cards
            .map(
              (c) => EquippedCard(
                cardId: c.cardId,
                name: c.name,
                rarity: c.rarity,
                type: c.type,
                level: c.level,
                maxLevel: c.maxLevel,
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  /// The counted items out of a whole inventory, and nothing else.
  ///
  /// The character owns hundreds of distinct items; four of them are asked
  /// about. Carrying the rest would put a second inventory in the index for
  /// the sake of four numbers — and the raw list is already in the collector's
  /// state, where a new question costs `--rebuild` and no network.
  Map<int, int> _countsIn(List<ParsedStack> inventory) {
    final counts = <int, int>{};

    // An inventory that was read and holds none of them still answers the
    // question — with zero. Only a page that never loaded says nothing, and
    // the card tells the two apart: `carrega 0` against no line at all.
    if (inventory.isNotEmpty) _readCounts.add(counts);

    for (final stack in inventory) {
      // Two ways in, and they are opposite on purpose. A counted item is found
      // by its name, because its id was unknown; a pet is found by its id,
      // because its name belongs to whoever owns it. See `counted_items.dart`.
      final label = _labelFor(stack);
      if (label == null) continue;

      // First sighting names the id, exactly as items do. Two ids under one
      // label would leave the second one's owners failing a filter silently,
      // which is what `counted_items_test.dart` checks for.
      _countedIds.putIfAbsent(label, () => stack.itemId);
      if (_countedIds[label] == stack.itemId) {
        counts[stack.itemId] = stack.count;
      }
    }
    return counts;
  }

  /// What this stack is called in the index, or null when it is one of the
  /// hundreds of things nobody asked about.
  String? _labelFor(ParsedStack stack) {
    if (countedItemNames.contains(stack.name)) return stack.name;
    for (final entry in countedItemIds.entries) {
      if (entry.value == stack.itemId) return entry.key;
    }
    return null;
  }

  EquippedItem _convert(ParsedItem item) {
    if (item.itemId > 0) {
      // First wearer wins. The name and grade belong to the item, not to the
      // character, so a later disagreement would be the parser misreading one
      // of them — not two different truths.
      _items.putIfAbsent(
        item.itemId,
        () => MarketItem(name: item.name, grade: item.grade),
      );
    }

    return EquippedItem(
      slot: item.slot,
      itemId: item.itemId,
      refine: item.refine,
      requireLevel: item.requireLevel,
      stones: item.stones,
      attributes: {
        for (final entry in item.attributes.entries)
          if (entry.value.isNotEmpty)
            _attributeId(entry.key): reduceAttribute(entry.key, entry.value),
      },
    );
  }

  int _attributeId(String name) =>
      _attributeIds.putIfAbsent(name, () => _attributeIds.length);

  MarketIndex build() {
    for (final counts in _readCounts) {
      for (final id in _countedIds.values) {
        counts.putIfAbsent(id, () => 0);
      }
    }

    final attributes = List<String>.filled(_attributeIds.length, '');
    for (final entry in _attributeIds.entries) {
      attributes[entry.value] = entry.key;
    }

    return MarketIndex(
      server: server,
      collectedAt: collectedAt,
      attributes: attributes,
      items: _items,
      characters: _characters,
      countedItems: _countedIds,
    );
  }
}
