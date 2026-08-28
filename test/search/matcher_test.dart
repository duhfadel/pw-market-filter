import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/celestial_realm.dart';
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
  Anecdotes? anecdotes,
  Map<int, int> counts = const {},
  String realm = '',
  String path = '',
  List<int> runes = const [],
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
  anecdotes: anecdotes,
  counts: counts,
  realm: realm,
  path: path,
  runes: runes,
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
  runes: const {
    52220: RuneKind(type: 'Argêntea', level: 6),
    52181: RuneKind(type: 'Áurea', level: 7),
    52183: RuneKind(type: 'Áurea', level: 9),
    69810: RuneKind(type: 'Celeste', level: 8),
  },
  countedItems: const {
    'Relíquia Maravilha: Arma': 50410,
    'Relíquia Maravilha: Artefato': 54687,
    'Harpia': 38587,
  },
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

  group('anecdotes', () {
    test(
      'a minimum admits the character above it and refuses the one below',
      () {
        final ahead = _character(
          'Leandrim',
          anecdotes: const Anecdotes(done: 1265, total: 2756),
        );
        final behind = _character(
          'Novato',
          anecdotes: const Anecdotes(done: 300, total: 2756),
        );

        const query = SearchQuery(minAnecdotes: 1000);
        expect(matchesQuery(_index, ahead, query), isTrue);
        expect(matchesQuery(_index, behind, query), isFalse);
      },
    );

    test('a character whose page predates the field fails the filter', () {
      // Unknown is not "has enough". While a collection is in flight half the
      // market has no anecdotes read, and those must not be reported as
      // matching a number nobody measured.
      final unread = _character('Antigo');

      expect(
        matchesQuery(_index, unread, const SearchQuery(minAnecdotes: 1)),
        isFalse,
      );
      expect(matchesQuery(_index, unread, const SearchQuery()), isTrue);
    });
  });

  group('ordering by what the page says about the character', () {
    test('most anecdotes first, and an unread page sinks below zero', () {
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 19),
        attributes: const [],
        items: const {},
        characters: [
          _character(
            'Novato',
            anecdotes: const Anecdotes(done: 40, total: 2756),
          ),
          _character('Antigo'),
          _character(
            'Leandrim',
            anecdotes: const Anecdotes(done: 1265, total: 2756),
          ),
          _character(
            'Zerado',
            anecdotes: const Anecdotes(done: 0, total: 2756),
          ),
        ],
      );

      expect(
        runQuery(
          index,
          const SearchQuery(order: ResultOrder.mostAnecdotes),
        ).map((c) => c.name),
        ['Leandrim', 'Novato', 'Zerado', 'Antigo'],
      );
    });

    test('most of the marked relics first, added across the marks', () {
      // Marking is what says which relic "mais relíquias" means. Without it
      // the order would have to pick one on the visitor's behalf.
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 19),
        attributes: const [],
        items: const {},
        countedItems: const {
          'Relíquia Maravilha: Arma': 50410,
          'Relíquia Maravilha: Artefato': 54687,
        },
        characters: [
          _character('Poucas', counts: const {50410: 2, 54687: 30}),
          _character('Muitas', counts: const {50410: 16, 54687: 0}),
          _character('Antigo'),
        ],
      );

      expect(
        runQuery(
          index,
          const SearchQuery(
            order: ResultOrder.mostOwned,
            shownOwned: {'Relíquia Maravilha: Arma'},
          ),
        ).map((c) => c.name),
        ['Muitas', 'Poucas', 'Antigo'],
      );

      expect(
        runQuery(
          index,
          const SearchQuery(
            order: ResultOrder.mostOwned,
            shownOwned: {
              'Relíquia Maravilha: Arma',
              'Relíquia Maravilha: Artefato',
            },
          ),
        ).map((c) => c.name),
        ['Poucas', 'Muitas', 'Antigo'],
      );
    });

    test('a tie is broken by price, which is what the list is read for', () {
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 19),
        attributes: const [],
        items: const {},
        characters: [
          _character(
            'Caro',
            price: 900,
            anecdotes: const Anecdotes(done: 1265, total: 2756),
          ),
          _character(
            'Barato',
            price: 100,
            anecdotes: const Anecdotes(done: 1265, total: 2756),
          ),
        ],
      );

      expect(
        runQuery(
          index,
          const SearchQuery(order: ResultOrder.mostAnecdotes),
        ).map((c) => c.name),
        ['Barato', 'Caro'],
      );
    });
  });

  group('pets', () {
    test('asking for one admits who has it and refuses who does not', () {
      final dona = _character('Nihal', counts: const {38587: 1});
      final sem = _character('Novata', counts: const {38587: 0});

      const query = SearchQuery(pets: {'Harpia'});
      expect(matchesQuery(_index, dona, query), isTrue);
      expect(matchesQuery(_index, sem, query), isFalse);
    });

    test('a page never read is refused, not assumed empty', () {
      expect(
        matchesQuery(
          _index,
          _character('Antigo'),
          const SearchQuery(pets: {'Harpia'}),
        ),
        isFalse,
      );
    });

    test('a pet the collection never met matches nobody', () {
      // Not everybody: asking for a pet the market has none of is answered
      // "ninguem tem", never "todo mundo".
      final dona = _character('Nihal', counts: const {38587: 1});

      expect(
        matchesQuery(_index, dona, const SearchQuery(pets: {'Hércules'})),
        isFalse,
      );
    });

    test('two pets are an and, as every other filter here is', () {
      final so = _character('Nihal', counts: const {38587: 1});

      expect(
        matchesQuery(
          _index,
          so,
          const SearchQuery(pets: {'Harpia', 'Hércules'}),
        ),
        isFalse,
      );
    });
  });

  group('the celestial realm', () {
    test('a minimum admits from that rung up', () {
      final alto = _character('Alto', realm: 'Céu Majestoso I');
      final baixo = _character('Baixo', realm: 'Céu Ápice X');

      // Majestoso I is one rung above Ápice X.
      final corte = CelestialRealm.parse('Céu Majestoso I')!.ordinal;
      expect(matchesQuery(_index, alto, SearchQuery(minRealm: corte)), isTrue);
      expect(
        matchesQuery(_index, baixo, SearchQuery(minRealm: corte)),
        isFalse,
      );
    });

    test('a realm nobody could read fails the filter', () {
      final sem = _character('Antigo');
      final estranho = _character('Estranho', realm: 'Céu Inventado I');

      expect(
        matchesQuery(_index, sem, const SearchQuery(minRealm: 1)),
        isFalse,
      );
      expect(
        matchesQuery(_index, estranho, const SearchQuery(minRealm: 1)),
        isFalse,
      );
    });

    test('orders both ways, and the unread sink to the bottom either way', () {
      final index = MarketIndex(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 28),
        attributes: const [],
        items: const {},
        characters: [
          _character('Meio', realm: 'Céu Real V'),
          _character('Sem'),
          _character('Alto', realm: 'Céu Soberano X'),
          _character('Baixo', realm: 'Céu Arcano I'),
        ],
      );

      expect(
        runQuery(
          index,
          const SearchQuery(order: ResultOrder.highestRealm),
        ).map((c) => c.name),
        ['Alto', 'Meio', 'Baixo', 'Sem'],
      );
      expect(
        runQuery(
          index,
          const SearchQuery(order: ResultOrder.lowestRealm),
        ).map((c) => c.name),
        ['Baixo', 'Meio', 'Alto', 'Sem'],
      );
    });
  });

  group('the path', () {
    test('God and Evil are asked for by name', () {
      final god = _character('Santa', path: 'God');
      final evil = _character('Danada', path: 'Evil');

      expect(matchesQuery(_index, god, const SearchQuery(path: 'God')), isTrue);
      expect(
        matchesQuery(_index, evil, const SearchQuery(path: 'God')),
        isFalse,
      );
      expect(
        matchesQuery(_index, evil, const SearchQuery(path: 'Evil')),
        isTrue,
      );
    });

    test('a character with no path read is not God by omission', () {
      final sem = _character('Antigo');

      expect(
        matchesQuery(_index, sem, const SearchQuery(path: 'God')),
        isFalse,
      );
      expect(
        matchesQuery(_index, sem, const SearchQuery(path: 'Evil')),
        isFalse,
      );
      expect(matchesQuery(_index, sem, const SearchQuery()), isTrue);
    });
  });

  group('runes', () {
    final rico = _character('Rico', runes: const [52181, 52183, 69810, 52220]);
    final pobre = _character('Pobre', runes: const [52220]);

    test('counts the runes at or above the level asked for', () {
      const query = SearchQuery(
        runes: RuneCriterion(minimumLevel: 7, minimum: 3),
      );

      expect(matchesQuery(_index, rico, query), isTrue);
      expect(matchesQuery(_index, pobre, query), isFalse);
    });

    test('a colour narrows the count to that colour', () {
      // Rico has two Áureas at 7+, so three of them is one too many.
      expect(
        matchesQuery(
          _index,
          rico,
          const SearchQuery(
            runes: RuneCriterion(type: 'Áurea', minimumLevel: 7, minimum: 2),
          ),
        ),
        isTrue,
      );
      expect(
        matchesQuery(
          _index,
          rico,
          const SearchQuery(
            runes: RuneCriterion(type: 'Áurea', minimumLevel: 7, minimum: 3),
          ),
        ),
        isFalse,
      );
    });

    test('a rune whose kind the index does not know counts for nothing', () {
      final desconhecida = _character('Estranha', runes: const [99999]);

      expect(
        matchesQuery(
          _index,
          desconhecida,
          const SearchQuery(runes: RuneCriterion(minimumLevel: 7)),
        ),
        isFalse,
      );
    });
  });
}
