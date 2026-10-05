import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

/// The founder rung, where the raw title the page printed becomes a number.
///
/// It is read here and not in the parser on purpose: the ladder is a fact
/// about the game, and the state keeps `Fundador X` whole, so correcting this
/// is `--rebuild` — seconds — rather than another eighty-three-minute crawl.
void main() {
  ListingCard card(int roleId) => ListingCard(
    roleId: roleId,
    name: 'n$roleId',
    characterClass: 'Guerreiro',
    occupation: 0,
    level: 105,
    price: 100,
    fame: 0,
    cultivation: 'Majestoso X',
  );

  ParsedTitles titles(String founder) => ParsedTitles(
    decoded: 1,
    inOctet: 1,
    equipped: '',
    attributes: const {},
    founder: founder,
  );

  int? tierOf(ParsedTitles? t) {
    final builder = IndexBuilder(server: 'pw187', collectedAt: DateTime.now());
    builder.add(card(1), const [], titles: t);
    return builder.build().characters.single.founderTier;
  }

  test('each of the ten figures becomes its own rung', () {
    const figuras = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
    ];
    for (var i = 0; i < figuras.length; i++) {
      expect(tierOf(titles('Fundador ${figuras[i]}')), i + 1);
    }
  });

  test('no founder title is null, never nought', () {
    // Nought would read as a rung, and "has none" is not rung zero.
    expect(tierOf(titles('')), isNull);
    expect(tierOf(null), isNull);
  });

  test('a founder name the ladder cannot place is dropped, not guessed', () {
    // A wrong rung sorts somebody into a pack they never bought, which is
    // worse than saying nothing — the same call `CelestialRealm` makes.
    expect(tierOf(titles('Fundador Ilustre')), isNull);
    expect(tierOf(titles('Fundador XI')), isNull);
    expect(tierOf(titles('Fundador')), isNull);
  });

  test('a title that merely begins with the word is not a founder', () {
    expect(tierOf(titles('Fundadores da Cidade')), isNull);
  });

  test('the real page carries it all the way to the index', () {
    // Through the state's codec as well, because that is the trip that has
    // already lost a field once.
    final html = File('test/fixtures/detail_2192.html').readAsStringSync();
    final page = CollectedPage(
      items: const [],
      cards: const [],
      sex: '',
      titles: parseTitles(html),
    );
    final restored = CollectedPage.fromJson(page.toJson('pw187'), const {});

    expect(tierOf(restored.titles), 10);
  });
}
