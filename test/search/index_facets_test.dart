import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/index_facets.dart';
import 'package:pw_market_filter/market/market_index.dart';

const attackLevel = 0;
const guardLevel = 1;
const hp = 2;

EquippedItem _item(int slot, int itemId, Map<int, int> attributes) =>
    EquippedItem(
      slot: slot,
      itemId: itemId,
      refine: 0,
      stones: const [],
      attributes: attributes,
    );

MarketCharacter _character(
  String name,
  String characterClass,
  int price,
  int level,
  List<EquippedItem> equipped,
) => MarketCharacter(
  roleId: name.hashCode.abs(),
  name: name,
  characterClass: characterClass,
  occupation: 1,
  level: level,
  price: price,
  fame: 1,
  cultivation: 'Leal',
  equipped: equipped,
);

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque', 'Nível de Guarda', 'HP'],
  items: const {
    50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
    50205: MarketItem(name: '★★★Dilacerador do Vento', grade: 6),
    38256: MarketItem(name: '★★★Coroa da Insanidade', grade: 0),
  },
  characters: [
    _character('Leandrim', 'Guerreiro', 1000, 105, [
      _item(10, 50206, {attackLevel: 70, hp: 800}),
      _item(8, 38256, {guardLevel: 350}),
    ]),
    _character('Bruto', 'Guerreiro', 90, 104, [
      _item(10, 50205, {attackLevel: 40}),
    ]),
    _character('Sabia', 'Arcano', 300, 101, [
      _item(10, 50205, {attackLevel: 40}),
    ]),
  ],
);

void main() {
  test('offers the slots that actually appear, in order', () {
    expect(IndexFacets(_index).slots, [8, 10]);
  });

  test('offers each class and cultivation once', () {
    expect(IndexFacets(_index).classes, ['Arcano', 'Guerreiro']);
    expect(IndexFacets(_index).cultivations, ['Leal']);
  });

  test('reports the real price and level range', () {
    final facets = IndexFacets(_index);

    expect(facets.lowestPrice, 90);
    expect(facets.highestPrice, 1000);
    expect(facets.lowestLevel, 101);
    expect(facets.highestLevel, 105);
  });

  test('offers only the attributes the chosen slot carries', () {
    final weapon = IndexFacets(_index).attributesIn(10);

    expect(weapon.map((f) => f.name), ['Nível de Ataque', 'HP']);
  });

  test('counts characters, not items, and reports the best value', () {
    final attack = IndexFacets(
      _index,
    ).attributesIn(10).firstWhere((f) => f.name == 'Nível de Ataque');

    expect(attack.characterCount, 3);
    expect(attack.highestValue, 70);
  });

  test('a null slot asks about the whole character', () {
    final anywhere = IndexFacets(_index).attributesIn(null);

    expect(anywhere.map((f) => f.name).toSet(), {
      'Nível de Ataque',
      'HP',
      'Nível de Guarda',
    });
  });

  group('the item dropdown', () {
    test('lists each distinct item in the slot, best attack level first', () {
      final weapons = IndexFacets(_index).itemsIn(10);

      expect(weapons.map((f) => f.itemId), [50206, 50205]);
      expect(weapons.first.attackLevel, 70);
      expect(weapons.last.attackLevel, 40);
    });

    test('counts wearers, not appearances of the name', () {
      final weapons = IndexFacets(_index).itemsIn(10);

      expect(weapons.firstWhere((f) => f.itemId == 50206).characterCount, 1);
      expect(weapons.firstWhere((f) => f.itemId == 50205).characterCount, 2);
    });

    test('writes the attack level into the label, so the name cannot lie', () {
      final weapon = IndexFacets(_index).itemsIn(10).first;

      expect(weapon.label, '★★★Dilacerador Raivoso  ·  +70');
      expect(weapon.detail, '+70 nível de ataque  ·  1 personagem');
    });

    test('an item with no attack level is labelled by name alone', () {
      final helm = IndexFacets(_index).itemsIn(8).single;

      expect(helm.attackLevel, isNull);
      expect(helm.label, '★★★Coroa da Insanidade');
      expect(helm.detail, '1 personagem');
    });

    test('the detail line pluralises the wearer count', () {
      final common = IndexFacets(
        _index,
      ).itemsIn(10).firstWhere((f) => f.itemId == 50205);

      expect(common.detail, '+40 nível de ataque  ·  2 personagens');
    });

    test('a slot nobody wears offers nothing', () {
      expect(IndexFacets(_index).itemsIn(99), isEmpty);
    });

    test('shows a range when the same item gives different values', () {
      // Measured on the collected market: of 62 weapons exactly one varied,
      // ★★★Dilacerador Raivoso at 70 on one wearer and 71 on another.
      // Announcing only the maximum promises 71 on a weapon that mostly gives
      // 70.
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
        attributes: const ['Nível de Ataque'],
        items: const {
          50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
        },
        characters: [
          _character('Leandrim', 'Guerreiro', 1000, 105, [
            _item(10, 50206, {attackLevel: 70}),
          ]),
          _character('Fera', 'Bárbaro', 900, 105, [
            _item(10, 50206, {attackLevel: 71}),
          ]),
        ],
      );

      final weapon = IndexFacets(index).itemsIn(10).single;

      expect(weapon.attackLevelVaries, isTrue);
      expect(weapon.lowestAttackLevel, 70);
      expect(weapon.attackLevel, 71);
      expect(weapon.label, '★★★Dilacerador Raivoso  ·  +70 a +71');
      expect(weapon.detail, '+70 a +71 nível de ataque  ·  2 personagens');
    });

    test('an instance lacking the attribute drags the floor to zero', () {
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
        attributes: const ['Nível de Ataque'],
        items: const {7: MarketItem(name: 'Arma Estranha', grade: 4)},
        characters: [
          _character('Com', 'Guerreiro', 100, 105, [
            _item(10, 7, {attackLevel: 70}),
          ]),
          _character('Sem', 'Guerreiro', 100, 105, [_item(10, 7, const {})]),
        ],
      );

      final weapon = IndexFacets(index).itemsIn(10).single;

      expect(weapon.lowestAttackLevel, 0);
      expect(weapon.label, 'Arma Estranha  ·  +0 a +70');
    });
  });

  test('names the commonest item in a slot, to identify unnamed slots', () {
    expect(IndexFacets(_index).exampleItemIn(10), '★★★Dilacerador do Vento');
    expect(IndexFacets(_index).exampleItemIn(8), '★★★Coroa da Insanidade');
  });

  test('an empty index answers without throwing', () {
    final empty = IndexFacets(
      MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
        attributes: const [],
        items: const {},
        characters: const [],
      ),
    );

    expect(empty.slots, isEmpty);
    expect(empty.attributesIn(null), isEmpty);
    expect(empty.lowestPrice, 0);
    expect(empty.exampleItemIn(10), '');
  });
}
