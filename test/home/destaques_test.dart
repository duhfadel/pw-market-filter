import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/destaques.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Pins `destaquesDe`: which six characters the front page shows, and why.
///
/// The distinct-class rule is the delicate part, and it is only exercised by
/// the real collection — the two synthetic fixtures in this file are too
/// small to reproduce the collision on their own, the same reason
/// `vitrine_real_market_test.dart` exists next to `vitrine_test.dart`.

MarketIndex _indiceVazio() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: const [],
);

EquippedItem _arma(int nivelAtaque) => EquippedItem(
  slot: weaponSlot,
  itemId: 50206,
  refine: 0,
  stones: const [],
  attributes: {0: nivelAtaque},
);

MarketCharacter _personagem(
  String nome,
  int preco,
  String classe, {
  int nivelAtaque = 0,
}) => MarketCharacter(
  roleId: nome.hashCode,
  name: nome,
  characterClass: classe,
  occupation: 1,
  level: 105,
  price: preco,
  fame: 0,
  cultivation: 'Leal',
  equipped: [_arma(nivelAtaque)],
);

/// A market where nobody's weapon reaches 80 — the UP5 tier simply never
/// happened on this collection.
MarketIndex _indiceOnde({required int ataqueMaximo}) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const ['Nível de Ataque'],
  items: const {},
  characters: [
    _personagem('a', 100, 'Guerreiro', nivelAtaque: ataqueMaximo),
    _personagem('b', 200, 'Mago', nivelAtaque: ataqueMaximo - 30),
  ],
);

/// A market built so category 1 (the cheapest overall) and category 2 (the
/// cheapest 70-weapon carrier) have the same true winner: `barato`, a
/// Guerreiro, is both the cheapest character on the whole market and the
/// cheapest carrier of a 70 weapon. Category 1 takes him and spends
/// `Guerreiro`, so category 2 has to fall through to `mago`, the next
/// cheapest 70-weapon carrier, of a class nobody has used yet.
MarketIndex _indiceComColisao() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const ['Nível de Ataque'],
  items: const {},
  characters: [
    _personagem('barato', 100, 'Guerreiro', nivelAtaque: 70),
    _personagem('mago', 500, 'Mago', nivelAtaque: 70),
  ],
);

void main() {
  test('six categories on the real market, all of distinct classes', () {
    final file = File('web/market_index.json');
    if (!file.existsSync()) return; // a fresh clone has not collected yet

    final index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
    final seis = destaquesDe(index);

    expect(seis, hasLength(6));
    final classes = seis.map((d) => d.personagem.characterClass).toList();
    expect(
      classes.toSet(),
      hasLength(6),
      reason: 'two cards of one class show the same art twice: $classes',
    );
  });

  test('an empty market draws no cards rather than throwing', () {
    expect(destaquesDe(_indiceVazio()), isEmpty);
  });

  test('a category nobody fills is dropped, not faked', () {
    // Nobody at 80: the UP5 cards cannot exist, and the others still do.
    final index = _indiceOnde(ataqueMaximo: 70);
    final rotulos = destaquesDe(index).map((d) => d.rotulo);
    expect(rotulos, isNot(contains(contains('Atq lvl UP5'))));
    expect(rotulos, contains(contains('O mais barato')));
  });

  test(
    'the label softens when a class collision pushes past the true winner',
    () {
      // Two categories whose real winner is the same person: the second says
      // "dos mais baratos", never "o mais barato", because it no longer is.
      final seis = destaquesDe(_indiceComColisao());
      final empurrado = seis.firstWhere((d) => d.rotulo.contains('dos mais'));
      expect(empurrado.rotulo, isNot(contains('o mais')));
    },
  );
}
