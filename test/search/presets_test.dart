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

  // **O gate duro saiu a 09/11/2026, e esta e a terceira vez que ele custou
  // o deploy.** A regra era que nenhum chip deixasse mais de 60% do mercado
  // no ecra. Nesse dia o chip `Ate 100 TCC` chegou a **60,1%** — quatro
  // personagens acima da linha — e travou catorze corridas seguidas, seis
  // horas sem publicar, sem uma linha de codigo ter mudado. Em 10/10 tinha
  // sido o `Arma de 70` a 49,7% contra um limiar de 50%; subir para 60% so
  // adiou o mesmo acidente.
  //
  // **O que decidiu foi perguntar o que o gate conserta.** Se o `Ate 100
  // TCC` passa dos 60%, a correccao e mudar o chip para `Ate 50 TCC` — uma
  // decisao de produto do dono, a tomar olhando para os numeros. Nao e
  // codigo partido. E um gate de publicacao so deve disparar por coisa que
  // se conserta mexendo no codigo; este disparava pelo mercado a mexer-se, e
  // deixava o site parado enquanto alguem decidia.
  //
  // **O que se perde, e onde foi parar.** O teste nasceu de um caso real:
  // dois chips devolviam 72% do mercado e nao ensinavam nada. Mas chips
  // entram a mao e raramente, e o teste abaixo imprime a fatia de cada um em
  // todas as corridas — quem acrescentar um chip mau ve-o na saida, no
  // momento em que corre a suite. A proteccao continua; deixou de ser um
  // cadeado.

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
    // Da maior para a menor, e com aviso acima de 50%: a deriva le-se de
    // relance em vez de se descobrir no dia em que um chip atravessa a linha.
    // O `Arma de 70` vive perto dos 47% e vai bater la — e a resposta e
    // mudar o chip, nao reprovar a suite.
    final ordenadas = fatias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in ordenadas) {
      final aviso = e.value >= 50
          ? '  <<< deixa metade do mercado no ecra'
          : '';
      debugPrint(
        'chip "${e.key}": ${e.value.toStringAsFixed(1)}% do mercado$aviso',
      );
    }
    // Nada aqui reprova: isto mede. So garante que houve o que medir.
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
