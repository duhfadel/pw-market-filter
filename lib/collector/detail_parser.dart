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
  });

  ParsedItem withRequireLevel(int level) => ParsedItem(
    slot: slot,
    itemId: itemId,
    grade: grade,
    name: name,
    refine: refine,
    stones: stones,
    attributes: attributes,
    requireLevel: level,
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
  final requireLevels = _requireLevelsById(document);

  return document
      .querySelectorAll('ul.character-equip--list > li')
      .map(_readItem)
      .whereType<ParsedItem>()
      .map(
        (item) => requireLevels.containsKey(item.itemId)
            ? item.withRequireLevel(requireLevels[item.itemId]!)
            : item,
      )
      .toList(growable: false);
}

/// Item id to the level it demands, read from the inventory panel's JSON.
///
/// The one thing taken from that panel. It has no slot numbers and lists
/// spares, so it cannot say what is worn — but it does carry `require_level`,
/// which the paper doll's tooltip never mentions.
Map<int, int> _requireLevelsById(Document document) {
  final levels = <int, int>{};

  for (final element in document.querySelectorAll('li[data-item]')) {
    final raw = element.attributes['data-item'];
    if (raw == null) continue;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final id = json['id'];
      final level = (json['decoded'] as Map<String, dynamic>?)?['require_level'];
      if (id is int && level is int) levels[id] = level;
    } on FormatException {
      // One unreadable entry must not cost the whole page.
      continue;
    }
  }
  return levels;
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

/// `Masculino` or `Feminino`, empty when the page does not say.
///
/// It cannot be derived from the class: Perfect World locks most classes to a
/// gender and this server mostly follows, but Bardo has both — which is why
/// this has to be read per character.
String parseSex(String html) {
  final document = html_parser.parse(html);

  for (final row in document.querySelectorAll('.character-info--list')) {
    if (row.querySelector('.skill-desc')?.text.trim() != 'Sexo') continue;
    return row.querySelector('.value')?.text.trim() ?? '';
  }
  return '';
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
