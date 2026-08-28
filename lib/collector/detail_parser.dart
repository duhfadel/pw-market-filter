import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// One item the character is actually wearing.
///
/// Attributes are keyed by the name the site prints — including the
/// `Atributo #3818` it falls back to when it cannot name one itself. There is
/// no numeric attribute id here on purpose; see [parseEquippedItems].
///
/// Each attribute maps to **every occurrence**, in the order the tooltip lists
/// them, rather than to one reduced number. How to reduce them is a question
/// about the game, not about HTML — three `HP` lines add up to a total, while
/// `Nível de Ataque +70` followed by `+1` is a principal and a minor bonus, and
/// the weapon is a 70. Reducing here would bake one of those answers into the
/// reader and, worse, make correcting it cost a fresh collection of all 771
/// pages. [IndexBuilder] applies the rules; this only reports what was on the
/// page.
class ParsedItem {
  const ParsedItem({
    required this.slot,
    required this.itemId,
    required this.grade,
    required this.name,
    required this.refine,
    required this.stones,
    required this.attributes,
    this.requireLevel = 0,
    this.weaponLevel = 0,
  });

  ParsedItem withLevels({required int require, required int weapon}) =>
      ParsedItem(
        slot: slot,
        itemId: itemId,
        grade: grade,
        name: name,
        refine: refine,
        stones: stones,
        attributes: attributes,
        requireLevel: require,
        weaponLevel: weapon,
      );

  final int slot;
  final int itemId;
  final int grade;
  final String name;
  final int refine;
  final List<int> stones;
  final Map<String, List<int>> attributes;

  /// The level the piece demands — 60, 80, 100 or 105. Zero when unknown.
  ///
  /// This one does come from the inventory panel's JSON, joined by item id.
  /// The join is safe because no character wears two copies of the same item
  /// id, checked across the fixture; and it is worth the exception because the
  /// paper doll's tooltip does not carry it at all.
  final int requireLevel;

  /// The `weapon_level` of the same JSON, and **not** a quality rank: it is 17
  /// for every common endgame weapon, including one that gives no attack level
  /// at all. Read because the page is already open — a second crawl of the
  /// market costs fifty minutes — and kept raw in the collector's state until
  /// something turns out to want it. Zero on anything that is not a weapon.
  final int weaponLevel;
}

/// One of the six War Avatar cards a character has equipped.
///
/// Six exactly, one per [type] — Destruidor, Batalha, Durabilidade, Alma
/// Primordial, Vida Primordial, Longevidade. A "combo" is those six belonging
/// to the same named set.
class ParsedCard {
  const ParsedCard({
    required this.cardId,
    required this.name,
    required this.rarity,
    required this.type,
    required this.level,
    required this.maxLevel,
  });

  final int cardId;
  final String name;

  /// `S`, `A` or `B`, and the cap moves with it: 80, 40, 25.
  final String rarity;

  final String type;

  /// Owning a card and having it finished are different things, and the price
  /// knows the difference: one character had ten S cards, nine of them at 1/80.
  final int level;
  final int maxLevel;
}

final _slotPattern = RegExp(r'slot-(\d+)');
final _gradePattern = RegExp(r'grade-(\d+)');
final _itemIdPattern = RegExp(r'/(\d+)\.png');
final _titlePattern = RegExp(r'<strong[^>]*>(.*?)</strong>', dotAll: true);
final _refinePattern = RegExp(r'\s\+(\d+)$');
// A stone is the only image inside a tooltip, and it is always 16 px wide.
final _stonePattern = RegExp(
  r'<img[^>]+src="[^"]*?/(\d+)\.png"[^>]*?width="16"',
);
// One bonus line: `➜ Nível de Ataque +70`, ending at the closing tag. Keeping
// the value anchored to the end of the text node stops a `+` inside a name
// from being read as the value.
final _attributePattern = RegExp(r'➜\s*([^<]*?)\s*([+-]\d+)\s*(?=<|$)');

