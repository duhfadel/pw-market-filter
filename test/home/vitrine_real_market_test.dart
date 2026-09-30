import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/vitrine.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// Pins finding 1 of the 2026-09-30 final review against the real
/// collection.
///
/// `vitrineDe` used to hand back the cheapest and dearest of *at least* the
/// attack tier `strongWeaponQuery` asks for, rather than of one exact tier —
/// so on this collection it picked SK_Alya (Arcano, +70) against KING-Von
/// (Mercenário, +80): different weapons, different classes, printed under
/// "a mesma arma" with the sub-line still reading "nível de ataque 70".
///
/// Both `vitrine_test.dart` and `vitrine_view_test.dart` build synthetic
/// indexes where every carrier of the attack attribute is exactly one tier
/// — which is precisely why this defect went unexercised. This file is the
/// one that can actually fail, because the real market carries two tiers at
/// once (measured 2026-09-29: 789 carriers at exactly 70, 21 at exactly 80).
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

  int? attackLevelOf(MarketCharacter character) {
    final idAtaque = index.attributes.indexOf('Nível de Ataque');
    if (idAtaque < 0) return null;
    for (final item in character.equipped) {
      if (item.slot != weaponSlot) continue;
      return item.attributes[idAtaque];
    }
    return null;
  }

  test('barato and caro carry the exact same attack level', () {
    final v = vitrineDe(index);
    expect(v, isNotNull, reason: 'the real market has no vitrine to show');

    final nivelBarato = attackLevelOf(v!.barato);
    final nivelCaro = attackLevelOf(v.caro);

    expect(nivelBarato, isNotNull);
    expect(nivelCaro, isNotNull);
    expect(
      nivelBarato,
      nivelCaro,
      reason:
          '${v.barato.name} carries $nivelBarato and ${v.caro.name} carries '
          '$nivelCaro — "o mesmo patamar" is false if these differ',
    );
    // v.nivel is what the sub-line prints, and it has to be the number the
    // pair actually shares, not the query's minimum.
    expect(v.nivel, nivelBarato);
  });
}
