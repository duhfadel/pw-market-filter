import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/novidade_repository.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';

import '../support/novidades_test_support.dart';

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

/// Mounts `Cabecalho` under a `NovidadesViewModel` with nothing posted —
/// `comNovidades` is what every one of these tests needs just to build at
/// all, now that the pill's own lookup has no fallback for a missing one.
/// [comProvider] exists only for the one test proving that fallback is
/// really gone: without it, this mounts `Cabecalho` bare, the way a screen
/// that forgot the provider would.
Future<void> _montarCabecalho(
  WidgetTester tester, {
  bool wide = true,
  bool comProvider = true,
}) async {
  final cabecalho = Scaffold(
    body: SizedBox(width: 1200, child: Cabecalho(wide: wide)),
  );
  await tester.pumpWidget(
    MaterialApp(home: comProvider ? comNovidades(cabecalho) : cabecalho),
  );
  if (comProvider) await tester.pump();
}

/// The tools filed under `Ferramentas`, the same list the pill reads.
final ferramentas = toolsDe('Ferramentas');

/// A `NovidadeRepository` answering [corpo] regardless of the request —
/// enough for the one entry these tests need the pill's `NovidadesViewModel`
/// to carry.
NovidadeRepository _repositorioDe(Object corpo) => NovidadeRepository(
  MockClient((_) async => http.Response(jsonEncode(corpo), 200)),
);

final _umaNovidade = [
  {
    'texto': '**Selo novo no site**\nUma linha contando o que mudou.',
    'autor': 'dono',
    'publicada_em': '2026-09-30T12:00:00Z',
  },
];

/// Mounts `Cabecalho` under a real `NovidadesViewModel`, the way `main.dart`
/// wraps every route — the pill reads it through `BlocProvider.of`, not
/// through a parameter any of the five screens have to pass by hand.
Future<void> _montarComNovidades(
  WidgetTester tester, {
  required Object corpo,
  BrowserMemory? memoria,
}) async {
  final viewModel = NovidadesViewModel(_repositorioDe(corpo));
  await tester.pumpWidget(
    BlocProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: Cabecalho(wide: true, memoriaDeNovidades: memoria),
          ),
        ),
      ),
    ),
  );
  await viewModel.load();
  await tester.pump();
}

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

  group('the Novidades pill carries the unread dot moved off the home bar', () {
    testWidgets('a browser that has never opened it gets the dot', (
      tester,
    ) async {
      await _montarComNovidades(
        tester,
        corpo: _umaNovidade,
        memoria: BrowserMemory.platform('teste-nunca-leu'),
      );

      expect(find.byKey(const Key('novidade-nao-lida')), findsOneWidget);
    });

    testWidgets('a browser already caught up gets no dot', (tester) async {
      final memoria = BrowserMemory.platform('teste-ja-leu')
        ..write(DateTime.utc(2026, 9, 30, 12).toIso8601String());

      await _montarComNovidades(tester, corpo: _umaNovidade, memoria: memoria);

      expect(find.byKey(const Key('novidade-nao-lida')), findsNothing);
    });

    testWidgets(
      'the dot shows the instant the real entries arrive, with no extra '
      'frame needed',
      (tester) async {
        // Pins the hazard the old bar's docstring warned about, read for the
        // new architecture: there is no write anywhere in this build path any
        // more, so a fresh read never flickers between frames the way a
        // write-then-reread would have.
        await _montarComNovidades(
          tester,
          corpo: _umaNovidade,
          memoria: BrowserMemory.platform('teste-primeiro-frame'),
        );

        expect(find.byKey(const Key('novidade-nao-lida')), findsOneWidget);

        // An idle pump, nothing changed — the dot must still be there and
        // not have cleared itself.
        await tester.pump();
        expect(find.byKey(const Key('novidade-nao-lida')), findsOneWidget);
      },
    );

    testWidgets(
      'with no NovidadesViewModel above it, the pill fails loudly rather '
      'than drawing silently with no dot',
      (tester) async {
        // The catch that used to sit around this lookup was removed on
        // purpose — see `_NovidadesPill`'s own build method for why — and
        // this is the behaviour that removal buys: a screen that genuinely
        // forgets the provider gets a clear error naming the missing type,
        // the same way `BlocProvider.of` already fails for every other bloc
        // in this app, rather than an unlit dot that explains nothing.
        await _montarCabecalho(tester, comProvider: false);

        // `takeException` bundles every exception recorded in one pump into
        // a single report the moment more than one lands — here that is
        // `BlocProvider.of`'s own error plus the layout overflow of the
        // error widget it leaves behind, one root cause wearing two faces.
        // So this proves the loud half of the behaviour (something failed)
        // rather than pattern-matching the exact text of a report the
        // framework itself may reshape.
        expect(tester.takeException(), isNotNull);
      },
    );
  });
}
