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

/// Pumps the app starting on [rota], the same five routes `main.dart`
/// answers, at [largura] — narrower than the default 1200 for **H2**, the
/// menu's own breakpoint, which only shows up at a width nothing else in this
/// file pumps at.
///
/// [rotas], when given, records every route name `onGenerateRoute` is asked
/// to build — the same log **M1** was found by reading by hand
/// (`[/, /novidades, /novidades]`).
Future<void> _abrir(
  WidgetTester tester,
  String rota, {
  double largura = 1200,
  List<String>? rotas,
}) async {
  tester.view.physicalSize = Size(largura, 900);
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
          rotas?.add(settings.name ?? '/');
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

  group('H1 — the header is not clipped on /filtro', () {
    // `search_view.dart`'s `bottom: PreferredSize` once declared 64 px for a
    // subtree that measured 106, so `AppBar` shrank the toolbar to absorb the
    // shortfall and `Cabecalho` laid out a few pixels above the viewport at
    // every width — silently, since a `Flexible` shrinking is not an
    // overflow and `tester.takeException()` stayed null throughout. The only
    // shape of test that would have caught it measures the rectangle.
    for (final largura in [390.0, 700.0, 1200.0]) {
      testWidgets('the mark is fully on screen at ${largura}px', (
        tester,
      ) async {
        await _abrir(tester, '/filtro', largura: largura);

        final marca = tester.getTopLeft(
          find.byKey(const Key('cabecalho-marca')),
        );
        expect(marca.dy, greaterThanOrEqualTo(0), reason: '$largura px');

        final nome = tester.getTopLeft(find.text('PORTAL PW'));
        expect(nome.dy, greaterThanOrEqualTo(0), reason: '$largura px');
      });
    }
  });

  group('H2 — the menu fits its own row at its own breakpoint', () {
    // Pumped at `Cabecalho.larguraMinima` itself, read live rather than
    // copied as a literal — if the constant ever regresses towards 680, the
    // same assertion starts pumping at that smaller width and goes red,
    // because the real row does not fit there. 680 was measured to overflow
    // by 4.6 px bare, 11 px in an `AppBar` title and 64 px inside the home's
    // own margins.
    for (final rota in ['/', '/filtro', '/registros', '/runas', '/novidades']) {
      testWidgets('no overflow on $rota at Cabecalho.larguraMinima', (
        tester,
      ) async {
        await _abrir(tester, rota, largura: Cabecalho.larguraMinima);

        expect(tester.takeException(), isNull, reason: rota);
      });
    }
  });

  testWidgets(
    'M1 — the Novidades pill does not push /novidades on top of itself',
    (tester) async {
      final rotas = <String>[];
      await _abrir(tester, '/novidades', rotas: rotas);

      await tester.tap(find.text('Novidades'));
      await tester.pumpAndSettle();

      // `MaterialApp` generates both `/` and `/novidades` for this initial
      // route on its own, to keep a proper back stack under a deep link —
      // that part is unrelated to M1. Before the guard in `_abrirNovidades`,
      // tapping the pill pushed a *third*, identical `/novidades` on top, and
      // the stack could pop back into a copy of the same screen, which is why
      // the back button's first press looked like it did nothing.
      expect(rotas, ['/', '/novidades']);
      expect(find.byType(NovidadesView), findsOneWidget);
    },
  );

  testWidgets(
    'M1 — picking the tool that names the open screen does not push it again',
    (tester) async {
      // The same hazard, through `abrirTool` rather than the Novidades pill:
      // picking *Títulos* from the drawer while already on `/registros`.
      final rotas = <String>[];
      await _abrir(tester, '/registros', rotas: rotas, largura: 390);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Títulos'));
      await tester.pumpAndSettle();

      expect(rotas, ['/', '/registros']);
    },
  );
}
