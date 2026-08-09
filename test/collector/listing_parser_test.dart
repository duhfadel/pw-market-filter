import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

void main() {
  // The real page, saved on 2026-08-09. Every assertion below is an exact
  // number read off it — a loose one would pass with the parser reading a
  // fraction of the cards.
  late String html;

  setUpAll(() {
    html = File('test/fixtures/listing_pw187.html').readAsStringSync();
  });

  test('reads every card on the page', () {
    expect(parseListing(html), hasLength(779));
  });

  test('reads the first card field by field', () {
    final first = parseListing(html).first;

    expect(first.roleId, 354080);
    expect(first.name, 'StormPower');
    expect(first.characterClass, 'Tormentador');
    expect(first.occupation, 11);
    expect(first.level, 101);
    expect(first.price, 80);
    expect(first.fame, 204237);
    expect(first.cultivation, 'Leal');
  });

  test('reads the last card, so the walk is not cut short', () {
    final last = parseListing(html).last;

    expect(last.roleId, 83008);
    expect(last.name, 'Aodk');
    expect(last.characterClass, 'Andarilho');
  });

  test('gives every card a role id, and no two the same', () {
    final ids = parseListing(html).map((c) => c.roleId).toList();

    expect(ids.where((id) => id > 0), hasLength(779));
    expect(ids.toSet(), hasLength(779));
  });

  test('finds the character used by the detail fixture', () {
    final leandrim = parseListing(html).singleWhere((c) => c.roleId == 64112);

    expect(leandrim.name, 'Leandrim');
    expect(leandrim.characterClass, 'Guerreiro');
    expect(leandrim.level, 105);
    expect(leandrim.price, 1000);
  });

  test('an empty page yields no cards instead of throwing', () {
    expect(parseListing('<html><body></body></html>'), isEmpty);
  });
}
