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
import 'package:pw_market_filter/features/home/ui/widgets/cartaz.dart';
import 'package:pw_market_filter/features/home/ui/widgets/destaques_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

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

EquippedItem _arma({int ataque = 0, int defesa = 0}) => EquippedItem(
  slot: weaponSlot,
  itemId: 50206,
  refine: 0,
  stones: const [],
  attributes: {0: ataque, 1: defesa},
);

MarketCharacter _personagem(
  String nome,
  int preco,
  String classe, {
  int ataque = 0,
  int defesa = 0,
}) => MarketCharacter(
  roleId: nome.hashCode,
  name: nome,
  characterClass: classe,
  occupation: 1,
  level: 105,
  price: preco,
  fame: 0,
  cultivation: 'Leal',
  equipped: [_arma(ataque: ataque, defesa: defesa)],
);

/// Five carriers of five distinct classes, so the Destaques actually draw
/// cards here — `_index` above is empty on purpose for the tests that only
/// care about section order, but the tablet-band and phone checks below need
/// real cards to measure a real grid.
final _indiceComDestaques = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 30),
  attributes: const ['Nível de Ataque', 'Nível de Defesa'],
  items: const {},
  characters: [
    _personagem('barato', 100, 'Guerreiro', ataque: 30),
    _personagem('setenta', 300, 'Mago', ataque: 70),
    _personagem('atqUp5', 500, 'Arqueiro', ataque: 80),
    _personagem('defUp5', 600, 'Bárbaro', defesa: 80),
    _personagem('caro', 9000, 'Feiticeira', ataque: 40),
  ],
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
///
/// [index] defaults to the empty market: the section-order tests do not care
/// what the Destaques draw, only where things sit, and an empty market draws
/// no Destaques section at all — the same "empty is an answer" rule
/// `destaques.dart` documents for itself.
Future<void> _pumpHome(
  WidgetTester tester, {
  MarketIndex? index,
  Size size = const Size(1100, 2400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final usedIndex = index ?? _index;
  final indexClient = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(usedIndex.toJson())), 200),
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
    // A market with real characters, so Destaques actually draws a section
    // to place in the order — `_index` alone is empty by design and would
    // leave this step silently skipped rather than checked.
    await _pumpHome(tester, index: _indiceComDestaques);

    // `AoVivoStrip`'s own heading reads `STREAMERS AMIGOS`, not
    // `AO VIVO NA TWITCH` — verified against the widget itself, which is the
    // source of truth over any brief's recollection of it.
    final ordem = [
      find.byKey(const Key('cabecalho-marca')),
      find.byType(Cartaz),
      find.byType(DestaquesView),
      find.text('NOVIDADES DO PORTAL'),
      find.text('STREAMERS AMIGOS'),
      find.text('COMUNIDADE'),
      find.textContaining('Projeto de fã'),
    ].map((f) => tester.getTopLeft(f).dy).toList();

    expect(ordem, orderedEquals([...ordem]..sort()));
  });

  testWidgets('the advert and the community are two different things', (
    tester,
  ) async {
    // This test used to assert `PUBLICIDADE` appeared nowhere, which was true
    // only while the advert was off the home — and that was never a rule, it
    // was a consequence. The owner put the advert back on 01/10/2026, so the
    // assertion that survives is the one that was always the point: the
    // Discord strip is the community's, not a paid slot, and the two must not
    // be confused for one another.
    await _pumpHome(tester);

    expect(find.text('PUBLICIDADE'), findsOneWidget);
    expect(find.text('COMUNIDADE'), findsOneWidget);

    // And the advert sits below the community — the lowest place on the page
    // that is still the page.
    expect(
      tester.getTopLeft(find.text('PUBLICIDADE')).dy,
      greaterThan(tester.getTopLeft(find.text('COMUNIDADE')).dy),
    );
  });

  testWidgets(
    'the tool cards and the guide line are gone — the header pills are the '
    'only menu now',
    (tester) async {
      // Decision of 01/10: "não acho que valha a pena duplicar". The cards
      // sold the tools with art and a tagline; the header's pills (already
      // proven in `menu_everywhere_test.dart`) list the same set. Keeping
      // both put two navigation surfaces for one set of tools on the same
      // page, one above the other.
      await _pumpHome(tester);

      expect(find.text('FERRAMENTAS'), findsNothing);
      expect(find.text('GUIAS'), findsNothing);
      expect(find.text('GUIA'), findsNothing);
      // The tagline that used to sit on the card, in the open — it survives
      // only inside the header's drawer now, which `GavetaItem` renders on
      // tap and not on load, so it must not be findable on a plain pump.
      expect(
        find.text(
          'Busque seu próximo personagem por arma, cartas e atributos.',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'the tablet band keeps the Cartaz and the Destaques on their compact '
    'layout, and the grid holds three columns without overflowing',
    (tester) async {
      // 1100 px sits inside the 680–1279 tablet band: wide (>=680) but not
      // large (>=1280). Cartaz and DestaquesView are the two widgets that
      // take `wide: large` rather than `wide: wide` like every other section
      // on this page, because Cartaz's own typography was measured at
      // 1200 px and overflows between 680 and 1279 — its 40 px headline by
      // 36 px. DestaquesView carried the same `wide: large` call forward
      // when it replaced VitrineView, and this is the check the Task 3
      // review asked for: the column count comes from the grid's own
      // measured width (`destaques_view.dart`'s `_columnsFor`), not from
      // `wide`, and nobody had rendered it inside the real page's margins
      // before now.
      await _pumpHome(tester, index: _indiceComDestaques);

      expect(tester.widget<Cartaz>(find.byType(Cartaz)).wide, isFalse);
      expect(
        tester.widget<DestaquesView>(find.byType(DestaquesView)).wide,
        isFalse,
      );

      // No `RenderFlex overflowed` or similar — `flutter_test` fails a test
      // outright the moment `FlutterError.onError` fires during it, so
      // reaching this line at all is already half the proof; the explicit
      // check is for a clear failure message over a buried one.
      expect(tester.takeException(), isNull);

      // Finding 3 of the 2026-10-01 review: `Cartaz`'s `wide` being this
      // page's `large` (>=1280) once meant the tablet band lost the 430 px
      // ceiling on its sub-line along with the headline's typography — the
      // line ran to the column's own ~732 px, about 120 characters wide.
      // `ConstrainedBox(maxWidth: 430)` fixed it without a `wide` gate at
      // all; this is the measurement the earlier version of this test could
      // not see, since neither `takeException()` nor the grid's row geometry
      // reads the sub-line's own width.
      expect(
        tester
            .getSize(
              find.textContaining('o que o marketplace guarda no inventário'),
            )
            .width,
        lessThanOrEqualTo(430),
      );

      // Three across at this width: `_ComMargem` takes 40 px either side at
      // `wide`, and the page's own content column caps at 780 px below
      // `large` — so the grid never sees more than ~700 px here, which
      // `_columnsFor` reads as the middle tier (>=440, <760), never the
      // six-column one. The five cards split 3-then-2.
      final topos = [
        for (var i = 0; i < 5; i++) tester.getTopLeft(find.byType(Card).at(i)),
      ];
      expect(topos[0].dy, topos[1].dy);
      expect(topos[1].dy, topos[2].dy);
      expect(topos[3].dy, greaterThan(topos[2].dy));
      expect(topos[3].dy, topos[4].dy);
    },
  );

  testWidgets(
    'on a phone, the Destaques grid holds two columns inside the real page',
    (tester) async {
      // Task 3's own test proved two columns in isolation at 390 px; what it
      // could not see is whether the page's own chrome around the grid —
      // `_ComMargem`, the Cartaz above it — leaves enough room for that to
      // still hold once the section sits inside the real page. It does.
      await _pumpHome(
        tester,
        index: _indiceComDestaques,
        size: const Size(390, 2600),
      );

      expect(tester.takeException(), isNull);

      final a = tester.getTopLeft(find.byType(Card).at(0));
      final b = tester.getTopLeft(find.byType(Card).at(1));
      final c = tester.getTopLeft(find.byType(Card).at(2));
      expect(b.dy, a.dy);
      expect(c.dy, greaterThan(a.dy));
    },
  );
}
