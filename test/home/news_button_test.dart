import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/domain/novidade.dart';
import 'package:pw_market_filter/features/home/ui/widgets/news_section.dart';

/// The front page's news, closed.
///
/// It started open, and three entries ran to a thousand pixels: the tools
/// began two screens below the fold, so the page led with a newspaper instead
/// of with what the site does. Nothing was dropped — the header carries the
/// latest entry's own title and date, and opening it gives back what was
/// always there.
Novidade _novidade(String titulo, DateTime quando) => Novidade(
  autor: 'duhit',
  titulo: titulo,
  corpo: 'O corpo do recado.',
  publicadaEm: quando,
);

final _entradas = [
  _novidade('Essência Dracônica no filtro', DateTime.utc(2026, 9, 22)),
  _novidade('Títulos e streamers', DateTime.utc(2026, 9, 21)),
];

Future<void> _pump(WidgetTester tester, {BrowserMemory? memoria}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NewsSection(entries: _entradas, wide: true, memoria: memoria),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('closed, it shows the latest title and date', (tester) async {
    await _pump(tester);

    expect(find.text('Essência Dracônica no filtro'), findsOneWidget);
    expect(find.text('22/09/2026'), findsOneWidget);
    // The body is what a thousand pixels were made of.
    expect(find.text('O corpo do recado.'), findsNothing);
  });

  testWidgets('tapping it gives back every entry', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Essência Dracônica no filtro'));
    await tester.pumpAndSettle();

    expect(find.text('Títulos e streamers'), findsOneWidget);
    expect(find.text('O corpo do recado.'), findsNWidgets(2));
  });

  testWidgets('a browser that has never read it gets the dot', (tester) async {
    await _pump(tester, memoria: BrowserMemory.platform('teste'));

    expect(find.byKey(const Key('novidade-nao-lida')), findsOneWidget);
  });

  testWidgets('opening it marks the latest as read', (tester) async {
    final memoria = BrowserMemory.platform('teste');
    await _pump(tester, memoria: memoria);

    await tester.tap(find.text('Essência Dracônica no filtro'));
    await tester.pumpAndSettle();

    expect(memoria.read(), _entradas.first.publicadaEm.toIso8601String());
    expect(find.byKey(const Key('novidade-nao-lida')), findsNothing);
  });

  testWidgets('a browser already up to date gets no dot', (tester) async {
    // The dot is the whole reason the bar earns a second look. One that stays
    // lit after it has been read teaches the reader to stop seeing it — the
    // same failure the `novo` badge's expiry date exists to avoid.
    final memoria = BrowserMemory.platform('teste')
      ..write(_entradas.first.publicadaEm.toIso8601String());

    await _pump(tester, memoria: memoria);

    expect(find.byKey(const Key('novidade-nao-lida')), findsNothing);
  });
}
