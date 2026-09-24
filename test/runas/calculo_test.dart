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

  test('more than enough is still enough, never a negative errand', () {
    final r = calcular(alvo: 4, estoque: {5: 1});

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
  });
}
