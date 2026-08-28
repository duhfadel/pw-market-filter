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

/// The dead end, and the way out of it.
///
/// Every control reads its options from the characters that pass every *other*
/// filter — which is what makes the form answer back, and which at zero
/// results leaves every list empty. The sections then collapse, taking with
/// them the controls of filters that are still in force.
const weaponSlot = 10;

MarketCharacter _character(int roleId, String name, int price) =>
    MarketCharacter(
      roleId: roleId,
      name: name,
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: price,
      fame: 1,
      cultivation: 'Leal',
      equipped: const [
        EquippedItem(
          slot: weaponSlot,
          itemId: 50206,
          refine: 12,
          stones: [],
          attributes: {0: 70},
        ),
      ],
    );

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 28),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [_character(1, 'Leandrim', 1000), _character(2, 'Bruto', 900)],
);

Future<SearchViewModel> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
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
  testWidgets('a weapon still filtering has a way out when its list empties', (
    tester,
  ) async {
    final viewModel = await _pump(tester);

    // The weapon everybody wears, plus a price nobody meets.
    viewModel.setItemInSlot(weaponSlot, 50206);
    viewModel.setPriceRange(1, 5);
    await tester.pumpAndSettle();

    expect((viewModel.state as SearchReady).results, isEmpty);

    // The chip is drawn from the query, so it is there whatever the market
    // says — and tapping it removes only the weapon.
    await tester.tap(find.text('★★★Dilacerador Raivoso'));
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.itemBySlot, isEmpty);
    expect(state.query.minPrice, 1, reason: 'o preço não podia ir junto');
  });

  testWidgets('with nothing asked there is no chip row at all', (tester) async {
    await _pump(tester);

    expect(find.text('limpar tudo'), findsNothing);
    expect(find.textContaining('FILTRO'), findsNothing);
  });

  testWidgets('the row counts what is in force', (tester) async {
    final viewModel = await _pump(tester);

    viewModel.setPriceRange(100, 500);
    await tester.pumpAndSettle();
    expect(find.text('1 FILTRO'), findsOneWidget);

    viewModel.setClass('Guerreiro');
    await tester.pumpAndSettle();
    expect(find.text('2 FILTROS'), findsOneWidget);
  });

  testWidgets('changing class keeps a weapon that class does wear', (
    tester,
  ) async {
    // The question is about the game, not about the current results: a price
    // range that excludes every Guerreiro wearing the weapon used to make the
    // empty answer read as "Guerreiro does not wear it".
    final viewModel = await _pump(tester);

    viewModel.setItemInSlot(weaponSlot, 50206);
    viewModel.setPriceRange(1, 5);
    await tester.pumpAndSettle();

    viewModel.setClass('Guerreiro');
    await tester.pumpAndSettle();

    expect(
      (viewModel.state as SearchReady).query.itemBySlot,
      {weaponSlot: 50206},
    );
  });
}
