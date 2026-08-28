import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

const attackLevel = 0;
const weaponSlot = 10;

EquippedItem _weapon(int itemId, int attack) => EquippedItem(
  slot: weaponSlot,
  itemId: itemId,
  refine: 0,
  stones: const [],
  attributes: {attackLevel: attack},
);

MarketCharacter _character(
  String name,
  String characterClass,
  List<EquippedItem> equipped,
) => MarketCharacter(
  roleId: name.hashCode.abs(),
  name: name,
  characterClass: characterClass,
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
  equipped: equipped,
);

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {
    50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
    60101: MarketItem(name: '★★★Cajado do Vazio', grade: 6),
  },
  characters: [
    _character('Leandrim', 'Guerreiro', [_weapon(50206, 70)]),
    _character('Sabia', 'Mago', [_weapon(60101, 70)]),
  ],
);

/// Answers the index request with whatever the test wants, or a 404 when the
/// collector has never run.
http.Client _serving(String? contents) => MockClient((request) async {
  if (contents == null) return http.Response('', 404);
  return http.Response.bytes(utf8.encode(contents), 200);
});

SearchViewModel _viewModelFor(String? contents) =>
    SearchViewModel(IndexRepository(_serving(contents)));

void main() {
  test('a missing index is first use, not a failure', () async {
    final viewModel = _viewModelFor(null);

    await viewModel.load();

    expect(viewModel.state, isA<SearchNoIndex>());
  });

  test('an index it cannot read names the field that broke', () async {
    final viewModel = _viewModelFor('{"formatVersion": 1, "server": 7}');

    await viewModel.load();

    expect(
      viewModel.state,
      isA<SearchUnreadable>().having((s) => s.field, 'field', 'server'),
    );
  });

  test('a readable index starts with everybody showing', () async {
    final viewModel = _viewModelFor(jsonEncode(_index.toJson()));

    await viewModel.load();

    expect((viewModel.state as SearchReady).results, hasLength(2));
  });

  group('once loaded', () {
    late SearchViewModel viewModel;

    setUp(() async {
      viewModel = _viewModelFor(jsonEncode(_index.toJson()));
      await viewModel.load();
    });

    test('choosing a class narrows the results', () {
      viewModel.setClass('Mago');

      final state = viewModel.state as SearchReady;
      expect(state.results.map((c) => c.name), ['Sabia']);
    });

    test('choosing a weapon narrows to whoever wears exactly it', () {
      viewModel.setItemInSlot(weaponSlot, 50206);

      final state = viewModel.state as SearchReady;
      expect(state.results.map((c) => c.name), ['Leandrim']);
    });

    test('changing class drops a weapon that class never wears', () {
      // Without this the screen shows Guerreiro plus a Mago weapon: zero
      // results, and nothing saying the two cannot go together.
      viewModel.setItemInSlot(weaponSlot, 60101);
      viewModel.setClass('Guerreiro');

      final state = viewModel.state as SearchReady;
      expect(state.query.itemBySlot, isEmpty);
      expect(state.results.map((c) => c.name), ['Leandrim']);
    });

    test('changing class keeps a weapon that class does wear', () {
      viewModel.setItemInSlot(weaponSlot, 60101);
      viewModel.setClass('Mago');

      final state = viewModel.state as SearchReady;
      expect(state.query.itemBySlot, {weaponSlot: 60101});
      expect(state.results.map((c) => c.name), ['Sabia']);
    });

    test('clearing the class keeps the weapon, which is still valid', () {
      viewModel.setItemInSlot(weaponSlot, 60101);
      viewModel.setClass('Mago');
      viewModel.setClass(null);

      final state = viewModel.state as SearchReady;
      expect(state.query.itemBySlot, {weaponSlot: 60101});
    });

    test('results arrive cheapest first without being asked', () {
      final state = viewModel.state as SearchReady;

      expect(state.query.order, ResultOrder.cheapest);
    });

    test('clearing keeps the ordering, which was never a filter', () {
      viewModel
        ..setOrder(ResultOrder.highestFame)
        ..setClass('Mago')
        ..clear();

      final state = viewModel.state as SearchReady;
      expect(state.query.isEmpty, isTrue);
      expect(state.query.order, ResultOrder.highestFame);
    });

    test('clearing everything empties the query and shows everybody', () {
      viewModel
        ..setClass('Mago')
        ..setItemInSlot(weaponSlot, 60101)
        ..clear();

      final state = viewModel.state as SearchReady;
      expect(state.query.isEmpty, isTrue);
      expect(state.results, hasLength(2));
    });

    test('a minimum of anecdotes goes into the query', () {
      viewModel.setMinAnecdotes(500);

      expect((viewModel.state as SearchReady).query.minAnecdotes, 500);
    });

    test('marking an item shows it without filtering anybody out', () {
      // The whole point of the mark: "how many does each of them carry" is a
      // question you can ask of the market without narrowing it first.
      viewModel.setOwnedShown('Relíquia Maravilha: Arma', true);

      final state = viewModel.state as SearchReady;
      expect(state.query.shownOwned, {'Relíquia Maravilha: Arma'});
      expect(state.query.isEmpty, isTrue);
      expect(state.results, hasLength(2));
    });

    test('a link ordering by relics with nothing marked still opens', () {
      // A `DropdownButton` throws when its value is absent from its items, and
      // a month-old link is how that happens. The order survives; it is the
      // picker that has to keep offering it.
      viewModel.requestUrl({
        'ordem': ['mostOwned'],
      });

      final state = viewModel.state as SearchReady;
      expect(state.query.order, ResultOrder.mostOwned);
      expect(state.query.shownOwned, isEmpty);
      expect(state.results, hasLength(2));
    });
  });
}
