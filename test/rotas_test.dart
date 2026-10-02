import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/rotas.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';
import 'package:pw_market_filter/features/search/data/address_bar.dart';

/// Records every push and replace a `Navigator` makes, so a test can tell
/// "landed somewhere new" apart from "stacked on top of what was already
/// there" — the distinction `pushReplacementNamed` exists for, and the one a
/// screenshot cannot show.
class _RecordingObserver extends NavigatorObserver {
  final List<String> pushedNames = [];
  final List<String> replacedNames = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name ?? '');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedNames.add(newRoute?.settings.name ?? '');
  }
}

/// Builds the same `onGenerateRoute` shape `main.dart` wires up, with the
/// routing decision itself reused from `rotas.dart` rather than duplicated —
/// the one thing every screen draws is a marker widget naming the [Tela] it
/// resolved to, which is all a routing test needs to see.
Widget _appPara(String rota, {List<NavigatorObserver> observers = const []}) {
  return MaterialApp(
    navigatorObservers: observers,
    initialRoute: rota,
    onGenerateRoute: (settings) {
      final resolvida = resolverRota(settings.name);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => switch (resolvida) {
          RotaRedirecionada(:final destino) => LegacyRedirect(destino: destino),
          RotaTela(:final tela) => Text(tela.name),
        },
      );
    },
  );
}

