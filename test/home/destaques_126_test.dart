import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/destaques.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Pins `destaques126De`: two cards, never six, and the same distinct-class
/// rule `destaquesDe` already follows — see `destaques_test.dart` for the
/// 1.8.7 half of this pair.
///
/// The real-market tests below read `web/market_index_126.json` directly
/// rather than trusting a hand-built index to be representative, the same
/// reasoning `destaques_test.dart` already gives for its own real-index
/// tests.

MarketIndex _indiceVazio() => MarketIndex(
  server: 'pw126',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: const [],
);

MarketCharacter _personagem(String nome, int preco, String classe) =>
    MarketCharacter(
      roleId: nome.hashCode,
      name: nome,
      characterClass: classe,
      occupation: 1,
      level: 100,
      price: preco,
      fame: 0,
      cultivation: 'Leal',
      // 1.2.6 has no `Nível de Ataque`/`Nível de Defesa` vocabulary at all —
      // an empty weapon slot is the honest shape of that collection, and it
      // is what keeps `weaponTierColor` returning `null` for every card here,
      // same as it does on the real 1.2.6 index.
      equipped: const [],
    );

/// Six characters of six distinct classes, cheapest to dearest — no
/// collision possible, so this is the plain case both cards exist and name
/// different people.
MarketIndex _indiceDeSeisClasses() => MarketIndex(
  server: 'pw126',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: [
    _personagem('barato', 10, 'Feiticeira'),
    _personagem('mago', 50, 'Mago'),
    _personagem('arqueiro', 80, 'Arqueiro'),
    _personagem('barbaro', 120, 'Bárbaro'),
    _personagem('sacerdote', 200, 'Sacerdote'),
    _personagem('caro', 9000, 'Guerreiro'),
  ],
);

/// A market where the cheapest character and the true dearest share a class:
/// `barato` is both the cheapest overall (10) and a Guerreiro, and
/// `caroGuerreiro` is the true dearest (9000) and a Guerreiro too. Category 1
/// spends `Guerreiro` on `barato`, so category 2 has to fall past
/// `caroGuerreiro` to `segundoCaroLivre` (5000, Mago) — dearer than `barato`
/// but not the true dearest, of a class nobody has used yet.
MarketIndex _indiceComColisao() => MarketIndex(
  server: 'pw126',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: [
    _personagem('barato', 10, 'Guerreiro'),
    _personagem('segundoCaroLivre', 5000, 'Mago'),
    _personagem('caroGuerreiro', 9000, 'Guerreiro'),
  ],
);

void main() {
  test('two cards on the real 1.2.6 market, never six', () {
    final file = File('web/market_index_126.json');
    if (!file.existsSync()) return; // a fresh clone has not collected yet

    final index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
    final cartas = destaques126De(index);

    expect(cartas.length, lessThanOrEqualTo(2));
    expect(
      cartas.map((d) => d.rotulo),
      isNot(
        anyOf(
          contains(contains('Arma de')),
          contains(contains('UP5')),
          contains(contains('relíquias')),
        ),
      ),
      reason:
          'the 1.2.6 home asks no question this market has not been '
          'studied for',
    );
  });

  test('the two cards are of distinct classes on a six-class market', () {
    final cartas = destaques126De(_indiceDeSeisClasses());

    expect(cartas, hasLength(2));
    final classes = cartas.map((d) => d.personagem.characterClass).toSet();
    expect(classes, hasLength(2));
  });

  test(
    'the dearest card softens when it shares the cheapest card\'s class',
    () {
      final cartas = destaques126De(_indiceComColisao());

      expect(cartas, hasLength(2));
      final maisBarato = cartas.firstWhere((d) => d.rotulo.contains('barato'));
      final maisCaro = cartas.firstWhere((d) => d.rotulo.contains('caro'));

      expect(maisBarato.personagem.name, 'barato');
      expect(maisBarato.rotulo, 'O mais barato');
      // `caroGuerreiro` is the true dearest but shares `barato`'s already-spent
      // class, so the card falls through to `segundoCaroLivre` — of a free
      // class — and the label has to say it no longer names the true winner.
      expect(maisCaro.personagem.name, 'segundoCaroLivre');
      expect(maisCaro.rotulo, 'Um dos mais caros');
    },
  );

  test('an empty market draws no cards rather than throwing', () {
    expect(destaques126De(_indiceVazio()), isEmpty);
  });

  test('a single-class market yields only one card, not a repeat', () {
    final umaClasse = MarketIndex(
      server: 'pw126',
      collectedAt: DateTime.utc(2026, 10, 1),
      attributes: const [],
      items: const {},
      characters: [
        _personagem('a', 10, 'Mago'),
        _personagem('b', 9000, 'Mago'),
      ],
    );

    final cartas = destaques126De(umaClasse);

    expect(cartas, hasLength(1));
    expect(cartas.single.rotulo, 'O mais barato');
  });

  test('every card frame reads the worn weapon, same as destaquesDe, and is '
      'null where 1.2.6 has no attack-level attribute at all', () {
    final cartas = destaques126De(_indiceDeSeisClasses());

    for (final destaque in cartas) {
      expect(destaque.cor, isNull, reason: destaque.rotulo);
    }
  });
}
