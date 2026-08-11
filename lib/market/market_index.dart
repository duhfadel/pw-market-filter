import 'item_rank.dart';

/// The offline snapshot of the marketplace — the only thing the collector and
/// the app share.
///
/// Attribute names are interned in [attributes] and referenced by position,
/// and item names live once in [items]. Without that, the same forty strings
/// would repeat across eleven thousand equipped items.
class MarketIndex {
  const MarketIndex({
    required this.server,
    required this.collectedAt,
    required this.attributes,
    required this.items,
    required this.characters,
  });

  final String server;
  final DateTime collectedAt;

  /// The attribute vocabulary. An [EquippedItem] refers to an entry by its
  /// index in this list.
  final List<String> attributes;

  /// Item id to name and grade.
  final Map<int, MarketItem> items;

  final List<MarketCharacter> characters;

  static const _formatVersion = 1;

  Map<String, dynamic> toJson() => {
    'formatVersion': _formatVersion,
    'server': server,
    'collectedAt': collectedAt.toUtc().toIso8601String(),
    'attributes': attributes,
    'items': {
      for (final entry in items.entries)
        entry.key.toString(): entry.value.toJson(),
    },
    'characters': characters.map((c) => c.toJson()).toList(),
  };

  /// Throws [IndexFormatException] naming the field it could not read, so the
  /// app can say what is wrong instead of opening empty.
  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    final version = json['formatVersion'];
    if (version != _formatVersion) {
      throw IndexFormatException(
        'formatVersion',
        'esperava $_formatVersion, veio $version',
      );
    }

