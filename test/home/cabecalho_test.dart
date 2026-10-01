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

Future<void> _montarCabecalho(WidgetTester tester, {bool wide = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 1200, child: Cabecalho(wide: wide)),
      ),
    ),
  );
}

/// The tools filed under `Ferramentas`, the same list the pill reads.
final ferramentas = toolsDe('Ferramentas');

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the mark is small and the name is beside it', (tester) async {
    // The fan art is not discarded — it is moved to the size at which it
    // reads. At 200 px of dark red on dark violet it was the largest element
    // on the page and the least legible.
    await _montarCabecalho(tester);

    final marca = tester.widget<Image>(find.byType(Image).first);
    expect((marca.image as AssetImage).assetName, contains('pw-mark'));
    expect(marca.height, lessThan(40));
    expect(find.text('PORTAL PW'), findsOneWidget);
  });

  testWidgets('the pill counts only the tools that are ready', (tester) async {
    await _montarCabecalho(tester);

    final prontas = ferramentas.where((t) => t.isReady).length;
    expect(find.text('$prontas'), findsOneWidget);
  });

  testWidgets('tapping opens the drawer, tapping away closes it', (
    tester,
  ) async {
    await _montarCabecalho(tester);

    expect(find.text('Calculadora de runas'), findsNothing);

    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora de runas'), findsOneWidget);

    // Outside the drawer, which `PopupMenuButton`'s own barrier dismisses —
    // not a custom gesture detector this file has to guess the bounds of.
    await tester.tapAt(const Offset(5, 400));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora de runas'), findsNothing);
  });

  testWidgets('every drawer item carries a one-line description', (
    tester,
  ) async {
    // *Títulos* alone says nothing to somebody who has never used it — the
    // tagline is what makes the drawer say more than a card's title would.
    await _montarCabecalho(tester);

    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    for (final tool in ferramentas) {
      expect(find.text(tool.tagline), findsOneWidget, reason: tool.name);
    }
  });

  testWidgets('a tool that is not ready is listed, dimmed, and says em breve', (
    tester,
  ) async {
    // The real `tools` list carries nothing unready today — the whole
    // reason `GavetaItem` is a public widget is so this case can still be
    // proven without inventing a fifth tool in the domain just for a test.
    const tool = Tool(
      name: 'Guerras territoriais',
      tagline: 'A guide nobody has written yet.',
      icon: Icons.map_outlined,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Material(child: GavetaItem(tool: tool)),
      ),
    );

    expect(find.text('Guerras territoriais'), findsOneWidget);
    expect(find.text('em breve'), findsOneWidget);

    final opacity = tester.widget<Opacity>(find.byType(Opacity));
    expect(opacity.opacity, lessThan(1));
  });

  testWidgets('on narrow, the sections collapse to one overflow button', (
    tester,
  ) async {
    // Not a second pill row: `mobile_filter_test` already fixes the rule
    // this site follows on a phone, one panel at a time, and a second
    // navigation surface would break it.
    await _montarCabecalho(tester, wide: false);

    expect(find.text('Ferramentas'), findsNothing);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('Filtro do Marketplace'), findsOneWidget);
  });
}
