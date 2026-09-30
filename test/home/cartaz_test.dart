import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cartaz.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` already declares,
/// so this file measures text the way a browser does.
///
/// `flutter_test` draws every glyph as a square the size of the font by
/// default, which is not what ships. Without this, a layout tuned against
/// the fake metrics can carry padding the real fonts never needed — that is
/// exactly what happened here once, and no widget test caught it because
/// none of them loaded the fonts the widget actually ships with.
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

Future<void> _pump(
  WidgetTester tester, {
  String classe = 'Espiritualista',
  VoidCallback? aoBuscar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 400,
          child: Cartaz(
            classe: classe,
            wide: true,
            aoBuscar: aoBuscar ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('it says what the site does before it says its name', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('Ache o personagem'), findsOneWidget);
  });

  testWidgets('the search button is there and calls back', (tester) async {
    var chamou = false;
    await _pump(tester, aoBuscar: () => chamou = true);

    await tester.tap(find.text('Buscar personagens'));
    expect(chamou, isTrue);
  });

  testWidgets('it draws the art of the class it was given', (tester) async {
    await _pump(tester, classe: 'Bárbaro');

    final imagens = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName);

    expect(imagens, contains('assets/images/classes/barbaro.webp'));
  });

  testWidgets('a class with no art draws no image and does not crash', (
    tester,
  ) async {
    // The index could name a class the art never covered — a new one, or a
    // spelling nobody predicted. The hero falls back to the ground.
    await _pump(tester, classe: 'Necromante');

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('Ache o personagem'), findsOneWidget);
  });

  testWidgets('gold appears on the button and nowhere else', (tester) async {
    // The page's one rule. Gold is price and the call to action; an arrow or a
    // rule wearing it would spend the colour that has to mean money.
    await _pump(tester);

    final dourados = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.color == PWColors.accent);

    expect(dourados, isEmpty, reason: 'no text on the Cartaz is gold');
  });

  testWidgets('the hero fits under real font metrics, no overflow', (
    tester,
  ) async {
    // The fake square-glyph font used to fabricate an overflow here that
    // never existed under Marcellus and Inter — this is the test that tells
    // the two apart, by loading the fonts the widget actually ships with.
    await _pump(tester);

    expect(tester.takeException(), isNull);
  });
}