/// Reads the items a character is wearing, out of a detail page.
///
/// The page carries equipment twice and only one copy is usable. The inventory
/// panel's `Equipamento` section has richer JSON but **no slot number**, and it
/// lists spares too — 31 entries against the 14 that are worn. The paper doll
/// (`ul.character-equip--list`) is the only place that says what is on the
/// character, so it is the one parsed here.
///
/// Its tooltip carries everything needed: name, refine, socket stones and the
/// bonus lines. The JSON's numeric addon ids are deliberately not joined in —
/// the two lists cannot be zipped, because the JSON also counts the refine
/// bonus and the socket stones as addons (14 entries against the tooltip's 11)
/// and the extras sit in the middle, not at the end.
List<ParsedItem> parseEquippedItems(String html) {
  final document = html_parser.parse(html);
  final levels = _levelsById(document);

  return document
      .querySelectorAll('ul.character-equip--list > li')
      .map(_readItem)
      .whereType<ParsedItem>()
      .map((item) {
        final level = levels[item.itemId];
        return level == null
            ? item
            : item.withLevels(require: level.require, weapon: level.weapon);
      })
      .toList(growable: false);
}

/// The two levels the inventory panel's JSON carries, per item id.
///
/// The only thing taken from that panel for a worn piece. It has no slot
/// numbers and lists spares, so it cannot say what is worn — but it does carry
/// `require_level` and `weapon_level`, which the paper doll's tooltip never
/// mentions.
Map<int, ({int require, int weapon})> _levelsById(Document document) {
  final levels = <int, ({int require, int weapon})>{};

  for (final json in _inventoryJson(document)) {
    final id = json['id'];
    final decoded = json['decoded'] as Map<String, dynamic>?;
    final require = decoded?['require_level'];
    final weapon = decoded?['weapon_level'];
    if (id is! int) continue;
    levels[id] = (
      require: require is int ? require : 0,
      weapon: weapon is int ? weapon : 0,
    );
  }
  return levels;
}

/// Every `data-item` on the page, decoded. One unreadable entry is skipped
/// rather than costing the whole page.
Iterable<Map<String, dynamic>> _inventoryJson(Document document) sync* {
  for (final element in document.querySelectorAll('li[data-item]')) {
    final raw = element.attributes['data-item'];
    if (raw == null) continue;
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) yield json;
    } on FormatException {
      continue;
    }
  }
}

/// How far a character has got through the game's anecdotes.
///
/// The pair is printed as one string — `1265/2756` — and the two halves mean
/// different things: [done] is the character's, [total] is the game's.
class ParsedAnecdotes {
  const ParsedAnecdotes({
    required this.done,
    required this.total,
    required this.lines,
  });

  final int done;
  final int total;

  /// How many anecdote lines the character has met at all. Read because it is
  /// beside the pair and free; nothing filters on it yet.
  final int lines;
}

final _anecdoteProgressPattern = RegExp(r'(\d+)\s*/\s*(\d+)');

/// Null when the page has no anecdote panel.
///
/// Null and not `0/0`: zero of zero would read as a character who has
/// completed nothing, and that is a claim. A page that does not say says
/// nothing.
ParsedAnecdotes? parseAnecdotes(String html) {
  final document = html_parser.parse(html);
  final summary = document.querySelector('.pw187-anecdote-summary');
  if (summary == null) return null;

  var done = 0;
  var total = 0;
  var lines = 0;
  var found = false;

  for (final row in summary.querySelectorAll('li')) {
    final label = row.querySelector('span')?.text.trim() ?? '';
    final value = row.querySelector('strong')?.text.trim() ?? '';

    if (label == 'Progresso total') {
      final match = _anecdoteProgressPattern.firstMatch(value);
      if (match == null) continue;
      done = int.parse(match.group(1)!);
      total = int.parse(match.group(2)!);
      found = true;
    } else if (label == 'Linhas') {
      lines = int.tryParse(value) ?? 0;
    }
  }

  return found ? ParsedAnecdotes(done: done, total: total, lines: lines) : null;
}

/// One stack of one item the character owns, wherever it is kept.
class ParsedStack {
  const ParsedStack({
    required this.itemId,
    required this.name,
    required this.count,
  });

  final int itemId;
  final String name;

  /// Every copy the character holds, added across bag, bank and the rest.
  final int count;
}

/// Everything the character owns, by item id.
///
/// This is the inventory JSON `CLAUDE.md` warns against — and counting is the
/// one job it is right for. The warning is about *worn* equipment, where the
/// panel carries no slot number and lists spares beside the real piece; the
/// paper doll stays the only source for that. Here the spares are the point.
///
/// Ids repeat across the subpanels — a stack in the bag and another in the
/// bank — so they are summed. The name is the first one seen, which is the
/// same item's name every time.
List<ParsedStack> parseInventory(String html) {
  final document = html_parser.parse(html);
  final counts = <int, int>{};
  final names = <int, String>{};

  for (final json in _inventoryJson(document)) {
    final id = json['id'];
    if (id is! int) continue;
    final count = json['count'];
    counts[id] = (counts[id] ?? 0) + (count is int ? count : 0);
    final name = json['item_name'] ?? json['name'];
    if (name is String) names.putIfAbsent(id, () => name);
  }

  return [
    for (final entry in counts.entries)
      ParsedStack(
        itemId: entry.key,
        name: names[entry.key] ?? '',
        count: entry.value,
      ),
  ];
}

