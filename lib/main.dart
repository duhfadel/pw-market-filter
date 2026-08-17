import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/pw_theme.dart';
import 'features/home/ui/home_view.dart';
import 'features/home/ui/visit_counter_view_model.dart';
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
    onGenerateRoute: (settings) {
      // The name carries the query string once a search is being shared, so it
      // cannot be compared to '/filtro' whole — that comparison sent every
      // shared link to the front page.
      final route = Uri.parse(settings.name ?? '/');

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => switch (route.path) {
          '/filtro' => SearchView(arriving: route.queryParametersAll),
          _ => const HomeView(),
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
      ],
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