void main() {
  group('resolverRota — one row per line of the table', () {
    test('/ is the choice between the two marketplaces', () {
      final resolvida = resolverRota('/');
      expect(resolvida, isA<RotaTela>());
      expect((resolvida as RotaTela).tela, Tela.escolha);
    });

    test('/1.8.7 is the 1.8.7 home', () {
      final resolvida = resolverRota('/1.8.7');
      expect((resolvida as RotaTela).tela, Tela.home187);
    });

    test('/1.8.7/filtro is the canonical 1.8.7 filter', () {
      final resolvida = resolverRota('/1.8.7/filtro');
      expect((resolvida as RotaTela).tela, Tela.filtro187);
    });

    test('/filtro, with a search, redirects — never a RotaTela', () {
      final resolvida = resolverRota('/filtro?c=10~0~70');
      expect(resolvida, isA<RotaRedirecionada>());
    });

    test('/1.8.7/registros is Títulos', () {
      final resolvida = resolverRota('/1.8.7/registros');
      expect((resolvida as RotaTela).tela, Tela.registros);
    });

    test('/1.8.7/runas is Runas', () {
      final resolvida = resolverRota('/1.8.7/runas');
      expect((resolvida as RotaTela).tela, Tela.runas);
    });

    test('/1.2.6 is the 1.2.6 home', () {
      final resolvida = resolverRota('/1.2.6');
      expect((resolvida as RotaTela).tela, Tela.home126);
    });

    test('/1.2.6/filtro is the 1.2.6 filter', () {
      final resolvida = resolverRota('/1.2.6/filtro');
      expect((resolvida as RotaTela).tela, Tela.filtro126);
    });

    test('/novidades is unprefixed and shared by both versions', () {
      final resolvida = resolverRota('/novidades');
      expect((resolvida as RotaTela).tela, Tela.novidades);
    });
  });

  group('the legacy /filtro redirect — the whole risk of this task', () {
    test('a bare /filtro, with no search, still redirects', () {
      final resolvida = resolverRota('/filtro') as RotaRedirecionada;
      expect(resolvida.destino, '/1.8.7/filtro');
    });

    test('/filtro?c=10~0~70 reaches /1.8.7/filtro with the search intact', () {
      final resolvida =
          resolverRota('/filtro?c=10~0~70&ordem=caro') as RotaRedirecionada;
      final destino = Uri.parse(resolvida.destino);

      expect(destino.path, '/1.8.7/filtro');
      expect(destino.queryParameters['c'], '10~0~70');
      expect(destino.queryParameters['ordem'], 'caro');
    });

    test('a link with several criteria keeps every one of them', () {
      // search_query_url.dart repeats the `c` key once per criterion — a
      // redirect that only carried the first would quietly drop a search
      // down to one condition.
      final resolvida =
          resolverRota('/filtro?c=10~0~70&c=5~0~40') as RotaRedirecionada;
      final destino = Uri.parse(resolvida.destino);

      expect(destino.queryParametersAll['c'], ['10~0~70', '5~0~40']);
    });
  });

  group('one canonical writer, one permanent reader — never the reverse', () {
    // `/filtro` must keep resolving forever (the group above), but nothing in
    // the app may *produce* that path any more: every place that builds a
    // destination for the filter — the address bar, the "copiar link"
    // control, and the menu's own tool entry — has to write the canonical
    // `/1.8.7/filtro` from the day this shipped onward. A regression here is
    // silent on screen: the redirect absorbs a wrongly-written `/filtro`
    // link just as well as an old one, so nothing looks broken — the only
    // thing that happens is the legacy path never gets to retire.
    test('AddressBar writes the canonical path, not the bare one', () {
      expect(AddressBar.canonicalFiltro, '/$pw187/filtro');
      expect(AddressBar.uriFor('classe=Mago').path, '/1.8.7/filtro');
    });

    test('AddressBar.linkTo shares a search at the canonical path', () {
      final link = AddressBar.linkTo(
        Uri.parse('https://portalpw.net/'),
        'classe=Mago',
      );

      expect(link, 'https://portalpw.net/#/1.8.7/filtro?classe=Mago');
    });

    test('a link with no search still points at the canonical path', () {
      final link = AddressBar.linkTo(Uri.parse('https://portalpw.net/'), '');

      expect(link, 'https://portalpw.net/#/1.8.7/filtro');
    });

    test("the menu's own Filtro tool writes the canonical path", () {
      final filtro = tools.firstWhere((t) => t.name == 'Filtro do Marketplace');

      expect(filtro.route, AddressBar.canonicalFiltro);
    });

    test('what the app writes is exactly what resolverRota already treats '
        'as canonical — no redirect in the loop', () {
      final resolvida = resolverRota(AddressBar.canonicalFiltro);

      expect(resolvida, isA<RotaTela>());
      expect((resolvida as RotaTela).tela, Tela.filtro187);
    });

    test('a bare /filtro still resolves — the permanent half of the pair', () {
      expect(resolverRota('/filtro'), isA<RotaRedirecionada>());
    });
  });

  group('/registros and /runas keep working bare', () {
    // Both were already linked from the front page before this file existed
    // — see CLAUDE.md, "`/registros` tem um card na página inicial" — and
    // growing a second marketplace may not 404 a link that already works.
    test('/registros, with no prefix, still opens Títulos', () {
      expect((resolverRota('/registros') as RotaTela).tela, Tela.registros);
    });

    test('/runas, with no prefix, still opens Runas', () {
      expect((resolverRota('/runas') as RotaTela).tela, Tela.runas);
    });
  });

  group('an unknown path falls back rather than throwing', () {
    test('an unknown top-level path falls back to the choice', () {
      expect((resolverRota('/nada-aqui') as RotaTela).tela, Tela.escolha);
    });

    test('an unknown screen under a known version falls back to its home', () {
      expect((resolverRota('/1.8.7/nada-aqui') as RotaTela).tela, Tela.home187);
      expect((resolverRota('/1.2.6/nada-aqui') as RotaTela).tela, Tela.home126);
    });
  });

  group('LegacyRedirect — proven against a real Navigator', () {
    testWidgets(
      'navigating to /filtro?... lands on /1.8.7/filtro with the search '
      'intact',
      (tester) async {
        await tester.pumpWidget(_appPara('/filtro?c=10~0~70'));
        await tester.pumpAndSettle();

        expect(find.text('filtro187'), findsOneWidget);
      },
    );

    testWidgets('the redirect replaces history rather than stacking on it', (
      tester,
    ) async {
      final observer = _RecordingObserver();
      await tester.pumpWidget(
        _appPara('/filtro?c=10~0~70', observers: [observer]),
      );
      await tester.pumpAndSettle();

      // `MaterialApp` pushes a synthetic `/` ahead of a deep link on its own,
      // to keep a proper back stack — the same thing `menu_everywhere_test`
      // notes for `/novidades`. What matters here is what comes after: the
      // legacy route is pushed once, and the redirect is a **replace**, never
      // a second push — a stacking bug would show up as a second push
      // instead, which is exactly what traps the back button in a loop.
      expect(observer.pushedNames, ['/', '/filtro?c=10~0~70']);
      expect(observer.replacedNames, ['/1.8.7/filtro?c=10~0~70']);

      // One entry below the redirect's target — the synthetic `/` — and
      // nothing else: the old `/filtro?...` entry was replaced, not kept
      // underneath as a second step back into the loop.
      final context = tester.element(find.text('filtro187'));
      expect(Navigator.of(context).canPop(), isTrue);
    });
  });
}
