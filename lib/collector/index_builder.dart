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

  /// Adds one character. [items] is what the detail page yielded; a character
  /// whose page failed to load is simply never added.
  void add(ListingCard card, List<ParsedItem> items) {
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
        equipped: items.map(_convert).toList(growable: false),
      ),
    );
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
    );
  }
}
