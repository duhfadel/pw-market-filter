import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/ao_vivo_repository.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/data/visit_repository.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/ui/home_view.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/visit_counter_view_model.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Where the assembled front page puts each section, top to bottom.
///
/// Two of these positions already cost an error and are recorded in
/// `CLAUDE.md`: the streamers sit below the tools and above the Discord, and
/// the news is closed. What changed on 30/09 is only that the news moved
/// below the tools — whoever arrives for the first time came for the tool,
/// not for a notice.

/// Loads the real Marcellus and Inter files `pubspec.yaml` already declares,
/// so this file measures text the way a browser does. Without this, the
/// Cartaz's own headline overflows under `flutter_test`'s fake square-glyph
/// metrics — a failure about the harness, not about the page.
/// `cartaz_test.dart` is where this pattern was learned.
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

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 30),
  attributes: const ['Nível de Ataque'],
  items: const {},
  characters: const [],
);

BrowserMemory _semMemoria() =>
    BrowserMemory.platform('portal_pw_home_ordem_test');

/// Answers whatever [corpo] says, regardless of the request — enough for the
/// three community-data repositories this page reads.
MockClient _clienteDe(Object corpo) =>
    MockClient((_) async => http.Response(jsonEncode(corpo), 200));

/// Pumps the whole assembled front page with real content in every section
/// that would otherwise draw nothing — a novidade, a live channel — so the
/// order asserted below is the order a full page actually shows.
Future<void> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1100, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final indexClient = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  final searchViewModel = SearchViewModel(IndexRepository(indexClient));

  final novidadesViewModel = NovidadesViewModel(
    NovidadeRepository(
      _clienteDe([
        {
          'texto': '**Selo novo no site**\nUma linha contando o que mudou.',
          'autor': 'dono',
          'publicada_em': '2026-09-30T12:00:00Z',
        },
      ]),
    ),
  );

  final aoVivoViewModel = AoVivoViewModel(
    AoVivoRepository(
      _clienteDe([
        {
          'canal': 'persybr',
          'nome': 'PersyBR',
          'ao_vivo': true,
          'titulo': 'The Classic PW 1.8.7',
          'jogo': 'Perfect World',
          'espectadores': 21,
          'visto_em': DateTime.now().toUtc().toIso8601String(),
        },
      ]),
    ),
  );

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: searchViewModel..load()),
        BlocProvider.value(value: aoVivoViewModel..load()),
        BlocProvider.value(value: novidadesViewModel..load()),
        BlocProvider(
          create: (_) => VisitCounterViewModel(
            VisitRepository(
              client: _clienteDe(const []),
              memory: _semMemoria(),
            ),
          ),
        ),
      ],
      child: const MaterialApp(home: HomeView()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the sections come in the order the spec fixed', (tester) async {
    await _pumpHome(tester);

    // `AoVivoStrip`'s own heading reads `STREAMERS AMIGOS`, not
    // `AO VIVO NA TWITCH` — verified against the widget itself, which is the
    // source of truth over any brief's recollection of it.
    final ordem = [
      find.text('FERRAMENTAS'),
      find.text('NOVIDADES DO PORTAL'),
      find.text('STREAMERS AMIGOS'),
      find.text('COMUNIDADE'),
    ].map((f) => tester.getTopLeft(f).dy).toList();

    expect(ordem, orderedEquals([...ordem]..sort()));
  });

  testWidgets('the Discord is no longer labelled advertising', (tester) async {
    await _pumpHome(tester);

    expect(find.text('PUBLICIDADE'), findsNothing);
    expect(find.text('COMUNIDADE'), findsOneWidget);
  });

  testWidgets('the guides are a line, not a section', (tester) async {
    // One card under a full section header with its own rule is more chrome
    // than content.
    await _pumpHome(tester);

    expect(find.text('GUIAS'), findsNothing);
    expect(find.text('GUIA'), findsOneWidget);
  });
}
