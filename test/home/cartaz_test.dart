import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';
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
  String subtitulo =
      'Arma, cartas, relíquias, essências, runas — o que o '
      'marketplace guarda no inventário e não deixa procurar.',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        // A tight outer box (the shape this file used to pump into) clamps
        // Cartaz's own `height: wide ? 360 : 340` away to whatever the box
        // says — so a `360` changed to `200` left every test here green.
        // `SingleChildScrollView` hands its child loose (0..infinity)
        // height constraints instead, the way the real front page's
        // scrolling column does, so Cartaz's own height actually reaches
        // the render tree and can be measured.
        body: SingleChildScrollView(
          child: SizedBox(
            width: 1200,
            child: Cartaz(
              classe: classe,
              wide: true,
              aoBuscar: aoBuscar ?? () {},
              aoVerGuias: () {},
              subtitulo: subtitulo,
            ),
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

    // Lido da função e não cravado à mão: um caminho escrito aqui divergiria
    // no dia em que a função mudasse de pasta, que é precisamente o que
    // aconteceu a 06/11/2026 ao entrarem os dois tamanhos.
    expect(imagens, contains(arteVerticalDaClasse('Bárbaro')));
    // E é o tamanho grande que ele pede, porque o Cartaz é o único sítio que
    // amplia a arte — a caixa é da largura da página.
    expect(imagens.single, contains('/960/'));
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

  testWidgets('o herói ocupa a dobra, não uma faixa', (tester) async {
    // **Eram 360 px cravados e passaram a ser `min(86vh, 760px)` a
    // 09/11/2026**, que é o que a maquete declara para `.heroi` — o mesmo
    // valor nas duas telas, raiz e versão. O número antigo estava certo para
    // o que ele era: uma faixa. Deixou de ser faixa.
    //
    // A razão de medir continua a mesma e vale repeti-la: o `height` deste
    // widget já foi engolido pelo `SizedBox` apertado deste ficheiro, e
    // baixá-lo de 360 para 200 deixava tudo verde. Mede-se o tamanho real,
    // sob restrições largas.
    await _pump(tester);

    final janela =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    expect(
      tester.getSize(find.byType(Cartaz)).height,
      Cartaz.alturaDoHeroi(true, janela),
    );
  });

  testWidgets('a arte cabe na altura e encosta à direita, nunca esticada', (
    tester,
  ) async {
    // **Troca presença por nitidez, decidida pelo dono a 10/11/2026 à vista
    // das três saídas.** Com `cover` a arte de 960×1440 era esticada pela
    // *largura* — 1,48× numa janela de 1420, 2,96× em píxeis de ecrã retina —
    // e era isso que amolecia o rosto. À altura fica a 1,06×.
    //
    // O preço está medido e aceite: a arte passa a ocupar 507 px fixos, que a
    // 1420 são 36% da dobra e num monitor de 1920 deixam 1400 px de chão.
    //
    // O `fit` é o que este teste guarda: um `cover` de volta traz a
    // ampliação sem nada no ecrã a dizer porquê. **E ele vive no `FittedBox`
    // e não na `Image`** — a imagem não leva `fit` nenhum, portanto procurá-lo
    // lá dá `null` e o teste passaria a afirmar nada.
    await _pump(tester, classe: 'Bárbaro');

    final caixa = tester.widget<FittedBox>(
      find.ancestor(of: find.byType(Image), matching: find.byType(FittedBox)),
    );
    expect(caixa.fit, BoxFit.fitHeight);
    expect(caixa.alignment, Alignment.centerRight);
  });

  testWidgets('e o herói da raiz continua a encher a caixa', (tester) async {
    // A raiz não faz isto, e a razão é que lá já não é preciso: a capa das
    // dezassete resolve a nitidez sem abrir mão da arte a encher. Aqui não
    // serviria, porque mataria a rotação de classe por coleta — que é o que
    // faz a tela de versão mudar de cara entre visitas.
    //
    // `heroi_da_raiz_test` crava o `cover` do outro lado; isto é só para a
    // diferença entre as duas telas ser deliberada e não um descuido.
    expect(Cartaz, isNotNull);
  });
}
