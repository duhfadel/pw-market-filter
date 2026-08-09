import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/index_facets.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Every class has its own weapons, and its own best one among them. A weapon
/// list that ignores the chosen class buries the entry you want among sixteen
/// you can never equip — and lets you pick a Mago weapon while filtering for
/// Guerreiro, which returns nothing and explains nothing.
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
    50205: MarketItem(name: '★★★Dilacerador do Vento', grade: 6),
    60101: MarketItem(name: '★★★Cajado do Vazio', grade: 6),
    60100: MarketItem(name: '★★Cajado Comum', grade: 4),
  },
  characters: [
    _character('Leandrim', 'Guerreiro', [_weapon(50206, 70)]),
    _character('Bruto', 'Guerreiro', [_weapon(50205, 40)]),
    _character('Sabia', 'Mago', [_weapon(60101, 70)]),
    _character('Aprendiz', 'Mago', [_weapon(60100, 30)]),
  ],
);

void main() {
  final facets = IndexFacets(_index);

  test('with no class chosen, every class\'s weapon is on offer', () {
    expect(facets.itemsIn(weaponSlot).map((f) => f.itemId).toSet(), {
      50206,
      50205,
      60101,
      60100,
    });
  });

  test('a class sees only its own weapons', () {
    expect(
      facets
          .itemsIn(weaponSlot, characterClass: 'Guerreiro')
          .map((f) => f.itemId),
      [50206, 50205],
    );
    expect(
      facets.itemsIn(weaponSlot, characterClass: 'Mago').map((f) => f.itemId),
      [60101, 60100],
    );
  });

  test('each class has its own +70, and it comes first', () {
    for (final characterClass in ['Guerreiro', 'Mago']) {
      final best = facets
          .itemsIn(weaponSlot, characterClass: characterClass)
          .first;
      expect(best.attackLevel, 70, reason: characterClass);
    }
  });

  test('the count is of that class only, not of the whole market', () {
    final guerreiro = facets
        .itemsIn(weaponSlot, characterClass: 'Guerreiro')
        .first;

    expect(guerreiro.characterCount, 1);
  });

  test('a class nobody plays offers no weapons', () {
    expect(facets.itemsIn(weaponSlot, characterClass: 'Paladino'), isEmpty);
  });

  test('the unscoped and the scoped answers are cached apart', () {
    // Both go through one cache, so a key that ignores the class would serve
    // the Guerreiro list to a Mago.
    final all = facets.itemsIn(weaponSlot);
    final mago = facets.itemsIn(weaponSlot, characterClass: 'Mago');

    expect(all, hasLength(4));
    expect(mago, hasLength(2));
    expect(facets.itemsIn(weaponSlot), hasLength(4));
  });
}
