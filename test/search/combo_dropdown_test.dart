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
import 'package:pw_market_filter/market/card_combos.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The combo dropdown obeys the rule every other control here obeys: it offers
/// what the market has.
///
/// It used to list the whole hand-written table, so a combo nobody is selling
/// sat in the list reading *0 personagens* — an option whose only possible
/// answer was "nobody". It also made the suite depend on who happened to be
/// advertising: on 2026-09-11 the single owner of *Corona* delisted, and the
/// site stopped publishing for eight hours over it.

const _types = [
  'Destruidor',
  'Batalha',
  'Durabilidade',
  'Alma Primordial',
  'Vida Primordial',
  'Longevidade',
];

/// Six worn cards, of which the first are [combo]'s. The rest are filler, so
/// the character is a legal one: exactly one card of each type.
List<EquippedCard> _wearing(CardCombo combo) {
  final cards = <EquippedCard>[];
  var type = 0;
  for (final id in combo.cardIds) {
    cards.add(_card(id, _types[type++]));
  }
  for (var filler = 90000; type < 6; filler++) {
    cards.add(_card(filler, _types[type++]));
  }
  return cards;
}

EquippedCard _card(int id, String type) => EquippedCard(
  cardId: id,
  name: 'carta $id',
  rarity: 'S',
  type: type,
  level: 80,
  maxLevel: 80,
);

MarketCharacter _character(int roleId, CardCombo combo) => MarketCharacter(
  roleId: roleId,
  name: 'Char$roleId',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  cards: _wearing(combo),
);

/// A market where somebody wears Portal de Nuema and nobody wears Corona.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 11),
  attributes: const [],
  items: const {},
  characters: [_character(1, nuema)],
);

Future<SearchViewModel> _pump(WidgetTester tester, {SearchQuery? query}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  final viewModel = SearchViewModel(IndexRepository(client));
  await viewModel.load();
  if (query != null) viewModel.request(query);

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

  await tester.tap(find.text('CARTAS'));
  await tester.pumpAndSettle();

  return viewModel;
}

void main() {
  testWidgets('a combo nobody wears is not offered', (tester) async {
    await _pump(tester);

    // The label itself is not the hit target — the decoration around it is,
    // and that is what opens the field.
    await tester.tap(find.text('Combo completo'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('Portal de Nuema'), findsWidgets);
    expect(find.text('Corona'), findsNothing);
  });

  testWidgets('the combo already chosen is offered whatever the market says', (
    tester,
  ) async {
    // A link a month old can name a combo this collection has nobody for, and
    // a DropdownButton whose value is absent from its own items throws — the
    // same trap the class list already guards against.
    await _pump(tester, query: const SearchQuery(comboName: 'Corona'));

    expect(find.text('Corona'), findsWidgets);
    expect(tester.takeException(), isNull);

    // The label floats above a filled field, so the field is opened by its own
    // value rather than by the label the other test taps.
    await tester.tap(find.text('Corona').first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
