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

    test('two attributes mean both, and narrow instead of widening', () {
      // An "or" widens: ticking a second box would light *more* slots, which
      // reads as the filter going backwards. Both is what somebody building a
      // character asks — "which of these gives me evasion *and* attack".
      const dois = RegistroQuery(
        aba: 'Área 1',
        atributos: {RegistroAtributo.esquiva, RegistroAtributo.atkF},
      );

      expect(atende(comEsquiva, dois), isFalse);
      expect(atende(comAtaque, dois), isFalse);
      expect(
        atende(
          _r(
            pontos: const {
              RegistroAtributo.esquiva: 6,
              RegistroAtributo.atkF: 3,
            },
          ),
          dois,
        ),
        isTrue,
      );
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

  group('which attributes can still be added', () {
    // The same rule the market's filter follows: a control offers what still
    // leads somewhere. Ticking a box that empties the grid teaches nothing and
    // gives no hint which choice did it.
    final daAba = [
      _r(
        ordem: 1,
        pontos: const {RegistroAtributo.atkF: 3, RegistroAtributo.esquiva: 6},
      ),
      _r(ordem: 2, pontos: const {RegistroAtributo.hp: 30}),
      _r(ordem: 3, semDados: true),
    ];

    test('with nothing chosen, every attribute somebody grants is offered', () {
      const nada = RegistroQuery(aba: 'Área 1');

      expect(atributosDisponiveis(daAba, nada), {
        RegistroAtributo.atkF,
        RegistroAtributo.esquiva,
        RegistroAtributo.hp,
      });
    });

    test('choosing one drops what no surviving recipe also grants', () {
      // Nothing gives Atk F and HP together, so HP stops being offered — the
      // question it would ask has no answer.
      const so = RegistroQuery(
        aba: 'Área 1',
        atributos: {RegistroAtributo.atkF},
      );

      expect(atributosDisponiveis(daAba, so), {
        RegistroAtributo.atkF,
        RegistroAtributo.esquiva,
      });
    });

    test('what is already chosen stays offered, so it can be turned off', () {
      // Otherwise the last choice becomes a trap: the box that emptied the
      // grid would be the one box nobody can untick.
      const so = RegistroQuery(aba: 'Área 1', atributos: {RegistroAtributo.hp});

      expect(atributosDisponiveis(daAba, so), contains(RegistroAtributo.hp));
    });

    test('an attribute nobody in the tab grants is never offered', () {
      const nada = RegistroQuery(aba: 'Área 1');

      expect(
        atributosDisponiveis(daAba, nada),
        isNot(contains(RegistroAtributo.defM)),
      );
    });
  });
}
