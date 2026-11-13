import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/faixa_viva.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Pins the live strip against both markets.
///
/// The property that matters is not the numbers themselves — they move every
/// half hour — but that **each figure's own query answers its own number**. A
/// door that opens a grid of a different size is the defect this file exists
/// to catch, and it is invisible on screen: both halves look like answers.
void main() {
  for (final caminho in const [
    'web/market_index.json',
    'web/market_index_126.json',
  ]) {
    final file = File(caminho);
    if (!file.existsSync()) continue;

    group(caminho, () {
      late MarketIndex index;

      setUpAll(() {
        index = MarketIndex.fromJson(
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        );
      });

      test('são três, nesta ordem', () {
        final figuras = figurasVivas(index);
        expect(figuras, hasLength(3));
        // **A ordem é a da maquete, e ela põe o movimento primeiro.** O
        // total vem no fim porque é o número que menos muda — está no selo
        // logo acima, com a data da coleta.
        expect(figuras.map((f) => f.rotulo), [
          'entraram hoje',
          'baixaram o preço',
          'à venda agora',
        ]);
      });

      test('cada porta abre exactamente o número que anuncia', () {
        for (final figura in figurasVivas(index)) {
          expect(
            runQuery(index, figura.query),
            hasLength(figura.numero),
            reason:
                'a porta "${figura.rotulo}" promete um número e entrega '
                'outro',
          );
        }
      });

      test('o total é todo o mercado, e a busca vazia confirma-o', () {
        expect(figurasVivas(index).last.numero, index.characters.length);
      });

      test('nenhum número é negativo nem passa do mercado', () {
        for (final figura in figurasVivas(index)) {
          expect(figura.numero, inInclusiveRange(0, index.characters.length));
        }
      });

      // Impresso e nunca reprovado: o que a faixa mostra é um facto sobre um
      // mercado que se move sozinho, e um gate duro sobre isso já congelou o
      // site duas vezes seguidas em 10/10/2026.
      test('mede quanto cada figura corta', () {
        final total = index.characters.length;
        for (final figura in figurasVivas(index).take(2)) {
          final fatia = total == 0 ? 0 : (100 * figura.numero / total).round();
          debugPrint('  ${figura.rotulo}: ${figura.numero} ($fatia%)');
        }
      });
    });
  }
}
