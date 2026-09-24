import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/runas/domain/runa.dart';

/// The rune ladder, and the arithmetic a player cannot do in their head.
///
/// Every number here was read off the game by the owner, not derived. The
/// ladder is irregular on purpose — two steps cost six runes and the rest
/// cost three, four or five — so a formula would be a guess dressed as a fact.
void main() {
  test('every level has art, and the art is a rune of that level', () {
    // An invented id draws an empty box — silently wrong on a page whose
    // entire job is telling levels apart. These are checked against the
    // collected market, which is the only thing that knows.
    final arquivo = File('web/market_index.json');
    if (!arquivo.existsSync()) return;

    final index =
        jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>;
    final runas = index['runes'] as Map<String, dynamic>;

    for (var n = 1; n <= nivelMaximo; n++) {
      final kind = runas['${arteDaRuna(n)}'] as Map<String, dynamic>?;
      expect(
        kind,
        isNotNull,
        reason: 'nível $n aponta para um id que o mercado não conhece',
      );
      expect(kind!['level'], n, reason: 'a arte do nível $n é de outro nível');
    }
  });

  group('the ladder', () {
    test('a rune of each level costs what the game says', () {
      // The owner's own list, which the game shows for a level 9 and a level
      // 10. Everything else in this file is derived from these two columns.
      expect(custoEmNivel1(1), 1);
      expect(custoEmNivel1(2), 3);
      expect(custoEmNivel1(3), 9);
      expect(custoEmNivel1(4), 54);
      expect(custoEmNivel1(5), 216);
      expect(custoEmNivel1(6), 864);
      expect(custoEmNivel1(7), 5184);
      expect(custoEmNivel1(8), 25920);
      expect(custoEmNivel1(9), 129600);
      expect(custoEmNivel1(10), 648000);
    });

    test('the whole of the owner\'s level 9 list falls out of it', () {
      // 129600 nv1, 43200 nv2, 14400 nv3, 2400 nv4, 600 nv5, 150 nv6,
      // 25 nv7, 5 nv8 — read off the game window.
      const esperado = {
        1: 129600,
        2: 43200,
        3: 14400,
        4: 2400,
        5: 600,
        6: 150,
        7: 25,
        8: 5,
      };
      for (final entry in esperado.entries) {
        expect(
          custoEmNivel1(9) ~/ custoEmNivel1(entry.key),
          entry.value,
          reason: 'uma runa 9 em runas nível ${entry.key}',
        );
      }
    });

    test('and the level 10 list too, including the step nobody predicted', () {
      // The last rung broke the pattern: 9 -> 10 multiplies by five, not six.
      // A model that had guessed it would have said 777600 here.
      expect(custoEmNivel1(10) ~/ custoEmNivel1(9), 5);
      expect(custoEmNivel1(10) ~/ custoEmNivel1(7), 125);
      expect(custoEmNivel1(10) ~/ custoEmNivel1(5), 3000);
    });

    test('two steps cost six and the rest do not', () {
      // 3 -> 4 and 6 -> 7 are the expensive rungs, and nothing about the
      // neighbouring levels says so. It is the whole reason for the table.
      expect(combustivelPara(4), 5);
      expect(combustivelPara(7), 5);
      expect(combustivelPara(5), 3);
      expect(combustivelPara(10), 4);
    });

    test('a same-level fuel is worth a hundred over what the step needs', () {
      // What the game prints in the fusion window, and what a player checks
      // this tool against.
      expect(porcentagemDoMesmoNivel(2), 50);
      expect(porcentagemDoMesmoNivel(4), closeTo(20, 0.01));
      expect(porcentagemDoMesmoNivel(5), closeTo(33.33, 0.01));
      expect(porcentagemDoMesmoNivel(8), 25);
    });
  });
}
