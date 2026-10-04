import 'detail_parser.dart';

/// Everything one detail page yielded, in the shape the collector's state file
/// keeps it.
///
/// **Raw is the point.** The state is what lets `--rebuild` answer a new
/// question in seconds instead of a fresh crawl of the whole market, so it
/// stores what the page said and not what the index needs. Two re-collections
/// were already paid for storing something already reduced — and a third for
/// storing nothing at all, since `require_level` was parsed, carried into a
/// live index, and dropped here.
///
/// It lives in `lib/` rather than beside the file that writes it because a
/// codec is not disk: here the round trip has a test, and the one thing that
/// cannot be recovered cheaply is the one thing worth pinning.
class CollectedPage {
  const CollectedPage({
    required this.items,
    required this.cards,
    required this.sex,
    this.anecdotes,
    this.inventory = const [],
    this.realm = '',
    this.path = '',
    this.runes = const [],
    this.titles,
  });

  /// What this reader knows how to write, **per marketplace**. An entry
  /// stamped with anything else — or with nothing, which is every entry
  /// written before the inventory existed — is stale, and the collector
  /// fetches its page again.
  ///
  /// A stamp, and not "is the anecdotes key there?": a page may legitimately
  /// have no anecdote panel, and that character would then be re-fetched on
  /// every run for ever.
  ///
  /// **One number per version, and that is what makes a new field affordable.**
  /// A single shared stamp meant adding a field only one marketplace publishes
  /// re-crawled the other for nothing: measured on 2026-10-04, the 1.2.6 asked
  /// for its slot counts, its pets and its crafting skills, and none of the
  /// three exists on a 1.8.7 page — so bumping one number would have spent
  /// eighty-four minutes of their server's traffic to learn nothing. The cost
  /// of a field should fall on the version that gains it.
  static const versoes = <String, int>{'pw187': 4, 'pw126': 5};

  /// The stamp a page collected from [servidor] carries.
  static int versaoDe(String servidor) => versoes[servidor] ?? 0;

  final List<ParsedItem> items;
  final List<ParsedCard> cards;
  final String sex;
  final ParsedAnecdotes? anecdotes;

  /// Everything the character owns, not only the counted items. With the whole
  /// list here, adding a counted item costs `--rebuild` and no network.
  final List<ParsedStack> inventory;

  /// The `Reino Celestial` row, raw. Reduced to a position only in the app,
  /// because the order of the ten realms is a fact about the game — and one
  /// that had to be asked, since the page lists them in a different sequence.
  /// Getting it wrong later must cost a rebuild, never a crawl.
  final String realm;

  /// `God` or `Evil`, from the eruption skill. Empty when the page has neither.
  final String path;

  /// The runes he has set, whole — kind, level, slot and the skill each sits
  /// on. The index keeps only what a filter needs; this keeps what a future
  /// question might.
  final List<ParsedRune> runes;

  /// The `Títulos` panel's summary, and the founder title if there is one.
  ///
  /// Null when the page carried no panel, which is not the same as a
  /// character holding no titles — [ParsedTitles] says why.
  ///
  /// The founder rung is **not** stored: `founder` keeps the name the page
  /// printed and the ladder is read in the app, so correcting the ladder is
  /// `--rebuild` rather than another crawl. Same bargain as [realm].
  final ParsedTitles? titles;

  static bool isCurrent(Map<String, dynamic> json, String servidor) =>
      json['v'] == versaoDe(servidor);

  Map<String, dynamic> toJson(String servidor) => {
    'v': versaoDe(servidor),
    'items': items.map(_itemToJson).toList(),
    'cards': cards.map(_cardToJson).toList(),
    'sex': sex,
    if (anecdotes != null)
      'anecdotes': {
        'done': anecdotes!.done,
        'total': anecdotes!.total,
        'lines': anecdotes!.lines,
      },
    // Ids to counts. The names live once, in the table [itemNamesOf] builds —
    // repeating three hundred of them per character would be most of the file
    // and none of the information.
    'inventory': {
      for (final stack in inventory) stack.itemId.toString(): stack.count,
    },
    if (realm.isNotEmpty) 'realm': realm,
    if (path.isNotEmpty) 'path': path,
    if (runes.isNotEmpty) 'runes': runes.map(_runeToJson).toList(),
    if (titles != null) 'titles': _titlesToJson(titles!),
  };

