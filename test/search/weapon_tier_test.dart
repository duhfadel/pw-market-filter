import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/search/ui/widgets/character_card.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The frame that tells a grid of forty cards apart.
///
/// It shipped with no test at all, and the rung that needed one most is the
/// defensive UP5: eight characters in 1519, which is a case nobody meets by
/// scrolling the page. A colour that silently fell through to the attack
/// ladder would look like a working frame.
const _atributos = ['Nível de Ataque', 'Nível de Defesa', 'HP'];
const _ataque = 0;
const _defesa = 1;
const _hp = 2;

MarketIndex _index() => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 29),
  attributes: _atributos,
  items: {},
  characters: [],
);

/// A character wearing one weapon giving [attributes], plus — when asked — a
/// second piece that is not a weapon.
MarketCharacter _wearing(
  Map<int, int> attributes, {
  Map<int, int>? noAmuleto,
}) => MarketCharacter(
  roleId: 1,
  name: 'Alvo',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 0,
  cultivation: 'Leal',
  equipped: [
    EquippedItem(
      slot: 10,
      itemId: 50206,
      refine: 0,
      stones: const [],
      attributes: attributes,
    ),
    if (noAmuleto != null)
      EquippedItem(
        slot: 8,
        itemId: 45306,
        refine: 0,
        stones: const [],
        attributes: noAmuleto,
      ),
  ],
);

void main() {
  final index = _index();

  test('the attack ladder takes its four rungs', () {
    expect(
      weaponTierColor(index, _wearing({_ataque: 80})),
      PWColors.gradeColors[6],
    );
    expect(
      weaponTierColor(index, _wearing({_ataque: 70})),
      PWColors.gradeColors[4],
    );
    expect(
      weaponTierColor(index, _wearing({_ataque: 40})),
      PWColors.gradeColors[3],
    );
  });

  test('the defensive UP5 is not the attacking one', () {
    // The whole reason this rung exists. Eight characters carry it, they are
    // 2.200 to 20.000 TCC, and a frame that painted them red would say they
    // were something they are not.
    expect(
      weaponTierColor(index, _wearing({_defesa: 80})),
      PWColors.defenceTier,
    );
    expect(
      weaponTierColor(index, _wearing({_defesa: 80})),
      isNot(PWColors.gradeColors[6]),
    );
  });

  test('defence wins when a weapon somehow carries both', () {
    // Disjoint in every collection so far, and the ordering must not depend on
    // that staying true.
    expect(
      weaponTierColor(index, _wearing({_ataque: 80, _defesa: 80})),
      PWColors.defenceTier,
    );
  });

  test('thirty draws nothing', () {
    // 212 characters of 1519 sat on this rung and it was taken away on the
    // owner's call: the bottom of the market does not need a badge saying it
    // is the bottom.
    expect(weaponTierColor(index, _wearing({_ataque: 30})), isNull);
    expect(weaponTierColor(index, _wearing({_ataque: 39})), isNull);
    expect(
      weaponTierColor(index, _wearing({_ataque: 40})),
      isNotNull,
      reason: 'forty is still a rung',
    );
  });

  test('a weapon with neither level draws the plain border', () {
    expect(weaponTierColor(index, _wearing({_hp: 5000})), isNull);
    expect(weaponTierColor(index, _wearing(const {})), isNull);
  });

  test('the low defence rolls are noise and colour nothing', () {
    // `Nível de Defesa` on a weapon runs 1 to 30 and then jumps straight to
    // 80. Reading the low end as a tier would paint a quarter of the market
    // for a roll nobody buys on.
    for (final roll in [1, 5, 20, 30]) {
      expect(
        weaponTierColor(index, _wearing({_defesa: roll})),
        isNull,
        reason: 'defence $roll is noise',
      );
    }
  });

  test('only the weapon speaks for the frame', () {
    // A criterion may ask about any piece; the frame is a statement about the
    // weapon. An amulet's attack level vouching for it would be the same
    // fraud the matcher refuses when it reads every condition off one item.
    expect(
      weaponTierColor(index, _wearing(const {}, noAmuleto: {_ataque: 80})),
      isNull,
    );
  });

  test('a collection that never met the attribute colours nothing', () {
    // `indexOf` answers -1, and a frame is not worth a crash.
    final semAtributos = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 9, 29),
      attributes: const ['HP'],
      items: {},
      characters: [],
    );

    expect(weaponTierColor(semAtributos, _wearing({0: 80})), isNull);
  });
}
