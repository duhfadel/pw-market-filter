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

  layout();

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

/// The slot layout, which the game does not fill in sequence.
///
/// Coletar has sixteen recipes and draws them 8, 2, 6 — so slots 11 to 16 of
/// row two are empty and row three starts at slot 17. Reading `ordem` as "the
/// nth recipe" put every icon after the eighth in the wrong place.
void layout() {
  group('slots and gaps', () {
    test('a tab that fills every slot needs as many rows as it needs', () {
      expect(linhasDaGrade([1, 2, 3, 4, 5, 6, 7, 8]), 1);
      expect(linhasDaGrade([1, 8, 9]), 2);
      expect(linhasDaGrade(List.generate(32, (i) => i + 1)), 4);
    });

    test('an empty last row is not drawn', () {
      // The game shows four rows always. Drawing a row of nothing is fidelity
      // to a frame rather than to the layout, and on a phone it is a screen of
      // nothing.
      expect(linhasDaGrade([1, 2, 9, 10, 17, 18]), 3);
    });

    test('a gap is a slot nobody claims, not a shifted neighbour', () {
      // Coletar: 8, 2, 6.
      final ocupados = [
        ...List.generate(8, (i) => i + 1),
        9,
        10,
        ...List.generate(6, (i) => 17 + i),
      ];

      expect(linhasDaGrade(ocupados), 3);
      expect(ocupados, isNot(contains(11)));
      expect(ocupados.last, 22);
    });
  });
}
