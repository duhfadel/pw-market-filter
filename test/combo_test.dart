import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/card_combos.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Pins `cardCombos` against the collected market.
///
/// The table is hand-written from data, which is exactly the shape of mistake
/// nothing else would catch: a wrong card id produces a filter that quietly
/// matches nobody, and "nobody has this combo" is a perfectly believable
/// answer. These tests fail loudly instead.
///
/// Skipped when there is no index — a fresh clone has not collected yet.
void main() {
  final file = File('web/market_index.json');
  if (!file.existsSync()) return;

  late MarketIndex index;

  setUpAll(() {
    index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  });

  test('every combo offered is a size the game has', () {
    // Two, four or six — the six slots hold one six, or a four and a two, or
    // three twos. Anything else is a half-written entry, and filtering on it
    // would answer "nobody" for a reason the visitor cannot see.
    for (final combo in cardCombos) {
      expect(
        const {2, 4, 6},
        contains(combo.cardIds.length),
        reason: combo.name,
      );
      expect(combo.isComplete, isTrue, reason: combo.name);
    }
  });

  test('no card belongs to two combos', () {
    // A card in two sets would mean one of the two tables is wrong, and the
    // filter would quietly report the same character under both.
    final visto = <int, String>{};
    for (final combo in cardCombos) {
      for (final id in combo.cardIds) {
        expect(
          visto[id],
          isNull,
          reason: 'carta $id em ${combo.name} e em ${visto[id]}',
        );
        visto[id] = combo.name;
      }
    }
  });

  test('every card id in the table exists in the market', () {
    // An invented id is the failure mode here. It cannot be spotted by reading
    // the code, and it makes the filter return nothing at all.
    final worn = {
      for (final character in index.characters)
        for (final card in character.cards) card.cardId,
    };

    for (final combo in cardCombos) {
      for (final id in combo.cardIds) {
        expect(worn, contains(id), reason: '${combo.name}: id $id');
      }
    }
  });

  test('no combo names two cards of the same type', () {
    final typeOf = {
      for (final character in index.characters)
        for (final card in character.cards) card.cardId: card.type,
    };

    for (final combo in cardCombos) {
      final types = combo.cardIds.map((id) => typeOf[id]).toSet();
      // One card per type, whether the combo has six of them or five.
      expect(types, hasLength(combo.cardIds.length), reason: combo.name);
    }
  });

  test('each combo is of the single rarity it claims', () {
    final rarityOf = {
      for (final character in index.characters)
        for (final card in character.cards) card.cardId: card.rarity,
    };

    for (final combo in cardCombos) {
      for (final id in combo.cardIds) {
        expect(rarityOf[id], combo.rarity, reason: '${combo.name}: id $id');
      }
    }
  });

  test('every combo offered has at least one wearer', () {
    // A dropdown option that can only ever return nothing is worse than an
    // absent one: it reads as "the market has none of these" when it means
    // "this was never confirmed". Two candidates — Emissários and Mestres —
    // are kept in the source and off the list for exactly this reason.
    for (final combo in cardCombos) {
      final wearers = runQuery(index, SearchQuery(comboName: combo.name));
      expect(wearers, isNotEmpty, reason: combo.name);
    }
  });

  test('a character wearing five of six does not count as complete', () {
    final combo = cardCombos.first;
    final wearers = runQuery(index, SearchQuery(comboName: combo.name));

    for (final character in wearers) {
      expect(
        character.cards.map((c) => c.cardId).toSet(),
        containsAll(combo.cardIds),
        reason: character.name,
      );
    }
  });

  test('an unknown combo name matches nobody rather than everybody', () {
    expect(
      runQuery(index, const SearchQuery(comboName: 'não existe')),
      isEmpty,
    );
  });

  test('asking for six maxed S cards is stricter than asking for six S', () {
    final allS = runQuery(index, const SearchQuery(cardRarity: 'S'));
    final maxed = runQuery(
      index,
      const SearchQuery(cardRarity: 'S', cardsMaxed: true),
    );

    expect(allS, isNotEmpty);
    expect(maxed.length, lessThanOrEqualTo(allS.length));
    for (final character in maxed) {
      expect(character.cards.every((c) => c.isMaxed), isTrue);
    }
  });

  test('a character whose cards were never read fails a card filter', () {
    // Absent is not the same as "does not have it", and the honest answer to
    // "does this one wear the combo?" for a character with no cards read is no.
    final bare = index.characters.where((c) => c.cards.isEmpty);
    if (bare.isEmpty) return;

    expect(
      runQuery(index, const SearchQuery(cardRarity: 'S'))
          .map((c) => c.roleId)
          .toSet()
          .intersection(bare.map((c) => c.roleId).toSet()),
      isEmpty,
    );
  });
}
