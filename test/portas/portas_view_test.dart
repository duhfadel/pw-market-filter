import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/di/injection.dart';
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

/// Every request the fake `versoes.json` endpoint received, so a test can
/// assert what was asked for without caring what answered it.
final _urisPedidas = <Uri>[];

/// Registers `VersoesRepository` in the real `GetIt` instance,
/// `configureDependencies()` never does for the suite, backed by [client] —
/// a network double, never the real one. This is what makes the mount below
/// exercise `getIt<VersoesRepository>().carregar` in
/// `_PortasViewState._carregar`, the only branch production ever runs: before
/// this test registered anything here, every case constructed `PortasView`
/// with its own `carregar:` override, so the `getIt` lookup — unregistered in
/// `injection.dart` — was never once reached, and the `StateError` it threw
/// was silently absorbed by the `unawaited(...)` call in `initState`, leaving
/// the real `/` spinning forever with a green suite on top of it.
void _registrarRepositorio(http.Client client) {
  getIt.registerLazySingleton<VersoesRepository>(
    () => VersoesRepository(client),
  );
}

MockClient _cliente(http.Response Function(http.Request) responder) =>
    MockClient((request) async {
      _urisPedidas.add(request.url);
      return responder(request);
    });

http.Response _corpo(Object json, [int status = 200]) =>
    http.Response(jsonEncode(json), status);

Future<void> _montar(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      onGenerateRoute: (settings) => MaterialPageRoute(
        settings: settings,
        builder: (_) =>
            comNovidades(Scaffold(body: Text('rota: ${settings.name}'))),
      ),
      // No `carregar:` override anywhere in this file — `PortasView` has none
      // any more. Every case below reaches `web/versoes.json` only through
      // `getIt<VersoesRepository>()`, registered per-test above.
      home: comNovidades(const PortasView()),
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

  setUp(() {
    _urisPedidas.clear();
  });

  tearDown(() async {
    await getIt.reset();
  });

  group('as duas portas', () {
    testWidgets('both versions collected: both doors show their own facts', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente(
          (_) => _corpo({
            'pw187': _resumo(
              chave: 'pw187',
              nome: '1.8.7',
              personagens: 1715,
              coletadoEm: DateTime.utc(2026, 10, 2, 7, 30),
            ).toJson(),
            'pw126': _resumo(
              chave: 'pw126',
              nome: '1.2.6',
              personagens: 1293,
              coletadoEm: DateTime.utc(2026, 10, 1, 18, 19),
            ).toJson(),
          }),
        ),
      );

      await _montar(tester);

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
        _registrarRepositorio(
          _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
        );

        await _montar(tester);

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

    testWidgets(
      "an unready door's art dims with it — never a bright picture over a "
      'greyed-out door',
      (tester) async {
        _registrarRepositorio(
          _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
        );

        await _montar(tester);

        // The class art for the dimmed pw126 door is a descendant of its own
        // `Opacity` (0.5, asserted above by another case) rather than a
        // sibling painted outside it — the only arrangement that actually
        // dims the picture along with the rest of the door.
        final arteFechada = find.descendant(
          of: _porta('pw126'),
          matching: find.byType(Image),
        );
        expect(arteFechada, findsOneWidget);

        final opacidadeFechada = tester.widget<Opacity>(_porta('pw126'));
        expect(opacidadeFechada.opacity, 0.5);

        // The ready door carries its own art too, at full strength.
        final arteAberta = find.descendant(
          of: _porta('pw187'),
          matching: find.byType(Image),
        );
        expect(arteAberta, findsOneWidget);
      },
    );

    testWidgets("tapping a ready door opens that version's home", (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      await _montar(tester);

      await tester.tap(_porta('pw187'));
      await tester.pumpAndSettle();

      expect(find.text('rota: /1.8.7'), findsOneWidget);
    });

    testWidgets(
      'no collection has ever run: both doors still draw, both dimmed — not an error screen',
      (tester) async {
        _registrarRepositorio(_cliente((_) => http.Response('', 404)));

        await _montar(tester);

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
        _registrarRepositorio(
          _cliente((_) => http.Response('não é json', 200)),
        );

        await _montar(tester);

        expect(_porta('pw187'), findsNothing);
        expect(_porta('pw126'), findsNothing);
        expect(find.textContaining('Não deu para carregar'), findsOneWidget);
      },
    );

    testWidgets(
      'the registration missing from GetIt is a real error too, never an '
      'eternal spinner',
      (tester) async {
        // No `_registrarRepositorio` call at all — the exact shape of B1:
        // `getIt<VersoesRepository>()` throws `StateError` because nothing
        // registered it. Before the `try`/`catch` in `_carregar`, that throw
        // escaped the `unawaited` call in `initState` unseen, `setState` was
        // never reached, and the screen stayed in `_Carregando` forever.
        await _montar(tester);

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Não deu para carregar'), findsOneWidget);
      },
    );

    testWidgets('the chooser never fetches either market index', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente((_) => _corpo({'pw187': _resumo().toJson()})),
      );

      await _montar(tester);

      expect(_urisPedidas, isNotEmpty);
      for (final uri in _urisPedidas) {
        expect(uri.path, endsWith('versoes.json'));
        expect(uri.path, isNot(contains('market_index')));
      }
    });

    testWidgets('no number on the doors is drawn in the display face', (
      tester,
    ) async {
      _registrarRepositorio(
        _cliente(
          (_) => _corpo({
            'pw187': _resumo(
              chave: 'pw187',
              nome: '1.8.7',
              personagens: 1715,
              coletadoEm: DateTime.utc(2026, 10, 2),
            ).toJson(),
          }),
        ),
      );

      await _montar(tester);

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
