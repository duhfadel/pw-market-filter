import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Each control reads its options from the characters that pass every filter
/// **but its own**. Without that the form is a set of independent dropdowns
/// that happily offer combinations returning nothing; with it, choosing a combo
/// empties the class list of classes nobody plays with it.
const attackLevel = 0;
const weaponSlot = 10;

EquippedCard _card(int id, String type) => EquippedCard(
  cardId: id,
  name: 'c$id',
  rarity: 'S',
  type: type,
  level: 80,
  maxLevel: 80,
);

EquippedItem _weapon(int itemId) => EquippedItem(
  slot: weaponSlot,
  itemId: itemId,
  refine: 0,
  stones: const [],
  attributes: const {attackLevel: 70},
);

MarketCharacter _character(
  String name,
  String characterClass,
  int price, {
  List<EquippedCard> cards = const [],
  int weaponId = 1,
}) => MarketCharacter(
  roleId: name.hashCode.abs(),
  name: name,
  characterClass: characterClass,
  occupation: characterClass.hashCode.abs() % 17,
  level: 105,
  price: price,
  fame: 1,
  cultivation: 'Leal',
  equipped: [_weapon(weaponId)],
  cards: cards,
);

/// Only the Guerreiros wear the six-card set; the Magos wear nothing.
final _seis = [
  _card(1, 'Destruidor'),
  _card(2, 'Batalha'),
  _card(3, 'Durabilidade'),
  _card(4, 'Alma Primordial'),
  _card(5, 'Vida Primordial'),
  _card(6, 'Longevidade'),
];

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 11),
  attributes: const ['Nível de Ataque'],
  items: const {
    1: MarketItem(name: 'Espada', grade: 0),
    2: MarketItem(name: 'Cajado', grade: 0),
  },
  characters: [
    _character('G1', 'Guerreiro', 1000, cards: _seis, weaponId: 1),
    _character('G2', 'Guerreiro', 900, cards: _seis, weaponId: 1),
    _character('M1', 'Mago', 100, weaponId: 2),
    _character('M2', 'Mago', 50, weaponId: 2),
  ],
);

SearchReady _ready(SearchQuery query) =>
    SearchReady(index: _index, query: query, results: runQuery(_index, query));

void main() {
  test('with nothing chosen, every control offers everything', () {
    final state = _ready(const SearchQuery());

    expect(
      state.facetsFor(FacetDimension.characterClass).classes,
      ['Guerreiro', 'Mago'],
    );
  });

  test('choosing cards narrows the class list to who wears them', () {
    // The point of the whole thing: pick the combo and Mago disappears,
    // because no Mago has it.
    final state = _ready(const SearchQuery(cardRarity: 'S'));

    expect(
      state.facetsFor(FacetDimension.characterClass).classes,
      ['Guerreiro'],
    );
  });

  test('choosing cards narrows the weapon list too', () {
    final state = _ready(const SearchQuery(cardRarity: 'S'));
    final weapons = state
        .facetsFor(FacetDimension.items)
        .itemsIn(weaponSlot)
        .map((f) => f.itemId);

    expect(weapons, [1]);
  });

  test('choosing cards narrows the price range', () {
    final state = _ready(const SearchQuery(cardRarity: 'S'));
    final price = state.facetsFor(FacetDimension.price);

    expect(price.lowestPrice, 900);
    expect(price.highestPrice, 1000);
  });

  test('a control never hides the value already chosen in it', () {
    // Excluding its own dimension is what makes the choice reversible. Include
    // it and the class list would offer Guerreiro alone, with no way back.
    final state = _ready(const SearchQuery(characterClass: 'Guerreiro'));

    expect(
      state.facetsFor(FacetDimension.characterClass).classes,
      ['Guerreiro', 'Mago'],
    );
  });

  test('but that choice does narrow the other controls', () {
    final state = _ready(const SearchQuery(characterClass: 'Mago'));

    expect(
      state.facetsFor(FacetDimension.items).itemsIn(weaponSlot).single.itemId,
      2,
    );
    expect(state.facetsFor(FacetDimension.price).highestPrice, 100);
  });

  test('two filters compose, and the third sees both', () {
    final state = _ready(
      const SearchQuery(characterClass: 'Guerreiro', maxPrice: 950),
    );

    expect(state.facetsFor(FacetDimension.cards).scope.map((c) => c.name), [
      'G2',
    ]);
  });

  test('a filter matching nobody leaves the other controls empty, not full', () {
    // The honest answer to "which classes have this?" when nothing does is
    // none — not "all of them", which would invite another dead query.
    final state = _ready(const SearchQuery(maxPrice: 1));

    expect(state.facetsFor(FacetDimension.characterClass).classes, isEmpty);
    expect(state.results, isEmpty);
  });

  test('the attribute vocabulary is read from the whole market', () {
    // Attributes must not vanish as a minimum is typed: the list is what tells
    // you the attribute exists at all.
    final state = _ready(const SearchQuery(maxPrice: 1));

    expect(state.allFacets.attributesIn(null), isNotEmpty);
  });
}
