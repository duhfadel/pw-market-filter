import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/market/counted_items.dart';

/// LeRato, role 330640, saved on 2026-08-25. A level 105 Feiticeira, and the
/// page was chosen for one reason: she carries **both** legendary pets and has
/// **renamed both of them**.
///
/// That is the whole case this file exists for. A pet's name belongs to its
/// owner — the same `38587` reads *Ovo de Harpia* on three other characters
/// and *GabirÚ* here — so the name cannot be the identity, and the id is.
/// Exactly the reverse of the counted relics, where the name is the identity
/// and the id was unknown.
void main() {
  late List<ParsedStack> inventory;

  setUpAll(() {
    inventory = parseInventory(
      File('test/fixtures/detail_330640.html').readAsStringSync(),
    );
  });

  ParsedStack? stackOf(int itemId) =>
      inventory.where((s) => s.itemId == itemId).firstOrNull;

  test('the pets are already collected, with no change to the crawler', () {
    // They are `li[data-item]` like everything else in the inventory, so the
    // reader that counts relics has been carrying them since 2026-08-19. This
    // filter costs no request at all.
    expect(stackOf(countedItemIds['Harpia']!), isNotNull);
    expect(stackOf(countedItemIds['Hércules']!), isNotNull);
  });

  test('the name on the page is the owner\'s, not the species', () {
    // If the filter went by name, as the relics do, it would miss precisely
    // the people who own one — naming the pet is what you do when you have it.
    expect(stackOf(38587)!.name, 'GabirÚ');
    expect(stackOf(37905)!.name, 'CariocA');
  });

  test('one of each is one of each, not a stack', () {
    expect(stackOf(38587)!.count, 1);
    expect(stackOf(37905)!.count, 1);
  });

  test('a character without them simply has no such stack', () {
    final guerreiro = parseInventory(
      File('test/fixtures/detail_64112.html').readAsStringSync(),
    );

    expect(guerreiro.where((s) => s.itemId == 38587), isEmpty);
    expect(guerreiro.where((s) => s.itemId == 37905), isEmpty);
  });
}
