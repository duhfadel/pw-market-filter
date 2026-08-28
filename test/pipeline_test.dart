import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/features/search/domain/index_facets.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/celestial_realm.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// End to end over the real pages, with no network: listing → detail → index →
/// JSON → query. Each piece has its own tests; this one exists because the
/// seams between them are where an index can come out empty while every unit
/// test stays green.
void main() {
  late MarketIndex index;

  setUpAll(() {
    final listing = parseListing(
      File('test/fixtures/listing_pw187.html').readAsStringSync(),
    );
    final page = File('test/fixtures/detail_64112.html').readAsStringSync();
    final items = parseEquippedItems(page);

    final builder = IndexBuilder(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 8, 9, 14),
    );
    // Only Leandrim's detail page was saved, so he is the only character with
    // gear. The rest go in bare, exactly as a half-finished collection would
    // leave them.
    for (final card in listing) {
      final his = card.roleId == 64112;
      builder.add(
        card,
        his ? items : const [],
        anecdotes: his ? parseAnecdotes(page) : null,
        inventory: his ? parseInventory(page) : const [],
        realm: his ? parseCelestialRealm(page) ?? '' : '',
        path: his ? parsePath(page) ?? '' : '',
        runes: his ? parseRunes(page) : const [],
      );
    }
    index = builder.build();
  });

  test('carries every character the listing had', () {
    expect(index.characters, hasLength(779));
  });

  test('interns each attribute name once', () {
    expect(index.attributes.toSet(), hasLength(index.attributes.length));
    expect(index.attributes, contains('Nível de Ataque'));
  });

  test('survives a round trip through JSON unchanged', () {
    final restored = MarketIndex.fromJson(
      jsonDecode(jsonEncode(index.toJson())) as Map<String, dynamic>,
    );

    expect(restored.server, 'pw187');
    expect(restored.collectedAt, index.collectedAt);
    expect(restored.characters, hasLength(779));
    expect(restored.attributes, index.attributes);

    final leandrim = restored.characters.singleWhere((c) => c.roleId == 64112);
    final weapon = leandrim.equipped.singleWhere((i) => i.slot == 10);
    expect(restored.items[weapon.itemId]?.name, '★★★Dilacerador Raivoso');
    expect(weapon.refine, 12);
    expect(weapon.stones, [51112, 51112]);
  });

  test('finds the +70 weapon that the site itself cannot filter for', () {
    final attackLevel = index.attributes.indexOf('Nível de Ataque');
    final matches = runQuery(
      index,
      SearchQuery(
        criteria: [
          ItemCriterion(slot: 10, attributeId: attackLevel, minimum: 70),
        ],
      ),
    );

    expect(matches.map((c) => c.name), ['Leandrim']);
  });

  test('a minimum above what anyone reaches finds nobody', () {
    final attackLevel = index.attributes.indexOf('Nível de Ataque');
    final matches = runQuery(
      index,
      SearchQuery(
        criteria: [
          ItemCriterion(slot: 10, attributeId: attackLevel, minimum: 71),
        ],
      ),
    );

    expect(matches, isEmpty);
  });

  test('the weapon slot offers Attack Level, and says how high it goes', () {
    final weapon = IndexFacets(
      index,
    ).attributesIn(10).singleWhere((f) => f.name == 'Nível de Ataque');

    expect(weapon.characterCount, 1);
    expect(weapon.highestValue, 70);
  });

  test('a character with no gear is kept, and matches no item criterion', () {
    final attackLevel = index.attributes.indexOf('Nível de Ataque');
    final bare = index.characters.firstWhere((c) => c.equipped.isEmpty);

    expect(
      matchesQuery(
        index,
        bare,
        SearchQuery(
          criteria: [ItemCriterion(attributeId: attackLevel, minimum: 1)],
        ),
      ),
      isFalse,
    );
    expect(matchesQuery(index, bare, const SearchQuery()), isTrue);
  });

  test('the three relics travel from the page to the index', () {
    // The whole seam in one line: the inventory JSON on the page, summed by
    // the parser, resolved by name in the builder, counted here.
    final leandrim = index.characters.singleWhere((c) => c.roleId == 64112);

    expect(
      leandrim.counts[index.countedItems['Relíquia Maravilha: Artefato']],
      22,
    );
    expect(leandrim.counts[index.countedItems['Relíquia Maravilha: Arma']], 16);
  });

  test('the counted names the market showed are resolved, the rest absent', () {
    expect(index.countedItems, {
      'Relíquia Maravilha: Artefato': 54687,
      'Relíquia Maravilha: Arma': 50410,
      'Relíquia Maravilha: Armadura': 70020,
    });
  });

  test('the anecdotes filter the market, and an unread page is not zero', () {
    expect(
      runQuery(index, const SearchQuery(minAnecdotes: 1265)).map((c) => c.name),
      ['Leandrim'],
    );
    expect(runQuery(index, const SearchQuery(minAnecdotes: 1266)), isEmpty);
    // The other 778 were never read. They fail the filter without pretending
    // to be at zero.
    expect(index.characters.where((c) => c.anecdotes == null), hasLength(778));
  });

  test('the sheet travels from the page to a filter and an order', () {
    // Leandrim is Céu Ápice VIII and Evil, with six runes, and he is the only
    // character in this index whose page was read.
    final rung = CelestialRealm.parse('Céu Ápice VIII')!.ordinal;

    expect(runQuery(index, SearchQuery(minRealm: rung)).map((c) => c.name), [
      'Leandrim',
    ]);
    expect(runQuery(index, SearchQuery(minRealm: rung + 1)), isEmpty);
    expect(
      runQuery(index, const SearchQuery(path: 'Evil')).map((c) => c.name),
      ['Leandrim'],
    );
    expect(runQuery(index, const SearchQuery(path: 'God')), isEmpty);
  });

  test('his runes are counted by kind, not by item id', () {
    // Two of his six are level 7 or better — Argêntea 7 and Áurea 7 — so
    // asking for three finds nobody.
    expect(
      runQuery(
        index,
        const SearchQuery(runes: RuneCriterion(minimumLevel: 7, minimum: 2)),
      ).map((c) => c.name),
      ['Leandrim'],
    );
    expect(
      runQuery(
        index,
        const SearchQuery(runes: RuneCriterion(minimumLevel: 7, minimum: 3)),
      ),
      isEmpty,
    );
  });

  test('ordering by realm puts the unread last in both directions', () {
    final maior = runQuery(
      index,
      const SearchQuery(order: ResultOrder.highestRealm),
    );
    final menor = runQuery(
      index,
      const SearchQuery(order: ResultOrder.lowestRealm),
    );

    expect(maior.first.name, 'Leandrim');
    expect(menor.first.name, 'Leandrim');
    expect(maior.last.realm, isEmpty);
    expect(menor.last.realm, isEmpty);
  });
}
