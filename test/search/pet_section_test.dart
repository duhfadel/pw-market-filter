import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The pets are a plain filter, and the section only exists where the market
/// has one — a row that can only ever return nothing reads as "the market has
/// none of these" when it means "this collection never saw one".

MarketCharacter _character(
  int roleId,
  String name,
  String characterClass, {
  Map<int, int> counts = const {},
}) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: characterClass,
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  counts: counts,
);

MarketIndex _index({required bool withPets}) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 25),
  attributes: const [],
  items: const {},
  countedItems: withPets ? const {'Harpia': 38587} : const {},
  characters: [
    _character(
      1,
      'Nihal',
      'Feiticeira',
      counts: withPets ? const {38587: 1} : const {},
    ),
    _character(
      2,
      'Leandrim',
      'Guerreiro',
      counts: withPets ? const {38587: 0} : const {},
    ),
  ],
);

Future<SearchViewModel> _pump(
  WidgetTester tester, {
  required bool withPets,
}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(jsonEncode(_index(withPets: withPets).toJson())),
      200,
    ),
  );
  final viewModel = SearchViewModel(IndexRepository(client));
  await viewModel.load();

  await tester.pumpWidget(
    BlocProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: Scaffold(
          body: BlocBuilder<SearchViewModel, SearchState>(
            builder: (context, state) =>
                FilterPanel(state: state as SearchReady, viewModel: viewModel),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return viewModel;
}

void main() {
  testWidgets('ticking a pet narrows the market to whoever has it', (
    tester,
  ) async {
    final viewModel = await _pump(tester, withPets: true);

    await tester.tap(find.text('MASCOTES'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harpia'));
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.pets, {'Harpia'});
    expect(state.results.map((c) => c.name), ['Nihal']);
  });

  testWidgets('the tick counts as a filter in force', (tester) async {
    // Unlike the counted items' mark, which shows a number and narrows
    // nothing, every tick here removes people from the results.
    final viewModel = await _pump(tester, withPets: true);

    viewModel.setPetRequired('Harpia', true);
    await tester.pumpAndSettle();

    expect(find.text('MASCOTES'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('a market with no pets collected grows no section', (
    tester,
  ) async {
    await _pump(tester, withPets: false);

    expect(find.text('MASCOTES'), findsNothing);
  });
}
