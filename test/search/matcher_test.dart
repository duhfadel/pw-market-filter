import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Attribute ids used throughout, matching [_index]'s vocabulary.
const attackLevel = 0;
const guardLevel = 1;
const hp = 2;

const weaponSlot = 10;
const helmSlot = 8;

EquippedItem _item(
  int slot, {
  int itemId = 1,
  int refine = 0,
  Map<int, int> attributes = const {},
}) => EquippedItem(
  slot: slot,
  itemId: itemId,
  refine: refine,
  stones: const [],
  attributes: attributes,
);

MarketCharacter _character(
  String name, {
  int price = 100,
  int level = 105,
  String characterClass = 'Guerreiro',
  String cultivation = 'Leal',
  List<EquippedItem> equipped = const [],
}) => MarketCharacter(
  roleId: name.hashCode.abs(),
  name: name,
  characterClass: characterClass,
  occupation: 1,
  level: level,
  price: price,
  fame: 1000,
  cultivation: cultivation,
  equipped: equipped,
);

/// The catalogue the matcher consults for an item's rank. Its `characters` are
/// empty on purpose: every test here builds the character it needs.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 9),
  attributes: const ['Nível de Ataque', 'Nível de Guarda', 'HP'],
  items: const {
    1: MarketItem(name: 'Espada Simples', grade: 0),
    50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
    50205: MarketItem(name: '★★Dilacerador Gelado', grade: 6),
    38256: MarketItem(name: '★★★Coroa da Insanidade', grade: 0),
  },
  characters: const [],
);

