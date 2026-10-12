import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/portas/domain/versao.dart';
import 'package:pw_market_filter/market/versoes.dart';

void main() {
  group('portasDe', () {
    test('every known version gets a door, in a fixed order', () {
      final portas = portasDe(const {});

      // Por ordem de versão, do 1.2.6 ao 1.8.7 — escolha do dono em
      // 12/10/2026. A ordem explica-se sozinha e põe o 1.4.4, que ainda não
      // lançou, entre os vizinhos em vez de pendurado no fim.
      expect(portas.map((p) => p.chave).toList(), ['pw126', 'pw144', 'pw187']);
      expect(portas.map((p) => p.nome).toList(), ['1.2.6', '1.4.4', '1.8.7']);
      // O 1.4.4 ainda não lançou: porta sem rota, de propósito. `/1.4.4`
      // cairia no próprio ecrã de escolha, e uma porta que abre para onde já
      // se está é pior do que uma porta fechada.
      expect(portas.map((p) => p.rota).toList(), ['/1.2.6', null, '/1.8.7']);
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

  test('uma coleta sozinha não abre uma porta que não tem rota', () {
    // **A armadilha que isto fecha é real e já mordeu no mapa de guerras**,
    // onde `tem_ficha` discordava do que a página desenhava: um território
    // clicável abria uma ficha vazia. Aqui bastaria alguém acrescentar uma
    // linha `pw144` ao `versoes.json` — à mão, ou um coletor novo — para a
    // porta acender e levar a lado nenhum.
    final comColeta = portasDe({
      'pw144': VersaoResumo(
        chave: 'pw144',
        nome: '1.4.4',
        personagens: 10,
        coletadoEm: DateTime.utc(2026, 10, 12),
      ),
    });
    final porta = comColeta.firstWhere((p) => p.chave == 'pw144');

    expect(porta.resumo, isNotNull);
    expect(porta.pronta, isFalse);
  });
}
