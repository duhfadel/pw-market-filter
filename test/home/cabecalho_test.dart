import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` already declares,
/// so this file measures text the way a browser does. `flutter_test` draws
/// every glyph as a square of the font size by default, which can fabricate
/// an overflow — or hide one — that never happens under the fonts the widget
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

Future<void> _pump(WidgetTester tester, {bool wide = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 1200, child: Cabecalho(wide: wide)),
      ),
    ),
  );
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the mark is small and the name is beside it', (tester) async {
    // The fan art is not discarded — it is moved to the size at which it
    // reads. At 200 px of dark red on dark violet it was the largest element
    // on the page and the least legible.
    await _pump(tester);

    final marca = tester.widget<Image>(find.byType(Image).first);
    expect((marca.image as AssetImage).assetName, contains('pw-mark'));
    expect(marca.height, lessThan(40));
    expect(find.text('PORTAL PW'), findsOneWidget);
  });

  testWidgets('the menu offers every tool that has a route', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    expect(find.text('Filtro do Marketplace'), findsOneWidget);
    expect(find.text('Títulos'), findsOneWidget);
  });

  testWidgets('it never offers a tool with no route', (tester) async {
    // `Tool.isReady` is the existing invariant. A menu entry that goes
    // nowhere is worse than an absent one.
    await _pump(tester);
    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    for (final tool in tools.where((t) => !t.isReady)) {
      expect(find.text(tool.name), findsNothing, reason: tool.name);
    }
  });

  testWidgets('on narrow, the sections collapse to one overflow button', (
    tester,
  ) async {
    // Not a drawer: `mobile_filter_test` already fixes the rule this site
    // follows on a phone, one panel at a time, and a second navigation
    // surface would break it.
    await _pump(tester, wide: false);

    expect(find.text('Ferramentas'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Filtro do Marketplace'), findsOneWidget);
  });
}
