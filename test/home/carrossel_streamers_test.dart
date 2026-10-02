import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/ui/widgets/ao_vivo_strip.dart';

import '../support/load_fonts.dart';

/// The strip as an endless carousel: two cards a page on wide, one on narrow,
/// and the first following the last for ever.
///
/// Real fonts, because the whole reason two fit and three do not is a measured
/// width — `flutter_test`'s square glyphs would make a card 286 px where a
/// browser draws 150, and the conclusion would be about the harness.
class _Fixo extends Cubit<List<CanalAoVivo>> implements AoVivoViewModel {
  _Fixo(super.canais);

  @override
  Future<void> load() async {}
}

void main() {
  setUpAll(loadAppFonts);

  CanalAoVivo canal(String login) => CanalAoVivo(
    canal: login,
    nome: login,
    aoVivo: true,
    titulo: 'The Classic PW 1.8.7',
    jogo: 'Perfect World',
    espectadores: 10,
    vistoEm: DateTime.now(),
  );

  Future<void> pump(
    WidgetTester tester,
    List<String> logins, {
    bool wide = true,
  }) async {
    tester.view.physicalSize = Size(wide ? 1040 : 390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<AoVivoViewModel>.value(
        value: _Fixo([for (final l in logins) canal(l)]),
        child: MaterialApp(
          theme: PWTheme.build(),
          home: Scaffold(body: AoVivoStrip(wide: wide)),
        ),
      ),
    );
    await tester.pump();
  }

  group('how many a page holds', () {
    testWidgets('two side by side on wide', (tester) async {
      await pump(tester, ['um', 'dois', 'tres', 'quatro']);

      expect(find.text('um'), findsOneWidget);
      expect(find.text('dois'), findsOneWidget);
      // The next page is built but off screen; what matters is that the
      // first page holds exactly two.
      expect(find.text('quatro'), findsNothing);
    });

    testWidgets('one at a time on narrow', (tester) async {
      await pump(tester, ['um', 'dois', 'tres'], wide: false);

      expect(find.text('um'), findsOneWidget);
      expect(find.text('dois'), findsNothing);
    });
  });

  group('the window wraps rather than leaving a hole', () {
    testWidgets('with three live, the second page is the third and the first', (
      tester,
    ) async {
      // The odd-number case. Without the wrap this page would be one card and
      // an empty half, and the strip would change shape as it turned.
      await pump(tester, ['um', 'dois', 'tres']);

      await tester.drag(find.byType(PageView), const Offset(-900, 0));
      await tester.pumpAndSettle();

      expect(find.text('tres'), findsOneWidget);
      expect(find.text('um'), findsOneWidget);
      expect(find.text('dois'), findsNothing);
    });
  });

  group('nothing moves while everyone already fits', () {
    testWidgets('two live on wide is a static pair, not a carousel', (
      tester,
    ) async {
      // A `PageView` of one page still eats drag gestures and springs back,
      // which reads as a bug in a section that is otherwise still.
      await pump(tester, ['um', 'dois']);

      expect(find.byType(PageView), findsNothing);
      expect(find.text('um'), findsOneWidget);
      expect(find.text('dois'), findsOneWidget);
    });

    testWidgets('one live on narrow is a static card', (tester) async {
      await pump(tester, ['um'], wide: false);

      expect(find.byType(PageView), findsNothing);
      expect(find.text('um'), findsOneWidget);
    });

    testWidgets('and it turns again the moment a third appears', (
      tester,
    ) async {
      // The Worker rewrites the table every five minutes, so the live set
      // changes under the widget — a strip that was static with two has to
      // start turning when a third goes live.
      await pump(tester, ['um', 'dois', 'tres']);

      expect(find.byType(PageView), findsOneWidget);
    });
  });

  testWidgets('nobody live draws nothing at all', (tester) async {
    await pump(tester, const []);

    expect(find.byType(PageView), findsNothing);
    expect(find.textContaining('ao vivo'), findsNothing);
  });

  testWidgets('it turns by itself, and stops under the pointer', (
    tester,
  ) async {
    // The one real defect of a carousel: the card sliding out from under
    // somebody on their way to clicking it. Here that does not merely annoy,
    // it opens the wrong streamer's channel — and this section exists to help
    // the people who stream.
    await pump(tester, ['um', 'dois', 'tres', 'quatro']);

    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(
      find.text('tres'),
      findsOneWidget,
      reason: 'did not turn on its own',
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: tester.getCenter(find.text('tres')));
    addTearDown(gesture.removePointer);
    await tester.pump();

    final antes = find.text('tres').evaluate().length;
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('tres').evaluate().length, antes);
    expect(
      find.text('tres'),
      findsOneWidget,
      reason: 'turned under the cursor',
    );
  });
}
