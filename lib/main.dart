import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/pw_theme.dart';
import 'features/home/ui/home_view.dart';
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
    initialRoute: '/',
    onGenerateRoute: (settings) => MaterialPageRoute(
      settings: settings,
      builder: (_) => switch (settings.name) {
        '/filtro' => const SearchView(),
        _ => const HomeView(),
      },
    ),

    // One ViewModel above every route. The front page shows figures off the
    // same index the filter searches, and `builder` wraps the Navigator, so
    // 1.7 MB is fetched once for the whole site rather than once per screen.
    builder: (context, child) => BlocProvider(
      create: (_) => getIt<SearchViewModel>()..load(),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
