import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/ui/widgets/destaques_view.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Loads the real fonts the widget ships with, the way `cartaz_test.dart`
/// does. `flutter_test` draws every glyph as a square of the font size by
/// default, which fabricates overflows no browser would ever show — a
/// mistake already made once on this branch and worth never repeating.
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

/// A market with five categories answerable, each by a different class — the
/// cheapest, a 70-weapon carrier, both UP5 carriers and the dearest. No
/// `Chave da Sorte` is collected here, so the sixth category drops on its
/// own, which is `destaquesDe`'s own rule and not this file's concern.
MarketIndex indiceDeTeste() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
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

MarketIndex indiceVazio() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const [],
  items: const {},
  characters: const [],
);

Future<void> _montar(
  WidgetTester tester, {
  MarketIndex? index,
  bool wide = true,
  void Function(SearchQuery)? onAbrir,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DestaquesView(
          index: index ?? indiceDeTeste(),
          wide: wide,
          onAbrir: onAbrir ?? (_) {},
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the price is on the body face, never Marcellus', (tester) async {
    await _montar(tester, index: indiceDeTeste());

    final preco = tester.widget<Text>(find.textContaining('TCC').first);
    expect(
      preco.style?.fontFamily,
      isNot(PWTheme.display),
      reason: 'Marcellus draws Roman figures: 150 TCC reads I5O TCC',
    );
  });

  testWidgets("tapping a card asks for that card's search", (tester) async {
    // `expect(pedida, isNotNull)` alone would stay green even if every card
    // handed back the same query — a refactor that passed
    // `destaques.first.busca` to all of them, or that swapped two cards'
    // queries, would pass that bar undetected. `SearchQuery` has no
    // `operator ==`, so two cards are told apart by what each query actually
    // asks rather than by identity: card 0 ("O mais barato") is the plain,
    // criterion-less query every card starts from; card 1 ("Arma de 70 mais
    // barata") is the one query here that names an attribute at all, and it
    // has to be the right one.
    final index = indiceDeTeste();
    final nivelDeAtaque = index.attributes.indexOf('Nível de Ataque');

    SearchQuery? pedida;
    await _montar(tester, index: index, onAbrir: (q) => pedida = q);

    await tester.tap(find.byType(InkWell).at(0));
    final primeira = pedida;
    expect(primeira, isNotNull);
    expect(primeira!.criteria, isEmpty);

    await tester.tap(find.byType(InkWell).at(1));
    final segunda = pedida;
    expect(segunda, isNotNull);
    expect(segunda!.criteria, hasLength(1));
    expect(segunda.criteria.single.attributeId, nivelDeAtaque);
    expect(segunda.criteria.single.minimum, 70);

    expect(
      primeira,
      isNot(same(segunda)),
      reason: "two distinct cards must not hand back the same query object",
    );
  });

  testWidgets('an empty market draws no section at all', (tester) async {
    await _montar(tester, index: indiceVazio());

    expect(find.byType(DestaquesView), findsOneWidget);
    expect(find.textContaining('TCC'), findsNothing);
  });

  testWidgets('on a phone, the six scroll in one row instead of a grid', (
    tester,
  ) async {
    // Replaced the 2-column, 3-row grid on 01/10/2026 — a 2:3 card at ~180 px
    // wide there ate roughly 800 px of height, about three screens before the
    // next section even started.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(tester, wide: false);

    expect(find.byType(GridView), findsNothing);

    // Every card shares one row: a carousel, not a grid that happens to fit
    // two across.
    final a = tester.getTopLeft(find.byType(Card).at(0));
    final b = tester.getTopLeft(find.byType(Card).at(1));
    expect(b.dy, a.dy);

    // More than fits the viewport at once — otherwise there would be
    // nothing to drag and no reason to draw this as a carousel at all.
    final posicao = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(posicao.position.axis, Axis.horizontal);
    expect(posicao.position.maxScrollExtent, greaterThan(0));
  });

  testWidgets(
    'the carousel cuts the last visible card instead of ending flush',
    (tester) async {
      // The detail that makes a carousel read as one: a row flush with the
      // margin looks like "this is everything", and the clipped edge is what
      // tells a thumb there is more to drag. Pinned as a range rather than
      // the exact fraction `destaques_view.dart` picks, so retuning that
      // number within reason does not break this test — only abandoning the
      // cut altogether would.
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _montar(tester, wide: false);

      final viewport = tester.getSize(find.byType(Scrollable)).width;
      final larguraDoCard = tester.getSize(find.byType(Card).first).width;

      // More than a third and less than half: between two and three cards
      // fit, which is only possible with the third one cut.
      expect(larguraDoCard, lessThan(viewport / 2));
      expect(larguraDoCard, greaterThan(viewport / 3));
    },
  );

  testWidgets('wide screens keep the grid, untouched', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(tester, wide: true);

    expect(find.byType(GridView), findsOneWidget);
  });
  testWidgets('the veil is dark where the footer text begins', (tester) async {
    // The defect this pins shipped once and was caught by eye, not by the
    // suite: the veil stayed clear until 62% of the card, the label is the
    // **first** line of the footer, and five of the six cards had their label
    // sitting on raw artwork. Only the first read, because that art happens
    // to be dark there — a gradient whose legibility depends on which
    // painting is behind it is a coincidence, not a design.
    //
    // So this asserts the property rather than the numbers: whatever the
    // stops are, the veil must already be mostly opaque at the height where
    // the text starts. Restating `stops: [0.38, …]` would pass for any
    // gradient, including the broken one.
    // Measured at the width the page actually serves. The default 800 px
    // harness viewport packs six cards into 133 px each, where the footer's
    // fixed type eats 45% of the card and no gradient could save it; the real
    // page caps its column near 1180 px, giving ~150 px cards whose footer
    // starts around 60%. A veil tuned against the harness's proportions would
    // be tuned against a layout nobody sees.
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(tester, index: indiceDeTeste());

    final carta = tester.getRect(find.byType(Card).first);
    // The topmost text in the footer, found by position rather than by widget
    // type: `find.byType(Column).first` returns the card's OUTER column, not
    // the footer's, and measuring that would pass for any gradient at all.
    // The badge is excluded by ignoring the top quarter — it carries its own
    // opaque chip and does not depend on the veil.
    final textos = find.descendant(
      of: find.byType(Card).first,
      matching: find.byType(Text),
    );
    final topos = <double>[
      for (var i = 0; i < tester.widgetList(textos).length; i++)
        tester.getRect(textos.at(i)).top,
    ].where((t) => (t - carta.top) / carta.height > 0.25).toList()..sort();

    expect(topos, isNotEmpty, reason: 'the card drew no footer text at all');
    final ondeOTextoComeca = (topos.first - carta.top) / carta.height;

    final veu = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(Card).first,
            matching: find.byType(DecoratedBox),
          )
          .last,
    );
    final gradiente =
        (veu.decoration as BoxDecoration).gradient! as LinearGradient;

    expect(
      _alphaEm(gradiente, ondeOTextoComeca),
      greaterThan(0.5),
      reason:
          'the label sits at ${(ondeOTextoComeca * 100).round()}% of the card '
          'and the veil is barely there — it will land on the artwork',
    );
  });
}

/// The gradient's alpha at [fracao] of the way down, interpolated between
/// whichever pair of stops bracket it.
double _alphaEm(LinearGradient gradiente, double fracao) {
  final stops = gradiente.stops!;
  final cores = gradiente.colors;

  if (fracao <= stops.first) return cores.first.a;
  if (fracao >= stops.last) return cores.last.a;

  for (var i = 0; i < stops.length - 1; i++) {
    if (fracao >= stops[i] && fracao <= stops[i + 1]) {
      final t = (fracao - stops[i]) / (stops[i + 1] - stops[i]);
      return cores[i].a + (cores[i + 1].a - cores[i].a) * t;
    }
  }
  return cores.last.a;
}
