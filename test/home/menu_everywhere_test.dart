import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/features/home/data/ao_vivo_repository.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/data/visit_repository.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/ui/home_view.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/visit_counter_view_model.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';
import 'package:pw_market_filter/features/novidades/ui/novidades_view.dart';
import 'package:pw_market_filter/features/registros/data/registro_repository.dart';
import 'package:pw_market_filter/features/registros/ui/registros_view.dart';
import 'package:pw_market_filter/features/registros/ui/registros_view_model.dart';
import 'package:pw_market_filter/features/runas/ui/runas_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Every tool screen reached through the menu, pumped the way `main.dart`
/// wires the real app: one `MaterialApp` with the same `onGenerateRoute`, the
/// per-page view models above the Navigator, and `GetIt` feeding the two
/// screens — `RegistrosView` and `NovidadesView` — that reach into it
/// directly rather than taking a `BlocProvider`.
///
/// Before this commit, a visitor reading `/runas` had no way to reach
/// `/registros` without going home first, and nothing proved the menu
/// actually changed the address bar rather than moving a private `Navigator`
/// nobody outside the app can see — a screenshot cannot tell the two apart,
/// which is why `task-2-brief.md` asks for the real address bar as well.

/// Loads the real Marcellus and Inter files `pubspec.yaml` declares, the way
/// `cabecalho_test.dart` does. `flutter_test` draws every glyph as a square
/// of the font size by default, which fabricates overflows no browser would
/// ever show — the app bars pumped here are dense enough that the square
/// glyphs alone would misreport them as broken.
Future<void> _carregarFontesReais() async {
  Future<void> carregar(String familia, List<String> arquivos) async {
    final carregador = FontLoader(familia);
    for (final arquivo in arquivos) {
      carregador.addFont(rootBundle.load(arquivo));
    }
    await carregador.load();
  }

  await carregar('Marcellus', ['assets/fonts/Marcellus-Regular.ttf']);
  await carregar('Inter', [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
}

MarketIndex _indiceVazio() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const [],
  items: const {},
  characters: const [],
);

/// A client that answers nothing, for every repository this file is not
/// about.
MockClient _semRede() => MockClient((_) async => http.Response('[]', 200));

MockClient _indiceFalso() => MockClient(
  (_) async => http.Response.bytes(
    utf8.encode(jsonEncode(_indiceVazio().toJson())),
    200,
  ),
);

/// Pumps the app starting on [rota], the same five routes `main.dart` answers.
Future<void> _abrir(WidgetTester tester, String rota) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  // `RegistrosView` and `NovidadesView` each reach into `GetIt` on their own
  // — the first for its `RegistrosViewModel`, the second for the
  // `NovidadeRepository` its own `carregar` falls back to — so both need a
  // registration here the same way `configureDependencies()` gives the real
  // app one, just backed by a client that never leaves this test.
  await getIt.reset();
  getIt
    ..registerLazySingleton<RegistroRepository>(
      () => RegistroRepository(_semRede()),
    )
    ..registerFactory<RegistrosViewModel>(
      () => RegistrosViewModel(getIt<RegistroRepository>()),
    )
    ..registerLazySingleton<NovidadeRepository>(
      () => NovidadeRepository(_semRede()),
    );
  addTearDown(getIt.reset);

  final searchViewModel = SearchViewModel(IndexRepository(_indiceFalso()));
  final novidadesViewModel = NovidadesViewModel(NovidadeRepository(_semRede()));
  final aoVivoViewModel = AoVivoViewModel(AoVivoRepository(_semRede()));
  final visitCounterViewModel = VisitCounterViewModel(
    VisitRepository(
      client: _semRede(),
      memory: BrowserMemory.platform('teste_menu_em_todo_lado'),
    ),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: searchViewModel..load()),
        BlocProvider.value(value: aoVivoViewModel..load()),
        BlocProvider.value(value: novidadesViewModel..load()),
        BlocProvider.value(value: visitCounterViewModel..load()),
      ],
      child: MaterialApp(
        initialRoute: rota,
        onGenerateRoute: (settings) {
          final route = Uri.parse(settings.name ?? '/');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => switch (route.path) {
              '/filtro' => SearchView(arriving: route.queryParametersAll),
              '/registros' => const RegistrosView(),
              '/runas' => const RunasView(),
              '/novidades' => const NovidadesView(),
              _ => const HomeView(),
            },
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('every tool screen carries the menu', (tester) async {
    for (final rota in ['/filtro', '/registros', '/runas', '/novidades']) {
      await _abrir(tester, rota);
      expect(find.byType(Cabecalho), findsOneWidget, reason: rota);
    }
  });

  testWidgets('the mark goes home from a tool screen', (tester) async {
    await _abrir(tester, '/runas');
    await tester.tap(find.byKey(const Key('cabecalho-marca')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeView), findsOneWidget);
  });

  testWidgets('Novidades navigates rather than scrolling', (tester) async {
    await _abrir(tester, '/registros');
    await tester.tap(find.text('Novidades'));
    await tester.pumpAndSettle();

    expect(find.byType(NovidadesView), findsOneWidget);
  });

  testWidgets('the back arrow still leaves /filtro, beside the mark', (
    tester,
  ) async {
    // Decision 2 of the brief: the hand-declared arrow in `SearchView` stays
    // even though `Cabecalho`'s own mark now does the same job — two doors
    // home is better than none, and this proves both still work.
    await _abrir(tester, '/filtro');

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.byKey(const Key('cabecalho-marca')), findsOneWidget);
  });
}
