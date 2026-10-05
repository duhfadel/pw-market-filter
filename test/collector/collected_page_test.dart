import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

/// The collector's state file is the contract between a collection and every
/// `--rebuild` after it, and it is the one thing a fresh crawl cannot recover
/// cheaply: a field dropped here costs fifty minutes to read again.
///
/// It went untested until 2026-08-19, and it had already lost `require_level`
/// that way — parsed, carried into a live index, and absent from the state, so
/// a rebuild wrote an index poorer than the collection that fed it.
void main() {
  late CollectedPage page;

  setUpAll(() {
    final html = File('test/fixtures/detail_64112.html').readAsStringSync();
    page = CollectedPage(
      items: parseEquippedItems(html),
      cards: parseEquippedCards(html),
      sex: parseSex(html),
      anecdotes: parseAnecdotes(html),
      inventory: parseInventory(html),
      realm: parseCelestialRealm(html) ?? '',
      path: parsePath(html) ?? '',
      runes: parseRunes(html),
      titles: parseTitles(html),
    );
  });

  /// Through real JSON, because a `Map` handed straight back would hide the
  /// one thing that matters: what survives being written to disk.
  CollectedPage roundTrip(CollectedPage page) {
    final names = itemNamesOf([page]);
    final json =
        jsonDecode(jsonEncode(page.toJson('pw187'))) as Map<String, dynamic>;
    return CollectedPage.fromJson(json, names);
  }

  test('the worn items come back whole, levels included', () {
    final weapon = roundTrip(page).items.singleWhere((i) => i.slot == 10);

    expect(weapon.itemId, 50206);
    expect(weapon.refine, 12);
    expect(weapon.stones, [51112, 51112]);
    expect(weapon.attributes['Nível de Ataque'], [70]);
    expect(weapon.attributes['HP'], [500, 150, 150]);
    expect(weapon.requireLevel, 100);
    expect(weapon.weaponLevel, 17);
  });

  test('the anecdotes and the six cards come back', () {
    final restored = roundTrip(page);

    expect(restored.anecdotes?.done, 1265);
    expect(restored.anecdotes?.total, 2756);
    expect(restored.anecdotes?.lines, 107);
    expect(restored.cards, hasLength(6));
    expect(restored.sex, 'Masculino');
  });

  test('the inventory comes back named, out of the shared table', () {
    // The names are written once for the whole file. If the table and the
    // counts ever stop agreeing, the counted items resolve to nothing and the
    // filter quietly matches nobody.
    final relic = roundTrip(
      page,
    ).inventory.singleWhere((s) => s.itemId == 54687);

    expect(relic.name, 'Relíquia Maravilha: Artefato');
    expect(relic.count, 22);
    expect(roundTrip(page).inventory, hasLength(292));
  });

  test('an entry written by an older collector is refused, not adapted', () {
    // It is missing the very fields the re-collection is for. Keeping it would
    // leave most of the market without them and nothing on screen saying why.
    final old = {...page.toJson('pw187')}..remove('v');

    expect(CollectedPage.isCurrent(old, 'pw187'), isFalse);
    expect(CollectedPage.isCurrent(page.toJson('pw187'), 'pw187'), isTrue);
  });

  test('a page whose site has no anecdote panel is still current', () {
    // Absent is a legitimate reading. If it were the staleness signal, that
    // character would be fetched again on every run for ever.
    final json = CollectedPage(
      items: const [],
      cards: const [],
      sex: '',
      inventory: const [],
    ).toJson('pw187');

    expect(CollectedPage.isCurrent(json, 'pw187'), isTrue);
    expect(CollectedPage.fromJson(json, const {}).anecdotes, isNull);
  });

  test('the sheet comes back: realm, path and every rune', () {
    final restored = roundTrip(page);

    expect(restored.realm, 'Céu Ápice VIII');
    expect(restored.path, 'Evil');
    expect(restored.runes, hasLength(6));
    expect(restored.runes.first.type, 'Argêntea');
    expect(restored.runes.first.level, 6);
    expect(restored.runes.first.skillName, 'ΨIra do Paraíso');
  });

  test('the titles summary survives the disk, founder included', () {
    final leandrim = roundTrip(page).titles!;

    expect(leandrim.decoded, 400);
    expect(leandrim.attributes['Nível de ataque'], 2);
    // He has 400 titles and not one is a founder's.
    expect(leandrim.founder, '');

    final html = File('test/fixtures/detail_2192.html').readAsStringSync();
    final comFundador = roundTrip(
      CollectedPage(
        items: const [],
        cards: const [],
        sex: '',
        titles: parseTitles(html),
      ),
    ).titles!;

    expect(comFundador.founder, 'Fundador X');
    expect(comFundador.equipped, 'Filha dos Dragões');
    expect(comFundador.attributes['Nível de ataque'], 24);
  });

  test('a page with no titles panel stays null across the disk', () {
    // Not an empty summary: unknown and none are different facts, and only
    // the first may read as unknown.
    final json = CollectedPage(
      items: const [],
      cards: const [],
      sex: '',
      titles: null,
    ).toJson('pw187');

    expect(json.containsKey('titles'), isFalse);
    expect(CollectedPage.fromJson(json, const {}).titles, isNull);
  });

  test(
    'the stamp is per marketplace, so one version pays for its own field',
    () {
      // Measured on 2026-10-04: the 1.2.6 asked for its slot counts, its pets
      // and its crafting skills, and none of the three exists on a 1.8.7 page.
      // With one shared number, bumping it would have spent eighty-four minutes
      // of their server's traffic re-reading 1.8.7 pages that could not gain a
      // thing. The cost of a field falls on the version that gains it.
      final pagina = CollectedPage(items: const [], cards: const [], sex: '');

      expect(CollectedPage.isCurrent(pagina.toJson('pw126'), 'pw126'), isTrue);
      // The same bytes, read as the other marketplace, are stale — which is
      // exactly how a 1.2.6-only bump leaves the 1.8.7 state alone.
      expect(CollectedPage.isCurrent(pagina.toJson('pw126'), 'pw187'), isFalse);
      expect(
        CollectedPage.versaoDe('pw126'),
        isNot(CollectedPage.versaoDe('pw187')),
      );
    },
  );

  test('an unknown marketplace is stale, never silently current', () {
    // A typo in a server key must re-fetch rather than accept whatever the
    // state happens to hold: a wrong profile reading a stale entry is how a
    // collection ends up publishing another version's data.
    final pagina = CollectedPage(items: const [], cards: const [], sex: '');

    expect(CollectedPage.versaoDe('pw144'), 0);
    expect(CollectedPage.isCurrent(pagina.toJson('pw187'), 'pw144'), isFalse);
  });

  test('the stamp moved, so every older entry is fetched again', () {
    // Realm, path and runes are in no state written before them, and the
    // titles panel is in none written before 2026-10-02 — which is what makes
    // each re-collection happen by itself rather than needing a flag.
    expect(CollectedPage.versaoDe('pw187'), greaterThan(3));
  });
}
