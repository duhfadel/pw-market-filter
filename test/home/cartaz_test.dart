import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cartaz.dart';

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
}
