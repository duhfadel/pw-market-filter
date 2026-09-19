import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/registros/domain/registro.dart';
import 'package:pw_market_filter/features/registros/domain/registro_filter.dart';

Registro _r({
  String aba = 'Área 1',
  int ordem = 1,
  int? paginas = 1,
  bool semDados = false,
  Map<RegistroAtributo, int> pontos = const {},
}) => Registro(
  aba: aba,
  ordem: ordem,
  nome: 'Registro $ordem',
  paginas: paginas,
  semDados: semDados,
  pontos: pontos,
);

void main() {
  group('the attribute filter', () {
    final comEsquiva = _r(pontos: const {RegistroAtributo.esquiva: 6});
    final comAtaque = _r(ordem: 2, pontos: const {RegistroAtributo.atkF: 3});

    test('asking nothing lights every slot', () {
      const nada = RegistroQuery(aba: 'Área 1');

      expect(atende(comEsquiva, nada), isTrue);
      expect(atende(comAtaque, nada), isTrue);
    });

    test('one attribute lights only what grants it', () {
      const so = RegistroQuery(
        aba: 'Área 1',
        atributos: {RegistroAtributo.esquiva},
      );

      expect(atende(comEsquiva, so), isTrue);
      expect(atende(comAtaque, so), isFalse);
    });

    test('two attributes mean either, never both at once', () {
      // An "and" would answer a question nobody asked: somebody after evasion
      // wants what grants it, not what grants it *together with* the other
      // box they happened to tick.
      const dois = RegistroQuery(
        aba: 'Área 1',
        atributos: {RegistroAtributo.esquiva, RegistroAtributo.atkF},
      );

      expect(atende(comEsquiva, dois), isTrue);
      expect(atende(comAtaque, dois), isTrue);
    });

    test('a recipe nobody checked is lit by nothing', () {
      const so = RegistroQuery(
        aba: 'Casal',
        atributos: {RegistroAtributo.atkF},
      );

      expect(atende(_r(aba: 'Casal', semDados: true), so), isFalse);
    });
  });

  group('the grid', () {
    final tudo = [
      _r(ordem: 1, paginas: 1, pontos: const {RegistroAtributo.atkF: 10}),
      _r(ordem: 2, paginas: 100, pontos: const {RegistroAtributo.hp: 90}),
      _r(ordem: 3, paginas: 1, pontos: const {RegistroAtributo.atkM: 118}),
      _r(ordem: 4, aba: 'Casal', semDados: true),
    ];

    test('draws one tab and keeps the NPC slot order', () {
      const query = RegistroQuery(aba: 'Área 1');

      expect(paraGrade(tudo, query).map((r) => r.ordem), [1, 2, 3]);
    });

    test('by value it is the best trade first', () {
      const query = RegistroQuery(aba: 'Área 1', porAproveitamento: true);

      // 118 por página, 10, e 0,9 por último.
      expect(paraGrade(tudo, query).map((r) => r.ordem), [3, 1, 2]);
    });

    test('a slot with no rate sinks instead of sorting as the worst', () {
      final comBranco = [
        ...tudo.where((r) => r.aba == 'Área 1'),
        _r(ordem: 5, semDados: true),
      ];
      const query = RegistroQuery(aba: 'Área 1', porAproveitamento: true);

      expect(paraGrade(comBranco, query).last.ordem, 5);
    });

    test('the filter never removes a slot, only the light on it', () {
      // The grid has to keep the game's shape: a player is looking at the same
      // window on another screen and has to find the same slot in the same
      // place.
      const query = RegistroQuery(
        aba: 'Área 1',
        atributos: {RegistroAtributo.hp},
      );

      expect(paraGrade(tudo, query), hasLength(3));
      expect(
        paraGrade(tudo, query).where((r) => atende(r, query)),
        hasLength(1),
      );
    });
  });
}
