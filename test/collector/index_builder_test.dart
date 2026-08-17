import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

ListingCard _card(int roleId) => ListingCard(
  roleId: roleId,
  name: 'p$roleId',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 1,
  cultivation: 'Leal',
);

ParsedItem _item(Map<String, List<int>> attributes) => ParsedItem(
  slot: 10,
  itemId: 50206,
  grade: 6,
  name: '★★★Dilacerador Raivoso',
  refine: 12,
  stones: const [],
  attributes: attributes,
);

void main() {
  group('reducing repeated attributes', () {
    test('a stacking bonus totals', () {
      // The fixture weapon lists HP +500, +150, +150. Those are one pool of
      // hit points; reporting 500 understates the item by 300.
      expect(reduceAttribute('HP', [500, 150, 150]), 800);
    });

    test('attack level takes the principal, not the sum', () {
      // Confirmed by the player against the site: ★★★Clareza Abençoada shows
      // Nível de Ataque +70 with a +2 beneath it. The weapon is a 70. Summing
      // calls it 72 and sorts it above every genuine 70 in the dropdown.
      expect(reduceAttribute('Nível de Ataque', [70, 2]), 70);
      expect(reduceAttribute('Nível de Ataque', [70, 1]), 70);
    });

    test('the principal is the largest, whatever order it came in', () {
      expect(reduceAttribute('Nível de Ataque', [1, 70]), 70);
    });

    test('defence and guard level follow the same rule as attack level', () {
      expect(reduceAttribute('Nível de Defesa', [7, 2]), 7);
      expect(reduceAttribute('Nível de Guarda', [350, 5]), 350);
    });

    test('a single occurrence is itself under either rule', () {
      expect(reduceAttribute('HP', [500]), 500);
      expect(reduceAttribute('Nível de Ataque', [70]), 70);
    });

    test('an unknown attribute totals, which is the safe default', () {
      expect(reduceAttribute('Atributo #3818', [13, 4]), 17);
    });
  });

  group('building the index', () {
    test('applies the rules on the way in', () {
      final builder = IndexBuilder(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
      );
      builder.add(_card(1), [
        _item({
          'Nível de Ataque': [70, 1],
          'HP': [500, 150],
        }),
      ]);

      final index = builder.build();
      final weapon = index.characters.single.equipped.single;
      final attack = index.attributes.indexOf('Nível de Ataque');
      final hp = index.attributes.indexOf('HP');

      expect(weapon.attributes[attack], 70);
      expect(weapon.attributes[hp], 650);
    });

    test('an attribute with no occurrences is left out entirely', () {
      final builder = IndexBuilder(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
      );
      builder.add(_card(1), [
        _item({'Nível de Ataque': const []}),
      ]);

      expect(
        builder.build().characters.single.equipped.single.attributes,
        isEmpty,
      );
    });

    test('the same item worn by two characters is stored once', () {
      final builder = IndexBuilder(
        server: 'pw187',
        collectedAt: DateTime.utc(2026, 8, 9),
      );
      builder
        ..add(_card(1), [
          _item({
            'Nível de Ataque': [70],
          }),
        ])
        ..add(_card(2), [
          _item({
            'Nível de Ataque': [70],
          }),
        ]);

      final index = builder.build();
      expect(index.items, hasLength(1));
      expect(index.characters, hasLength(2));
      expect(index.attributes, ['Nível de Ataque']);
    });
  });
}
