import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/card_combos.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Os chips de renascimento, no sítio onde uma pessoa toca.
///
/// O domínio está cravado em `combo_rebirth_test`, contra páginas reais. Isto
/// é a outra metade, e a secção das pedras é a razão de ela existir: lá o
/// filtro, o link e o chip estavam todos certos, e a seta não fechava nada —
/// nenhum teste de domínio veria.

final _nuema = cardCombos.singleWhere((c) => c.name == 'Portal de Nuema');
final _soberanos = cardCombos.singleWhere(
  (c) => c.name == 'Seis Soberanos da Chama da Vela',
);

MarketCharacter _comCombo(
  int roleId,
  String name,
  CardCombo combo,
  List<int> renascimentos,
) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Guerreiro',
  occupation: 0,
  level: 105,
  price: 100 + roleId,
  fame: 1,
  cultivation: 'Leal',
  equipped: const [],
  cards: [
    for (final (i, id) in combo.cardIds.indexed)
      EquippedCard(
        cardId: id,
        name: 'carta $i',
        rarity: combo.rarity,
        type: 'tipo $i',
        level: 80,
        maxLevel: 80,
        rebirths: renascimentos[i],
      ),
  ],
);

MarketIndex _index() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 11, 5),
  attributes: const [],
  items: const {},
  characters: [
    _comCombo(1, 'Full2', _nuema, const [2, 2, 2, 2, 2, 2]),
    _comCombo(2, 'Misto', _nuema, const [2, 2, 1, 2, 2, 1]),
    _comCombo(3, 'Normal', _nuema, const [0, 0, 0, 0, 1, 0]),
    // Um segundo combo, sem renascimento nenhum: é o que prova que os chips
    // contam dentro do combo escolhido e não no mercado todo.
    _comCombo(4, 'Outro', _soberanos, const [0, 0, 0, 0, 0, 0]),
  ],
);

Future<SearchViewModel> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1400, 3000);
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

SearchReady _ready(SearchViewModel vm) => vm.state as SearchReady;

void main() {
  testWidgets('os chips só aparecem com um combo escolhido', (tester) async {
    // Sem conjunto nomeado a pergunta não existe: as seis cartas de alguém
    // podem não formar combo nenhum, e «renascidas 2» não diria de quê.
    final viewModel = await _pump(tester);

    await tester.tap(find.text('CARTAS'));
    await tester.pumpAndSettle();
    expect(find.text('Renascidas 1+'), findsNothing);

    viewModel.setCombo('Portal de Nuema');
    await tester.pumpAndSettle();
    expect(find.text('Renascidas 1+'), findsOneWidget);
    expect(find.text('Renascidas 2+'), findsOneWidget);
    expect(find.text('Sem exigir'), findsOneWidget);
  });

  testWidgets('tocar num chip filtra pela pior carta das seis', (tester) async {
    final viewModel = await _pump(tester);
    viewModel.setCombo('Portal de Nuema');
    await tester.tap(find.text('CARTAS'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Renascidas 1+'));
    await tester.pumpAndSettle();
    expect(_ready(viewModel).query.comboMinRebirth, 1);
    expect(_ready(viewModel).results.map((c) => c.name), ['Full2', 'Misto']);

    await tester.tap(find.text('Renascidas 2+'));
    await tester.pumpAndSettle();
    expect(_ready(viewModel).results.map((c) => c.name), ['Full2']);
  });

  testWidgets('um nível que ninguém tem fica apagado, nunca ausente', (
    tester,
  ) async {
    // Ausência lê-se como erro, e aqui pesa mais do que nas pedras: até à
    // recolha que trouxe o campo, nenhum personagem tem renascimento nenhum,
    // portanto todos os chips nascem apagados e o painel tem de se explicar
    // em vez de ficar vazio.
    final viewModel = await _pump(tester);
    viewModel.setCombo('Seis Soberanos da Chama da Vela');
    await tester.tap(find.text('CARTAS'));
    await tester.pumpAndSettle();

    expect(find.text('Renascidas 1+'), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(
      find.ancestor(
        of: find.text('Renascidas 1+'),
        matching: find.byType(ChoiceChip),
      ),
    );
    expect(chip.onSelected, isNull, reason: 'devia estar apagado');
  });

  testWidgets('trocar de combo leva o renascimento com ele', (tester) async {
    // «Renascidas 2» era uma afirmação sobre o Nuema, não sobre o conjunto
    // seguinte. Deixá-la em vigor filtraria por um pedido que ninguém fez.
    final viewModel = await _pump(tester);
    viewModel.setCombo('Portal de Nuema');
    viewModel.setComboMinRebirth(2);
    await tester.pumpAndSettle();
    expect(_ready(viewModel).query.comboMinRebirth, 2);

    viewModel.setCombo('Seis Soberanos da Chama da Vela');
    await tester.pumpAndSettle();
    expect(_ready(viewModel).query.comboMinRebirth, isNull);
  });
}
