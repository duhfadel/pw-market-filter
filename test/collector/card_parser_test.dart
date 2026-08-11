import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

void main() {
  late String html;

  setUpAll(() {
    html = File('test/fixtures/detail_64112.html').readAsStringSync();
  });

  test('reads the six worn cards, not the thirty-five in the collection', () {
    // The inventory's `cards` panel holds everything the character owns — 35
    // here, 60 on a richer account. Only six are equipped, and it is the six
    // that decide whether a combo is complete.
    expect(parseEquippedCards(html), hasLength(6));
  });

  test('reads one card field by field', () {
    final card = parseEquippedCards(html).first;

    expect(card.cardId, 41816);
    expect(card.name, 'Chong Yun');
    expect(card.rarity, 'S');
    expect(card.type, 'Destruidor');
    expect(card.level, 80);
    expect(card.maxLevel, 80);
  });

  test('covers the six types, each exactly once', () {
    final types = parseEquippedCards(html).map((c) => c.type).toList();

    expect(types.toSet(), hasLength(6));
    expect(types.toSet(), {
      'Destruidor',
      'Batalha',
      'Durabilidade',
      'Alma Primordial',
      'Vida Primordial',
      'Longevidade',
    });
  });

  test('gives every card an id, a name and a rarity', () {
    for (final card in parseEquippedCards(html)) {
      expect(card.cardId, greaterThan(0), reason: card.name);
      expect(card.name, isNotEmpty);
      expect(card.rarity, isIn(const ['S', 'A', 'B']));
    }
  });

  test('a page with no cards yields nothing instead of throwing', () {
    expect(parseEquippedCards('<html><body></body></html>'), isEmpty);
  });

  group('the character sex', () {
    test('is read from the info list', () {
      expect(parseSex(html), 'Masculino');
    });

    test('is empty when the page does not say, never a guess', () {
      // It cannot be inferred from the class — Bardo has both — so an absent
      // value has to stay absent.
      expect(parseSex('<html><body></body></html>'), isEmpty);
    });
  });
}
