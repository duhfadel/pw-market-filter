import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/ao_vivo_repository.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/visit_repository.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/visit_counter_view_model.dart';
import 'package:pw_market_filter/features/home/ui/home_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` already declares,
/// so this file measures text the way a browser does. `flutter_test` draws
/// every glyph as a square of the font size by default, which can fabricate
/// an overflow — or hide one — that never happens under the fonts the page
/// actually ships with. `cartaz_test.dart` is where this pattern was learned.
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

/// The front page is where a link shared in the community lands. Everything
/// asserted here is about the first five seconds: what the site is, and one
/// way in that does not require reading a card.

MarketCharacter _character({
  required int roleId,
  required String name,
  required int price,
  List<EquippedItem> equipped = const [],
}) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: price,
  fame: 1,
  cultivation: 'Leal',
  equipped: equipped,
);

const _weapon = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [
    _character(roleId: 1, name: 'Leandrim', price: 300, equipped: [_weapon]),
    _character(roleId: 2, name: 'Solaria', price: 120, equipped: [_weapon]),
    _character(roleId: 3, name: 'Sabia', price: 90),
  ],
);

/// Uma memória que não lembra de nada, para o contador não tocar em
/// localStorage num teste.
BrowserMemory _semMemoria() =>
    BrowserMemory.platform('portal_pw_last_visit_day');

/// A client that answers nothing, for the widgets this test is not about.
MockClient _semRede() => MockClient((_) async => http.Response('[]', 200));

/// Pumps the front page and records every route it asks for.
Future<List<String>> _pumpHome(WidgetTester tester) async {
  // Taller than the default 800×600, and the reason is the harness rather than
  // the page: in `flutter_test` every glyph is a square of the font size, so
  // the front page measures far taller here than in any browser. At 600 the
  // fold's own content landed off-screen and `tap` refused it — a failure
  // about the test window, not about the layout.
  tester.view.physicalSize = const Size(1100, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final pushed = <String>[];
  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  final viewModel = SearchViewModel(IndexRepository(client));

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: viewModel..load()),
        // A faixa de quem está ao vivo lê daqui. Sem repositório de verdade:
        // o cubit nasce vazio e a faixa some, que é exatamente o estado em
        // que a home fica quando ninguém está transmitindo.
        BlocProvider(
          create: (_) => AoVivoViewModel(AoVivoRepository(_semRede())),
        ),
        // As novidades vêm do Discord por uma tabela, e aqui não há rede: a
        // seção nasce vazia, que é como a home fica quando ninguém postou.
        BlocProvider(
          create: (_) => NovidadesViewModel(NovidadeRepository(_semRede())),
        ),
        // O contador do rodapé. Ele sempre esteve na árvore e o teste nunca o
        // forneceu — passava porque a exceção caía num ramo que ninguém
        // alcançava. Mexer na ordem da home trouxe o ramo para o caminho.
        BlocProvider(
          create: (_) => VisitCounterViewModel(
            VisitRepository(client: _semRede(), memory: _semMemoria()),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateRoute: (settings) {
          final name = settings.name ?? '/';
          if (name != '/') pushed.add(name);
          return MaterialPageRoute(
            builder: (_) =>
                name == '/' ? const HomeView() : const SizedBox.shrink(),
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

  testWidgets('the wheel scrolls with the pointer at the right edge', (
    tester,
  ) async {
    // Reported from a real window: the content column is capped at 1040 and
    // centred, so on a wider screen the margins either side belonged to
    // nothing. A wheel event lands on whatever is under the pointer, and out
    // there that was the background — the page simply did not move, which
    // reads as the site being broken rather than as a layout choice.
    //
    // The scrollbar sitting beside the column instead of at the window's edge
    // was the same fact showing itself; both go when the scrollable is the
    // full width and the cap moves inside it.
    await _pumpHome(tester);

    final antes = tester
        .widget<Scrollable>(find.byType(Scrollable).first)
        .controller!
        .offset;

    // 40 px from the right edge: outside a 1040-wide column in an 1100 window.
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(1060, 700),
        scrollDelta: Offset(0, 300),
      ),
    );
    await tester.pumpAndSettle();

    final depois = tester
        .widget<Scrollable>(find.byType(Scrollable).first)
        .controller!
        .offset;
    expect(depois, greaterThan(antes));
  });

  testWidgets('the fold says what the site does, not only its name', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.textContaining('Ache o personagem'), findsOneWidget);
    expect(find.text('Buscar personagens'), findsOneWidget);
  });

  testWidgets('the primary action opens the filter', (tester) async {
    final pushed = await _pumpHome(tester);

    await tester.tap(find.text('Buscar personagens'));
    await tester.pumpAndSettle();

    expect(pushed, ['/filtro']);
  });

  testWidgets('the Destaques prove the claim with real people from the '
      'index', (tester) async {
    // The figures MarketPulse used to print are gone, and so is the Vitrine
    // that replaced them — `DestaquesView` is what draws from the index now,
    // and its own tests (`destaques_view_test.dart`, `destaques_test.dart`)
    // cover the category arithmetic in isolation. All three characters here
    // share one class, so the distinct-class rule prunes every category but
    // the cheapest down to a single card — Sabia, the market's real
    // cheapest. What this test guards is only that the home page actually
    // wires the loaded index into the section, not the arithmetic itself.
    await _pumpHome(tester);

    expect(find.text('Sabia'), findsOneWidget);
    expect(find.text('90 TCC'), findsOneWidget);
  });
}
