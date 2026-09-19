import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/registros/domain/registro.dart';

/// The model behind `/registros`.
///
/// Its whole job is to keep two things apart that a row of numbers would
/// merge: an attribute a recipe does **not** grant, which is a zero, and a
/// recipe nobody has checked, which is an absence. The screen says different
/// things about them, so the model has to.

Registro _registro({
  String aba = 'Área 1',
  int ordem = 1,
  String nome = 'Registro: Cidade do Dragão',
  int? paginas = 1,
  bool semDados = false,
  Map<RegistroAtributo, int> pontos = const {},
}) => Registro(
  aba: aba,
  ordem: ordem,
  nome: nome,
  paginas: paginas,
  semDados: semDados,
  pontos: pontos,
);

void main() {
  group('reading a row', () {
    test('keeps only the attributes a recipe actually grants', () {
      final r = Registro.fromJson(const {
        'aba': 'Área 1',
        'ordem': 1,
        'nome': 'Registro: Cidade do Dragão',
        'paginas': 1,
        'sem_dados': false,
        'atk_f': 3,
        'atk_m': 3,
        'def_f': 0,
        'def_m': 0,
        'acerto': 6,
        'esquiva': 6,
        'hp': 0,
      });

      // The zeros are dropped on the way in: the card prints what a recipe
      // gives, and a row of `Def F 0` is noise that pushes the real numbers
      // off a phone's screen.
      expect(r.pontos, {
        RegistroAtributo.atkF: 3,
        RegistroAtributo.atkM: 3,
        RegistroAtributo.acerto: 6,
        RegistroAtributo.esquiva: 6,
      });
      expect(r.semDados, isFalse);
    });

    test('a recipe nobody checked carries no points and says so', () {
      final r = Registro.fromJson(const {
        'aba': 'Casal',
        'ordem': 1,
        'nome': 'Registro: Orvalho Dourado',
        'paginas': 1,
        'sem_dados': true,
        'atk_f': 0,
        'atk_m': 0,
        'def_f': 0,
        'def_m': 0,
        'acerto': 0,
        'esquiva': 0,
        'hp': 0,
      });

      expect(r.semDados, isTrue);
      expect(r.pontos, isEmpty);
    });

    test('a missing page count is null, never zero', () {
      // `Arqueólogo Esp.` has its page count in the wrong column at the
      // source. Zero would read as "this one is free", which is a lie the
      // screen would repeat.
      final r = Registro.fromJson(const {
        'aba': 'Área 2',
        'ordem': 8,
        'nome': 'Registro: Arqueólogo Esp.',
        'paginas': null,
        'sem_dados': true,
      });

      expect(r.paginas, isNull);
    });
  });

  group('what the numbers add up to', () {
    test('the total is every point it grants', () {
      final r = _registro(
        pontos: const {
          RegistroAtributo.atkF: 15,
          RegistroAtributo.atkM: 25,
          RegistroAtributo.defF: 39,
          RegistroAtributo.defM: 39,
        },
      );

      expect(r.total, 118);
    });

    test('points per page is the reading the game never offers', () {
      final caro = _registro(
        paginas: 100,
        pontos: const {RegistroAtributo.hp: 90},
      );
      final barato = _registro(
        paginas: 1,
        pontos: const {RegistroAtributo.atkF: 118},
      );

      expect(caro.porPagina, 0.9);
      expect(barato.porPagina, 118);
    });

    test(
      'with no page count there is no rate, rather than a division by zero',
      () {
        expect(
          _registro(
            paginas: null,
            pontos: const {RegistroAtributo.atkF: 5},
          ).porPagina,
          isNull,
        );
      },
    );

    test('an unchecked recipe has no rate even though its total is zero', () {
      // Otherwise it would sort as the worst trade in the game, which is a
      // claim about a recipe nobody has read.
      expect(_registro(semDados: true).porPagina, isNull);
    });
  });

  group('the grid', () {
    test('slots keep the order the NPC shows, never alphabetical', () {
      final soltos = [
        _registro(ordem: 3, nome: 'Registro: Rio Congelado'),
        _registro(ordem: 1, nome: 'Registro: Cidade do Dragão'),
        _registro(ordem: 2, nome: 'Registro: Terra Cruel'),
      ];

      expect(ordenados(soltos).map((r) => r.ordem), [1, 2, 3]);
    });

    test('tabs come in the NPC order, not the order the rows arrived', () {
      final tudo = [
        _registro(aba: 'Casal'),
        _registro(aba: 'Área 1'),
        _registro(aba: 'Coletar'),
        _registro(aba: 'Área 2'),
      ];

      expect(abasDe(tudo), ['Área 1', 'Área 2', 'Coletar', 'Casal']);
    });

    test('an unknown tab lands at the end instead of vanishing', () {
      // A tab added to the table before this list knows about it must still
      // reach the screen: silently dropping rows is how a table grows a hole
      // nobody notices.
      final tudo = [_registro(aba: 'Pescaria'), _registro(aba: 'Área 1')];

      expect(abasDe(tudo), ['Área 1', 'Pescaria']);
    });
  });
}
