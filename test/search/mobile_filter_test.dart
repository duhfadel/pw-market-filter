import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/ui/search_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// A phone is where word of mouth lands: somebody pastes the filter's link in
/// the group and it opens on 830 results with the controls hidden behind an
/// icon with no label. Everything here is about that screen admitting it can
/// be narrowed.

MarketCharacter _character(int roleId, String name, int price, int attack) =>
    MarketCharacter(
      roleId: roleId,
      name: name,
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: price,
      fame: 1,
      cultivation: 'Leal',
      equipped: [
        EquippedItem(
          slot: 10,
          itemId: 50206,
          refine: 12,
          stones: const [],
          attributes: {0: attack},
        ),
      ],
    );

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [
    _character(1, 'Leandrim', 300, 70),
    _character(2, 'Solaria', 120, 70),
    _character(3, 'Sabia', 90, 30),
  ],
);

Future<SearchViewModel> _pumpPhone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
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

void main() {
  testWidgets('the phone says the results can be narrowed', (tester) async {
    await _pumpPhone(tester);

    expect(find.text('Filtros'), findsOneWidget);
  });

  testWidgets('the filters open over the results', (tester) async {
    await _pumpPhone(tester);

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();

    expect(find.byType(FilterPanel), findsOneWidget);
  });

  testWidgets('the sheet counts what closing it will show', (tester) async {
    // The count is the whole point of opening the panel here: it turns each
    // criterion into a visible consequence instead of a guess to be checked
    // after closing.
    await _pumpPhone(tester);

    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();

    expect(find.text('Ver 3 personagens'), findsOneWidget);
  });

  testWidgets('the count follows the form while the sheet is open', (
    tester,
  ) async {
    await _pumpPhone(tester);
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '200');
    await tester.pumpAndSettle();

    expect(find.text('Ver 2 personagens'), findsOneWidget);
  });

  testWidgets('the button says how many are being filtered', (tester) async {
    // A criterion in force with nothing on screen saying so makes the results
    // look wrong for no visible reason.
    await _pumpPhone(tester);
    await tester.tap(find.text('Filtros'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), '200');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver 2 personagens'));
    await tester.pumpAndSettle();

    expect(find.text('Filtros · 1'), findsOneWidget);
  });

  testWidgets('one panel exists at a time, and the drawer is gone', (
    tester,
  ) async {
    // The panel used to live in a Drawer that was still there, so a swipe from
    // the edge opened a second copy of the same form beside the sheet.
    await _pumpPhone(tester);

    expect(find.byType(Drawer), findsNothing);
    expect(find.byType(FilterPanel), findsNothing);
  });

  testWidgets('the phone carries a mark it can actually read', (tester) async {
    // The wordmark is a script over an ornate globe and it dies below about
    // 40 px, which is why the bar used to carry nothing at all on a phone.
    // The monogram is the same lettering with the globe taken away.
    await _pumpPhone(tester);

    final marks = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => image.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName);

    expect(marks, contains('assets/images/pw-mark.webp'));
    expect(marks, isNot(contains('assets/images/portal-pw-logo.webp')));
  });
}
