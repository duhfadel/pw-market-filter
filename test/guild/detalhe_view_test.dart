import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/fichas_repository.dart';
import 'package:pw_market_filter/features/guild/domain/ficha.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/ui/detalhe_view.dart';

import '../support/load_fonts.dart';

class _FakeFichasRepository implements FichasRepository {
  _FakeFichasRepository(this._historico);
  final List<Ficha> _historico;

  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      Success(_historico);
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

      await tester.pumpWidget(
        MaterialApp(
          home: DetalheView(
            jogador: Jogador(id: '1', nome: 'Mozaum'),
          ),
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
}
