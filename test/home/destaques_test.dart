import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/destaques.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/ui/widgets/character_card.dart'
    show weaponTierColor;
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Pins `destaquesDe`: which six characters the front page shows, and why.
///
/// The distinct-class rule is the delicate part, and it is only exercised by
/// the real collection — the two synthetic fixtures in this file are too
/// small to reproduce the collision on their own, so the market-backed tests
/// below read `web/market_index.json` directly rather than trusting a
/// hand-built index to be representative.

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

/// A market where the cheapest carrier of at least 70 attack level actually
/// wears 80 — nobody cheaper wears exactly 70. `strongWeaponQuery` asks for
/// *at least* 70, so this is a legal result, not a broken collection.
///
/// A second, cheaper character of a different class is needed so category 1
/// ("O mais barato") takes *him* rather than the 80-carrier — leaving the
/// 80-carrier free to win category 2 instead of being spent, and dropped, by
/// the class-collision rule.
MarketIndex _indiceComVencedorDeOitenta() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const ['Nível de Ataque'],
  items: const {},
  characters: [
    _personagem('barato', 10, 'Mago'),
    _personagem('oitenta', 100, 'Guerreiro', nivelAtaque: 80),
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

  test(
    'every card\'s frame is exactly weaponTierColor, never a parallel ladder',
    () {
      // Pins the agreement, not the colours: a test that hardcoded amber
      // would stay green even if both ladders drifted together in the wrong
      // direction. Two cards landing on the same colour is expected, not a
      // bug — the frame says what the person wears, not which question the
      // card answers.
      final file = File('web/market_index.json');
      if (!file.existsSync()) return; // a fresh clone has not collected yet

      final index = MarketIndex.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );

      for (final destaque in destaquesDe(index)) {
        expect(
          destaque.cor,
          weaponTierColor(index, destaque.personagem),
          reason:
              '${destaque.rotulo} (${destaque.personagem.name}) disagrees '
              'with the results grid about its own frame',
        );
      }
    },
  );

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

  test(
    "the keys card's door contains its own subject and its note's count",
    () {
      // `shownOwned` alone prints the count but filters nobody — it used to
      // open onto the whole market with the card's own subject off the first
      // screen and the result count contradicting the note on the card. The
      // door must at least contain the character it names, and the
      // destination's size must agree with what the card already says.
      final file = File('web/market_index.json');
      if (!file.existsSync()) return; // a fresh clone has not collected yet

      final index = MarketIndex.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
      final cartao = destaquesDe(
        index,
      ).firstWhere((d) => d.rotulo.contains('Chaves da Sorte'));

      final destino = runQuery(index, cartao.busca);
      expect(
        destino.map((c) => c.roleId),
        contains(cartao.personagem.roleId),
        reason: "the card's door must show the character it names",
      );
      expect(
        destino.length.toString(),
        cartao.nota.split(' ').first,
        reason: "the door's result count must match the card's own note",
      );
    },
  );

  test('the weapon card\'s badge is the winner\'s own worn attack level, never '
      'a hardcoded 70', () {
    // Finding 6 of the 2026-10-01 review: `strongWeaponQuery` asks **at
    // least** 70, and the market has an 80 tier above it, so a
    // cheapest-first winner can genuinely wear 80. A badge that always
    // printed "ARMA 70" would be the fourth appearance of a shape
    // CLAUDE.md already names three times — a label asserting a number the
    // data does not support.
    final file = File('web/market_index.json');
    if (!file.existsSync()) return; // a fresh clone has not collected yet

    final index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
    final cartao = destaquesDe(
      index,
    ).firstWhere((d) => d.rotulo.contains('Arma de'));

    final id = index.attributes.indexOf('Nível de Ataque');
    final arma = cartao.personagem.equipped.firstWhere(
      (item) => item.slot == weaponSlot,
    );
    final nivelReal = arma.attributes[id] ?? 0;

    expect(cartao.selo, 'ARMA $nivelReal');
    expect(cartao.rotulo, contains('Arma de $nivelReal'));
  });

  test(
    'an 80-carrier winning the 70-weapon category badges itself 80, not 70',
    () {
      // Synthetic because today's real market happens to land this category
      // on an exact 70 (SK_Alya, 45 TCC) — true, but latent, which is exactly
      // the shape Finding 6 warns about. This market forces the 80 case so a
      // hardcoded "ARMA 70" cannot hide behind the real collection agreeing
      // with it by coincidence.
      final seis = destaquesDe(_indiceComVencedorDeOitenta());
      final cartao = seis.firstWhere((d) => d.rotulo.contains('Arma de'));

      expect(cartao.selo, 'ARMA 80');
      expect(cartao.rotulo, 'Arma de 80 mais barata');
    },
  );
}
