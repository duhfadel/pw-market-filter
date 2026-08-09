import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme/pw_theme.dart';
import 'features/search/ui/search_view.dart';
import 'features/search/ui/search_view_model.dart';

void main() {
  configureDependencies();
  runApp(const PWMarketFilterApp());
}

class PWMarketFilterApp extends StatelessWidget {
  const PWMarketFilterApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PW Market Filter',
    debugShowCheckedModeBanner: false,
    theme: PWTheme.build(),
    home: BlocProvider(
      create: (_) => getIt<SearchViewModel>()..load(),
      child: const SearchView(),
    ),
  );
}
