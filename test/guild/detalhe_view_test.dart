import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/detalhe_view.dart';
import 'package:pw_market_filter/features/guild/ui/roster_view_model.dart';

import '../support/load_fonts.dart';

class _FakeFichasRepository implements FichasRepository {
  _FakeFichasRepository(this._historico);
  final List<Ficha> _historico;

  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      Success(_historico);
}

class _FakeJogadoresRepository implements JogadoresRepository {
  _FakeJogadoresRepository(this._lista);
  final List<Jogador> _lista;

  @override
  Future<Result<List<Jogador>>> lista() async => Success(_lista);

  @override
  Future<Result<void>> criar(Jogador j) async => const Success<void>(null);

  @override
  Future<Result<String>> subirPrint(
    Uint8List bytes,
    String nomeArquivo,
  ) async => Success(nomeArquivo);

  @override
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async =>
      const Success<void>(null);
}

/// Fix round 1: `atual.dados[chave]` sat as an unconstrained `Text` beside
/// an `Expanded` label, so a free-text field long enough — `critico` and
/// `furia` are documented on `Jogador` as carrying ranges or units, not bare
/// numbers — overflowed the Row on a narrow phone. This pumps the real
/// `DetalheView` at 360px with exactly such values and asserts nothing
/// overflowed.
void main() {
  setUpAll(loadAppFonts);

  tearDown(() {
    if (getIt.isRegistered<FichasRepository>()) {
      getIt.unregister<FichasRepository>();
    }
  });

  testWidgets(
    'long free-text stats do not overflow the stat row on a narrow phone',
    (tester) async {
      getIt.registerLazySingleton<FichasRepository>(
        () => _FakeFichasRepository([
          Ficha(
            jogadorId: '1',
            dados: {
              'nivel_ataque': 428,
              'critico':
                  '35% (chance extrema, quase nunca erra o golpe, texto bem mais longo ainda para garantir overflow)',
              'furia':
                  '0-100 barra cheia com regeneração acelerada e muito mais texto para garantir o estouro',
              'hp': 55000,
            },
            runas: const [],
          ),
        ]),
      );

      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final jogador = Jogador(id: '1', nome: 'Mozaum');
      final vm = RosterViewModel(
        _FakeJogadoresRepository([jogador]),
        Papel.admin,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetalheView(jogador: jogador, papel: Papel.admin, vm: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Confirms the grouped section actually rendered the field under
      // test, so the assertion above is about the real row and not an
      // empty screen.
      expect(find.text('Crítico'), findsOneWidget);
    },
  );

  testWidgets(
    'a long nickname does not push the editar action off the app bar',
    (tester) async {
      getIt.registerLazySingleton<FichasRepository>(
        () => _FakeFichasRepository(const []),
      );

      tester.view.physicalSize = const Size(360, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final jogador = Jogador(
        id: '1',
        nome: 'umnomebembemlongoparaestourarabarra',
      );
      final vm = RosterViewModel(
        _FakeJogadoresRepository([jogador]),
        Papel.admin,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DetalheView(jogador: jogador, papel: Papel.admin, vm: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The action only shows up because the name's own title made room —
      // confirms the ellipsis fix actually did something, not that the
      // button was simply absent.
      expect(find.text('editar'), findsOneWidget);
    },
  );
}
