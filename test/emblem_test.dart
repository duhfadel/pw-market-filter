import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Pins the filter's section emblems against the collected market — both
/// markets, not just 1.8.7.
///
/// They are hand-picked item ids, which is the same shape of mistake
/// `combo_test.dart` guards against: `ItemIcon` falls back to an empty box, so
/// a wrong id draws nothing at all and the header simply looks a little bare.
/// Nobody would call that a bug on sight.
///
/// Before 02/10/2026 this file only ever read `slotGroups` against
/// `web/market_index.json`, so the three `slotGroups126` emblems — added the
/// same day as the market they describe — were pinned by nothing: a typo'd id
/// there would have drawn a blank box on every 1.2.6 filter and failed no
/// test. The third check below is exactly the one that would have caught the
/// 898 missing icon files that shipped alongside them (`tool/fetch_icons.dart`
/// read only the 1.8.7 index), had it been looking.
///
/// Skipped per market when there is no index for it — a fresh clone has not
/// collected yet.
void main() {
  void checarEmblemas(
    String arquivo,
    List<SlotGroup> grupos, {
    required int? Function(MarketIndex) emblemaDeCartas,
  }) {
    final file = File(arquivo);
    if (!file.existsSync()) return;

    late MarketIndex index;

    setUpAll(() {
      index = MarketIndex.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    });

    test('[$arquivo] every group emblem is an item somebody wears in that '
        'group', () {
      for (final group in grupos) {
        final worn = {
          for (final character in index.characters)
            for (final item in character.equipped)
              if (group.slots.contains(item.slot)) item.itemId,
        };
        expect(
          worn,
          contains(group.emblem),
          reason:
              '${group.title}: o emblema ${group.emblem} não é usado em '
              'nenhum slot do grupo',
        );
      }
    });

    test('[$arquivo] the cards emblem is an S card somebody wears', () {
      final emblema = emblemaDeCartas(index);
      if (emblema == null) return; // this market has no cards section at all

      final s = {
        for (final character in index.characters)
          for (final card in character.cards)
            if (card.rarity == 'S') card.cardId,
      };
      expect(s, contains(emblema));
    });

    test('[$arquivo] every emblem has an icon file on disk', () {
      // The icon is fetched by name from the index, so a valid id with no
      // file means `fetch_icons.dart` has not been run for this market since
      // the emblem appeared — exactly what happened to the three
      // `slotGroups126` ids until `--server pw126` existed to fetch them.
      final emblema = emblemaDeCartas(index);
      for (final id in [
        for (final group in grupos) group.emblem,
        ?emblema,
      ]) {
        expect(
          File('assets/icons/items/$id.png').existsSync(),
          isTrue,
          reason: 'falta assets/icons/items/$id.png',
        );
      }
    });
  }

  group('1.8.7', () {
    checarEmblemas(
      'web/market_index.json',
      slotGroups,
      // 1.8.7 is the only market with a cards section today.
      emblemaDeCartas: (_) => cardsEmblem,
    );
  });

  group('1.2.6', () {
    checarEmblemas(
      'web/market_index_126.json',
      slotGroups126,
      // 1.2.6 has no cards at all yet — see `slotGroupsFor`'s and
      // `cardsEmblem`'s own notes — so there is no emblem to pin here.
      emblemaDeCartas: (_) => null,
    );
  });
}
