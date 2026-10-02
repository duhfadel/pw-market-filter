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
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';
import 'package:pw_market_filter/features/home/domain/destaques.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/ui/home_view.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/visit_counter_view_model.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cartaz.dart';
import 'package:pw_market_filter/features/home/ui/widgets/destaques_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// `HomeView(pw126: true)` end to end — the wiring `home_view.dart` added for
/// Task 4, not just `destaques126De` in isolation (`destaques_126_test.dart`
/// covers that half).
///
/// What this guards, specifically: the Cartaz only ever wears one of the
/// 1.2.6 game's own six classes, the Destaques section draws the two-card
/// set rather than the 1.8.7 six, and tapping into the filter writes
/// `/1.2.6/filtro` — never the 1.8.7 path a card built from a different
/// index would be wrong to open.

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

MarketCharacter _personagem(String nome, int preco, String classe) =>
    MarketCharacter(
      roleId: nome.hashCode,
      name: nome,
      characterClass: classe,
      occupation: 1,
      level: 100,
      price: preco,
      fame: 0,
      cultivation: 'Leal',
      equipped: const [],
    );

/// Six characters, one per 1.2.6 class, cheapest to dearest — enough for
/// `destaques126De` to draw both cards without a collision.
final _indicePw126 = MarketIndex(
  server: 'pw126',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: [
    _personagem('Niz', 40, 'Feiticeira'),
    _personagem('Vento', 300, 'Arqueiro'),
    _personagem('Montanha', 500, 'Bárbaro'),
    _personagem('Fé', 800, 'Sacerdote'),
    _personagem('Arcano', 1200, 'Mago'),
    _personagem('Rocha', 27500, 'Guerreiro'),
  ],
);

BrowserMemory _semMemoria() =>
    BrowserMemory.platform('portal_pw_home_pw126_test');

MockClient _semRede() => MockClient((_) async => http.Response('[]', 200));

MockClient _indiceComoRede(MarketIndex index) => MockClient(
  (_) async =>
      http.Response.bytes(utf8.encode(jsonEncode(index.toJson())), 200),
);

/// Pumps `HomeView(pw126: true)` behind the same providers `main.dart` wires
/// for the real 1.2.6 route, and records every name a push navigates to —
/// the only way to tell `/1.2.6/filtro` apart from `/1.8.7/filtro` without a
/// real `Navigator` in the loop, the same lesson `rotas_test.dart` already
/// draws about screenshots.
Future<List<String>> _pumpHomePw126(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final searchViewModel = SearchViewModel(
    IndexRepository(_indiceComoRede(_indicePw126)),
  );
  final aoVivoViewModel = AoVivoViewModel(AoVivoRepository(_semRede()));
  final novidadesViewModel = NovidadesViewModel(NovidadeRepository(_semRede()));

  final pushed = <String>[];

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: searchViewModel..load()),
        BlocProvider.value(value: aoVivoViewModel..load()),
        BlocProvider.value(value: novidadesViewModel..load()),
        BlocProvider(
          create: (_) => VisitCounterViewModel(
            VisitRepository(client: _semRede(), memory: _semMemoria()),
          ),
        ),
      ],
      child: MaterialApp(
        home: const HomeView(pw126: true),
        onGenerateRoute: (settings) {
          pushed.add(settings.name ?? '');
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Text(settings.name ?? ''),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return pushed;
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the Cartaz only ever wears one of the six 1.2.6 classes', (
    tester,
  ) async {
    await _pumpHomePw126(tester);

    final cartaz = tester.widget<Cartaz>(find.byType(Cartaz));
    expect(classesClassicasPw126, contains(cartaz.classe));
  });

  testWidgets('the Destaques section draws exactly the two-card set', (
    tester,
  ) async {
    await _pumpHomePw126(tester);

    final esperadas = destaques126De(_indicePw126);
    expect(esperadas, hasLength(2));

    final cards = find.descendant(
      of: find.byType(DestaquesView),
      matching: find.byType(Card),
    );
    expect(cards, findsNWidgets(2));

    for (final destaque in esperadas) {
      expect(find.text(destaque.personagem.name), findsOneWidget);
    }
  });

  testWidgets(
    "the Cartaz's own search button opens the 1.2.6 filter, never the 1.8.7 "
    'one',
    (tester) async {
      final pushed = await _pumpHomePw126(tester);

      await tester.tap(find.text('Buscar personagens'));
      await tester.pumpAndSettle();

      expect(pushed, contains('/1.2.6/filtro'));
      expect(pushed, isNot(contains('/1.8.7/filtro')));
    },
  );

  testWidgets('a Destaque card opens the 1.2.6 filter too', (tester) async {
    final pushed = await _pumpHomePw126(tester);

    // Tapping the `InkWell` directly rather than the name `Text` inside it:
    // `_Carta` deliberately layers the ink surface *above* the art and the
    // footer text (see its own comment in `destaques_view.dart`), so a tap
    // computed from the text's own centre can land on the ink feature above
    // it instead of the `RenderParagraph` — correct for a real tap, but a
    // spurious "did not hit test the specified widget" warning from the
    // harness if the text itself is the target.
    final inkWell = find.descendant(
      of: find.byType(DestaquesView),
      matching: find.byType(InkWell),
    );
    await tester.tap(inkWell.first);
    await tester.pumpAndSettle();

    expect(
      pushed.any((nome) => nome.startsWith('/1.2.6/filtro')),
      isTrue,
      reason: 'pushed: $pushed',
    );
    expect(pushed.any((nome) => nome.startsWith('/1.8.7/filtro')), isFalse);
  });
}
