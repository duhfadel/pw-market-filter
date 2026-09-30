import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/runas/domain/calculo.dart';
import 'package:pw_market_filter/features/runas/domain/runa.dart';

/// What is still missing, given what somebody already owns.
void main() {
  test('the owner\'s own example: a level 9 with two level 7 in hand', () {
    final r = calcular(alvo: 9, estoque: {7: 2});

    // 25 level sevens make a level nine, and two are already in the drawer.
    expect(r.faltaEm(7), 23);
    expect(r.faltaEm(5), 552);
    expect(r.faltaEm(1), 119232);
  });

  test('an empty drawer asks for the whole ladder', () {
    final r = calcular(alvo: 10, estoque: const {});

    expect(r.faltaEm(1), 648000);
    expect(r.faltaEm(5), 3000);
    expect(r.faltaEm(7), 125);
  });

  test('stock of mixed levels adds up by what it is worth', () {
    // One level 8 is 25920 level ones and one level 5 is 216; together they
    // cover 26136 of the 129600 a level 9 costs.
    final r = calcular(alvo: 9, estoque: {8: 1, 5: 1});

    expect(r.restante, 129600 - 25920 - 216);
  });

  test('enough in hand leaves nothing to find', () {
    // Five level eights are exactly a level nine. The screen has to say
    // "you already have it" rather than "0 runes missing", which reads as an
    // error.
    final r = calcular(alvo: 9, estoque: {8: 5});

    expect(r.restante, 0);
    expect(r.jaDa, isTrue);
  });

  test('a bigger rune is not a smaller one, and never was', () {
    // This test used to assert the opposite — that owning a level 5 settled a
    // level 4 — under the name "more than enough is still enough". The owner
    // reported the same shape from the screen on 30/09/2026 and called it a
    // bug, and he is right about the game: **a rune is fused with runes at its
    // own level or below**, so a 5 cannot be taken apart into 4s.
    //
    // The old name was about never printing a negative errand, which the
    // clamp below still guarantees. What it should never have bought was the
    // claim that a higher rune is spendable.
    final r = calcular(alvo: 4, estoque: {5: 1});

    expect(r.restante, greaterThan(0));
    expect(r.jaDa, isFalse);
  });

  test('a negative errand is still impossible', () {
    // The half of the old test that was always right.
    final r = calcular(alvo: 4, estoque: {3: 99});

    expect(r.restante, 0);
    expect(r.jaDa, isTrue);
  });

  test('a scale that does not divide evenly rounds up', () {
    // Two level sevens are 40% of a level eight, so what is left is 4.6 of
    // them. Nobody can buy six tenths of a rune: the errand is five, and the
    // finer scales are where the leftover shows.
    final r = calcular(alvo: 9, estoque: {7: 2});

    expect(r.faltaEm(8), 5);
  });

  group('a line per level, cascading what does not divide', () {
    test('an exact level is one parcel', () {
      final r = calcular(alvo: 9, estoque: {7: 2});

      expect(r.linhaDe(7), [const Parcela(nivel: 7, quantos: 23)]);
      expect(r.linhaDe(5), [const Parcela(nivel: 5, quantos: 552)]);
    });

    test('a remainder is paid in the biggest coin that fits', () {
      // 119.232 is four level eights and 15.552 over — and that leftover is
      // exactly three level sevens. Saying `15.552 nível 1` would be the same
      // debt in a currency nobody goes shopping with.
      final r = calcular(alvo: 9, estoque: {7: 2});

      expect(r.linhaDe(8), [
        const Parcela(nivel: 8, quantos: 4),
        const Parcela(nivel: 7, quantos: 3),
      ]);
    });

    test('every line adds back up to the same debt', () {
      // The lines are alternatives, so each has to be worth the whole thing.
      // A cascade that loses a rune would be invisible on screen.
      final r = calcular(alvo: 10, estoque: {8: 3, 5: 7});

      for (final nivel in r.escalas) {
        final soma = r
            .linhaDe(nivel)
            .fold(0, (t, p) => t + p.quantos * custoEmNivel1(p.nivel));
        expect(soma, r.restante, reason: 'a linha do nível $nivel');
      }
    });

    test('the levels offered are every one below the target', () {
      expect(calcular(alvo: 10, estoque: const {}).escalas, [
        9,
        8,
        7,
        6,
        5,
        4,
        3,
        2,
        1,
      ]);
      expect(calcular(alvo: 3, estoque: const {}).escalas, [2, 1]);
    });
    test('stock above the target cannot be spent on it', () {
      // Reported from the screen on 30/09/2026: pick a level 9, mark some
      // level 8s, then drop the target to 5 — and the page announced the
      // rune was already affordable.
      //
      // It is not. The game's rule, and the one this whole calculator rests
      // on, is that **fuel may never be above the centre's level**: a level 8
      // does not feed a level 5 fusion. Counting it turned three unusable
      // runes into an answer of zero.
      //
      // Worse than wrong, it was invisible: the chips stop at one below the
      // target, so the stock producing the answer had no control on screen.
      expect(calcular(alvo: 5, estoque: const {8: 3}).restante, greaterThan(0));

      final semAjuda = calcular(alvo: 5, estoque: const {1: 10}).restante;
      final comInutil = calcular(
        alvo: 5,
        estoque: const {1: 10, 8: 3},
      ).restante;
      expect(
        comInutil,
        semAjuda,
        reason: 'a level 8 is unusable here, so it must change nothing',
      );
    });

    test('stock at exactly the target is the rune itself', () {
      // Owning one is the one case where "nothing left to get" is true.
      expect(calcular(alvo: 5, estoque: const {5: 1}).restante, 0);
    });

    test('what is below the target still counts, whatever the mix', () {
      final r = calcular(alvo: 6, estoque: const {5: 1, 4: 2, 1: 7});
      final esperado =
          custoEmNivel1(6) - (custoEmNivel1(5) + 2 * custoEmNivel1(4) + 7);
      expect(r.restante, esperado);
    });
  });
}