void main() {
  group('an item criterion', () {
    test('matches when the item in that slot meets the minimum', () {
      final character = _character(
        'Leandrim',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 70}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('rejects a value one short of the minimum', () {
      final character = _character(
        'Bruto',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 69}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('does not let another slot satisfy a slot-specific criterion', () {
      // The helm has the attack level; the weapon does not. Asking for it on
      // the weapon has to fail, or the whole per-slot idea is decoration.
      final character = _character(
        'Xnokas',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 40}),
          _item(helmSlot, attributes: {attackLevel: 70}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('a criterion with no slot accepts the attribute anywhere', () {
      final character = _character(
        'Xnokas',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 40}),
          _item(helmSlot, attributes: {attackLevel: 70}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [ItemCriterion(attributeId: attackLevel, minimum: 70)],
          ),
        ),
        isTrue,
      );
    });

    test('an item missing the attribute never matches', () {
      final character = _character(
        'Poeira',
        equipped: [
          _item(weaponSlot, attributes: {hp: 500}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [ItemCriterion(attributeId: attackLevel, minimum: 1)],
          ),
        ),
        isFalse,
      );
    });

    test('an empty slot never matches', () {
      final character = _character('Nu');

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 1,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('two criteria are an AND, and both must find their own item', () {
      final character = _character(
        'Leandrim',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 70}),
          _item(helmSlot, attributes: {guardLevel: 350}),
        ],
      );

      const both = SearchQuery(
        criteria: [
          ItemCriterion(
            slot: weaponSlot,
            attributeId: attackLevel,
            minimum: 70,
          ),
          ItemCriterion(slot: helmSlot, attributeId: guardLevel, minimum: 350),
        ],
      );
      const secondUnreachable = SearchQuery(
        criteria: [
          ItemCriterion(
            slot: weaponSlot,
            attributeId: attackLevel,
            minimum: 70,
          ),
          ItemCriterion(slot: helmSlot, attributeId: guardLevel, minimum: 351),
        ],
      );

      expect(matchesQuery(_index, character, both), isTrue);
      expect(matchesQuery(_index, character, secondUnreachable), isFalse);
    });

    test('two criteria on the same slot are met by the same item', () {
      final character = _character(
        'Leandrim',
        equipped: [
          _item(weaponSlot, attributes: {attackLevel: 70, guardLevel: 350}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
              ),
              ItemCriterion(
                slot: weaponSlot,
                attributeId: guardLevel,
                minimum: 350,
              ),
            ],
          ),
        ),
        isTrue,
      );
    });

    test('a minimum refine is checked on the item that has the attribute', () {
      final character = _character(
        'Leandrim',
        equipped: [
          _item(weaponSlot, refine: 10, attributes: {attackLevel: 70}),
        ],
      );

      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
                minimumRefine: 10,
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        matchesQuery(
          _index,
          character,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 70,
                minimumRefine: 11,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });
  });

  group('choosing an exact item for a slot', () {
    final leandrim = _character(
      'Leandrim',
      equipped: [
        _item(weaponSlot, itemId: 50206, attributes: {attackLevel: 70}),
        _item(helmSlot, itemId: 38256),
      ],
    );

    test('matches the wearer of that exact item', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(itemBySlot: {weaponSlot: 50206}),
        ),
        isTrue,
      );
    });

    test('rejects a different item, however similar the name', () {
      // 50205 is ★★★Dilacerador do Vento; 50206 is ★★★Dilacerador Raivoso.
      // Two words apart, thirty attack levels and 900 TCC apart.
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(itemBySlot: {weaponSlot: 50205}),
        ),
        isFalse,
      );
    });

    test('rejects the right item worn in the wrong slot', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(itemBySlot: {helmSlot: 50206}),
        ),
        isFalse,
      );
    });

    test('two slots at once are an AND', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(itemBySlot: {weaponSlot: 50206, helmSlot: 38256}),
        ),
        isTrue,
      );
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(itemBySlot: {weaponSlot: 50206, helmSlot: 1}),
        ),
        isFalse,
      );
    });

    test('combines with a criterion rather than replacing it', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(
            itemBySlot: {weaponSlot: 50206},
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                attributeId: attackLevel,
                minimum: 71,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });
  });

  group('the character filters', () {
    final leandrim = _character(
      'Leandrim',
      price: 1000,
      level: 105,
      characterClass: 'Guerreiro',
    );

    test('an empty query matches everybody', () {
      expect(matchesQuery(_index, leandrim, const SearchQuery()), isTrue);
    });

    test('class, price, level and cultivation each exclude on their own', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(characterClass: 'Arcano'),
        ),
        isFalse,
      );
      expect(
        matchesQuery(_index, leandrim, const SearchQuery(maxPrice: 999)),
        isFalse,
      );
      expect(
        matchesQuery(_index, leandrim, const SearchQuery(minPrice: 1001)),
        isFalse,
      );
      expect(
        matchesQuery(_index, leandrim, const SearchQuery(minLevel: 106)),
        isFalse,
      );
      expect(
        matchesQuery(_index, leandrim, const SearchQuery(maxLevel: 104)),
        isFalse,
      );
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(cultivation: 'Demônio'),
        ),
        isFalse,
      );
    });

    test('the boundaries are inclusive', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(
            minPrice: 1000,
            maxPrice: 1000,
            minLevel: 105,
            maxLevel: 105,
            characterClass: 'Guerreiro',
            cultivation: 'Leal',
          ),
        ),
        isTrue,
      );
    });
  });

  group('running a query over the market', () {
    final index = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 8, 9),
      attributes: const ['Nível de Ataque', 'Nível de Guarda', 'HP'],
      items: const {
        50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
        50205: MarketItem(name: '★★★Dilacerador do Vento', grade: 6),
      },
      characters: [
        _character(
          'Leandrim',
          price: 1000,
          equipped: [
            _item(
              weaponSlot,
              itemId: 50206,
              refine: 12,
              attributes: {attackLevel: 70},
            ),
          ],
        ),
        _character(
          'Bruto',
          price: 90,
          equipped: [
            _item(
              weaponSlot,
              itemId: 50205,
              refine: 11,
              attributes: {attackLevel: 40},
            ),
          ],
        ),
        _character('Poeira', price: 40),
      ],
    );

    test('keeps only the characters that match, cheapest first', () {
      // Cheapest first is the default on purpose: finding who has the weapon
      // is half the question, and the site's own order answers neither half.
      final matches = runQuery(
        index,
        const SearchQuery(
          criteria: [
            ItemCriterion(
              slot: weaponSlot,
              attributeId: attackLevel,
              minimum: 40,
            ),
          ],
        ),
      );

      expect(matches.map((c) => c.name), ['Bruto', 'Leandrim']);
    });

    test('each ordering puts a different character first', () {
      const empty = SearchQuery();

      expect(runQuery(index, empty).map((c) => c.price), [40, 90, 1000]);
      expect(
        runQuery(
          index,
          empty.copyWith(order: ResultOrder.dearest),
        ).map((c) => c.price),
        [1000, 90, 40],
      );
    });

    test('clearing the filters does not disturb the ordering', () {
      // The order is how the list is read, not something that was asked for.
      final viewModelLike = const SearchQuery(
        order: ResultOrder.dearest,
      ).copyWith(characterClass: () => 'Guerreiro');

      expect(runQuery(index, viewModelLike).map((c) => c.price).first, 1000);
    });

    test('a query nobody matches returns empty, and that is an answer', () {
      final matches = runQuery(
        index,
        const SearchQuery(
          maxPrice: 500,
          criteria: [
            ItemCriterion(
              slot: weaponSlot,
              attributeId: attackLevel,
              minimum: 70,
            ),
          ],
        ),
      );

      expect(matches, isEmpty);
    });
  });
}
