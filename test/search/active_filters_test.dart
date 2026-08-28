import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/active_filters.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/celestial_realm.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// What the form is asking, said in words and undoable one at a time.
///
/// This exists because of a dead end the panel had: with a dozen sections, a
/// filter set inside one of them is found only by hunting for badges — and
/// when a search returns nobody, the sections themselves collapse and the
/// control that set the filter disappears. "Limpar tudo" was the only way out,
/// and it throws away the parts you wanted to keep.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 28),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  countedItems: const {'Harpia': 38587},
  characters: const [],
);

void main() {
  test('an empty query is asking nothing', () {
    expect(activeFilters(_index, const SearchQuery()), isEmpty);
  });

  test('each filter in force becomes one chip', () {
    final query = SearchQuery(
      characterClass: 'Feiticeira',
      path: 'God',
      minPrice: 100,
      maxPrice: 1500,
      minRealm: CelestialRealm.parse('Céu Ápice V')!.ordinal,
      pets: const {'Harpia'},
      minAnecdotes: 1000,
      runes: const RuneCriterion(type: 'Áurea', minimumLevel: 7, minimum: 2),
      itemBySlot: const {10: 50206},
    );

    final rotulos = activeFilters(_index, query).map((f) => f.label).toList();

    expect(rotulos, contains('Feiticeira'));
    expect(rotulos, contains('God'));
    expect(rotulos, contains('100 a 1500 TCC'));
    expect(rotulos, contains('Céu Ápice V ou mais'));
    expect(rotulos, contains('Harpia'));
    expect(rotulos, contains('1000 anedotas ou mais'));
    expect(rotulos, contains('2 runas Áurea nível 7+'));
    expect(rotulos, contains('★★★Dilacerador Raivoso'));
  });

  test('removing one chip leaves every other filter alone', () {
    const query = SearchQuery(
      characterClass: 'Feiticeira',
      path: 'God',
      minAnecdotes: 1000,
    );

    final classe = activeFilters(
      _index,
      query,
    ).firstWhere((f) => f.label == 'Feiticeira');
    final sobrou = classe.remove(query);

    expect(sobrou.characterClass, isNull);
    expect(sobrou.path, 'God');
    expect(sobrou.minAnecdotes, 1000);
  });

  test('two pets are two chips, and one goes without the other', () {
    const query = SearchQuery(pets: {'Harpia', 'Hércules'});

    final chips = activeFilters(_index, query);
    expect(chips.map((f) => f.label), containsAll(['Harpia', 'Hércules']));

    final semHarpia = chips
        .firstWhere((f) => f.label == 'Harpia')
        .remove(query);
    expect(semHarpia.pets, {'Hércules'});
  });

  test('half a range says which half', () {
    expect(
      activeFilters(_index, const SearchQuery(minPrice: 100)).single.label,
      'a partir de 100 TCC',
    );
    expect(
      activeFilters(_index, const SearchQuery(maxPrice: 500)).single.label,
      'até 500 TCC',
    );
  });

  test('what only changes the card is not a filter', () {
    // Marking a relic or the anecdotes prints a number and narrows nothing, so
    // it has no chip — the same reason it is out of `isEmpty` and out of the
    // count of filters in force.
    const query = SearchQuery(
      shownOwned: {'Relíquia Maravilha: Arma'},
      anecdotesOnCard: true,
      order: ResultOrder.dearest,
    );

    expect(activeFilters(_index, query), isEmpty);
  });

  test('an item the index cannot name still gets a chip', () {
    // Otherwise a filter in force would have no way out, which is the whole
    // dead end this exists to close.
    const query = SearchQuery(itemBySlot: {10: 99999});

    expect(activeFilters(_index, query), hasLength(1));
    expect(
      activeFilters(_index, query).single.remove(query).itemBySlot,
      isEmpty,
    );
  });

  test('every criterion is its own chip', () {
    const query = SearchQuery(
      criteria: [
        ItemCriterion(slot: 10, attributeId: 0, minimum: 70),
        ItemCriterion(minimumRefine: 10),
      ],
    );

    final chips = activeFilters(_index, query);
    expect(chips, hasLength(2));
    expect(chips.first.remove(query).criteria, hasLength(1));
  });
}
