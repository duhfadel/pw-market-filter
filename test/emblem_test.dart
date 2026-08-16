import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Pins the filter's section emblems against the collected market.
///
/// They are hand-picked item ids, which is the same shape of mistake
/// `combo_test.dart` guards against: `ItemIcon` falls back to an empty box, so
/// a wrong id draws nothing at all and the header simply looks a little bare.
/// Nobody would call that a bug on sight.
///
/// Skipped when there is no index — a fresh clone has not collected yet.
void main() {
  final file = File('web/market_index.json');
  if (!file.existsSync()) return;

  late MarketIndex index;

  setUpAll(() {
    index = MarketIndex.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  });

  test('every group emblem is an item somebody wears in that group', () {
    for (final group in slotGroups) {
      final worn = {
        for (final character in index.characters)
          for (final item in character.equipped)
            if (group.slots.contains(item.slot)) item.itemId,
      };
      expect(
        worn,
        contains(group.emblem),
        reason:
            '${group.title}: o emblema ${group.emblem} não é usado em nenhum '
            'slot do grupo',
      );
    }
  });

  test('the cards emblem is an S card somebody wears', () {
    // Cards live in `character.cards`, never in `index.items` — an emblem
    // picked out of the items map would be an equipment icon by mistake.
    final s = {
      for (final character in index.characters)
        for (final card in character.cards)
          if (card.rarity == 'S') card.cardId,
    };
    expect(s, contains(cardsEmblem));
  });

  test('every emblem has an icon file on disk', () {
    // The icon is fetched by name from the index, so a valid id with no file
    // means `fetch_icons.dart` has not been run since it appeared.
    for (final id in [
      for (final group in slotGroups) group.emblem,
      cardsEmblem,
    ]) {
      expect(
        File('assets/icons/items/$id.png').existsSync(),
        isTrue,
        reason: 'falta assets/icons/items/$id.png',
      );
    }
  });
}