final _rarityPattern = RegExp(r'Nível ([SAB])<br>');
final _cardTypePattern = RegExp(r'Tipo ([^<]+?)<br>');
final _cardLevelPattern = RegExp(r'Nível (\d+)/(\d+)');

/// The six cards the character has equipped.
///
/// Same trap as the equipment, same answer. The inventory has a `cards` panel
/// holding the whole collection — 35 cards on one character, 60 on another —
/// and that is not what is worn. `<h4>Cartas equipadas</h4>` is, and it always
/// holds exactly six.
List<ParsedCard> parseEquippedCards(String html) {
  final document = html_parser.parse(html);

  return document
      .querySelectorAll('.pw187-detail-equipped-cards .pw187-detail-card-slot')
      .map(_readCard)
      .whereType<ParsedCard>()
      .toList(growable: false);
}

ParsedCard? _readCard(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final tooltip = image.attributes['data-pw187-tooltip'] ?? '';
  final progress = _cardLevelPattern.firstMatch(tooltip);

  return ParsedCard(
    cardId: _firstNumber(_itemIdPattern, image.attributes['src']),
    name: (image.attributes['alt'] ?? '').trim(),
    rarity: _rarityPattern.firstMatch(tooltip)?.group(1) ?? '',
    type: _cardTypePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '',
    level: int.tryParse(progress?.group(1) ?? '') ?? 0,
    maxLevel: int.tryParse(progress?.group(2) ?? '') ?? 0,
  );
}

/// One of the two paths the character committed to, or null when the page
/// does not say.
///
/// Read off the name of a skill, which is the player's own test: **Evil has
/// `Erupção Demoníaca`, God has `Erupção Celestial`**. There is no field for
/// it anywhere on the sheet — `Sagrado` and `Demoníaco` appear only as item
/// names — so it has to be derived, and this is the most legible way to derive
/// it: a word the game prints on screen.
///
/// The page carries a second, redundant signal: the path's skills are prefixed
/// `●`/`Φ` for God and `○`/`Ω` for Evil, and the God ones also carry the CSS
/// class `pw187-skill-slot--sage`. Across fifteen pages the symbol and the
/// eruption agreed every time, and `sheet_test` pins the eruption because a
/// name the game shows outlives a class name a redesign can rewrite.
///
/// Null and not a guess: a character too low to have the skill has no path
/// yet, and calling him God by omission would put half the market on the wrong
/// side of a filter.
String? parsePath(String html) {
  // Through the parser, never over the raw bytes: the page writes the name as
  // `Erup&ccedil;&atilde;o Demon&iacute;aca`, so a plain `contains` on the
  // source finds nothing and reports every character as pathless.
  for (final slot in html_parser.parse(html).querySelectorAll('[aria-label]')) {
    final label = slot.attributes['aria-label'] ?? '';
    if (label.contains('Erupção Demoníaca')) return 'Evil';
    if (label.contains('Erupção Celestial')) return 'God';
  }
  return null;
}

/// The `Reino Celestial` row of the character sheet, exactly as the site
/// writes it — `Céu Ápice VIII`.
///
/// Kept raw rather than reduced to a number here, for the reason the whole
/// collector works this way: the ordering is a fact about the game, not about
/// HTML, and a wrong order corrected later would otherwise cost a fresh crawl.
/// `CelestialRealm` turns the string into a position.
String? parseCelestialRealm(String html) =>
    _sheetValue(html_parser.parse(html), 'Reino Celestial');

/// `Masculino` or `Feminino`, empty when the page does not say.
///
/// It cannot be derived from the class: Perfect World locks most classes to a
/// gender and this server mostly follows, but Bardo has both — which is why
/// this has to be read per character.
String parseSex(String html) =>
    _sheetValue(html_parser.parse(html), 'Sexo') ?? '';

