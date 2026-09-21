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

/// The slider under a marked relic.
///
/// Marking still narrows nothing — the slider starts at zero, which asks
/// nothing — and the number beside it says what the choice would cost before
/// the choice is made.

const _relic = 'Relíquia Maravilha: Arma';
const _relicId = 50410;

MarketCharacter _character(int roleId, int owned) => MarketCharacter(
  roleId: roleId,
  name: 'Char$roleId',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  counts: {_relicId: owned},
);

/// Twenty characters carrying 0 to 19, so the 95th percentile is 19 and every
/// count in the test is arithmetic anybody can check.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 6),
  attributes: const [],
  items: const {},
  countedItems: const {
    _relic: [_relicId],
  },
  characters: [for (var i = 0; i < 20; i++) _character(i + 1, i)],
);

Future<SearchViewModel> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 2400);
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

  await tester.tap(find.text('RELÍQUIAS E CHAVES'));
  await tester.pumpAndSettle();

  return viewModel;
}

void main() {
  testWidgets('the slider appears only once the relic is marked', (
    tester,
  ) async {
    final viewModel = await _pump(tester);

    expect(find.byType(Slider), findsNothing);

    viewModel.setOwnedShown(_relic, true);
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    // At zero it asks nothing, so marking still only prints a number.
    expect((viewModel.state as SearchReady).results, hasLength(20));
    expect(find.text('qualquer quantidade'), findsOneWidget);
  });

  testWidgets('the slider says what the choice costs, and then costs it', (
    tester,
  ) async {
    final viewModel = await _pump(tester);

    viewModel
      ..setOwnedShown(_relic, true)
      ..setOwnedMinimum(_relic, 10);
    await tester.pumpAndSettle();

    // Ten of the twenty carry ten or more, and the label says so before the
    // results are read.
    expect(find.text('10 ou mais — 10 personagens'), findsOneWidget);
    expect((viewModel.state as SearchReady).results, hasLength(10));
  });

  testWidgets('unmarking takes the minimum with it', (tester) async {
    // Otherwise a filter stays in force with its control gone from the screen,
    // which is the dead end the chips exist to close.
    final viewModel = await _pump(tester);

    viewModel
      ..setOwnedShown(_relic, true)
      ..setOwnedMinimum(_relic, 10)
      ..setOwnedShown(_relic, false);
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.minimumOwned, isEmpty);
    expect(state.results, hasLength(20));
  });

  testWidgets('sliding back to zero stops asking', (tester) async {
    final viewModel = await _pump(tester);

    viewModel
      ..setOwnedShown(_relic, true)
      ..setOwnedMinimum(_relic, 10)
      ..setOwnedMinimum(_relic, 0);
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.minimumOwned, isEmpty);
    expect(state.results, hasLength(20));
  });
}
