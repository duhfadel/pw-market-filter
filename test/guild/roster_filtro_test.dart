import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/roster_filtro.dart';

Jogador _j({
  required String id,
  required String nome,
  String? classe,
  int? nivelAtaque,
  int? hp,
  int? nivelDefesa,
  String? critico,
  String status = 'transcrito',
}) => Jogador(
  id: id,
  nome: nome,
  classe: classe,
  nivelAtaque: nivelAtaque,
  hp: hp,
  nivelDefesa: nivelDefesa,
  critico: critico,
  status: status,
);

void main() {
  final mozaum = _j(
    id: '1',
    nome: 'Mozaum',
    classe: 'Místico',
    nivelAtaque: 70,
    hp: 50000,
    nivelDefesa: 40,
    critico: '32%',
  );
  final sksk = _j(
    id: '2',
    nome: 'SK_Alya',
    classe: 'Arcano',
    nivelAtaque: 40,
    hp: 30000,
    nivelDefesa: 60,
    critico: '18%',
  );
  final pendente = _j(id: '3', nome: 'NovoNaGuild', classe: 'Místico', status: 'pendente');

  final todos = [mozaum, sksk, pendente];

  group('busca', () {
    test('matches a substring of the name, case-insensitively', () {
      final r = const RosterFiltro(busca: 'moz').aplicar(todos);
      expect(r, [mozaum]);
    });

    test('empty busca keeps everyone', () {
      final r = const RosterFiltro().aplicar(todos);
      expect(r, todos);
    });

    test('whitespace-only busca is the same as empty', () {
      final r = const RosterFiltro(busca: '   ').aplicar(todos);
      expect(r, todos);
    });

    test('a name with no match returns an empty list', () {
      final r = const RosterFiltro(busca: 'xyz').aplicar(todos);
      expect(r, isEmpty);
    });
  });

  group('classe', () {
    test('keeps only the players of that class', () {
      final r = const RosterFiltro(classe: 'Místico').aplicar(todos);
      expect(r, [mozaum, pendente]);
    });

    test('null classe keeps everyone', () {
      final r = const RosterFiltro(classe: null).aplicar(todos);
      expect(r, todos);
    });
  });

  group('status', () {
    test('keeps only players with that status', () {
      final r = const RosterFiltro(status: 'pendente').aplicar(todos);
      expect(r, [pendente]);
    });
  });

  group('combined filters stack as an and', () {
    test('classe and status both have to pass', () {
      final r = const RosterFiltro(classe: 'Místico', status: 'transcrito').aplicar(todos);
      expect(r, [mozaum]);
    });
  });

  group('ordem', () {
    test('nivelAtaque sorts descending, with the no-value row last', () {
      final r = const RosterFiltro(ordem: OrdemColuna.nivelAtaque).aplicar(todos);
      expect(r, [mozaum, sksk, pendente]);
    });

    test('hp sorts descending, with the no-value row last', () {
      final r = const RosterFiltro(ordem: OrdemColuna.hp).aplicar(todos);
      expect(r, [mozaum, sksk, pendente]);
    });

    test('nivelDefesa sorts descending — sk_alya has the higher defence', () {
      final r = const RosterFiltro(ordem: OrdemColuna.nivelDefesa).aplicar(todos);
      expect(r, [sksk, mozaum, pendente]);
    });

    test('critico reads the number baked into the text and sorts on it', () {
      final r = const RosterFiltro(ordem: OrdemColuna.critico).aplicar(todos);
      expect(r, [mozaum, sksk, pendente]);
    });

    test('two rows tied on the column keep their relative order (stable sort)', () {
      final a = _j(id: 'a', nome: 'A', nivelAtaque: 70);
      final b = _j(id: 'b', nome: 'B', nivelAtaque: 70);
      final r = const RosterFiltro(ordem: OrdemColuna.nivelAtaque).aplicar([a, b]);
      expect(r, [a, b]);
    });

    test('two rows both missing the column keep their relative order', () {
      final a = _j(id: 'a', nome: 'A', status: 'pendente');
      final b = _j(id: 'b', nome: 'B', status: 'pendente');
      final r = const RosterFiltro(ordem: OrdemColuna.nivelAtaque).aplicar([a, b]);
      expect(r, [a, b]);
    });

    test('null ordem leaves the list in arrival order', () {
      final r = const RosterFiltro().aplicar(todos);
      expect(r, todos);
    });
  });

  group('copy helpers', () {
    test('comBusca, comClasse, comStatus and comOrdem change only their own field', () {
      const base = RosterFiltro(busca: 'x', classe: 'Mago', status: 'pendente');
      expect(base.comBusca('y').busca, 'y');
      expect(base.comBusca('y').classe, 'Mago');
      expect(base.comClasse('Bardo').classe, 'Bardo');
      expect(base.comClasse(null).classe, isNull);
      expect(base.comStatus('transcrito').status, 'transcrito');
      expect(base.comOrdem(OrdemColuna.hp).ordem, OrdemColuna.hp);
      expect(base.comOrdem(OrdemColuna.hp).busca, 'x');
    });
  });
}