/// One labelled row of the character sheet — the short list that carries
/// `Classe`, `Sexo` and `Reino Celestial` and nothing else.
String? _sheetValue(Document document, String label) {
  for (final row in document.querySelectorAll('.character-info--list')) {
    if (row.querySelector('.skill-desc')?.text.trim() != label) continue;
    return row.querySelector('.value')?.text.trim();
  }
  return null;
}

/// One rune, and the skill it was set on.
///
/// The pair is the unit the page draws and the unit the game thinks in: a rune
/// does nothing on its own, it empowers a skill.
class ParsedRune {
  const ParsedRune({
    required this.slot,
    required this.itemId,
    required this.type,
    required this.level,
    required this.skillId,
    required this.skillName,
  });

  final int slot;
  final int itemId;

  /// `Argêntea`, `Áurea`, `Celeste`, `Escarlate`, `Verdejante` — a category,
  /// not a grade: every colour was seen from level 4 to 9.
  final String type;

  final int level;
  final int skillId;
  final String skillName;
}

// `Runa Áurea Nv. 6 · Slot 3` and `Runa Celeste Nível 8 · Slot 3` both occur,
// on the same page. Reading only `Nv.` silently drops every level 8 — which is
// exactly the band anybody filtering on runes cares about.
final _runeLabelPattern = RegExp(r'Runa\s+(\S+)\s+(?:Nv\.|Nível)\s+(\d+)');

/// The runes the character has set, one per slot, in slot order.
///
/// Six slots is the common case and nine exists; the count is read from the
/// page rather than assumed. A character with none has the section drawn and
/// empty, which is not an error and not an absence of the section.
List<ParsedRune> parseRunes(String html) {
  final document = html_parser.parse(html);
  final runes = <ParsedRune>[];

  for (final pair in document.querySelectorAll('.pw187-rune-pair')) {
    final slot = int.tryParse(pair.attributes['data-rune-slot'] ?? '');
    final rune = pair.querySelector('.pw187-rune-pair__rune');
    final skill = pair.querySelector('.pw187-rune-pair__skill');
    if (slot == null || rune == null) continue;

    final match = _runeLabelPattern.firstMatch(
      rune.attributes['aria-label'] ?? '',
    );
    if (match == null) continue;

    final tooltip = skill?.attributes['data-pw187-skill-tooltip'] ?? '';
    runes.add(
      ParsedRune(
        slot: slot,
        itemId: int.tryParse(rune.attributes['data-item-id'] ?? '') ?? 0,
        type: match.group(1)!,
        level: int.parse(match.group(2)!),
        skillId: int.tryParse(skill?.attributes['data-skill-id'] ?? '') ?? 0,
        skillName: _titlePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '',
      ),
    );
  }

  runes.sort((a, b) => a.slot.compareTo(b.slot));
  return runes;
}

ParsedItem? _readItem(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final tooltip = image.attributes['data-pw187-tooltip'] ?? '';
  final title = _titlePattern.firstMatch(tooltip)?.group(1)?.trim() ?? '';
  // Falling back to the image's alt keeps an item with a broken tooltip in the
  // index under its name, rather than dropping it silently.
  final name = title.isEmpty ? (image.attributes['alt'] ?? '').trim() : title;

  return ParsedItem(
    slot: _firstNumber(_slotPattern, element.attributes['data-item-type']),
    itemId: _firstNumber(_itemIdPattern, image.attributes['src']),
    grade: _firstNumber(_gradePattern, element.attributes['data-item-grade']),
    name: name.replaceFirst(_refinePattern, ''),
    refine: _firstNumber(_refinePattern, name),
    stones: _stonePattern
        .allMatches(tooltip)
        .map((m) => int.parse(m.group(1)!))
        .toList(growable: false),
    attributes: _readAttributes(tooltip),
  );
}

/// A single item can carry the same bonus more than once — the weapon in the
/// fixture lists `HP +500`, `HP +150`, `HP +150`. Every occurrence is kept, in
/// order; overwriting on collision would report 150 where the item gives 800,
/// and summing here would report 71 for a weapon whose principal is 70.
Map<String, List<int>> _readAttributes(String tooltip) {
  final attributes = <String, List<int>>{};

  for (final match in _attributePattern.allMatches(tooltip)) {
    final name = match.group(1)!.trim();
    if (name.isEmpty) continue;
    final value = int.tryParse(match.group(2)!);
    if (value == null) continue;
    (attributes[name] ??= <int>[]).add(value);
  }

  return attributes;
}

int _firstNumber(RegExp pattern, String? source) {
  if (source == null) return 0;
  final match = pattern.firstMatch(source);
  return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
}
