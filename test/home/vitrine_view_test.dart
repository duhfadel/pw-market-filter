import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/ui/widgets/vitrine_view.dart';
import 'package:pw_market_filter/features/search/domain/presets.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` already declares,
/// so this file measures text the way a browser does.
///
/// `flutter_test` draws every glyph as a square the size of the font by
/// default, which measures far wider than the real face — a `Row` that fits
/// everywhere in the app can overflow under the fake metrics. Loading the
/// real fonts is the fix; shrinking the layout to dodge a fake overflow is
/// not.
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

// Copied from test/home/vitrine_test.dart rather than imported: a test
// helper shared between files is a test helper that gets changed for one and
// breaks the other.
const _arma70 = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);
const _armaFraca = EquippedItem(
  slot: 10,
  itemId: 50100,
  refine: 0,
  stones: [],
  attributes: {0: 30},
);
const _armaDef80 = EquippedItem(
  slot: 10,
  itemId: 50300,
  refine: 12,
  stones: [],
  attributes: {1: 80},
);

MarketCharacter _quem(
  String nome,
  int preco, {
  List<EquippedItem> usa = const [_arma70],
}) => MarketCharacter(
  roleId: nome.hashCode,
  name: nome,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: preco,
  fame: 0,
  cultivation: 'Leal',
  equipped: usa,
);

MarketIndex _indice(List<MarketCharacter> quem) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 30),
  attributes: const ['Nível de Ataque', 'Nível de Defesa'],
  items: const {},
  characters: quem,
);

Future<void> _pump(
  WidgetTester tester,
  List<MarketCharacter> characters, {
  void Function(MarketCharacter)? aoTocar,
  bool wide = true,
  double width = 1200,
  double height = 400,
  // Lets a test read the exact same index the widget renders from, so it
  // can pull a number (like the weapon tier) out of the real query instead
  // of retyping it.
  MarketIndex? index,
}) async {
  await _carregarFontesReais();

  // A `SizedBox` alone is not enough: the test window's own default size is
  // smaller than some of the sizes this file asks for, and the Scaffold
  // clamps the box to whatever the window allows before it ever reaches
  // `VitrineView`. Setting the window itself is what the rest of the suite
  // does for the same reason (see `mobile_filter_test.dart`).
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: VitrineView(
            index: index ?? _indice(characters),
            wide: wide,
            aoTocar: aoTocar ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('it prints the spread between the two prices', (tester) async {
    // 8000 ~/ 130 is 61, not 60 — 130 * 61 = 7930 and 130 * 62 = 8060, so the
    // honest floor of the real gap is sixty-one. The multiple is computed
    // from these two prices, never written down, so the assertion has to
    // agree with the arithmetic the widget actually does.
    await _pump(tester, [_quem('barato', 130), _quem('caro', 8000)]);

    expect(find.textContaining('61'), findsWidgets);
  });

  testWidgets('both prices are on screen', (tester) async {
    await _pump(tester, [_quem('barato', 130), _quem('caro', 8000)]);

    expect(find.textContaining('130'), findsOneWidget);
    expect(find.textContaining('8000'), findsOneWidget);
  });

  testWidgets('tapping a card hands back the character', (tester) async {
    MarketCharacter? tocado;
    await _pump(tester, [
      _quem('barato', 130),
      _quem('caro', 8000),
    ], aoTocar: (c) => tocado = c);

    await tester.tap(find.textContaining('130'));
    expect(tocado?.name, 'barato');
  });

  testWidgets('a market with no pair draws nothing at all', (tester) async {
    await _pump(tester, [_quem('sozinho', 500)]);

    expect(find.textContaining('mesma arma'), findsNothing);
  });

  testWidgets('a market with no attack-tier carriers at all draws nothing', (
    tester,
  ) async {
    await _pump(tester, [
      _quem('fraco', 40, usa: const [_armaFraca]),
    ]);

    expect(find.byType(VitrineView), findsOneWidget);
    expect(find.textContaining('mesma arma'), findsNothing);
  });

  testWidgets('the rare card and its defensive-tier line render', (
    tester,
  ) async {
    await _pump(tester, [
      _quem('barato', 130),
      _quem('caro', 8000),
      _quem('raro', 2200, usa: const [_armaDef80]),
    ]);

    expect(find.text('O MAIS RARO'), findsOneWidget);
    expect(find.textContaining('raro'), findsWidgets);
    // The defensive branch of `_armaDe`: this weapon has no attack level at
    // all, only `Nível de Defesa`, so the line has to name that attribute
    // and never fall back to attack — the one it would print by default.
    expect(find.textContaining('Nível de Defesa'), findsOneWidget);
    expect(find.textContaining('+80'), findsOneWidget);
  });

  testWidgets(
    'the sub-line names whatever tier strongWeaponQuery actually asks for',
    (tester) async {
      // The number must come from the query, never be retyped: a test that
      // hardcodes the same literal on both sides would still pass the day
      // the widget's prose and strongWeaponQuery's minimum drift apart --
      // exactly the failure mode that let an 80 tier slip through a chip
      // still labelled 70 elsewhere in this codebase.
      final index = _indice([_quem('barato', 130), _quem('caro', 8000)]);
      final nivelDaQuery = strongWeaponQuery(index)!.criteria.first.minimum;

      await _pump(tester, [
        _quem('barato', 130),
        _quem('caro', 8000),
      ], index: index);

      expect(
        find.textContaining('nível de ataque $nivelDaQuery'),
        findsOneWidget,
      );
    },
  );

  testWidgets('a phone stacks the three cards instead of a row', (
    tester,
  ) async {
    // 390 px is the phone width used across the rest of the suite. The
    // height is generous on purpose: the real page is a scrollable column,
    // so nothing here needs to fit a fixed viewport — only the test harness
    // does, and starving it would fabricate an overflow no browser has.
    await _pump(
      tester,
      [
        _quem('barato', 130),
        _quem('caro', 8000),
        _quem('raro', 2200, usa: const [_armaDef80]),
      ],
      wide: false,
      width: 390,
      height: 2000,
    );

    // Stacked, not side by side: the cheapest card sits above the dearest
    // one rather than beside it.
    final topoBarato = tester.getTopLeft(find.text('130 TCC')).dy;
    final topoCaro = tester.getTopLeft(find.text('8000 TCC')).dy;
    final topoRaro = tester.getTopLeft(find.text('2200 TCC')).dy;
    expect(topoBarato, lessThan(topoCaro));
    expect(topoCaro, lessThan(topoRaro));
  });
}
