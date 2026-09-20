import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/registros/domain/plano.dart';
import 'package:pw_market_filter/features/registros/domain/registro.dart';

/// What the visitor has marked to do, and what it costs in pages.
///
/// **Pages add up where points did not.** A page is one currency, so thirty
/// plus forty really is seventy; Atk F plus Esquiva was never a quantity of
/// anything, which is why that sum was taken off the panel.

Registro _r({
  String aba = 'Área 1',
  int ordem = 1,
  int? paginas = 1,
  bool semDados = false,
  Map<RegistroAtributo, int> pontos = const {},
}) => Registro(
  aba: aba,
  ordem: ordem,
  nome: 'Registro $aba $ordem',
  paginas: paginas,
  semDados: semDados,
  pontos: pontos,
);

void main() {
  test('nothing marked costs nothing and says nothing', () {
    expect(planoDe([_r()], const {}).vazio, isTrue);
  });

  test('the cost is the pages of what is marked', () {
    final tudo = [
      _r(ordem: 1, paginas: 30),
      _r(ordem: 2, paginas: 40),
      _r(ordem: 3, paginas: 100),
    ];

    final plano = planoDe(tudo, {tudo[0].chave, tudo[1].chave});

    expect(plano.registros, 2);
    expect(plano.paginas, 70);
  });

  test('a plan reaches across tabs, because planning does', () {
    final tudo = [
      _r(aba: 'Área 1', ordem: 1, paginas: 1),
      _r(aba: 'Coletar', ordem: 1, paginas: 65),
    ];

    expect(planoDe(tudo, {tudo[0].chave, tudo[1].chave}).paginas, 66);
  });

  test('a recipe whose cost nobody recorded is counted and flagged', () {
    // It must not quietly contribute zero: the total would read as complete
    // while being short by an unknown amount, which is worse than admitting
    // the gap.
    final tudo = [_r(ordem: 1, paginas: 40), _r(ordem: 2, paginas: null)];

    final plano = planoDe(tudo, {tudo[0].chave, tudo[1].chave});

    expect(plano.registros, 2);
    expect(plano.paginas, 40);
    expect(plano.semCusto, 1);
  });

  test('the same slot in two tabs is two different recipes', () {
    // The key has to carry the tab: slot 1 exists six times.
    final a = _r(aba: 'Área 1', ordem: 1);
    final b = _r(aba: 'Casal', ordem: 1);

    expect(a.chave, isNot(b.chave));
    expect(planoDe([a, b], {a.chave}).registros, 1);
  });

  test('a mark for a recipe that is gone is ignored, never counted', () {
    // A link or a stale state can name a recipe the table no longer has.
    expect(planoDe([_r()], {'Área 9#99'}).registros, 0);
  });

  group('what the plan grants', () {
    test('an attribute adds up across recipes', () {
      // Within one attribute a sum is a real quantity: three Atk F plus
      // fifteen Atk F is eighteen Atk F. It is adding *different* attributes
      // that means nothing, and that is the sum the panel does not show.
      final tudo = [
        _r(ordem: 1, pontos: const {RegistroAtributo.atkF: 3}),
        _r(ordem: 2, pontos: const {RegistroAtributo.atkF: 15}),
      ];

      expect(planoDe(tudo, {tudo[0].chave, tudo[1].chave}).pontos, {
        RegistroAtributo.atkF: 18,
      });
    });

    test('attributes stay apart, never merged into one number', () {
      final tudo = [
        _r(
          ordem: 1,
          pontos: const {RegistroAtributo.atkF: 3, RegistroAtributo.esquiva: 6},
        ),
        _r(ordem: 2, pontos: const {RegistroAtributo.esquiva: 12}),
      ];

      expect(planoDe(tudo, {tudo[0].chave, tudo[1].chave}).pontos, {
        RegistroAtributo.atkF: 3,
        RegistroAtributo.esquiva: 18,
      });
    });

    test('only what is marked counts', () {
      final tudo = [
        _r(ordem: 1, pontos: const {RegistroAtributo.hp: 30}),
        _r(ordem: 2, pontos: const {RegistroAtributo.hp: 90}),
      ];

      expect(planoDe(tudo, {tudo[0].chave}).pontos, {RegistroAtributo.hp: 30});
    });

    test('a recipe nobody read adds nothing and is still counted apart', () {
      final tudo = [
        _r(ordem: 1, pontos: const {RegistroAtributo.atkF: 5}),
        _r(ordem: 2, semDados: true),
      ];

      final plano = planoDe(tudo, {tudo[0].chave, tudo[1].chave});

      expect(plano.pontos, {RegistroAtributo.atkF: 5});
      expect(plano.registros, 2);
    });

    test('the attributes come in the order the screen uses', () {
      // A total whose lines reshuffle between two marks is a total nobody can
      // compare against the one they just read.
      final tudo = [
        _r(
          ordem: 1,
          pontos: const {RegistroAtributo.hp: 30, RegistroAtributo.atkF: 3},
        ),
      ];

      expect(planoDe(tudo, {tudo[0].chave}).pontos.keys, [
        RegistroAtributo.atkF,
        RegistroAtributo.hp,
      ]);
    });
  });
}
