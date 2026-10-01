import 'dart:convert';

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import 'atributos_126.dart';
import 'detail_parser.dart' show ParsedItem;

final _slotPattern = RegExp(r'slot-(\d+)');
final _gradePattern = RegExp(r'grade-(\d+)');
final _itemIdPattern = RegExp(r'/(\d+)\.png');

/// Reads the items a character is wearing, out of a 1.2.6 detail page.
///
/// The page carries equipment in two places, and the relationship is the
/// *same shape* as 1.8.7's but not the same mechanism. The paper doll
/// (`ul.character-equip--list`) is the only place that says what is worn —
/// confirmed on both fixtures, 11 slots each. The **first** tab of the
/// inventory panel, labelled `Equipamento` (`.v-window-item.inventory
/// ul.list-item`, taken in document order, before `Inventário` and
/// `Banqueiro`), lists more than what is worn: 21 entries against 11 worn on
/// both fixtures, the extra ten being fashion pieces and switched-out
/// equipment with no stat JSON (`data-item='null'`).
///
/// Unlike 1.8.7, there is no tooltip and no numeric id to join stats by — and
/// joining by item id would be wrong here anyway: a character can wear two
/// rings of the same item id with **different rolls** (measured on
/// `detail_pw126_5424.html`, item `6175`, one copy giving 81 defence and the
/// other 60). What *is* reliable, measured on both fixtures: the
/// `Equipamento` tab's entries are in the **same order** as the paper doll
/// for exactly as many positions as are worn, id for id. So the two lists are
/// paired by position, not by id — id equality is still checked per pair as a
/// guard, and a mismatch drops that item's attributes rather than attaching
/// the wrong ones.
///
/// `data-item` is single-quoted in 1.2.6, with its own quotes escaped as
/// `&quot;` — reading it through `Element.attributes`, as this does, decodes
/// that transparently; the trap is only real for a hand-written regex that
/// assumes double quotes, which matches zero and reports success on nothing.
List<ParsedItem> parseEquippedItems126(String html) {
  final document = html_parser.parse(html);

  final dollElements = document.querySelectorAll(
    'ul.character-equip--list > li',
  );
  final tabElements =
      document
          .querySelector('.v-window-item.inventory ul.list-item')
          ?.querySelectorAll('li[data-item]') ??
      const <Element>[];

  final items = <ParsedItem>[];
  for (var i = 0; i < dollElements.length; i++) {
    final worn = _readDollItem(dollElements[i]);
    if (worn == null) continue;

    final decoded = i < tabElements.length
        ? _decodedFor(tabElements[i], worn.itemId)
        : null;

    items.add(decoded == null ? worn : _withStats(worn, decoded));
  }
  return items;
}

/// `Masculino` or `Feminino`, empty when the page does not say.
///
/// Read off the same `.character-info--list` / `.skill-desc` / `.value`
/// shape 1.8.7 uses — the two versions' character sheets share this markup.
String parseSex126(String html) =>
    _sheetValue126(html_parser.parse(html), 'Sexo') ?? '';

/// The character's class, read off the header badge (`li.classname span`).
/// Null when the page does not carry it.
String? parseClasse126(String html) {
  final text = html_parser
      .parse(html)
      .querySelector('li.classname span')
      ?.text
      .trim();
  return (text == null || text.isEmpty) ? null : text;
}

String? _sheetValue126(Document document, String label) {
  for (final row in document.querySelectorAll('.character-info--list')) {
    if (row.querySelector('.skill-desc')?.text.trim() != label) continue;
    return row.querySelector('.value')?.text.trim();
  }
  return null;
}

ParsedItem? _readDollItem(Element element) {
  final image = element.querySelector('img');
  if (image == null) return null;

  final enchance = element.querySelector('.item-enchance')?.text.trim() ?? '';

  return ParsedItem(
    slot: _firstNumber(_slotPattern, element.attributes['data-item-type']),
    itemId: _firstNumber(_itemIdPattern, image.attributes['src']),
    grade: _firstNumber(_gradePattern, element.attributes['data-item-grade']),
    name: (image.attributes['data-item-name'] ?? '').trim(),
    refine: int.tryParse(enchance.replaceFirst('+', '')) ?? 0,
    stones: const [],
    attributes: const {},
  );
}

/// The decoded `data-item` JSON of one `Equipamento`-tab entry, or null when
/// it carries no stats (`data-item='null'`, the fashion/spare tail of the
/// tab) or when its item id does not match the worn piece at the same
/// position — the guard against the positional pairing being wrong.
Map<String, dynamic>? _decodedFor(Element tabElement, int expectedItemId) {
  final actualId = _firstNumber(
    _itemIdPattern,
    tabElement.querySelector('img')?.attributes['src'],
  );
  if (actualId != expectedItemId) return null;

  final raw = tabElement.attributes['data-item'];
  if (raw == null) return null;
  try {
    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : null;
  } on FormatException {
    return null;
  }
}

ParsedItem _withStats(ParsedItem worn, Map<String, dynamic> decoded) =>
    ParsedItem(
      slot: worn.slot,
      itemId: worn.itemId,
      grade: worn.grade,
      name: worn.name,
      refine: worn.refine,
      stones: _stonesFrom(decoded),
      attributes: _translateAttributes(decoded),
      requireLevel: _intOf(decoded['require_level']),
      weaponLevel: _intOf(decoded['weapon_level']),
    );

/// Every column named in [atributos126], carried over when the item actually
/// grants it. A zero in these columns means the same thing an absent tooltip
/// line means in 1.8.7 — the item does not touch that attribute — so it is
/// skipped rather than printed as a false `+0`.
Map<String, List<int>> _translateAttributes(Map<String, dynamic> decoded) {
  final attributes = <String, List<int>>{};
  for (final entry in atributos126.entries) {
    final value = decoded[entry.key];
    if (value is num && value != 0) {
      attributes[entry.value] = [value.round()];
    }
  }
  return attributes;
}

/// The socketed stones, straight off `slots.slotStones` — an empty socket is
/// `0` in this JSON, and is filtered out the same way a missing stone image
/// is simply absent in 1.8.7's tooltip.
List<int> _stonesFrom(Map<String, dynamic> decoded) {
  final slots = decoded['slots'];
  if (slots is! Map) return const [];
  final stones = slots['slotStones'];
  if (stones is! List) return const [];
  return stones
      .whereType<num>()
      .map((stone) => stone.toInt())
      .where((stone) => stone != 0)
      .toList(growable: false);
}

int _intOf(Object? value) => value is num ? value.toInt() : 0;

int _firstNumber(RegExp pattern, String? source) {
  if (source == null) return 0;
  final match = pattern.firstMatch(source);
  return match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
}
