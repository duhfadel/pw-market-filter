import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/item_rank.dart';
import 'package:pw_market_filter/market/market_index.dart';

const attackLevel = 0;
const weaponSlot = 10;

const raivoso = 50206; // ★★★, rank 4, 70 attack level
const geada = 50143; // ★★, rank 3, no attack level
const simples = 1; // no stars, rank 1

EquippedItem _weapon(int itemId, {int refine = 0, int? attack}) => EquippedItem(
  slot: weaponSlot,
  itemId: itemId,
  refine: refine,
  stones: const [],
  attributes: attack == null ? const {} : {attackLevel: attack},
);

MarketCharacter _character(String name, List<EquippedItem> equipped) =>
    MarketCharacter(
      roleId: name.hashCode.abs(),
      name: name,
      characterClass: 'Guerreiro',
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
    raivoso: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
    geada: MarketItem(name: '★★Geada Tardia', grade: 4),
    simples: MarketItem(name: 'Espada Simples', grade: 0),
  },
  characters: const [],
);

void main() {
  group('reading a rank off the name', () {
    test('counts the stars and adds one', () {
      expect(rankFromName('Espada Simples'), 1);
      expect(rankFromName('★Capa da Nuvem'), 2);
      expect(rankFromName('★★Geada Tardia'), 3);
      expect(rankFromName('★★★Dilacerador Raivoso'), 4);
    });

    test('only the prefix counts', () {
      // Checked against all 538 items in the collected market: stars appear as
      // a prefix and nowhere else. This pins the reading anyway, because a
      // star mid-name must not inflate the rank.
      expect(rankFromName('Estrela ★ do Norte'), 1);
    });

    test('an empty name is rank 1, not a crash', () {
      expect(rankFromName(''), 1);
    });
  });

  group('filtering by rank', () {
    final leandrim = _character('Leandrim', [
      _weapon(raivoso, refine: 12, attack: 70),
    ]);
    final pobre = _character('Pobre', [_weapon(simples)]);

    test('accepts an item at the rank asked for', () {
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(
            criteria: [ItemCriterion(slot: weaponSlot, minimumRank: 4)],
          ),
        ),
        isTrue,
      );
    });

    test('rejects an item below it', () {
      expect(
        matchesQuery(
          _index,
          pobre,
          const SearchQuery(
            criteria: [ItemCriterion(slot: weaponSlot, minimumRank: 2)],
          ),
        ),
        isFalse,
      );
    });

    test('a criterion with no attribute asks only about the item', () {
      // This was unsayable while every criterion had to name an attribute:
      // "a rank 4 weapon at +11 or better" is about the piece, not a bonus.
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                minimumRank: 4,
                minimumRefine: 11,
              ),
            ],
          ),
        ),
        isTrue,
      );
      expect(
        matchesQuery(
          _index,
          leandrim,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                minimumRank: 4,
                minimumRefine: 13,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('rank and attack level are independent, and both are enforced', () {
      // ★★Geada Tardia is rank 3 with no attack level; ★★★Dilacerador Raivoso
      // is rank 4 with 70. A rank filter is not an attack-level filter in
      // disguise, and the market has rank 4 weapons giving nothing at all.
      final comGeada = _character('Fraco', [_weapon(geada)]);

      expect(
        matchesQuery(
          _index,
          comGeada,
          const SearchQuery(
            criteria: [ItemCriterion(slot: weaponSlot, minimumRank: 3)],
          ),
        ),
        isTrue,
      );
      expect(
        matchesQuery(
          _index,
          comGeada,
          const SearchQuery(
            criteria: [
              ItemCriterion(
                slot: weaponSlot,
                minimumRank: 3,
                attributeId: attackLevel,
                minimum: 1,
              ),
            ],
          ),
        ),
        isFalse,
      );
    });

    test('an unknown item is rank 0, so it fails any rank asked for', () {
      final fantasma = _character('Fantasma', [_weapon(99999)]);

      expect(
        matchesQuery(
          _index,
          fantasma,
          const SearchQuery(
            criteria: [ItemCriterion(slot: weaponSlot, minimumRank: 2)],
          ),
        ),
        isFalse,
      );
    });
  });

  group('the card and the filter read the same rule', () {
    test('the item named on the card is one the filter accepted', () {
      final xnokas = _character('Xnokas', [
        _weapon(geada, refine: 12),
        _weapon(raivoso, refine: 5, attack: 70),
      ]);
      const criterion = ItemCriterion(slot: weaponSlot, minimumRank: 4);

      expect(bestMatchFor(_index, xnokas, criterion)?.itemId, raivoso);
    });

    test('nothing is named when nothing qualified', () {
      const criterion = ItemCriterion(slot: weaponSlot, minimumRank: 4);

      expect(
        bestMatchFor(
          _index,
          _character('Pobre', [_weapon(simples)]),
          criterion,
        ),
        isNull,
      );
    });

    test('with an attribute, the best value wins', () {
      final duas = _character('Duas', [
        _weapon(raivoso, attack: 40),
        _weapon(raivoso, attack: 70),
      ]);
      const criterion = ItemCriterion(
        slot: weaponSlot,
        attributeId: attackLevel,
        minimum: 40,
      );

      expect(
        bestMatchFor(_index, duas, criterion)?.attributes[attackLevel],
        70,
      );
    });
  });
}
