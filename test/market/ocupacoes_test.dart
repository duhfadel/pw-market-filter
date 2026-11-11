import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/ocupacoes.dart';

/// **A tabela é escrita à mão e o mercado é quem a confere.**
///
/// Uma ocupação errada desenha o ícone de outra classe — não falha, não
/// avisa, só mostra o Mago onde devia estar o Bardo. É o mesmo tipo de
/// defeito silencioso que a arte do Ceifador já pagou nas Sagas, e a cura é
/// a mesma: cravar contra uma fonte que não é esta.
void main() {
  test('cada classe do índice real casa com a ocupação escrita à mão', () {
    final ficheiro = File('web/market_index.json');
    if (!ficheiro.existsSync()) {
      // Um índice que não está em disco não é defeito nosso — ver a regra do
      // `counted_items_test`: uma suíte não congela por falta de recolha.
      return;
    }

    final indice = jsonDecode(ficheiro.readAsStringSync()) as Map;
    final vistas = <String, Set<int>>{};
    for (final c in indice['characters'] as List) {
      final mapa = c as Map;
      vistas
          .putIfAbsent(mapa['class'] as String, () => <int>{})
          .add((mapa['occupation'] as num).toInt());
    }

    expect(vistas, isNotEmpty, reason: 'o índice não trouxe personagem nenhum');

    for (final entrada in vistas.entries) {
      expect(
        entrada.value.length,
        1,
        reason: '${entrada.key} aparece com mais de uma ocupação',
      );
      expect(
        ocupacaoDaClasse[entrada.key],
        entrada.value.single,
        reason: '${entrada.key} mudou de ocupação ou falta na tabela',
      );
    }
  });

  test('são dezassete e a ordem é a da ocupação', () {
    expect(classesDoJogo.length, 17);
    expect(classesDoJogo.first, 'Guerreiro');
    expect(ocupacaoDaClasse.values.toList(), List.generate(17, (i) => i));
  });
}
