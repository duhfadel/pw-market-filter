import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/market/counted_items.dart';
import 'package:pw_market_filter/market/market_index.dart';

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

  group('anecdotes and counted items', () {
    IndexBuilder builder() =>
        IndexBuilder(server: 'pw187', collectedAt: DateTime.utc(2026, 8, 9));

    const relic = ParsedStack(
      itemId: 54687,
      name: 'Relíquia Maravilha: Artefato',
      count: 22,
    );
    const junk = ParsedStack(itemId: 60017, name: 'Pó Reparador', count: 5448);

    test('keeps the count of a counted item and nothing else', () {
      // The character owns 292 distinct items. Carrying all of them into the
      // index would be a second inventory per character for the sake of four
      // numbers the screen asks about.
      final index =
          (builder()..add(_card(1), const [], inventory: const [junk, relic]))
              .build();

      expect(index.characters.single.counts, {54687: 22});
    });

    test('resolves the counted name to the id the market actually used', () {
      final index =
          (builder()..add(_card(1), const [], inventory: const [relic]))
              .build();

      expect(index.countedItems['Relíquia Maravilha: Artefato'], 54687);
    });

    test('a name nobody carries is absent rather than guessed at', () {
      // The `Chave da Sorte` may not be in the market at all, and its id is
      // unknown. An invented one yields a filter that quietly matches nobody.
      final index =
          (builder()..add(_card(1), const [], inventory: const [relic]))
              .build();

      expect(index.countedItems.containsKey('Chave da Sorte'), isFalse);
      expect(countedItemNames, contains('Chave da Sorte'));
    });

    test('carries the anecdote pair, and leaves it null when unread', () {
      final index =
          (builder()
                ..add(
                  _card(1),
                  const [],
                  anecdotes: const ParsedAnecdotes(
                    done: 1265,
                    total: 2756,
                    lines: 107,
                  ),
                )
                ..add(_card(2), const []))
              .build();

      expect(index.characters.first.anecdotes?.done, 1265);
      expect(index.characters.first.anecdotes?.total, 2756);
      expect(index.characters.last.anecdotes, isNull);
    });

    test('both survive a round trip through JSON', () {
      final index =
          (builder()..add(
                _card(1),
                const [],
                anecdotes: const ParsedAnecdotes(
                  done: 1265,
                  total: 2756,
                  lines: 107,
                ),
                inventory: const [relic],
              ))
              .build();

      final restored = MarketIndex.fromJson(
        jsonDecode(jsonEncode(index.toJson())) as Map<String, dynamic>,
      );

      expect(restored.countedItems, {'Relíquia Maravilha: Artefato': 54687});
      expect(restored.characters.single.counts, {54687: 22});
      expect(restored.characters.single.anecdotes?.done, 1265);
    });

    test('a read inventory carrying none of them says zero, not nothing', () {
      // "Carries none" and "was never read" have to be different on the card:
      // one prints `carrega 0` and the other prints no line at all. They were
      // the same empty map until the counts were filled in at build time.
      final index =
          (builder()
                ..add(_card(1), const [], inventory: const [junk])
                ..add(_card(2), const [], inventory: const [relic]))
              .build();

      expect(index.characters.first.counts, {54687: 0});
      expect(index.characters.last.counts, {54687: 22});
    });

    test('a character whose page never loaded keeps an empty map', () {
      final index =
          (builder()
                ..add(_card(1), const [])
                ..add(_card(2), const [], inventory: const [relic]))
              .build();

      expect(index.characters.first.counts, isEmpty);
    });

    test('a pet is resolved by id, whatever its owner called it', () {
      // The name on the page is a nickname. Matching by it would miss exactly
      // the owners — naming the pet is what you do when you have one.
      const apelidado = ParsedStack(itemId: 38587, name: 'GabirÚ', count: 1);

      final index =
          (builder()..add(_card(1), const [], inventory: const [apelidado]))
              .build();

      expect(index.countedItems['Harpia'], 38587);
      expect(index.characters.single.counts[38587], 1);
    });

    test('a pet nobody in the market has stays absent', () {
      final index =
          (builder()..add(_card(1), const [], inventory: const [junk])).build();

      expect(index.countedItems.containsKey('Hércules'), isFalse);
      // And whoever was read gets the explicit zero for the ones that resolved.
      expect(index.characters.single.counts, isEmpty);
    });
  });

  group('the sheet: realm, path and runes', () {
    IndexBuilder builder() =>
        IndexBuilder(server: 'pw187', collectedAt: DateTime.utc(2026, 8, 28));

    const runa = ParsedRune(
      slot: 0,
      itemId: 52220,
      type: 'Argêntea',
      level: 6,
      skillId: 3931,
      skillName: 'ΨIra do Paraíso',
    );

    test('carries the realm and the path as the page wrote them', () {
      final index =
          (builder()..add(
                _card(1),
                const [],
                realm: 'Céu Ápice VIII',
                path: 'Evil',
              ))
              .build();

      expect(index.characters.single.realm, 'Céu Ápice VIII');
      expect(index.characters.single.path, 'Evil');
    });

    test('an unread sheet leaves both empty rather than inventing one', () {
      final index = (builder()..add(_card(1), const [])).build();

      expect(index.characters.single.realm, isEmpty);
      expect(index.characters.single.path, isEmpty);
    });

    test('the runes go in by slot, and their kind into one table', () {
      // The same kind has two item ids — Áurea 5 is both 52179 and 200359 —
      // so the table is what lets a filter treat them as one rune.
      final index =
          (builder()..add(
                _card(1),
                const [],
                runes: const [
                  runa,
                  ParsedRune(
                    slot: 1,
                    itemId: 200359,
                    type: 'Áurea',
                    level: 5,
                    skillId: 1,
                    skillName: 'x',
                  ),
                ],
              ))
              .build();

      expect(index.characters.single.runes, [52220, 200359]);
      expect(index.runes[52220]?.type, 'Argêntea');
      expect(index.runes[52220]?.level, 6);
      expect(index.runes[200359]?.level, 5);
    });

    test('all three survive a round trip through JSON', () {
      final index =
          (builder()..add(
                _card(1),
                const [],
                realm: 'Céu Soberano X',
                path: 'God',
                runes: const [runa],
              ))
              .build();

      final restored = MarketIndex.fromJson(
        jsonDecode(jsonEncode(index.toJson())) as Map<String, dynamic>,
      );

      expect(restored.characters.single.realm, 'Céu Soberano X');
      expect(restored.characters.single.path, 'God');
      expect(restored.characters.single.runes, [52220]);
      expect(restored.runes[52220]?.type, 'Argêntea');
    });
  });
}
