import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/portas/domain/versao.dart';
import 'package:pw_market_filter/market/versoes.dart';

void main() {
  group('portasDe', () {
    test('every known version gets a door, in a fixed order', () {
      final portas = portasDe(const {});

      expect(portas.map((p) => p.chave).toList(), ['pw187', 'pw126']);
      expect(portas.map((p) => p.nome).toList(), ['1.8.7', '1.2.6']);
      expect(portas.map((p) => p.rota).toList(), ['/1.8.7', '/1.2.6']);
    });

    test('a version with no row in versoes.json is not ready', () {
      final portas = portasDe(const {});

      for (final porta in portas) {
        expect(porta.pronta, isFalse);
        expect(porta.resumo, isNull);
      }
    });

    test('a version with a row is ready and carries its own facts', () {
      final resumo = VersaoResumo(
        chave: 'pw187',
        nome: '1.8.7',
        personagens: 1715,
        coletadoEm: DateTime.utc(2026, 10, 2),
      );

      final portas = portasDe({'pw187': resumo});
      final pw187 = portas.firstWhere((p) => p.chave == 'pw187');
      final pw126 = portas.firstWhere((p) => p.chave == 'pw126');

      expect(pw187.pronta, isTrue);
      expect(pw187.resumo, resumo);
      expect(pw126.pronta, isFalse);
    });
  });
}
