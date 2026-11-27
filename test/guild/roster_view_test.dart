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
import 'package:pw_market_filter/features/guild/ui/roster_view.dart';

import '../support/load_fonts.dart';

class _FakeRepo implements JogadoresRepository {
  _FakeRepo(this._lista);
  final List<Jogador> _lista;

  @override
  Future<Result<List<Jogador>>> lista() async => Success(_lista);

  @override
  Future<Result<void>> criar(Jogador j) async => const Success<void>(null);

  @override
  Future<Result<String>> subirPrint(Uint8List bytes, String nomeArquivo) async =>
      Success(nomeArquivo);

  @override
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async =>
      const Success<void>(null);
}

class _FakeFichasRepo implements FichasRepository {
  @override
  Future<Result<List<Ficha>>> historico(String jogadorId) async =>
      const Success([]);

  @override
  Future<Result<void>> corrigirUltima(
    String jogadorId,
    Map<String, dynamic> camposDados,
  ) async => const Success<void>(null);
}

/// Fix round 1: the wide table's fixed columns (90+130+100+100+90+110+140 =
/// 760) alone already outrun the 681–760px band of the wide/narrow
/// breakpoint (680), so any Jogador column — fixed or `Expanded` — pushed
/// the Row past the available width there and `flutter test` reported a
/// real `RenderFlex` overflow. The fix wraps the whole table in a
/// horizontally-scrolling `SingleChildScrollView`; this test pumps the real
/// `RosterView` (not a hand-built fragment) at a window wide enough that the
/// LayoutBuilder's own `maxWidth` (window width minus the screen's 32px of
/// padding) lands squarely inside that band, and asserts nothing overflowed.
void main() {
  // `flutter_test` otherwise draws every glyph as a square of the font
  // size, which fabricated two header-label overflows ("Nível de Ataque",
  // "Nv. Defesa") that no browser ever shows — a different artefact from
  // the real breakpoint defect this test exists to catch. See
  // `load_fonts.dart` and the equivalent `setUpAll` in
  // `instancias_view_test.dart`.
  setUpAll(loadAppFonts);

  tearDown(() {
    if (getIt.isRegistered<JogadoresRepository>()) {
      getIt.unregister<JogadoresRepository>();
    }
    if (getIt.isRegistered<FichasRepository>()) {
      getIt.unregister<FichasRepository>();
    }
  });

  testWidgets(
    'the wide table does not overflow in the 681-760px band that used to break',
    (tester) async {
      getIt.registerLazySingleton<FichasRepository>(_FakeFichasRepo.new);
      getIt.registerLazySingleton<JogadoresRepository>(
        () => _FakeRepo([
          Jogador(
            id: '1',
            nome: 'Mozaum',
            classe: 'Místico',
            limite: 'Alma',
            nivelAtaque: 70,
            hp: 55000,
            nivelDefesa: 40,
            critico: '32%',
            status: 'transcrito',
          ),
          Jogador(id: '2', nome: 'SK_Alya', classe: 'Arcano', status: 'pendente'),
        ]),
      );

      tester.view.physicalSize = const Size(740, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(home: RosterView(papel: Papel.admin)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Confirms the wide table actually rendered (not the narrow cards) —
      // otherwise the test would pass for the wrong reason.
      expect(find.text('Limite'), findsOneWidget);
    },
  );
}
