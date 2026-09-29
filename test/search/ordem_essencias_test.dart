import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/presets.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';

MarketCharacter _c(String nome, int preco, Map<int, int> counts) =>
    MarketCharacter(
      roleId: nome.hashCode,
      name: nome,
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: preco,
      fame: 1,
      cultivation: 'Leal',
      equipped: const [],
      counts: counts,
    );

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 29),
  attributes: const [],
  items: const {},
  countedItems: const {
    'Essência Dracônica': [50264, 50265],
    'Relíquia Maravilha: Arma': [50410],
  },
  characters: [
    _c('Poucas', 10, const {50264: 1}),
    _c('Muitas', 900, const {50264: 8, 50265: 2}),
    _c('Nenhuma', 50, const {50264: 0}),
  ],
);

void main() {
  test('ordering by essences counts the whole group, not one id', () {
    // Ten, not eight: the raw essence is part of the same number, the same
    // way `countOf` adds it up everywhere else.
    final r = runQuery(
      _index,
      const SearchQuery(order: ResultOrder.maisEssencias),
    );

    expect(r.map((c) => c.name), ['Muitas', 'Poucas', 'Nenhuma']);
  });

  test('it is offered only where the market has one', () {
    final sem = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 9, 29),
      attributes: const [],
      items: const {},
      characters: const [],
    );

    expect(
      ResultOrder.maisEssencias.offeredFor(_index, const SearchQuery()),
      isTrue,
    );
    expect(
      ResultOrder.maisEssencias.offeredFor(sem, const SearchQuery()),
      isFalse,
    );
  });

  test('the filter opens with the three relics marked, not the key', () {
    // The relics are one question asked three ways — 94% of the market carries
    // each, and the spread between them is what a buyer compares. The key was
    // tried here first and taken off: it is a different animal, and its own
    // doc in `counted_items.dart` says why.
    expect(buscaInicial.shownOwned, {
      'Relíquia Maravilha: Artefato',
      'Relíquia Maravilha: Arma',
      'Relíquia Maravilha: Armadura',
    });
    expect(buscaInicial.shownOwned, isNot(contains('Chave da Sorte')));
    expect(buscaInicial.isEmpty, isTrue);
  });
}
