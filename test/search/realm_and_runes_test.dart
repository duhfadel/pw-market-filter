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
import 'package:pw_market_filter/market/celestial_realm.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

MarketCharacter _character(
  int roleId,
  String name, {
  String realm = '',
  String path = '',
  List<int> runes = const [],
}) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Feiticeira',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  realm: realm,
  path: path,
  runes: runes,
);

MarketIndex _index({required bool collected}) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 28),
  attributes: const [],
  items: const {},
  runes: collected
      ? const {
          52183: RuneKind(type: 'Áurea', level: 9),
          52220: RuneKind(type: 'Argêntea', level: 6),
        }
      : const {},
  characters: [
    if (collected) ...[
      _character(
        1,
        'Alta',
        realm: 'Céu Majestoso II',
        path: 'God',
        runes: const [52183, 52183],
      ),
      _character(
        2,
        'Baixa',
        realm: 'Céu Arcano I',
        path: 'Evil',
        runes: const [52220],
      ),
    ] else ...[
      _character(1, 'Alta'),
      _character(2, 'Baixa'),
    ],
  ],
);

Future<SearchViewModel> _pump(
  WidgetTester tester, {
  required bool collected,
}) async {
  tester.view.physicalSize = const Size(1400, 1800);
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
  testWidgets('the realm filter takes everyone from that rung up', (
    tester,
  ) async {
    final viewModel = await _pump(tester, collected: true);

    viewModel.setMinRealm(CelestialRealm.parse('Céu Real I')!.ordinal);
    await tester.pumpAndSettle();

    final state = viewModel.state as SearchReady;
    expect(state.results.map((c) => c.name), ['Alta']);
  });

  testWidgets('the step only appears once a realm is chosen', (tester) async {
    // A step on its own means nothing, and a control that cannot do anything
    // is worse than an absent one.
    final viewModel = await _pump(tester, collected: true);

    await tester.tap(find.text('CÉU'));
    await tester.pumpAndSettle();
    expect(find.text('Degrau'), findsNothing);

    viewModel.setMinRealm(CelestialRealm.parse('Céu Ápice I')!.ordinal);
    await tester.pumpAndSettle();
    expect(find.text('Degrau'), findsOneWidget);
  });

  testWidgets('the path narrows to one side', (tester) async {
    final viewModel = await _pump(tester, collected: true);

    viewModel.setPath('Evil');
    await tester.pumpAndSettle();

    expect((viewModel.state as SearchReady).results.map((c) => c.name), [
      'Baixa',
    ]);
  });

  testWidgets('a rune question counts, and a quantity of none puts it away', (
    tester,
  ) async {
    final viewModel = await _pump(tester, collected: true);

    viewModel.setRunes(const RuneCriterion(minimumLevel: 7, minimum: 2));
    await tester.pumpAndSettle();
    expect((viewModel.state as SearchReady).results.map((c) => c.name), [
      'Alta',
    ]);

    viewModel.setRunes(null);
    await tester.pumpAndSettle();
    final state = viewModel.state as SearchReady;
    expect(state.query.runes, isNull);
    expect(state.results, hasLength(2));
  });

  testWidgets('the colour list only offers what the market has', (
    tester,
  ) async {
    await _pump(tester, collected: true);

    await tester.tap(find.text('RUNAS'));
    await tester.pumpAndSettle();
    // The options only exist once the menu is open; closed, the field shows
    // the chosen value and nothing else.
    await tester.tap(find.text('Qualquer cor'));
    await tester.pumpAndSettle();

    expect(find.text('Áurea'), findsOneWidget);
    expect(find.text('Argêntea'), findsOneWidget);
    expect(find.text('Celeste'), findsNothing);
  });

  testWidgets('an index collected before these fields grows no section', (
    tester,
  ) async {
    await _pump(tester, collected: false);

    expect(find.text('CÉU'), findsNothing);
    expect(find.text('RUNAS'), findsNothing);
  });
}
