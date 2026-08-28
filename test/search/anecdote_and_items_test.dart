import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The two filters that came from outside: the anecdote progress and the
/// counted items.
///
/// They are two sections and not one because they are two kinds of fact — one
/// is what the character owns, the other is time he spent. What is worth a
/// widget test is the rule that decides whether either appears at all: a field
/// for an item the market has none of can only ever return nothing, and an
/// index collected before the fields existed must not grow a section that
/// refuses everybody.

const _relic = 'Relíquia Maravilha: Arma';

MarketCharacter _character(
  int roleId,
  String name, {
  Anecdotes? anecdotes,
  Map<int, int> counts = const {},
}) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  anecdotes: anecdotes,
  counts: counts,
);

MarketIndex _index({required bool collected}) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 19),
  attributes: const [],
  items: const {},
  countedItems: collected ? const {_relic: 50410} : const {},
  characters: [
    if (collected) ...[
      _character(
        1,
        'Leandrim',
        anecdotes: const Anecdotes(done: 1265, total: 2756),
        counts: const {50410: 16},
      ),
      _character(
        2,
        'Novato',
        anecdotes: const Anecdotes(done: 40, total: 2756),
      ),
    ] else ...[
      _character(1, 'Leandrim'),
      _character(2, 'Novato'),
    ],
  ],
);

Future<SearchViewModel> _pump(
  WidgetTester tester, {
  required bool collected,
}) async {
  tester.view.physicalSize = const Size(1400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(jsonEncode(_index(collected: collected).toJson())),
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
  testWidgets('each section is closed, and opens onto its own filter', (
    tester,
  ) async {
    await _pump(tester, collected: true);

    expect(find.text('Anedotas a partir de'), findsNothing);
    expect(find.text(_relic), findsNothing);

    await tester.tap(find.text('ANEDOTAS'));
    await tester.pumpAndSettle();
    expect(find.text('Mostrar no card'), findsOneWidget);
    // The minimum is behind the mark, as it is for a counted item.
    expect(find.text('Anedotas a partir de'), findsNothing);
    expect(find.text(_relic), findsNothing);

    await tester.tap(find.text('RELÍQUIAS E CHAVES'));
    await tester.pumpAndSettle();
    expect(find.text(_relic), findsOneWidget);
  });

  testWidgets('typing a minimum narrows the results', (tester) async {
    final viewModel = await _pump(tester, collected: true);

    await tester.tap(find.text('ANEDOTAS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar no card'));
    await tester.pumpAndSettle();
    // By its label, not by position: the panel has the price fields above it.
    await tester.enterText(
      find.ancestor(
        of: find.text('Anedotas a partir de'),
        matching: find.byType(TextField),
      ),
      '1000',
    );
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.minAnecdotes, 1000);
    expect(state.results.map((c) => c.name), ['Leandrim']);
  });

  testWidgets('a closed section still says how much it is marking', (
    tester,
  ) async {
    // Nothing here filters any more, so the badge counts what is being shown.
    final viewModel = await _pump(tester, collected: true);

    viewModel.setOwnedShown(_relic, true);
    await tester.pumpAndSettle();

    expect(find.text('RELÍQUIAS E CHAVES'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('marking the anecdotes shows them without filtering', (
    tester,
  ) async {
    final viewModel = await _pump(tester, collected: true);

    await tester.tap(find.text('ANEDOTAS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mostrar no card'));
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.showsAnecdotes, isTrue);
    expect(state.query.isEmpty, isTrue);
    expect(state.results, hasLength(2));
  });

  testWidgets('unmarking the anecdotes undoes what was forcing the line', (
    tester,
  ) async {
    // Otherwise the box comes unticked with the number still on the cards.
    final viewModel = await _pump(tester, collected: true);

    viewModel
      ..setMinAnecdotes(100)
      ..setOrder(ResultOrder.mostAnecdotes);
    await tester.pumpAndSettle();

    viewModel.setAnecdotesShown(false);
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.query.showsAnecdotes, isFalse);
    expect(state.query.minAnecdotes, isNull);
    expect(state.query.order, ResultOrder.cheapest);
  });

  testWidgets('unmarking the last relic gives up ordering by relics', (
    tester,
  ) async {
    // The order would otherwise sort by a number that is the same for
    // everybody, which reads as a broken list.
    final viewModel = await _pump(tester, collected: true);

    viewModel
      ..setOwnedShown(_relic, true)
      ..setOrder(ResultOrder.mostOwned);
    await tester.pumpAndSettle();
    expect((viewModel.state as SearchReady).query.order, ResultOrder.mostOwned);

    viewModel.setOwnedShown(_relic, false);
    await tester.pumpAndSettle();
    expect((viewModel.state as SearchReady).query.order, ResultOrder.cheapest);
  });

  testWidgets('an index collected before the fields grows no section', (
    tester,
  ) async {
    // Offering the filters over a collection that carries neither would
    // return zero for everything, which reads as a broken market rather than
    // an old index.
    await _pump(tester, collected: false);

    expect(find.text('ANEDOTAS'), findsNothing);
    expect(find.text('RELÍQUIAS E CHAVES'), findsNothing);
  });
}
