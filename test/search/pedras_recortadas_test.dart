@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/stone_set_criterion.dart';
import 'package:pw_market_filter/market/set_stones.dart';

/// Os ícones recortados que o chip desenha.
///
/// **O chip chama `StoneIcon`, que desenha nada quando o ficheiro falta** —
/// o mesmo recuo silencioso do `ItemIcon`, e aqui ele esconderia um chip sem
/// ícone em vez de falhar. Este teste é o que torna a falta visível.
void main() {
  test('cada conjunto oferecido tem a sua pedra recortada em disco', () {
    for (final s in setsDisponiveis) {
      final pedra = equipmentStoneOf(s.kind, s.level);
      final f = File('assets/icons/pedras/${pedra.id}.png');
      expect(
        f.existsSync(),
        isTrue,
        reason:
            '${pedra.name} (${pedra.id}) não está recortada. '
            'Corra `python3 tool/pedras/recortar.py`.',
      );
    }
  });

  test('o recorte tem mesmo transparência, e não é o ficheiro original', () {
    // Um `cp` de `items/` para `pedras/` passaria no teste acima e desenharia
    // a moldura de volta. O PNG recortado tem de ser menor que 32 px e
    // carregar alfa — as duas coisas que o corte faz.
    for (final s in setsDisponiveis) {
      final pedra = equipmentStoneOf(s.kind, s.level);
      final bytes = File('assets/icons/pedras/${pedra.id}.png').readAsBytesSync();

      // Cabeçalho PNG: largura e altura são big-endian nos bytes 16..23.
      final largura =
          (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
      expect(
        largura,
        lessThan(32),
        reason: '${pedra.name} ainda tem 32 px — a moldura não foi cortada',
      );

      // Byte 25 é o tipo de cor: 6 é RGBA.
      expect(
        bytes[25],
        6,
        reason: '${pedra.name} não tem canal alfa',
      );
    }
  });

  test('o script recorta as cinco de equipamento, e só essas', () {
    // As de acessório não cortam — brilho mediano de 157 contra 53 — e por
    // isso não são geradas. Se alguém as acrescentar sem medir outra vez,
    // este teste diz que a ausência era decisão.
    final naPasta = Directory('assets/icons/pedras')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.png'))
        .length;
    final deEquipamento = setStones.where((p) => !p.accessory).length;
    expect(naPasta, deEquipamento);
  });
}
