import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/market_index.dart';
import '../../../search/domain/matcher.dart';
import '../../../search/domain/presets.dart';
import '../../../search/domain/search_query.dart';
import '../../../search/domain/search_query_url.dart';
import '../../../search/ui/search_state.dart';

/// Live numbers off the collected market, each one a way in.
///
/// This is the argument, not decoration: the gap between the cheapest and the
/// dearest character carrying the same weapon tier is the whole reason the
/// filter exists, and a visitor sees it before reading a word about features.
///
/// Every figure is computed from the index, never written down. A hardcoded
/// "830 personagens" would be wrong within the hour — the market moved 36
/// listings in two hours on the day this was built.
///
/// Each figure is also a link to the search that produced it. Reading "205 com
/// arma de 70 de ataque" and having to then find that same question inside a
/// form is the long way round to a screen that is one tap away.
///
/// Every count comes from `runQuery` over the query the figure opens, rather
/// than from a scan written here. Counted two different ways, the front page
/// and the filter drift, and the page ends up promising a market the next
/// screen contradicts.
class MarketPulse extends StatelessWidget {
  const MarketPulse({
    required this.state,
    required this.wide,
    this.large = false,
    super.key,
  });

  /// Null while the index is still loading, or if it failed. The strip then
  /// reserves its space quietly instead of flashing zeros — and the button
  /// under it does not jump when the numbers arrive.
  final SearchReady? state;

  final bool wide;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ready = state;
    if (ready == null) return SizedBox(height: wide ? 84 : 150);

    final index = ready.index;
    final figures = <_Figure>[
      _Figure(
        '${index.characters.length}',
        'personagens à venda',
        const SearchQuery(),
        index,
      ),
    ];

    final weapon = strongWeaponQuery(index);
    if (weapon != null) {
      final strong = runQuery(index, weapon);
      if (strong.isNotEmpty) {
        figures.add(
          _Figure(
            '${strong.length}',
            'com arma de 70 de ataque',
            weapon,
            index,
          ),
        );
        // `runQuery` orders by cheapest first, which is the default and also
        // what this figure is asking for.
        figures.add(
          _Figure(
            '${strong.first.price} TCC',
            'o mais barato deles',
            weapon,
            index,
          ),
        );
      }
    }

    final nuemaWearers = runQuery(index, nuemaQuery);
    if (nuemaWearers.isNotEmpty) {
      figures.add(
        _Figure(
          '${nuemaWearers.length}',
          'com o Portal de Nuema',
          nuemaQuery,
          index,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: large ? 48 : (wide ? 34 : 22),
      runSpacing: 18,
      children: [
        for (final figure in figures)
          _Stat(figure: figure, wide: large || wide, large: large),
      ],
    );
  }
}

class _Figure {
  const _Figure(this.value, this.label, this.query, this.index);

  final String value;
  final String label;

  /// The search this figure counted, and the one tapping it opens.
  final SearchQuery query;

  /// Needed to write the link: an attribute is written by name, and the name
  /// lives here.
  final MarketIndex index;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.figure, required this.wide, required this.large});

  final _Figure figure;
  final bool wide;
  final bool large;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: () {
      // The whole search travels in the route name, so the address bar is
      // right on arrival rather than being corrected a frame later.
      final query = encodeQuery(figure.query, figure.index);
      Navigator.of(
        context,
      ).pushNamed(query.isEmpty ? '/filtro' : '/filtro?$query');
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            figure.value,
            style: TextStyle(
              fontSize: large ? 36 : (wide ? 30 : 24),
              fontWeight: FontWeight.w800,
              color: PWColors.accent,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            figure.label,
            style: TextStyle(
              color: PWColors.textMuted,
              fontSize: large ? 13 : 12,
            ),
          ),
        ],
      ),
    ),
  );
}
