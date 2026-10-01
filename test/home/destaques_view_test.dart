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
    SearchQuery? pedida;
    await _montar(tester, onAbrir: (q) => pedida = q);

    await tester.tap(find.byType(InkWell).first);
    expect(pedida, isNotNull);
  });

  testWidgets('an empty market draws no section at all', (tester) async {
    await _montar(tester, index: indiceVazio());

    expect(find.byType(DestaquesView), findsOneWidget);
    expect(find.textContaining('TCC'), findsNothing);
  });

  testWidgets('two columns on a phone, not one', (tester) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(tester, wide: false);

    // The first two cards share the same row.
    final a = tester.getTopLeft(find.byType(Card).at(0));
    final b = tester.getTopLeft(find.byType(Card).at(1));
    expect(b.dy, a.dy);
  });
}
