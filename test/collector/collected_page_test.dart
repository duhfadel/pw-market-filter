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
    );
  });

  /// Through real JSON, because a `Map` handed straight back would hide the
  /// one thing that matters: what survives being written to disk.
  CollectedPage roundTrip(CollectedPage page) {
    final names = itemNamesOf([page]);
    final json = jsonDecode(jsonEncode(page.toJson())) as Map<String, dynamic>;
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
    final old = {...page.toJson()}..remove('v');

    expect(CollectedPage.isCurrent(old), isFalse);
    expect(CollectedPage.isCurrent(page.toJson()), isTrue);
  });

  test('a page whose site has no anecdote panel is still current', () {
    // Absent is a legitimate reading. If it were the staleness signal, that
    // character would be fetched again on every run for ever.
    final json = CollectedPage(
      items: const [],
      cards: const [],
      sex: '',
      inventory: const [],
    ).toJson();

    expect(CollectedPage.isCurrent(json), isTrue);
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

  test('the stamp moved, so every older entry is fetched again', () {
    // Realm, path and runes are in no state written before them, which is what
    // makes the re-collection happen by itself.
    expect(CollectedPage.version, greaterThan(2));
  });
}