    return MarketIndex(
      server: _string(json, 'server'),
      collectedAt: DateTime.parse(_string(json, 'collectedAt')).toUtc(),
      attributes: _list(json, 'attributes').cast<String>(),
      items: {
        for (final entry in _map(json, 'items').entries)
          int.parse(entry.key): MarketItem.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
      characters: _list(json, 'characters')
          .map((c) => MarketCharacter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MarketItem {
  const MarketItem({required this.name, required this.grade});

  final String name;
  final int grade;

  /// Derived, never stored: the stars are already in [name], and a second copy
  /// of the same fact is a second thing that can go stale.
  int get rank => rankFromName(name);

  Map<String, dynamic> toJson() => {'name': name, 'grade': grade};

  factory MarketItem.fromJson(Map<String, dynamic> json) =>
      MarketItem(name: _string(json, 'name'), grade: _int(json, 'grade'));
}

class MarketCharacter {
  const MarketCharacter({
    required this.roleId,
    required this.name,
    required this.characterClass,
    required this.occupation,
    required this.level,
    required this.price,
    required this.fame,
    required this.cultivation,
    required this.equipped,
    this.sex = '',
    this.cards = const [],
  });

  final int roleId;
  final String name;
  final String characterClass;
  final int occupation;
  final int level;
  final int price;
  final int fame;
  final String cultivation;
  final List<EquippedItem> equipped;

  /// `Masculino`, `Feminino`, or empty when this index predates the field.
  final String sex;

  /// The six equipped War Avatar cards — never the whole collection.
  final List<EquippedCard> cards;

  Map<String, dynamic> toJson() => {
    'roleId': roleId,
    'name': name,
    'class': characterClass,
    'occupation': occupation,
    'level': level,
    'price': price,
    'fame': fame,
    'cultivation': cultivation,
    if (sex.isNotEmpty) 'sex': sex,
    'equipped': equipped.map((e) => e.toJson()).toList(),
    if (cards.isNotEmpty) 'cards': cards.map((c) => c.toJson()).toList(),
  };

  factory MarketCharacter.fromJson(Map<String, dynamic> json) =>
      MarketCharacter(
        roleId: _int(json, 'roleId'),
        name: _string(json, 'name'),
        characterClass: _string(json, 'class'),
        occupation: _int(json, 'occupation'),
        level: _int(json, 'level'),
        price: _int(json, 'price'),
        fame: _int(json, 'fame'),
        cultivation: _string(json, 'cultivation'),
        sex: json['sex'] as String? ?? '',
        equipped: _list(
          json,
          'equipped',
        ).map((e) => EquippedItem.fromJson(e as Map<String, dynamic>)).toList(),
        cards: (json['cards'] as List<dynamic>? ?? const [])
            .map((c) => EquippedCard.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

/// One of the six War Avatar cards a character wears.
class EquippedCard {
  const EquippedCard({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.type,
    required this.level,
    required this.maxLevel,
  });

  final int cardId;
  final String name;

  /// `S`, `A` or `B`.
  final String rarity;

  /// One of six: Destruidor, Batalha, Durabilidade, Alma Primordial, Vida
  /// Primordial, Longevidade. A character wears exactly one of each.
  final String type;

  final int level;
  final int maxLevel;

  /// A card at its cap. Owning one and having it finished are different
  /// things — a character was found with ten S cards, nine of them at 1/80.
  bool get isMaxed => maxLevel > 0 && level >= maxLevel;

  Map<String, dynamic> toJson() => {
    'card': cardId,
    'name': name,
    'rarity': rarity,
    'type': type,
    'level': level,
    'maxLevel': maxLevel,
  };

  factory EquippedCard.fromJson(Map<String, dynamic> json) => EquippedCard(
    cardId: _int(json, 'card'),
    name: _string(json, 'name'),
    rarity: _string(json, 'rarity'),
    type: _string(json, 'type'),
    level: _int(json, 'level'),
    maxLevel: _int(json, 'maxLevel'),
  );
}

class EquippedItem {
  const EquippedItem({
    required this.slot,
    required this.itemId,
    required this.refine,
    required this.stones,
    required this.attributes,
    this.requireLevel = 0,
  });

  final int slot;
  final int itemId;
  final int refine;
  final List<int> stones;

  /// Index into [MarketIndex.attributes] to the value this item gives. An
  /// attribute the item carries twice was already summed by the collector.
  final Map<int, int> attributes;

  /// The level the piece demands: 60, 80, 100 or 105. Zero when the index
  /// predates the field.
  final int requireLevel;

  Map<String, dynamic> toJson() => {
    'slot': slot,
    'item': itemId,
    'refine': refine,
    if (requireLevel > 0) 'requireLevel': requireLevel,
    if (stones.isNotEmpty) 'stones': stones,
    if (attributes.isNotEmpty)
      'attributes': {
        for (final entry in attributes.entries)
          entry.key.toString(): entry.value,
      },
  };

  factory EquippedItem.fromJson(Map<String, dynamic> json) => EquippedItem(
    slot: _int(json, 'slot'),
    itemId: _int(json, 'item'),
    refine: _int(json, 'refine'),
    requireLevel: json['requireLevel'] as int? ?? 0,
    stones: (json['stones'] as List<dynamic>? ?? const []).cast<int>(),
    attributes: {
      for (final entry
          in (json['attributes'] as Map<String, dynamic>? ?? const {}).entries)
        int.parse(entry.key): entry.value as int,
    },
  );
}

/// Names the field that could not be read. A silent `null` here would open the
/// app on an empty market and look like "nobody matches".
class IndexFormatException implements Exception {
  const IndexFormatException(this.field, this.detail);

  final String field;
  final String detail;

  @override
  String toString() => 'Campo "$field" do índice não pôde ser lido: $detail';
}

String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) {
    throw IndexFormatException(field, 'esperava texto, veio $value');
  }
  return value;
}

int _int(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! int) {
    throw IndexFormatException(field, 'esperava número, veio $value');
  }
  return value;
}

List<dynamic> _list(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! List) {
    throw IndexFormatException(field, 'esperava lista, veio $value');
  }
  return value;
}

Map<String, dynamic> _map(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! Map<String, dynamic>) {
    throw IndexFormatException(field, 'esperava objeto, veio $value');
  }
  return value;
}
