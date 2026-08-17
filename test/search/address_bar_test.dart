import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/data/address_bar.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Records what would have been written to the browser's address bar.
class _Recording implements AddressBar {
  final writes = <String>[];

  @override
  void writeFilter(String query) => writes.add(query);
}

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [
    MarketCharacter(
      roleId: 1,
      name: 'Leandrim',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: 100,
      fame: 1,
      cultivation: 'Leal',
      equipped: const [
        EquippedItem(
          slot: 10,
          itemId: 50206,
          refine: 0,
          stones: [],
          attributes: {0: 70},
        ),
      ],
    ),
    MarketCharacter(
      roleId: 2,
      name: 'Sabia',
      characterClass: 'Mago',
      occupation: 2,
      level: 105,
      price: 100,
      fame: 1,
      cultivation: 'Leal',
      equipped: const [],
    ),
  ],
);

(SearchViewModel, _Recording) _viewModel() {
  final address = _Recording();
  final client = MockClient(
    (_) async =>
        http.Response.bytes(utf8.encode(jsonEncode(_index.toJson())), 200),
  );
  return (SearchViewModel(IndexRepository(client), address), address);
}

void main() {
  test('a search asked for before the index arrives waits for it', () async {
    // The link is read while the index is still 1.7 MB in flight. Dropping the
    // query there would open the shared link on the unfiltered market, which
    // looks like a filter that failed rather than a page that is still loading.
    final (viewModel, _) = _viewModel();

    viewModel.request(const SearchQuery(characterClass: 'Mago'));
    await viewModel.load();

    final state = viewModel.state as SearchReady;
    expect(state.query.characterClass, 'Mago');
    expect(state.results.map((c) => c.name), ['Sabia']);
  });

  test(
    'a search asked for after the index arrives is applied at once',
    () async {
      final (viewModel, _) = _viewModel();
      await viewModel.load();

      viewModel.request(const SearchQuery(characterClass: 'Mago'));

      expect((viewModel.state as SearchReady).results, hasLength(1));
    },
  );

  test('arriving with a search does not rewrite the address', () async {
    // The address already says it. Writing it back on load would replace the
    // visitor's own link with our rendering of it before they had read it.
    final (viewModel, address) = _viewModel();

    viewModel.request(const SearchQuery(characterClass: 'Mago'));
    await viewModel.load();

    expect(address.writes, isEmpty);
  });

  test('changing the form writes the search to the address', () async {
    final (viewModel, address) = _viewModel();
    await viewModel.load();

    viewModel.setClass('Mago');

    expect(address.writes.last, contains('classe=Mago'));
  });

  test('clearing the form empties the address', () async {
    final (viewModel, address) = _viewModel();
    await viewModel.load();
    viewModel.setClass('Mago');

    viewModel.clear();

    expect(address.writes.last, isEmpty);
  });
}
