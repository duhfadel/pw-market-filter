import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/card_combos.dart';
import '../../../search/ui/search_state.dart';

/// Live numbers off the collected market.
///
/// This is the argument, not decoration: the gap between the cheapest and the
/// dearest character carrying the same weapon tier is the whole reason the
/// filter exists, and a visitor sees it before reading a word about features.
///
/// Every figure is computed from the index, never written down. A hardcoded
/// "830 personagens" would be wrong within the hour — the market moved 36
/// listings in two hours on the day this was built.
class MarketPulse extends StatelessWidget {
  const MarketPulse({
    required this.state,
    required this.wide,
    this.large = false,
    super.key,
  });

  /// Null while the index is still loading, or if it failed. The strip then
  /// reserves its space quietly instead of flashing zeros.
  final SearchReady? state;

  final bool wide;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ready = state;
    if (ready == null) return SizedBox(height: wide ? 84 : 150);

    final characters = ready.index.characters;
    final attackLevel = ready.index.attributes.indexOf('Nível de Ataque');

    final strong = attackLevel < 0
        ? const <int>[]
        : characters
              .where(
                (c) => c.equipped.any(
                  (i) => i.slot == 10 && (i.attributes[attackLevel] ?? 0) >= 70,
                ),
              )
              .map((c) => c.price)
              .toList();
    strong.sort();

    final nuemaWearers = characters
        .where(
          (c) => c.cards
              .map((card) => card.cardId)
              .toSet()
              .containsAll(nuema.cardIds),
        )
        .length;

    final stats = <(String, String)>[
      ('${characters.length}', 'personagens à venda'),
      if (strong.isNotEmpty) ('${strong.length}', 'com arma de 70 de ataque'),
      if (strong.isNotEmpty) ('${strong.first} TCC', 'o mais barato deles'),
      if (nuemaWearers > 0) ('$nuemaWearers', 'com o Portal de Nuema'),
    ];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: large ? 48 : (wide ? 34 : 22),
      runSpacing: 18,
      children: [
        for (final (value, label) in stats)
          _Stat(value, label, large || wide, large),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label, this.wide, this.large);

  final String value;
  final String label;
  final bool wide;
  final bool large;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: large ? 36 : (wide ? 30 : 24),
          fontWeight: FontWeight.w800,
          color: PWColors.accent,
          height: 1.1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(color: PWColors.textMuted, fontSize: large ? 13 : 12),
      ),
    ],
  );
}
