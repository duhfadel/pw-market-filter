import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/data/browser_memory.dart';
import 'package:pw_market_filter/features/home/data/novidade_lida.dart';
import 'package:pw_market_filter/features/home/domain/novidade.dart';
import 'package:pw_market_filter/features/novidades/ui/novidades_view.dart';

import '../support/novidades_test_support.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` declares, the way
/// `test/home/cartaz_test.dart` does. `flutter_test` draws every glyph as a
/// square of the font size by default, which fabricates overflows no browser
/// would ever show.
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

Novidade _nova({
  String? titulo = 'Atualização do mercado',
  String corpo = 'Corpo padrão da novidade.',
  DateTime? em,
}) => Novidade(
  titulo: titulo,
  corpo: corpo,
  autor: null,
  publicadaEm: em ?? DateTime.utc(2026, 1, 1),
);

Future<void> _montar(
  WidgetTester tester, {
  required List<Novidade> novidades,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      // `NovidadesView` carries `Cabecalho` in its `AppBar`, and the pill's
      // own lookup has no fallback for a missing `NovidadesViewModel` —
      // every test here needs `comNovidades` for that reason alone, not
      // because any of them cares what the pill's dot shows.
      home: comNovidades(
        NovidadesView(carregar: () async => Success(novidades)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(_carregarFontesReais);

  testWidgets('the newest entry is at the top', (tester) async {
    await _montar(
      tester,
      novidades: [
        _nova(titulo: 'Mais antiga', em: DateTime.utc(2026, 9, 1)),
        _nova(titulo: 'Mais nova', em: DateTime.utc(2026, 10, 1)),
      ],
    );

    final nova = tester.getRect(find.text('Mais nova'));
    final antiga = tester.getRect(find.text('Mais antiga'));
    expect(nova.top, lessThan(antiga.top));
  });

  testWidgets('an entry with no title still draws its body and date', (
    tester,
  ) async {
    // A short Discord message has no wholly-bold first line, and
    // `Novidade.deTexto` leaves `titulo` null for it. It must not vanish.
    await _montar(
      tester,
      novidades: [_nova(titulo: null, corpo: 'servidor de pé')],
    );
    expect(find.text('servidor de pé'), findsOneWidget);
  });

  testWidgets('no news at all says so, and does not look broken', (
    tester,
  ) async {
    await _montar(tester, novidades: const []);
    expect(find.textContaining('Nenhuma novidade'), findsOneWidget);
  });

  testWidgets('a failed request is not drawn the same as no news', (
    tester,
  ) async {
    // The repository never throws, but it does distinguish an empty table
    // from a request that failed — this screen must not fold the two back
    // into one blank state.
    await tester.pumpWidget(
      MaterialApp(
        home: comNovidades(
          NovidadesView(
            carregar: () async =>
                const Failure(IndexUnreadableFailure('rede', 'timeout')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Nenhuma novidade'), findsNothing);
    expect(find.textContaining('Não deu para carregar'), findsOneWidget);
  });

  testWidgets('the date never renders in Marcellus', (tester) async {
    // Its `0` is barely an `O` and its `1` has no flag: a date in that face
    // is unreadable, and it is the most expensive defect available here.
    await _montar(tester, novidades: [_nova(em: DateTime.utc(2026, 10, 1))]);

    for (final texto in tester.widgetList<Text>(find.byType(Text))) {
      final temDigito = RegExp(r'\d').hasMatch(texto.data ?? '');
      if (temDigito) {
        expect(
          texto.style?.fontFamily,
          isNot(PWTheme.display),
          reason: 'digits must stay on the body face: ${texto.data}',
        );
      }
    }
  });

  group('opening this screen clears the header pill\'s unread dot', () {
    testWidgets('a successful load marks the newest entry as read', (
      tester,
    ) async {
      final memoria = BrowserMemory.platform('teste-marca-ao-abrir');
      final lida = NovidadeLida(memoria);
      final entradas = [
        _nova(titulo: 'Mais antiga', em: DateTime.utc(2026, 9, 1)),
        _nova(titulo: 'Mais nova', em: DateTime.utc(2026, 10, 1)),
      ];
      expect(lida.existeNaoLida(entradas), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: comNovidades(
            NovidadesView(carregar: () async => Success(entradas), lida: lida),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(lida.existeNaoLida(entradas), isFalse);
    });

    testWidgets('a failed load marks nothing', (tester) async {
      // The screen does not know what the newest entry actually is when the
      // request fails, so marking off a guess would clear the dot for news
      // this browser never saw.
      final memoria = BrowserMemory.platform('teste-marca-falha');
      final lida = NovidadeLida(memoria);

      await tester.pumpWidget(
        MaterialApp(
          home: comNovidades(
            NovidadesView(
              carregar: () async =>
                  const Failure(IndexUnreadableFailure('rede', 'timeout')),
              lida: lida,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(memoria.read(), isNull);
    });

    testWidgets('an empty table marks nothing, for the same reason', (
      tester,
    ) async {
      final memoria = BrowserMemory.platform('teste-marca-vazio');
      final lida = NovidadeLida(memoria);

      await tester.pumpWidget(
        MaterialApp(
          home: comNovidades(
            NovidadesView(carregar: () async => const Success([]), lida: lida),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(memoria.read(), isNull);
    });
  });
}
