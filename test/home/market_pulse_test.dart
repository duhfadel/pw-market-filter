import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/ui/widgets/market_pulse.dart';
import 'package:pw_market_filter/features/search/domain/presets.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The front page and the filter must ask the market the same questions.
///
/// `MarketPulse` used to build every figure by hand — it looked up
/// `Nível de Ataque` and assembled its own `SearchQuery` — while the chips
/// were built in `presets.dart`. The two drifted the first time the chips
/// changed: the set gained *5 essências* and *Seis cartas S* and lost a
/// weapon tier, and the front page followed none of it because nothing
/// connected them. `market_pulse.dart` reads `presetsFor` now, and this
/// pins the join that makes the drift impossible.
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

  test('every figure names a preset that exists', () {
    // The join is by label, so a preset renamed in `presets.dart` takes its
    // figure off the front page in silence — the `Wrap` simply draws one
    // fewer. Nothing on screen would say the page had stopped answering a
    // question it used to answer, which is the same class of failure
    // `combo_test` exists to catch: an invented key yields no results, and
    // "nobody has that" is a believable answer.
    final labels = presetsFor(index).map((preset) => preset.label).toSet();

    for (final named in figureLabels.keys) {
      expect(
        labels,
        contains(named),
        reason: '"$named" is a figure on the front page and no longer a chip',
      );
    }
  });

  test('the figures keep the order the chips are in', () {
    // Somebody arriving from the front page and tapping through to the filter
    // should meet the same questions in the same sequence. Two orderings of
    // one set reads as two different sets.
    //
    // Repeats are collapsed because one chip legitimately gives two figures:
    // `687 com arma de 70 ou mais` and `45 TCC o mais barato deles` are two
    // readings of one search, and the second is the page's whole argument.
    // What the test forbids is a figure appearing where its chip does not.
    final chips = presetsFor(
      index,
    ).map((preset) => preset.label).where(figureLabels.containsKey).toList();

    final figures = <String>[];
    for (final figure in figuresFor(index)) {
      final named = figure.presetLabel;
      if (named != null && named != figures.lastOrNull) figures.add(named);
    }

    expect(figures, chips);
  });

  test('the total is the only figure that is not a chip', () {
    // "1519 personagens à venda" opens the unfiltered market, which is not a
    // preset and must not become one: a chip that asks for nothing would
    // leave the whole market on screen, which is the bar `presets_test`
    // refuses.
    final unnamed = figuresFor(
      index,
    ).where((figure) => figure.presetLabel == null);

    expect(unnamed, hasLength(1));
    expect(unnamed.single.label, 'personagens à venda');
  });
}
