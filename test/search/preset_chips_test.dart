import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

const _weapon = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);

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
      equipped: const [_weapon],
    );

/// Nobody here wears a card, so the Nuema chip matches nobody — which is the
/// case worth testing, not the happy one.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [_character(1, 'Leandrim', 300), _character(2, 'Solaria', 120)],
);

Future<SearchViewModel> _pumpFilter(WidgetTester tester) async {
  // Wide enough for four of the five chips to be built. The row scrolls
  // horizontally, and the test font draws every glyph as a square of the font
  // size — "Arma de 70 até 500 TCC" measures 286 px here against roughly 150
  // in a browser — so a chip that is comfortably on screen in the app can be
  // past the edge in a test. Nothing below depends on the fifth.
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  final viewModel = SearchViewModel(IndexRepository(client));

  await tester.pumpWidget(
    BlocProvider.value(
      value: viewModel..load(),
      child: const MaterialApp(home: SearchView()),
    ),
  );
  await tester.pumpAndSettle();

  return viewModel;
}

SearchReady _ready(SearchViewModel viewModel) => viewModel.state as SearchReady;

void main() {
  testWidgets('the ready-made searches are offered before anything is asked', (
    tester,
  ) async {
    await _pumpFilter(tester);

    expect(find.text('Arma de 70 de ataque'), findsOneWidget);
    expect(find.text('Portal de Nuema'), findsOneWidget);
  });

  testWidgets('tapping one asks its whole search', (tester) async {
    final viewModel = await _pumpFilter(tester);

    await tester.tap(find.text('Arma de 70 até 500 TCC'));
    await tester.pumpAndSettle();

    expect(_ready(viewModel).query.maxPrice, 500);
    expect(_ready(viewModel).query.criteria.single.minimum, 70);
  });

  testWidgets('tapping the active one puts the market back', (tester) async {
    // Every chip has to be its own way out. A control that can only be
    // switched on is a dead end on a screen whose whole job is narrowing.
    final viewModel = await _pumpFilter(tester);

    await tester.tap(find.text('Arma de 70 de ataque'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Arma de 70 de ataque'));
    await tester.pumpAndSettle();

    expect(_ready(viewModel).query.isEmpty, isTrue);
    expect(_ready(viewModel).results, hasLength(2));
  });

  testWidgets('one chip replaces another rather than stacking on it', (
    tester,
  ) async {
    // Two presets at once produce a combination nobody asked for, with no way
    // to see which of the two emptied the screen.
    final viewModel = await _pumpFilter(tester);

    await tester.tap(find.text('Arma de 70 até 500 TCC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seis cartas S'));
    await tester.pumpAndSettle();

    expect(_ready(viewModel).query.cardRarity, 'S');
    expect(_ready(viewModel).query.criteria, isEmpty);
    expect(_ready(viewModel).query.maxPrice, isNull);
  });

  testWidgets('the chips survive a search that finds nobody', (tester) async {
    // The chip that emptied the screen is the one that has to be on it. Hidden
    // along with the results, the only way back would be the browser's back
    // button.
    final viewModel = await _pumpFilter(tester);

    await tester.tap(find.text('Portal de Nuema'));
    await tester.pumpAndSettle();

    expect(_ready(viewModel).results, isEmpty);
    expect(find.text('Portal de Nuema'), findsOneWidget);
  });
}
