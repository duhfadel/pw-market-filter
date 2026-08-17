import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/home/ui/home_view.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The front page is where a link shared in the community lands. Everything
/// asserted here is about the first five seconds: what the site is, and one
/// way in that does not require reading a card.

MarketCharacter _character({
  required int roleId,
  required String name,
  required int price,
  List<EquippedItem> equipped = const [],
}) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: price,
  fame: 1,
  cultivation: 'Leal',
  equipped: equipped,
);

const _weapon = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [
    _character(roleId: 1, name: 'Leandrim', price: 300, equipped: [_weapon]),
    _character(roleId: 2, name: 'Solaria', price: 120, equipped: [_weapon]),
    _character(roleId: 3, name: 'Sabia', price: 90),
  ],
);

/// Pumps the front page and records every route it asks for.
Future<List<String>> _pumpHome(WidgetTester tester) async {
  final pushed = <String>[];
  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  final viewModel = SearchViewModel(IndexRepository(client));

  await tester.pumpWidget(
    BlocProvider.value(
      value: viewModel..load(),
      child: MaterialApp(
        onGenerateRoute: (settings) {
          final name = settings.name ?? '/';
          if (name != '/') pushed.add(name);
          return MaterialPageRoute(
            builder: (_) =>
                name == '/' ? const HomeView() : const SizedBox.shrink(),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  return pushed;
}

void main() {
  testWidgets('the fold says what the site does, not only its name', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.textContaining('Ache o personagem certo'), findsOneWidget);
    expect(find.text('Buscar personagens'), findsOneWidget);
  });

  testWidgets('the figures are read off the index, never written down', (
    tester,
  ) async {
    await _pumpHome(tester);

    expect(find.text('3'), findsOneWidget); // characters for sale
    expect(find.text('2'), findsOneWidget); // carrying a 70 weapon
    expect(find.text('120 TCC'), findsOneWidget); // the cheaper of those two
  });

  testWidgets('the primary action opens the filter', (tester) async {
    final pushed = await _pumpHome(tester);

    await tester.tap(find.text('Buscar personagens'));
    await tester.pumpAndSettle();

    expect(pushed, ['/filtro']);
  });

  testWidgets('a figure carries its own search into the filter', (
    tester,
  ) async {
    // The proof is the way in. A visitor who reads "2 com arma de 70 de
    // ataque" and taps it should land on those two, not on the whole market
    // with a form to fill in.
    final pushed = await _pumpHome(tester);

    await tester.tap(find.text('com arma de 70 de ataque'));
    await tester.pumpAndSettle();

    expect(pushed, hasLength(1));
    final asked = decodeQuery(Uri.parse(pushed.single).queryParametersAll);
    final criterion = asked.criteria.single;
    expect(criterion.slot, 10);
    expect(criterion.attributeId, 0);
    expect(criterion.minimum, 70);
  });

  testWidgets('the figure counting everybody asks for nothing', (tester) async {
    final pushed = await _pumpHome(tester);

    await tester.tap(find.text('personagens à venda'));
    await tester.pumpAndSettle();

    expect(
      decodeQuery(Uri.parse(pushed.single).queryParametersAll).isEmpty,
      isTrue,
    );
  });
}
