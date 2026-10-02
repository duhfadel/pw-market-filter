import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/portas/ui/portas_view.dart';
import 'package:pw_market_filter/market/versoes.dart';
import 'package:pw_market_filter/market/versoes_repository.dart';

import '../support/novidades_test_support.dart';

/// Loads the real Marcellus and Inter files `pubspec.yaml` declares, the way
/// `test/home/cartaz_test.dart` does. `flutter_test` draws every glyph as a
/// square of the font size by default, which fabricates overflows no browser
/// would ever show and would hide a real one just as easily.
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

VersaoResumo _resumo({
  String chave = 'pw187',
  String nome = '1.8.7',
  int personagens = 1715,
  DateTime? coletadoEm,
}) => VersaoResumo(
  chave: chave,
  nome: nome,
  personagens: personagens,
  coletadoEm: coletadoEm ?? DateTime.utc(2026, 10, 2, 7, 30),
);

Future<void> _montar(
  WidgetTester tester, {
  required Future<Result<Map<String, VersaoResumo>>> Function() carregar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            comNovidades(Scaffold(body: Text('rota: ${settings.name}'))),
      ),
      home: comNovidades(PortasView(carregar: carregar)),
    ),
  );
  await tester.pumpAndSettle();
}

/// The door for [chave] — `'pw187'` or `'pw126'` — and nothing else.
///
/// `Cabecalho`'s own `_Marca` prints the literal text `'1.8.7'` beside the
/// site's mark on every screen, this one included — "the game's own version,
/// not this site's", by its own doc comment. A bare `find.text('1.8.7')`
/// therefore matches that badge too, which has nothing to do with the door
/// under test; scoping every lookup to the door's own key is what keeps this
/// suite about the chooser and not about the header it happens to share with
/// every other screen.
Finder _porta(String chave) => find.byKey(Key('porta-$chave'));

Finder _textoNaPorta(String chave, String texto) =>
    find.descendant(of: _porta(chave), matching: find.text(texto));

Finder _contendoNaPorta(String chave, String trecho) =>
    find.descendant(of: _porta(chave), matching: find.textContaining(trecho));

void main() {
  setUpAll(_carregarFontesReais);

  group('as duas portas', () {
    testWidgets('both versions collected: both doors show their own facts', (
      tester,
    ) async {
      await _montar(
        tester,
        carregar: () async => Success({
          'pw187': _resumo(
            chave: 'pw187',
            nome: '1.8.7',
            personagens: 1715,
            coletadoEm: DateTime.utc(2026, 10, 2, 7, 30),
          ),
          'pw126': _resumo(
            chave: 'pw126',
            nome: '1.2.6',
            personagens: 1293,
            coletadoEm: DateTime.utc(2026, 10, 1, 18, 19),
          ),
        }),
      );

      expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
      expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
      expect(_contendoNaPorta('pw187', '1.715 personagens'), findsOneWidget);
      expect(_contendoNaPorta('pw126', '1.293 personagens'), findsOneWidget);
      // The date is read in local time by `DateTime.toLocal()`, so the test
      // only pins the label — the exact day depends on where this suite runs.
      expect(_contendoNaPorta('pw187', 'coletado em'), findsOneWidget);
      expect(_contendoNaPorta('pw126', 'coletado em'), findsOneWidget);
      expect(find.textContaining('em breve'), findsNothing);
    });

    testWidgets(
      'a version with no index yet is dimmed, labelled em breve, and opens nothing',
      (tester) async {
        await _montar(
          tester,
          carregar: () async => Success({'pw187': _resumo()}),
        );

        expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
        expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
        expect(_contendoNaPorta('pw126', 'em breve'), findsOneWidget);
        // The ready door prints its facts; the dimmed one prints none of them.
        expect(_contendoNaPorta('pw187', 'personagens'), findsOneWidget);
        expect(_contendoNaPorta('pw126', 'personagens'), findsNothing);

        final portaFechada = tester.widget<Opacity>(_porta('pw126'));
        expect(portaFechada.opacity, lessThan(1));

        final toqueFechado = tester.widget<InkWell>(
          find.descendant(of: _porta('pw126'), matching: find.byType(InkWell)),
        );
        expect(
          toqueFechado.onTap,
          isNull,
          reason: 'a door with no market yet must not be enterable',
        );

        final portaAberta = tester.widget<Opacity>(_porta('pw187'));
        expect(portaAberta.opacity, 1);
      },
    );

    testWidgets("tapping a ready door opens that version's home", (
      tester,
    ) async {
      await _montar(
        tester,
        carregar: () async => Success({'pw187': _resumo()}),
      );

      await tester.tap(_porta('pw187'));
      await tester.pumpAndSettle();

      expect(find.text('rota: /1.8.7'), findsOneWidget);
    });

    testWidgets(
      'no collection has ever run: both doors still draw, both dimmed — not an error screen',
      (tester) async {
        await _montar(
          tester,
          carregar: () async => const Failure(IndexMissingFailure()),
        );

        expect(_textoNaPorta('pw187', '1.8.7'), findsOneWidget);
        expect(_textoNaPorta('pw126', '1.2.6'), findsOneWidget);
        expect(_contendoNaPorta('pw187', 'em breve'), findsOneWidget);
        expect(_contendoNaPorta('pw126', 'em breve'), findsOneWidget);
        expect(find.textContaining('Não deu para carregar'), findsNothing);
      },
    );

    testWidgets(
      'the file existing and failing to parse is a real error, not a blank screen',
      (tester) async {
        await _montar(
          tester,
          carregar: () async => const Failure(
            IndexUnreadableFailure('(arquivo)', 'json inválido'),
          ),
        );

        expect(_porta('pw187'), findsNothing);
        expect(_porta('pw126'), findsNothing);
        expect(find.textContaining('Não deu para carregar'), findsOneWidget);
      },
    );

    testWidgets('the chooser never fetches either market index', (
      tester,
    ) async {
      final urisPedidas = <Uri>[];
      final client = MockClient((request) async {
        urisPedidas.add(request.url);
        return http.Response(jsonEncode({'pw187': _resumo().toJson()}), 200);
      });

      await _montar(tester, carregar: VersoesRepository(client).carregar);

      expect(urisPedidas, isNotEmpty);
      for (final uri in urisPedidas) {
        expect(uri.path, endsWith('versoes.json'));
        expect(uri.path, isNot(contains('market_index')));
      }
    });

    testWidgets('no number on the doors is drawn in the display face', (
      tester,
    ) async {
      await _montar(
        tester,
        carregar: () async => Success({
          'pw187': _resumo(
            chave: 'pw187',
            nome: '1.8.7',
            personagens: 1715,
            coletadoEm: DateTime.utc(2026, 10, 2),
          ),
        }),
      );

      final nomeDaPorta = tester.widget<Text>(_textoNaPorta('pw187', '1.8.7'));
      expect(
        nomeDaPorta.style?.fontFamily,
        isNot(PWTheme.display),
        reason:
            'Marcellus draws Roman figures: its 1 has no flag and its 0 is '
            'barely an O',
      );

      final contagem = tester.widget<Text>(
        _contendoNaPorta('pw187', 'personagens à venda'),
      );
      expect(contagem.style?.fontFamily, isNot(PWTheme.display));

      final data = tester.widget<Text>(
        _contendoNaPorta('pw187', 'coletado em'),
      );
      expect(data.style?.fontFamily, isNot(PWTheme.display));
    });
  });
}
