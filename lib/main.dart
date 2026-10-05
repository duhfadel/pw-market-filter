import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/rotas.dart';
import 'core/theme/pw_theme.dart';
import 'features/home/ui/home_view.dart';
import 'features/home/ui/ao_vivo_view_model.dart';
import 'features/home/ui/novidades_view_model.dart';
import 'features/home/ui/visit_counter_view_model.dart';
import 'features/novidades/ui/novidades_view.dart';
import 'features/portas/ui/portas_view.dart';
import 'features/registros/ui/registros_view.dart';
import 'features/guias/ui/guerras_view.dart';
import 'features/runas/ui/runas_view.dart';
import 'features/search/ui/search_view.dart';
import 'features/search/ui/search_view_model.dart';
import 'market/index_repository.dart';

void main() {
  configureDependencies();
  runApp(const PortalPWApp());
}

/// Wraps [child] with its own `SearchViewModel`, backed by the 1.2.6 index
/// rather than the ambient 1.8.7 one every other route reads — see
/// `injection.dart` for why the two live under separate GetIt instance names
/// instead of one bare registration shadowing the other.
///
/// Scoped to just the route this builds, not to the whole app: the
/// `MultiBlocProvider` in [PortalPWApp.builder] stays the single 1.8.7
/// `SearchViewModel` above the Navigator, untouched, and this provider only
/// shadows it for the one subtree the 1.2.6 routes build. Two ambient
/// providers of the same type above the whole Navigator would not coexist —
/// the inner one would win for every route, 1.8.7's included.
Widget _comIndicePw126(Widget child) => BlocProvider<SearchViewModel>(
  create: (_) =>
      getIt<SearchViewModel>(instanceName: IndexRepository.pw126)..load(),
  child: child,
);

class PortalPWApp extends StatelessWidget {
  const PortalPWApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Portal PW',
    debugShowCheckedModeBanner: false,
    theme: PWTheme.build(),

    // Routing belongs to MaterialApp, not to a Navigator placed under it. A
    // nested Navigator moves between screens perfectly and never touches the
    // address bar — so the filter would have no link of its own and the
    // browser's back button would leave the site instead of going home.
    //
    // Flutter web's default strategy writes the route after a `#`, which is
    // what GitHub Pages needs: it serves files, so `/filtro` would 404 while
    // `/#/filtro` is the same index.html.
    // A browser arriving at `/#/filtro?preco=-500` overrides this: Flutter
    // takes the platform's route whenever it is not `/`, which is exactly what
    // makes a shared search openable.
    initialRoute: '/',
    // The routing table itself lives in `core/rotas.dart`, as a pure function
    // from a URL to what it means — this closure only turns that answer into
    // widgets. See that file for the full table, including the one path that
    // predates the two marketplaces (`/filtro`) and must redirect forever.
    onGenerateRoute: (settings) {
      final resolvida = resolverRota(settings.name);

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => switch (resolvida) {
          RotaRedirecionada(:final destino) => LegacyRedirect(destino: destino),
          // Both filters share the same `SearchView` screen — `SearchView`
          // and its matcher are already blind to which marketplace fed the
          // index (proven on 01/10/2026 by serving the 1.2.6 index through it
          // unchanged) — but not the same index any more. `filtro126` wraps
          // it in its own `SearchViewModel`, so a 1.2.6 query is never run
          // against the 1.8.7 market behind its back.
          RotaTela(tela: Tela.filtro187, :final query) => SearchView(
            arriving: query,
          ),
          RotaTela(tela: Tela.filtro126, :final query) => _comIndicePw126(
            SearchView(arriving: query),
          ),
          RotaTela(tela: Tela.registros) => const RegistrosView(),
          RotaTela(tela: Tela.runas) => const RunasView(),
          RotaTela(tela: Tela.guerras) => const GuerrasView(),
          RotaTela(tela: Tela.guerras126) => const GuerrasView(versao: pw126),
          RotaTela(tela: Tela.novidades) => const NovidadesView(),
          // The choice screen now exists on its own — `/` no longer opens
          // the 1.8.7 home directly.
          RotaTela(tela: Tela.escolha) => const PortasView(),
          // The 1.2.6 home: the same `HomeView`, `pw126: true`, reading the
          // 1.2.6-backed `SearchViewModel` wrapped around it here rather than
          // the ambient 1.8.7 one every other route below falls through to.
          RotaTela(tela: Tela.home126) => _comIndicePw126(
            const HomeView(pw126: true),
          ),
          RotaTela() => const HomeView(),
        },
      );
    },

    // Both ViewModels sit above every route. The front page shows figures off
    // the same index the filter searches, and `builder` wraps the Navigator,
    // so 1.7 MB is fetched once for the whole site rather than once per
    // screen. The visit counter is here for the same reason inverted: mounted
    // per route it would fire again every time someone came back from the
    // filter, and one arrival is one visit.
    builder: (context, child) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SearchViewModel>()..load()),
        BlocProvider(create: (_) => getIt<VisitCounterViewModel>()..load()),
        // Uma consulta por visita, não uma por tela: a faixa é a mesma em
        // qualquer lugar e o dado muda de cinco em cinco minutos.
        BlocProvider(create: (_) => getIt<AoVivoViewModel>()..load()),
        BlocProvider(create: (_) => getIt<NovidadesViewModel>()..load()),
      ],
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
