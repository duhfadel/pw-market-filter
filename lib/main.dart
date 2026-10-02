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
import 'features/registros/ui/registros_view.dart';
import 'features/runas/ui/runas_view.dart';
import 'features/search/ui/search_view.dart';
import 'features/search/ui/search_view_model.dart';

void main() {
  configureDependencies();
  runApp(const PortalPWApp());
}

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
          // Both filters share this screen for now. `SearchView` and its
          // matcher are already blind to which marketplace fed the index
          // (proven on 01/10/2026 by serving the 1.2.6 index through it
          // unchanged), and only *which* index to load is version-specific —
          // wiring that up is later work; this route only gives the 1.2.6
          // filter a URL of its own.
          RotaTela(tela: Tela.filtro187, :final query) ||
          RotaTela(
            tela: Tela.filtro126,
            :final query,
          ) => SearchView(arriving: query),
          RotaTela(tela: Tela.registros) => const RegistrosView(),
          RotaTela(tela: Tela.runas) => const RunasView(),
          RotaTela(tela: Tela.novidades) => const NovidadesView(),
          // escolha, home187 and home126 all draw today's home: the choice
          // screen and the 1.2.6 home are later tasks, and until they exist
          // every one of these three names the same front page.
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
