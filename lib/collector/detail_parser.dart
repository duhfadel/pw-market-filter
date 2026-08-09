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
  });

  final int slot;
  final int itemId;
  final int grade;
  final String name;
  final int refine;
  final List<int> stones;
  final Map<String, List<int>> attributes;
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

  return document
      .querySelectorAll('ul.character-equip--list > li')
      .map(_readItem)
      .whereType<ParsedItem>()
      .toList(growable: false);
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
