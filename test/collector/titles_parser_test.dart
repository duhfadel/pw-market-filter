import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

/// The `Títulos` panel of a character page.
///
/// Four real pages, picked for the spread they give: one with a founder title
/// and 646 others, one with 400 and no equipped title at all, one with a long
/// list and no attack level in its summary, and one with six.
void main() {
  late String maloquivera; // 2192, Fundador X
  late String leandrim; // 64112, 400 titles, nothing equipped
  late String leRato; // 330640
  late String magro; // 11076, six titles

  setUpAll(() {
    maloquivera = File('test/fixtures/detail_2192.html').readAsStringSync();
    leandrim = File('test/fixtures/detail_64112.html').readAsStringSync();
    leRato = File('test/fixtures/detail_330640.html').readAsStringSync();
    magro = File('test/fixtures/detail_11076.html').readAsStringSync();
  });

  group('the summary', () {
    test('counts the titles the page says it decoded', () {
      expect(parseTitles(maloquivera)!.decoded, 646);
      expect(parseTitles(leandrim)!.decoded, 400);
      expect(parseTitles(magro)!.decoded, 6);
    });

    test('keeps the octet total, which is the larger of the two', () {
      // 656 against 646: the page itself reports more in the octet than it
      // can name, and flattening the two into one number would hide that.
      expect(parseTitles(maloquivera)!.inOctet, 656);
    });

    test('names the equipped title, and says nothing when none is', () {
      expect(parseTitles(maloquivera)!.equipped, 'Filha dos Dragões');
      expect(parseTitles(leRato)!.equipped, 'Águia do Trovão');
      expect(parseTitles(leandrim)!.equipped, '');
    });

    test('carries what the titles add up to', () {
      final total = parseTitles(maloquivera)!.attributes;
      expect(total['Nível de ataque'], 24);
      expect(total['Nível de defesa'], 24);
      expect(total['HP'], 4303);
      expect(total['Defesa física'], 6535);
    });

    test('an attribute the summary does not list is absent, never zero', () {
      // Leandrim's summary carries an attack level; LeRato's does not list
      // one at all. Zero would assert the titles grant none, which nobody
      // checked — the same distinction `counts` draws for the counted items.
      expect(parseTitles(leandrim)!.attributes['Nível de ataque'], 2);
      expect(
        parseTitles(leRato)!.attributes.containsKey('Nível de ataque'),
        isFalse,
      );
    });
  });

  group('the founder title', () {
    test('is read exactly as the page writes it', () {
      expect(parseTitles(maloquivera)!.founder, 'Fundador X');
    });

    test('is empty on a character who has none, however many titles he has', () {
      // 400 titles and not one of them a founder: a long list is not evidence.
      expect(parseTitles(leandrim)!.founder, '');
      expect(parseTitles(leRato)!.founder, '');
      expect(parseTitles(magro)!.founder, '');
    });
  });

  test(
    'a page with no panel at all yields nothing rather than an empty one',
    () {
      // "The page has no titles panel" and "the character has no titles" are
      // different facts, and only the first may ever read as unknown.
      expect(parseTitles('<html><body>nada</body></html>'), isNull);
    },
  );
}
