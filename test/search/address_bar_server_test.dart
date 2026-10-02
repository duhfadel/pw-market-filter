import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/data/address_bar.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Records the real [Uri] `writeFilter` would have sent to the browser,
/// instead of a bare query string the way `address_bar_test.dart`'s own
/// `_Recording` does.
///
/// Extends [AddressBar] rather than faking its interface from scratch, so
/// [AddressBar.uriFor] — and through it `pathFor` and `versaoDoServidor` —
/// is the real production chain, not a copy of it. Only [writeFilter] itself
/// is overridden, and only because `flutter test` runs on the Dart VM where
/// `kIsWeb` is always false: the real method's first line would return
/// before ever building a [Uri], which is the one line this double has to
/// skip to observe anything at all. If `pathFor`, `uriFor` or `linkTo` is
/// ever edited to ignore [server] again — the exact shape of the bug this
/// file exists to catch — every assertion below reads the wrong prefix and
/// goes red.
class _RecordingAddressBar extends AddressBar {
  _RecordingAddressBar(super.server);

  final writes = <Uri>[];

  @override
  void writeFilter(String query) =>
      writes.add(AddressBar.uriFor(query, server: server));
}

MarketIndex _indiceDe(String server) => MarketIndex(
  server: server,
  collectedAt: DateTime.utc(2026, 10, 1),
  attributes: const ['Nível de Ataque'],
  items: const {},
  characters: [
    MarketCharacter(
      roleId: 1,
      name: 'Alvo',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: 100,
      fame: 1,
      cultivation: 'Leal',
      equipped: const [],
    ),
  ],
);

MockClient _clienteDe(String server) => MockClient(
  (_) async => http.Response.bytes(
    utf8.encode(jsonEncode(_indiceDe(server).toJson())),
    200,
  ),
);

/// `injection.dart`'s own two `SearchViewModel` factories never pass a
/// second constructor argument — both markets rely on
/// `addressBar ?? AddressBar(repository.server)` to pick the right one. So
/// this helper mirrors that: an explicit `_RecordingAddressBar` is still
/// passed, because nothing short of a web platform can observe the real
/// `writeFilter`'s side effect, but it is built from the exact same
/// [server] the repository carries — the value production's own default
/// line reads — so the chain under test (`pathFor`/`uriFor`/`linkTo`, keyed
/// by [IndexRepository.server]) is identical either way.
Future<(SearchViewModel, _RecordingAddressBar)> _viewModelPara(
  String server,
) async {
  final addressBar = _RecordingAddressBar(server);
  final viewModel = SearchViewModel(
    IndexRepository(_clienteDe(server), server),
    addressBar,
  );
  await viewModel.load();
  return (viewModel, addressBar);
}

void main() {
  group('a filtered search writes under its own market, never the other', () {
    test('pw126 writes under /1.2.6/filtro, never /1.8.7/filtro', () async {
      final (viewModel, addressBar) = await _viewModelPara(
        IndexRepository.pw126,
      );

      viewModel.setClass('Guerreiro');

      expect(addressBar.writes, isNotEmpty);
      for (final uri in addressBar.writes) {
        expect(uri.path, startsWith('/$pw126Versao/filtro'));
        expect(uri.path, isNot(startsWith('/$pw187Versao/filtro')));
      }
    });

    test('pw187 writes under /1.8.7/filtro, never /1.2.6/filtro', () async {
      final (viewModel, addressBar) = await _viewModelPara(
        IndexRepository.pw187,
      );

      viewModel.setClass('Guerreiro');

      expect(addressBar.writes, isNotEmpty);
      for (final uri in addressBar.writes) {
        expect(uri.path, startsWith('/$pw187Versao/filtro'));
        expect(uri.path, isNot(startsWith('/$pw126Versao/filtro')));
      }
    });
  });

  group('the copy-link button reads the same chain', () {
    // `_CopyLink` in `search_view.dart` calls `AddressBar.linkTo` directly —
    // no `SearchViewModel` in the way — passing `state.index.server`. A pure
    // function, so no `kIsWeb` double is needed here at all.
    test('a 1.2.6 link names /1.2.6/filtro', () {
      final link = AddressBar.linkTo(
        Uri.parse('https://portalpw.net/'),
        'preco=-100',
        server: IndexRepository.pw126,
      );

      expect(link, 'https://portalpw.net/#/1.2.6/filtro?preco=-100');
    });

    test('a 1.8.7 link names /1.8.7/filtro', () {
      final link = AddressBar.linkTo(
        Uri.parse('https://portalpw.net/'),
        'preco=-100',
        server: IndexRepository.pw187,
      );

      expect(link, 'https://portalpw.net/#/1.8.7/filtro?preco=-100');
    });
  });
}

/// Local aliases so the assertions above read `/1.2.6/filtro` and
/// `/1.8.7/filtro` without importing `core/rotas.dart` just for two string
/// constants already duplicated, by design, in `AddressBar`'s own doc
/// comment.
const pw126Versao = '1.2.6';
const pw187Versao = '1.8.7';
