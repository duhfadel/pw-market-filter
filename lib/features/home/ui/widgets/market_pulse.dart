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
/// The chips the front page turns into a figure, and how each one reads here.
///
/// The key is the chip's label in `presets.dart` and the value is the front
/// page's wording for it: `Arma de 70 ou mais` is a thing to tap on the filter
/// and `687 com arma de 70 ou mais` is a sentence on the home. One question,
/// two readings — but the question itself is written once, over there.
///
/// **Not every chip earns a figure**, and the map is where that is decided.
/// The figures are the page's argument rather than a menu of the filter, so
/// three chips deliberately have none: somebody who wants *Seis cartas S* is
/// already looking for it, while the gap between the cheapest and the dearest
/// character wearing the same weapon tier is the thing a first-time visitor
/// has to be shown before reading a word about features.
const figureLabels = <String, String>{
  'Arma de 70 ou mais': 'com arma de 70 ou mais',
  'Atq lvl UP5': 'com Atq lvl UP5',
  'Def lvl UP5': 'com Def lvl UP5',
  'Portal de Nuema': 'com o Portal de Nuema',
};

/// The chip whose results also give the page its second figure — the cheapest
/// character carrying that weapon.
///
/// That one number is the whole argument: 45 TCC against the 8000 somebody
/// else asks for the same tier. It is a second reading of one search and not a
/// search of its own, which is why it borrows the chip rather than naming one.
const _cheapestOf = 'Arma de 70 ou mais';

/// One number on the front page, and the search that produced it.
class MarketFigure {
  const MarketFigure({
    required this.value,
    required this.label,
    required this.query,
    required this.index,
    required this.presetLabel,
  });

  final String value;
  final String label;

  /// The search this figure counted, and the one tapping it opens.
  final SearchQuery query;

  /// Needed to write the link: an attribute is written by name, and the name
  /// lives here.
  final MarketIndex index;

  /// The chip in `presets.dart` this figure borrowed its question from, or
  /// `null` for the one figure that is not a chip — the market entire.
  final String? presetLabel;
}

/// The front page's figures, in the order the chips are in.
///
/// **Every question comes from `presetsFor`**, and that is the point of this
/// function existing at all. The figures were assembled here by hand until
/// 29/09/2026 — this file looked up `Nível de Ataque` and built its own
/// `SearchQuery` — while the chips were built in `presets.dart`, and the two
/// drifted the first time the chips changed: the set gained *5 essências* and
/// lost a weapon tier, and the front page followed none of it, because nothing
/// connected them. Counted two different ways, the front page and the filter
/// promise a market the next screen contradicts.
///
/// Reading the chips also means a chip that this collection cannot build —
/// `weaponQuery` answers `null` for a tier the market has not reached — takes
/// its figure off the page by itself, instead of leaving a nought behind.
List<MarketFigure> figuresFor(MarketIndex index) {
  final figures = <MarketFigure>[
    MarketFigure(
      value: '${index.characters.length}',
      label: 'personagens à venda',
      query: const SearchQuery(),
      index: index,
      presetLabel: null,
    ),
  ];

  for (final preset in presetsFor(index)) {
    final label = figureLabels[preset.label];
    if (label == null) continue;

    // Counted with `runQuery` over the query the figure opens, never with a
    // scan written here: the number and the screen it leads to have to be the
    // same answer.
    final found = runQuery(index, preset.query);
    if (found.isEmpty) continue;

    figures.add(
      MarketFigure(
        value: '${found.length}',
        label: label,
        query: preset.query,
        index: index,
        presetLabel: preset.label,
      ),
    );

    if (preset.label == _cheapestOf) {
      // `runQuery` orders by cheapest first, which is the default and also
      // what this figure is asking for.
      figures.add(
        MarketFigure(
          value: '${found.first.price} TCC',
          label: 'o mais barato deles',
          query: preset.query,
          index: index,
          presetLabel: preset.label,
        ),
      );
    }
  }

  return figures;
}

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

    final figures = figuresFor(ready.index);

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

class _Stat extends StatelessWidget {
  const _Stat({required this.figure, required this.wide, required this.large});

  final MarketFigure figure;
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
