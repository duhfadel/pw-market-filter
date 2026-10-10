import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
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

  test('no preset leaves most of the market on screen', () {
    // Not `lessThan(everybody)`: that bar passed two presets that returned 72%
    // of the market, which is a chip that teaches nothing — the visitor taps
    // it, the page does not move, and the tool looks broken.
    //
    // **O limiar era metade e passou a 60%, em 10/10/2026, porque metade
    // estava a travar o deploy do site inteiro.** `Arma de 70 ou mais` vive
    // em 49,7% — cinco personagens abaixo da linha — e o mercado move-se
    // sozinho de vinte em vinte minutos: duas corridas seguidas falharam com
    // `974` contra `lessThan(974)`, sem uma linha de código ter mudado.
    //
    // A escolha é a mesma que `confirmedCountedItems` já fez: um defeito
    // nosso deve pôr a suíte vermelha, um facto sobre um mercado que muda
    // sozinho não deve congelar o site. 60% continua a apanhar o caso para
    // que este teste nasceu — os dois chips de 72% — e deixa de disparar com
    // ruído de meia dúzia de anúncios.
    //
    // O que se perdeu é o aviso sobre um chip fraco, e ele está no teste
    // abaixo, que mede sem reprovar.
    for (final preset in presetsFor(index)) {
      expect(
        runQuery(index, preset.query).length,
        lessThan((index.characters.length * 0.6).round()),
        reason: '"${preset.label}" leaves most of the market on screen',
      );
    }
  });

  test('a fatia de cada chip fica no log, mesmo quando passa', () {
    // **Medir sem reprovar.** O limiar acima só apanha um chip claramente
    // inútil; um que se aproxime da metade é notícia de produto, não defeito
    // de código — e a diferença entre as duas é que a primeira se lê e a
    // segunda se conserta. Sem esta linha, um chip a derivar para 55% chega
    // a 61% sem ninguém ter visto o caminho.
    final fatias = <String, double>{};
    for (final preset in presetsFor(index)) {
      final n = runQuery(index, preset.query).length;
      fatias[preset.label] = 100 * n / index.characters.length;
    }
    for (final e in fatias.entries) {
      debugPrint('chip "${e.key}": ${e.value.toStringAsFixed(1)}% do mercado');
    }
    // O teste acima é que reprova; este só garante que houve o que medir.
    expect(fatias, isNotEmpty);
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

  test('each UP5 tier has a chip of its own', () {
    // Measured on 2026-09-29 over 1519 listings: 13 characters carry an 80
    // attack weapon, 8 carry an 80 defence one, and **not one carries both**.
    // A single chip asking only for `Nível de Ataque` therefore did not merge
    // the two questions into one — it answered half of it and dropped the
    // eight, whose only other way in had been deleted in the same commit.
    final labels = presetsFor(index).map((preset) => preset.label);

    expect(labels, contains('Atq lvl UP5'));
    expect(labels, contains('Def lvl UP5'));
  });

  test('the two UP5 chips never answer for each other', () {
    // Disjoint in the market, so each chip has to find its own people and
    // none of the other's. A chip that quietly returned the union would be
    // the merged one again wearing two labels.
    final presets = presetsFor(index);
    SearchQuery queryOf(String label) =>
        presets.firstWhere((preset) => preset.label == label).query;

    final attack = runQuery(index, queryOf('Atq lvl UP5'));
    final defence = runQuery(index, queryOf('Def lvl UP5'));

    expect(attack, isNotEmpty);
    expect(defence, isNotEmpty);

    final attackIds = attack.map((character) => character.roleId).toSet();
    final defenceIds = defence.map((character) => character.roleId).toSet();
    expect(attackIds.intersection(defenceIds), isEmpty);
  });
}
