import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/presets.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Pins the ready-made searches against the collected market.
///
/// A preset is the first thing a visitor taps, and it is the one control whose
/// failure is invisible: a preset that matches nobody returns the same empty
/// screen as a working filter over a picked-clean market, and "nobody has that"
/// is a believable answer. `combo_test.dart` guards the card combos for exactly
/// this reason; the presets need the same guard for the same reason.
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

  test('every preset finds somebody', () {
    for (final preset in presetsFor(index)) {
      expect(
        runQuery(index, preset.query),
        isNotEmpty,
        reason: '"${preset.label}" matches nobody',
      );
    }
  });

  test('every preset cuts the market at least in half', () {
    // Not `lessThan(everybody)`: that bar passed two presets that returned 72%
    // of the market, which is a chip that teaches nothing — the visitor taps
    // it, the page does not move, and the tool looks broken. Half is the line
    // where a tap is visibly an answer.
    for (final preset in presetsFor(index)) {
      expect(
        runQuery(index, preset.query).length,
        lessThan(index.characters.length ~/ 2),
        reason: '"${preset.label}" leaves most of the market on screen',
      );
    }
  });

  test('a preset recognises its own query', () {
    final presets = presetsFor(index);

    for (final preset in presets) {
      expect(activePreset(presets, preset.query)?.label, preset.label);
    }
  });

  test('no preset claims an empty form', () {
    expect(activePreset(presetsFor(index), const SearchQuery()), isNull);
  });

  test('a preset still counts as active after the order changes', () {
    // Ordering is how the list is read, not something that was asked for.
    // Losing the highlight when somebody sorts by price would leave the chip
    // saying the search is off while it is plainly still on.
    final presets = presetsFor(index);
    final reordered = presets.first.query.copyWith(
      order: ResultOrder.highestLevel,
    );

    expect(activePreset(presets, reordered)?.label, presets.first.label);
  });

  test('a hand-built search that happens to match is recognised', () {
    // The chip has to light up whether the search came from tapping it or from
    // filling the form to the same place; two ways to say one thing, one
    // answer.
    final presets = presetsFor(index);
    final rebuilt = SearchQuery(criteria: presets.first.query.criteria);

    expect(activePreset(presets, rebuilt)?.label, presets.first.label);
  });
}
