import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/counted_items.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Pins `countedItemNames` against the collected market, the way
/// `combo_test.dart` pins the card ids.
///
/// The failure this exists for is silent: a name misspelt by one accent
/// resolves to nothing, the field never appears on screen, and the tool
/// answers "the market has none" — which is a perfectly believable answer for
/// a `Chave da Sorte`. These tests say which name found nothing instead.
///
/// Skipped when there is no index, and when the index predates the fields — a
/// fresh clone has not collected, and an old collection carries neither. The
/// one thing that must not fail here is the collection being old.
void main() {
  final file = File('web/market_index.json');
  if (!file.existsSync()) return;

  late MarketIndex index;

  setUpAll(() {
    index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  });

  bool collectedBefore() =>
      index.countedItems.isEmpty &&
      index.characters.every((c) => c.anecdotes == null);

  test('every confirmed name still resolves against the market', () {
    if (collectedBefore()) return;

    for (final name in confirmedCountedItems) {
      expect(
        index.countedItems[name],
        isNotNull,
        reason:
            '"$name" já foi visto numa página real e agora não resolve. '
            'O nome ou o parser mudaram — não o mercado.',
      );
    }
  });

  test('every counted item has somebody carrying at least one', () {
    if (collectedBefore()) return;

    for (final entry in index.countedItems.entries) {
      final carriers = runQuery(
        index,
        SearchQuery(minimumOwned: {entry.key: 1}),
      );
      expect(carriers, isNotEmpty, reason: entry.key);
    }
  });

  test('a pet that resolved has somebody carrying it', () {
    // The ids themselves are pinned against a real page in
    // `test/collector/pets_test.dart`, which is the fixture that cannot go
    // stale. This only asks that the live market agrees.
    for (final label in countedItemIds.keys) {
      if (index.countedItems[label] == null) continue;
      expect(
        runQuery(index, SearchQuery(pets: {label})),
        isNotEmpty,
        reason: label,
      );
    }
  });

  test('a name the collection never met matches nobody, not everybody', () {
    expect(
      runQuery(index, const SearchQuery(minimumOwned: {'não existe': 1})),
      isEmpty,
    );
  });

  test('the anecdote pair is a pair: done never exceeds the total', () {
    for (final character in index.characters) {
      final anecdotes = character.anecdotes;
      if (anecdotes == null) continue;
      expect(anecdotes.total, greaterThan(0), reason: character.name);
      expect(
        anecdotes.done,
        lessThanOrEqualTo(anecdotes.total),
        reason: character.name,
      );
    }
  });

  test('asking for more anecdotes than anyone has returns nobody', () {
    if (collectedBefore()) return;

    final most = index.characters
        .map((c) => c.anecdotes?.done ?? 0)
        .reduce((a, b) => a > b ? a : b);

    expect(runQuery(index, SearchQuery(minAnecdotes: most)), isNotEmpty);
    expect(runQuery(index, SearchQuery(minAnecdotes: most + 1)), isEmpty);
  });
}
