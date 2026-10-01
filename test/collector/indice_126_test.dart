import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser_126.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Builds a 1.2.6 index out of the two saved detail fixtures plus the
/// listing fixture, exactly as `tool/collect.dart --server pw126` would from
/// a state file holding those two role ids. No network, no `dart:io` outside
/// this test file.
MarketIndex _indiceDasFixtures126() {
  final listing = parseListing(
    File('test/fixtures/listing_pw126.html').readAsStringSync(),
  );
  final builder = IndexBuilder(
    server: 'pw126',
    collectedAt: DateTime.utc(2026, 10, 1),
  );

  const fixtures = {
    229217: 'test/fixtures/detail_pw126_229217.html',
    5424: 'test/fixtures/detail_pw126_5424.html',
  };

  for (final entry in fixtures.entries) {
    final card = listing.singleWhere((c) => c.roleId == entry.key);
    final html = File(entry.value).readAsStringSync();
    builder.add(card, parseEquippedItems126(html), sex: parseSex126(html));
  }

  return builder.build();
}

void main() {
  test(
    'an index built from the 1.2.6 fixtures carries our attribute names',
    () {
      final index = _indiceDasFixtures126();
      expect(index.server, 'pw126');
      expect(index.attributes, contains('Dano máximo'));
      expect(index.attributes, contains('Resistência ao fogo'));
      // And none of the game's own column names leaked through.
      expect(index.attributes, isNot(contains('damage_high_max')));
    },
  );

  test('both fixtures are in and their gear carried over', () {
    final index = _indiceDasFixtures126();
    expect(index.characters, hasLength(2));

    final comSeisArmas = index.characters.singleWhere(
      (c) => c.roleId == 229217,
    );
    expect(comSeisArmas.sex, 'Feminino');
    expect(comSeisArmas.equipped, hasLength(11));

    final arqueiro = index.characters.singleWhere((c) => c.roleId == 5424);
    expect(arqueiro.sex, 'Feminino');
    expect(arqueiro.equipped, hasLength(11));
  });
}
