import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/domain/streamer_accent.dart';
import 'package:pw_market_filter/features/home/ui/widgets/ao_vivo_strip.dart';

import '../support/load_fonts.dart';

/// The redesigned streamer card: full width, one colour per streamer, and a
/// scoreboard that replaces `58 assistindo` set in 13 px.
///
/// `flutter_test` renders every glyph as a square of the font size, which
/// both hides real overflows and invents ones no browser would ever show —
/// [loadAppFonts] puts the real Marcellus and Roboto on the test binding so
/// these tests measure what a browser measures.
void main() {
  setUpAll(loadAppFonts);

  CanalAoVivo canal({
    String canal = 'gsafoot',
    String nome = 'GsaFoot',
    int? espectadores = 58,
    String? jogo = 'Perfect World',
  }) => CanalAoVivo(
    canal: canal,
    nome: nome,
    aoVivo: true,
    titulo: 'The Classic PW 1.8.7',
    jogo: jogo,
    espectadores: espectadores,
    vistoEm: DateTime.now(),
  );

  Future<void> pump(
    WidgetTester tester, {
    required CanalAoVivo canal,
    required bool wide,
    double? width,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: CardDoStreamer(canal: canal, wide: wide),
          ),
        ),
      ),
    ),
  );

  group('at narrow width', () {
    testWidgets('a long name and game lay out with no overflow', (
      tester,
    ) async {
      await pump(
        tester,
        canal: canal(
          nome: 'Um Nome de Streamer Bem Comprido Para Testar',
          jogo: 'Perfect World The Classic 1.8.7',
        ),
        wide: false,
        width: 350,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('"ao vivo na Twitch" does not appear narrow', (tester) async {
      await pump(tester, canal: canal(), wide: false, width: 350);
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('ao vivo na Twitch'), findsNothing);
    });

    testWidgets('it does appear wide', (tester) async {
      await pump(tester, canal: canal(), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('ao vivo na Twitch'), findsOneWidget);
    });
  });

  group('a channel with no art', () {
    testWidgets('renders with no exception and no reserved gap', (
      tester,
    ) async {
      // The test harness has no network access, so every `Image.network`
      // here fails the same way a 404 would on the real bucket — this is
      // the "no art" path exercised for free, not simulated.
      await pump(tester, canal: canal(), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
      expect(find.text('GsaFoot'), findsOneWidget);
    });

    testWidgets('draws no emblem column at all — no seam, no empty box', (
      tester,
    ) async {
      // The regression this pins: the emblem used to be mounted
      // unconditionally and fail silently through its own `errorBuilder`,
      // but that `errorBuilder` sat inside a `Stack(fit: StackFit.expand)`,
      // which forces a non-positioned child to the parent's full size no
      // matter what it asked for. "Nothing" came out as an empty, tinted
      // rectangle at the column's full size with a hard seam at its right
      // edge — reported live on zMaroto's card as two shades of violet and
      // a line, not the absence every other missing-art case in this app
      // draws. This test builds the emblem's own signature —
      // `FractionallySizedBox(widthFactor: 0.24)` — and demands it is
      // simply not there when no art loaded, which is what "no column"
      // means: not an invisible one, no column.
      await pump(
        tester,
        canal: canal(canal: 'zmaroto', nome: 'zMaroto'),
        wide: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(
        find.byWidgetPredicate(
          (w) => w is FractionallySizedBox && w.widthFactor == 0.24,
        ),
        findsNothing,
      );
    });
  });

  group('the scoreboard', () {
    testWidgets('shows the raw viewer count', (tester) async {
      await pump(tester, canal: canal(espectadores: 58), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('58'), findsOneWidget);
      expect(find.text('ASSISTINDO'), findsOneWidget);
    });

    testWidgets('never sits on the Marcellus display face', (tester) async {
      await pump(tester, canal: canal(espectadores: 58), wide: true);
      await tester.pump(const Duration(seconds: 1));

      final numero = tester.widget<Text>(find.text('58'));
      expect(numero.style?.fontFamily, isNot(PWTheme.display));
    });

    testWidgets('is absent when the viewer count is unknown', (tester) async {
      await pump(tester, canal: canal(espectadores: null), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('ASSISTINDO'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('the accent', () {
    testWidgets('an unknown login falls back to the site violet', (
      tester,
    ) async {
      await pump(
        tester,
        canal: canal(canal: 'ninguem-conhece-esse', nome: 'Desconhecido'),
        wide: true,
      );
      await tester.pump(const Duration(seconds: 1));

      final borda = _bordaDoCard(tester);
      expect(borda, StreamerAccent.fallback);
      expect(borda, isNot(PWColors.accent));
    });

    testWidgets('gsafoot wears its measured green on the border', (
      tester,
    ) async {
      await pump(tester, canal: canal(canal: 'gsafoot'), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(_bordaDoCard(tester), StreamerAccent.of('gsafoot'));
    });
  });

  group('the live dot', () {
    testWidgets('wears the streamer\'s own accent, not a universal green', (
      tester,
    ) async {
      // The approved design has every mark on the card — border, glow,
      // wash and the dot — carry the streamer's accent. The first cut of
      // this redesign left the dot on the old, pre-existing `PWColors.live`
      // green: not a decision, just the one mark nobody re-examined when
      // the accent system was added. Caught live on zMaroto, whose card is
      // violet while the dot still drew green.
      await pump(
        tester,
        canal: canal(canal: 'ninguem-conhece-esse', nome: 'Desconhecido'),
        wide: true,
      );
      await tester.pump(const Duration(seconds: 1));

      expect(_corDoPonto(tester), StreamerAccent.fallback);
      expect(_corDoPonto(tester), isNot(PWColors.live));
    });

    testWidgets('matches a known streamer\'s measured accent', (tester) async {
      await pump(tester, canal: canal(canal: 'gsafoot'), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(_corDoPonto(tester), StreamerAccent.of('gsafoot'));
    });
  });

  group('gold never appears on a streamer card', () {
    testWidgets('no colour anywhere in the tree is PWColors.accent', (
      tester,
    ) async {
      await pump(tester, canal: canal(), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(_todasAsCores(tester), isNot(contains(PWColors.accent)));
    });

    testWidgets('holds for a card with no viewer count too', (tester) async {
      await pump(tester, canal: canal(espectadores: null), wide: true);
      await tester.pump(const Duration(seconds: 1));

      expect(_todasAsCores(tester), isNot(contains(PWColors.accent)));
    });
  });
}

/// The accent colour, read off the inner, bordered `Container` — the one
/// `CardDoStreamer` paints with `Border.all(color: accent)`.
Color _bordaDoCard(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere((c) => (c.decoration as BoxDecoration?)?.border != null);
  final border = (container.decoration! as BoxDecoration).border! as Border;
  return border.top.color;
}

/// The live dot's own colour — the 10×10 circular `Container` beside the
/// name, found by its shape rather than by position so the test does not
/// care which widget happens to sit next to it.
Color _corDoPonto(WidgetTester tester) {
  final container = tester
      .widgetList<Container>(find.byType(Container))
      .firstWhere(
        (c) =>
            c.constraints?.maxWidth == 10 &&
            (c.decoration as BoxDecoration?)?.shape == BoxShape.circle,
      );
  return (container.decoration! as BoxDecoration).color!;
}

/// Every colour mentioned anywhere in the built tree: text, borders, box
/// shadows and gradient stops. Broad on purpose — the one rule that must
/// hold everywhere is "gold never shows up here", and that is only proven by
/// looking at everything, not at the one place a gold border was expected.
Set<Color> _todasAsCores(WidgetTester tester) {
  final cores = <Color>{};

  for (final widget in tester.allWidgets) {
    if (widget is Text && widget.style?.color != null) {
      cores.add(widget.style!.color!);
    }
    if (widget is DecoratedBox) {
      cores.addAll(_coresDaDecoracao(widget.decoration));
    }
    if (widget is Container && widget.decoration != null) {
      cores.addAll(_coresDaDecoracao(widget.decoration!));
    }
  }

  return cores;
}

Set<Color> _coresDaDecoracao(Decoration decoration) {
  final cores = <Color>{};
  if (decoration is BoxDecoration) {
    if (decoration.color != null) cores.add(decoration.color!);
    final border = decoration.border;
    if (border is Border) cores.add(border.top.color);
    for (final sombra in decoration.boxShadow ?? const <BoxShadow>[]) {
      cores.add(sombra.color);
    }
    final gradient = decoration.gradient;
    if (gradient is LinearGradient) cores.addAll(gradient.colors);
  }
  return cores;
}