  /// [names] is the state's shared id-to-name table.
  factory CollectedPage.fromJson(
    Map<String, dynamic> json,
    Map<int, String> names,
  ) {
    final anecdotes = json['anecdotes'] as Map<String, dynamic>?;

    return CollectedPage(
      items: (json['items'] as List<dynamic>)
          .map((i) => _itemFromJson(i as Map<String, dynamic>))
          .toList(),
      cards: (json['cards'] as List<dynamic>? ?? const [])
          .map((c) => _cardFromJson(c as Map<String, dynamic>))
          .toList(),
      sex: json['sex'] as String? ?? '',
      anecdotes: anecdotes == null
          ? null
          : ParsedAnecdotes(
              done: anecdotes['done'] as int,
              total: anecdotes['total'] as int,
              lines: anecdotes['lines'] as int? ?? 0,
            ),
      inventory: [
        for (final entry
            in (json['inventory'] as Map<String, dynamic>? ?? const {}).entries)
          ParsedStack(
            itemId: int.parse(entry.key),
            name: names[int.parse(entry.key)] ?? '',
            count: entry.value as int,
          ),
      ],
      realm: json['realm'] as String? ?? '',
      path: json['path'] as String? ?? '',
      runes: (json['runes'] as List<dynamic>? ?? const [])
          .map((r) => _runeFromJson(r as Map<String, dynamic>))
          .toList(),
      titles: json['titles'] == null
          ? null
          : _titlesFromJson(json['titles'] as Map<String, dynamic>),
    );
  }
}

/// One id-to-name table for a whole state file.
///
/// The same three hundred item names repeat in every character's inventory,
/// and writing them out per character is most of the file for no information
/// at all.
Map<int, String> itemNamesOf(Iterable<CollectedPage> pages) {
  final names = <int, String>{};
  for (final page in pages) {
    for (final stack in page.inventory) {
      if (stack.name.isNotEmpty) names[stack.itemId] = stack.name;
    }
  }
  return names;
}

Map<String, dynamic> _itemToJson(ParsedItem item) => {
  'slot': item.slot,
  'itemId': item.itemId,
  'grade': item.grade,
  'name': item.name,
  'refine': item.refine,
  'stones': item.stones,
  'attributes': item.attributes,
  'requireLevel': item.requireLevel,
  'weaponLevel': item.weaponLevel,
};

ParsedItem _itemFromJson(Map<String, dynamic> json) => ParsedItem(
  slot: json['slot'] as int,
  itemId: json['itemId'] as int,
  grade: json['grade'] as int,
  name: json['name'] as String,
  refine: json['refine'] as int,
  stones: (json['stones'] as List<dynamic>).cast<int>(),
  attributes: (json['attributes'] as Map<String, dynamic>).map(
    (key, value) => MapEntry(key, (value as List<dynamic>).cast<int>()),
  ),
  requireLevel: json['requireLevel'] as int? ?? 0,
  weaponLevel: json['weaponLevel'] as int? ?? 0,
);

Map<String, dynamic> _titlesToJson(ParsedTitles titles) => {
  'decoded': titles.decoded,
  'inOctet': titles.inOctet,
  if (titles.equipped.isNotEmpty) 'equipped': titles.equipped,
  if (titles.attributes.isNotEmpty) 'attributes': titles.attributes,
  if (titles.founder.isNotEmpty) 'founder': titles.founder,
};

ParsedTitles _titlesFromJson(Map<String, dynamic> json) => ParsedTitles(
  decoded: json['decoded'] as int? ?? 0,
  inOctet: json['inOctet'] as int? ?? 0,
  equipped: json['equipped'] as String? ?? '',
  attributes: (json['attributes'] as Map<String, dynamic>? ?? const {}).map(
    (key, value) => MapEntry(key, value as int),
  ),
  founder: json['founder'] as String? ?? '',
);

Map<String, dynamic> _runeToJson(ParsedRune rune) => {
  'slot': rune.slot,
  'itemId': rune.itemId,
  'type': rune.type,
  'level': rune.level,
  'skillId': rune.skillId,
  'skillName': rune.skillName,
};

ParsedRune _runeFromJson(Map<String, dynamic> json) => ParsedRune(
  slot: json['slot'] as int,
  itemId: json['itemId'] as int,
  type: json['type'] as String,
  level: json['level'] as int,
  skillId: json['skillId'] as int? ?? 0,
  skillName: json['skillName'] as String? ?? '',
);

Map<String, dynamic> _cardToJson(ParsedCard card) => {
  'cardId': card.cardId,
  'name': card.name,
  'rarity': card.rarity,
  'type': card.type,
  'level': card.level,
  'maxLevel': card.maxLevel,
};

ParsedCard _cardFromJson(Map<String, dynamic> json) => ParsedCard(
  cardId: json['cardId'] as int,
  name: json['name'] as String,
  rarity: json['rarity'] as String,
  type: json['type'] as String,
  level: json['level'] as int,
  maxLevel: json['maxLevel'] as int,
);
