import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

void main() {
  // Leandrim, role 64112, saved on 2026-08-09. A level 105 Guerreiro at
  // 1000 TCC — the only character in the sample carrying a +70 Attack Level
  // weapon, which is the case this whole project exists to find.
  late String html;

  setUpAll(() {
    html = File('test/fixtures/detail_64112.html').readAsStringSync();
  });

  test('reads the fourteen worn items, not the thirty-one in the bag', () {
    // The inventory panel has a section that also holds equipment-class items
    // — spares included, and with no slot number. The paper doll is the only
    // place that says what is actually worn.
    expect(parseEquippedItems(html), hasLength(14));
  });

  test('reads the weapon field by field', () {
    final weapon = parseEquippedItems(html).singleWhere((i) => i.slot == 10);

    expect(weapon.itemId, 50206);
    expect(weapon.name, '★★★Dilacerador Raivoso');
    expect(weapon.grade, 6);
    expect(weapon.refine, 12);
    expect(weapon.stones, [51112, 51112]);
    expect(weapon.attributes['Nível de Ataque'], [70]);
    expect(weapon.attributes['Nível de Guarda'], [350]);
  });

  test('keeps every occurrence of a repeated attribute, in order', () {
    // The tooltip lists HP three times: +500, +150, +150. Reducing here would
    // decide for the whole project whether that is 800 or 500 — and the answer
    // differs by attribute. The parser reports; IndexBuilder decides.
    final weapon = parseEquippedItems(html).singleWhere((i) => i.slot == 10);

    expect(weapon.attributes['HP'], [500, 150, 150]);
  });

  test('keeps the number of an attribute the site itself cannot name', () {
    final weapon = parseEquippedItems(html).singleWhere((i) => i.slot == 10);

    expect(weapon.attributes['Atributo #3818'], [13]);
  });

  test('reads an unrefined item as refine zero, not as null or one', () {
    final cape = parseEquippedItems(html).singleWhere((i) => i.slot == 19);

    expect(cape.name, '★★Céu Tempestuoso');
    expect(cape.refine, 0);
  });

  test('reads an item with no stones as an empty list', () {
    final seal = parseEquippedItems(html).singleWhere((i) => i.slot == 5);

    expect(seal.name, '★★Lacre de Jade - Po');
    expect(seal.stones, isEmpty);
  });

  test('reads an item with no attributes at all', () {
    final astrolabe = parseEquippedItems(html).singleWhere((i) => i.slot == 17);

    expect(astrolabe.name, 'Astrolábio: Guerreiro');
    expect(astrolabe.attributes, isEmpty);
  });

  test('reads every slot the paper doll shows, each exactly once', () {
    final slots = parseEquippedItems(html).map((i) => i.slot).toList();

    expect(slots, hasLength(14));
    expect(slots.toSet(), hasLength(14));
    expect(
      slots.toSet(),
      containsAll([2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 16, 17, 18, 19]),
    );
  });

  test('gives every item a name and a positive item id', () {
    for (final item in parseEquippedItems(html)) {
      expect(item.name, isNotEmpty, reason: 'slot ${item.slot}');
      expect(item.itemId, greaterThan(0), reason: 'slot ${item.slot}');
    }
  });

  test('a page with no paper doll yields nothing instead of throwing', () {
    expect(parseEquippedItems('<html><body></body></html>'), isEmpty);
  });
}
