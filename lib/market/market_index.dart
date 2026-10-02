import 'item_rank.dart';
import 'price_history.dart';

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
    this.countedItems = const {},
    this.runes = const {},
    this.historyFrom,
  });

  final String server;
  final DateTime collectedAt;

  /// The attribute vocabulary. An [EquippedItem] refers to an entry by its
  /// index in this list.
  final List<String> attributes;

  /// Item id to name and grade.
  final Map<int, MarketItem> items;

  final List<MarketCharacter> characters;

  /// Each counted label to **every** id this collection found under it.
  ///
  /// A name from `countedItemNames` that no character carried is simply absent
  /// — the market has none, so there is nothing to filter on and no field to
  /// put on screen. Empty on an index collected before the counts existed.
  ///
  /// **It is a list because one label is genuinely several ids**, and binding
  /// it to the first one met dropped the rest in silence: their owners failed
  /// the filter and nothing on screen said why. Two items are called
  /// *Essência Dracônica* (50264 and 63051), and a group gathers several names
  /// besides — see `countedItemGroups`. Read it through [countOf], never by
  /// taking `.first`.
  final Map<String, List<int>> countedItems;

  /// Every rune the market wears, by item id.
  ///
  /// A table rather than a copy on each character, for the reason the item
  /// names are one: the same six kinds repeat across a thousand people. It
  /// also settles a trap — `Áurea 5` exists under two ids (`52179` and
  /// `200359`, serving byte-identical art), so a filter that compared ids
  /// would treat one rune as two. Through this table both read as Áurea 5.
  final Map<int, RuneKind> runes;

  /// The first collection that kept records, or `null` before any did.
  ///
  /// **This is what stops the site announcing 1519 arrivals on day one.** On
  /// the first run with history every character gets a `firstSeen` of today,
  /// which means *first sighting*, not *new listing*. Only a character whose
  /// `firstSeen` is after this date genuinely arrived while we were watching;
  /// the rest are unknown, and unknown is never dressed up as new.
  final DateTime? historyFrom;

  /// How many of [label] this character carries, added across every id and
  /// every name the label gathers.
  ///
  /// **`null` and `0` are different answers and both matter.** `null` is a
  /// page that was never read, or a label this market has none of; `0` is a
  /// character who was read and carries none. The card prints `carrega 0` for
  /// the second and draws no line at all for the first, and collapsing them
  /// would turn "we do not know" into "he has none".
  ///
  /// This is the one place the arithmetic lives. The card and the matcher both
  /// call it, for the reason `bestMatchFor` exists: a card naming a number the
  /// filter did not use is worse than a card naming nothing.
  int? countOf(MarketCharacter character, String label) {
    final ids = countedItems[label];
    if (ids == null) return null;

    int? total;
    for (final id in ids) {
      final count = character.counts[id];
      if (count == null) continue;
      total = (total ?? 0) + count;
    }
    return total;
  }

  static const _formatVersion = 2;

  /// Versions this build knows how to read. **Two, not one**, and the older
  /// is not politeness: the first run of the history code fetches an index
  /// published at version 1, and the app has to open on whatever collection
  /// last landed. A version nobody wrote is still refused, because that is a
  /// file we cannot reason about.
  static const _readableVersions = {1, 2};

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
    if (countedItems.isNotEmpty) 'countedItems': countedItems,
    if (runes.isNotEmpty)
      'runes': {
        for (final entry in runes.entries)
          entry.key.toString(): entry.value.toJson(),
      },
    if (historyFrom != null)
      'historyFrom': historyFrom!.toUtc().toIso8601String(),
  };

  /// Throws [IndexFormatException] naming the field it could not read, so the
  /// app can say what is wrong instead of opening empty.
  factory MarketIndex.fromJson(Map<String, dynamic> json) {
    final version = json['formatVersion'];
    if (!_readableVersions.contains(version)) {
      throw IndexFormatException(
        'formatVersion',
        'esperava um de $_readableVersions, veio $version',
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
      countedItems: (json['countedItems'] as Map<String, dynamic>? ?? const {})
          .map(
            // An index written before a label could hold several ids says
            // `"name": 54687` rather than `"name": [54687]`. It is still a
            // true answer about that market, and the site serves whatever
            // collection last landed — so it is read, not rejected.
            (name, ids) => MapEntry(name, <int>[
              if (ids is int) ids else ...(ids as List).cast<int>(),
            ]),
          ),
      runes: {
        for (final entry
            in (json['runes'] as Map<String, dynamic>? ?? const {}).entries)
          int.parse(entry.key): RuneKind.fromJson(
            entry.value as Map<String, dynamic>,
          ),
      },
      historyFrom: json['historyFrom'] == null
          ? null
          : DateTime.parse(json['historyFrom'] as String).toUtc(),
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
    this.anecdotes,
    this.counts = const {},
    this.realm = '',
    this.path = '',
    this.runes = const [],
    this.founderTier,
    this.history,
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

  /// How far through the game's anecdotes this character is, or `null` when
  /// the page was read before the field existed.
  ///
  /// Null and not `0/0`: a character who has completed nothing is a claim, and
  /// an unread page makes none. A filter treats the two differently.
  final Anecdotes? anecdotes;

  /// Item id to how many of it the character owns, for the items in
  /// `MarketIndex.countedItems` and no others.
  ///
  /// An empty map is "carries none of them" and also "the inventory was never
  /// read". Both fail a *pelo menos N* filter, which is the same answer either
  /// way, so nothing is lost by not telling them apart.
  final Map<int, int> counts;

  /// The `Reino Celestial` row, exactly as the site wrote it — `Céu Ápice
  /// VIII`. Empty when the page was read before the field existed, or did not
  /// say. `CelestialRealm.parse` turns it into a position on the scale.
  final String realm;

  /// `God`, `Evil`, or empty when unknown — read off whether the character has
  /// `Erupção Celestial` or `Erupção Demoníaca`, since the sheet has no field
  /// for it. Empty is not a third path: it is a character too low to have
  /// chosen, or a page read before this was collected.
  final String path;

  /// The runes he has set, by item id, in slot order. Six is common and nine
  /// exists; an empty list is a character with none, which is real.
  final List<int> runes;

  /// Which founder pack this character's title came from — 1 to 10 for
  /// `Fundador I` through `Fundador X` — or `null` for everybody else.
  ///
  /// Null rather than zero, and the distinction is the whole honesty of the
  /// control: zero would read as a rung, and "has no founder title" is not
  /// rung nought. It is also null on every index collected before 2026-10-02,
  /// which is the same answer a filter wants from both.
  ///
  /// A rung here and the raw name in the state: the ladder is a fact about
  /// the game, so reading it wrong is a `--rebuild`, never another crawl.
  final int? founderTier;

  /// What the market remembers about this character between collections, or
  /// `null` where no collection has recorded it yet.
  final PriceHistory? history;

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
    if (anecdotes != null) 'anecdotes': anecdotes!.toJson(),
    if (counts.isNotEmpty)
      'counts': {
        for (final entry in counts.entries) entry.key.toString(): entry.value,
      },
    if (realm.isNotEmpty) 'realm': realm,
    if (path.isNotEmpty) 'path': path,
    if (runes.isNotEmpty) 'runes': runes,
    // Omitted rather than written null: almost nobody is a founder, and
    // 1.600 nulls are weight the browser downloads to learn nothing.
    if (founderTier != null) 'founderTier': founderTier,
    if (history != null) 'history': history!.toJson(),
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
        anecdotes: json['anecdotes'] == null
            ? null
            : Anecdotes.fromJson(json['anecdotes'] as Map<String, dynamic>),
        counts: {
          for (final entry
              in (json['counts'] as Map<String, dynamic>? ?? const {}).entries)
            int.parse(entry.key): entry.value as int,
        },
        realm: json['realm'] as String? ?? '',
        path: json['path'] as String? ?? '',
        runes: (json['runes'] as List<dynamic>? ?? const []).cast<int>(),
        founderTier: json['founderTier'] as int?,
        history: json['history'] == null
            ? null
            : PriceHistory.fromJson(json['history'] as Map<String, dynamic>),
      );
}

/// What a rune is, independent of which copy of it somebody owns.
class RuneKind {
  const RuneKind({required this.type, required this.level});

  /// `Argêntea`, `Áurea`, `Celeste`, `Escarlate` or `Verdejante`. A category
  /// and not a grade: every colour was seen from level 4 to 9.
  final String type;

  final int level;

  Map<String, dynamic> toJson() => {'type': type, 'level': level};

  factory RuneKind.fromJson(Map<String, dynamic> json) =>
      RuneKind(type: _string(json, 'type'), level: _int(json, 'level'));
}

/// A character's progress through the game's anecdotes.
///
/// [total] is the game's number, not the character's, and it is stored per
/// character anyway: it is two bytes against a megabyte, and an index that
/// carries the pair the site printed cannot disagree with the site.
class Anecdotes {
  const Anecdotes({required this.done, required this.total});

  final int done;
  final int total;

  /// How much of it is finished, rounded. `1265 de 2756` is a division nobody
  /// does in their head while scanning a grid of forty cards, and [total] is
  /// the same number for everybody — so the share is the part that separates
  /// one character from another at a glance.
  int get percent => total == 0 ? 0 : (done * 100 / total).round();

  Map<String, dynamic> toJson() => {'done': done, 'total': total};

  factory Anecdotes.fromJson(Map<String, dynamic> json) =>
      Anecdotes(done: _int(json, 'done'), total: _int(json, 'total'));
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
