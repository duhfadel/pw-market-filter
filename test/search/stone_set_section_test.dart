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
import 'package:pw_market_filter/market/set_stones.dart';

/// A secção das pedras recolhe ao tocar no título.
///
/// **A seta é desenhada pelo `SectionHeader`; recolher é trabalho da
/// secção** — e a primeira versão passou `expanded: true` fixo, portanto
/// desenhou uma seta que não fazia nada. O dono tentou fechar e nada
/// aconteceu. Uma seta que promete um gesto inexistente é pior do que seta
/// nenhuma.
///
/// **Nenhum teste de domínio apanharia isto**: o filtro funcionava, o link
/// funcionava, o chip funcionava. Só um teste que toca no sítio onde uma
/// pessoa toca é que vê.

MarketCharacter _comConjunto(int roleId, String name, int nivel) {
  final equip = setStones.firstWhere(
    (p) => p.kind == StoneKind.attack && p.level == nivel && !p.accessory,
  );
  final acess = setStones.firstWhere(
    (p) => p.kind == StoneKind.attack && p.level >= nivel && p.accessory,
  );
  return MarketCharacter(
    roleId: roleId,
    name: name,
    characterClass: 'Guerreiro',
    occupation: 0,
    level: 105,
    price: 100,
    fame: 1,
    cultivation: 'Leal',
    equipped: [
      for (final slot in setSlots)
        EquippedItem(
          slot: slot,
          itemId: 1000 + slot,
          refine: 0,
          stones: [accessorySlots.contains(slot) ? acess.id : equip.id],
          attributes: const {},
        ),
    ],
  );
}

MarketIndex _index() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 11, 4),
  attributes: const [],
  items: const {},
  countedItems: const {},
  characters: [_comConjunto(1, 'Leandrim', 3), _comConjunto(2, 'Nihal', 1)],
);

Future<SearchViewModel> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index().toJson())), 200),
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
  testWidgets('tocar no título fecha e reabre a secção', (tester) async {
    await _pump(tester);

    expect(find.text('PEDRAS DO SET'), findsOneWidget);
    expect(find.text('Ataque +3'), findsOneWidget);

    await tester.tap(find.text('PEDRAS DO SET'));
    await tester.pumpAndSettle();
    expect(
      find.text('Ataque +3'),
      findsNothing,
      reason: 'tocar no título não fechou a secção',
    );

    await tester.tap(find.text('PEDRAS DO SET'));
    await tester.pumpAndSettle();
    expect(find.text('Ataque +3'), findsOneWidget);
  });

  testWidgets('fechar não desliga o conjunto escolhido', (tester) async {
    // Recolher é sobre o que se vê, nunca sobre o que está em vigor. Se
    // fechar limpasse o filtro, a grelha mudava por trás de um gesto que
    // não promete nada disso.
    final viewModel = await _pump(tester);

    await tester.tap(find.text('Ataque +3'));
    await tester.pumpAndSettle();
    expect((viewModel.state as SearchReady).results.map((c) => c.name), [
      'Leandrim',
    ]);

    await tester.tap(find.text('PEDRAS DO SET'));
    await tester.pumpAndSettle();
    expect((viewModel.state as SearchReady).query.stoneSet, isNotNull);
    expect((viewModel.state as SearchReady).results.map((c) => c.name), [
      'Leandrim',
    ]);
  });
}
