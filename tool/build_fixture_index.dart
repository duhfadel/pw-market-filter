// Builds an index out of the saved fixtures, with no network.
//
//   dart run tool/build_fixture_index.dart
//
// It is the whole market's roster with one character's gear — enough to see
// the screen work before a real collection has run, and enough to catch a
// pipeline that produces an index the app cannot read.

import 'dart:convert';
import 'dart:io';

import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

void main() {
  final listing = parseListing(
    File('test/fixtures/listing_pw187.html').readAsStringSync(),
  );
  final page = File('test/fixtures/detail_64112.html').readAsStringSync();
  final items = parseEquippedItems(page);

  final builder = IndexBuilder(
    server: 'pw187',
    collectedAt: DateTime.now().toUtc(),
  );
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

  final index = builder.build();
  final json = jsonEncode(index.toJson());
  File('web/market_index.json').writeAsStringSync(json);

  stdout
    ..writeln('web/market_index.json — ${(json.length / 1024).round()} KB')
    ..writeln('  personagens: ${index.characters.length}')
    ..writeln(
      '  com equipamento: '
      '${index.characters.where((c) => c.equipped.isNotEmpty).length}',
    )
    ..writeln('  atributos: ${index.attributes.length}')
    ..writeln('  itens contados: ${index.countedItems.length}');
}
