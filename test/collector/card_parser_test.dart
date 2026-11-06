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

  group('Renascimentos', () {
    String fixture(String name) =>
        File('test/fixtures/$name').readAsStringSync();

    test('reads the count off the tooltip', () {
      final cards = parseEquippedCards(fixture('detail_92624.html'));

      expect(cards, hasLength(6));
      expect(cards.map((c) => c.rebirths), everyElement(2));
    });

    test('a card never reborn reads zero, which is not unknown', () {
      // The page prints `Renascimentos 0` nowhere — measured across every
      // fixture that has a cards panel — so an absent line is a real nought,
      // and that is what lets a combo's level be the minimum of six numbers.
      final cards = parseEquippedCards(fixture('detail_330640.html'));

      expect(cards.map((c) => c.rebirths).toList(), [0, 0, 0, 0, 1, 0]);
    });

    test('a combo may mix levels, and that is what a minimum is for', () {
      final cards = parseEquippedCards(fixture('detail_2192.html'));

      expect(cards.map((c) => c.rebirths).toList(), [2, 2, 1, 2, 2, 1]);
    });

    test('the garbage in the inventory panel never reaches the worn six', () {
      // The same page's inventory cards print `Renascimentos 6619244` and
      // `Renascimentos 1192755200` — raw bits wearing a number's clothes, the
      // same family as `Movimento m/seg. +1036831949`. They sit outside
      // `.pw187-detail-equipped-cards`, so a `>= 2` filter can never see one.
      final cards = parseEquippedCards(fixture('detail_92624.html'));

      expect(cards.map((c) => c.rebirths), everyElement(lessThan(10)));
    });
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
