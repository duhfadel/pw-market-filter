import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/counted_items.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// How many of the counted items a character is carrying — the three
/// `Relíquia Maravilha` and the `Chave da Sorte`.
///
/// One question per item: **show me how many of this each character carries** —
/// and, once it is marked, *at least how many*.
///
/// The mark and the minimum are one control on purpose. A *pelo menos N* field
/// stood beside the mark once and was dropped, because a field asking for a
/// number nobody can size is a guess: the market's maximum is around 130 and
/// the useful cut is 30, and nothing on the screen said so. The slider only
/// appears once the relic is marked, ends at the market's 95th percentile
/// rather than at its outlier, and prints what the choice costs — *30 ou mais
/// — 291 personagens* — before the choice is made.
///
/// It starts at zero, which asks nothing, so marking alone still only prints a
/// number. Everything starts unmarked, and the section shows nothing until it
/// is touched.
class CountedItemsSection extends StatefulWidget {
  const CountedItemsSection({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<CountedItemsSection> createState() => _CountedItemsSectionState();
}

class _CountedItemsSectionState extends State<CountedItemsSection> {
  bool _open = false;

  SearchReady get state => widget.state;

  /// The counted items this collection actually found, in the order they are
  /// written down rather than the order the crawl happened to meet them.
  ///
  /// A name the market has none of gets no field: it could only ever return
  /// nothing, which reads as "the market has none of these" when it means
  /// "this collection never saw one".
  /// The id is only the picture. A label can gather several ids and the
  /// count adds them all up (`MarketIndex.countOf`), but the row needs one
  /// sprite and they are the same item to a reader — so the first is as true
  /// as any, and nothing here is counted from it.
  List<MapEntry<String, int>> get _counted => [
    for (final label in countedItemGroups.keys)
      if (state.index.countedItems[label]?.isNotEmpty ?? false)
        MapEntry(label, state.index.countedItems[label]!.first),
  ];

  @override
  Widget build(BuildContext context) {
    final counted = _counted;
    if (counted.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(counted),
        if (_open) ...[
          for (final item in counted) _row(item.key, item.value),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _header(List<MapEntry<String, int>> counted) => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SectionHeader(
        title: 'Relíquias e chaves',
        // The first counted item the collection found, so the emblem is a
        // picture of the thing rather than a glyph meaning "some section".
        emblem: counted.first.value,
        // Counts what is marked. Every minimum in force sits under a mark, so
        // this can never be smaller than the number of filters hiding inside.
        badge: state.query.shownOwned.length,
        expanded: _open,
      ),
    ),
  );

  Widget _row(String name, int itemId) {
    final marked = state.query.shownOwned.contains(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: marked,
          onChanged: (v) => widget.viewModel.setOwnedShown(name, v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: PWColors.accent,
          checkColor: PWColors.background,
          // The item's own art beside its name, for the same reason the section
          // headers carry one: four long names that begin with the same two
          // words are read by their pictures.
          secondary: ItemIcon(itemId, size: 26),
          title: Row(
            children: [
              // `Flexible` and no `Spacer`: a Spacer beside a Flexible splits
              // the free space with it, which is what once crushed the
              // nicknames on the card to `NI…`.
              Flexible(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (countedItemsInTest.contains(name)) ...[
                const SizedBox(width: 7),
                const _BetaBadge(),
              ],
            ],
          ),
        ),
        if (marked) _slider(name, itemId),
      ],
    );
  }

  Widget _slider(String name, int itemId) {
    final facets = state.facetsFor(FacetDimension.owned);
    final ceiling = facets.ceilingOwned(name);
    // A market where nobody carries one has no track to draw and no question
    // to ask — the mark alone still prints the zero.
    if (ceiling < 1) return const SizedBox.shrink();

    final chosen = (state.query.minimumOwned[name] ?? 0).clamp(0, ceiling);

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 4, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              // No tick marks. There is one division per relic and the market
              // reaches fifty of them, so they draw a dashed line rather than
              // stops anybody could aim at — and the number under the track is
              // what the value is read from anyway.
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: Slider(
              value: chosen.toDouble(),
              max: ceiling.toDouble(),
              // One stop per relic: the number is a count of things, and a
              // slider that lands between two of them would be lying.
              divisions: ceiling,
              activeColor: PWColors.accent,
              inactiveColor: PWColors.border,
              onChanged: (v) =>
                  widget.viewModel.setOwnedMinimum(name, v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              // What the choice costs, said before it is made. Without it the
              // slider is a number with no scale — which is exactly why the
              // text field it replaced was dropped.
              chosen == 0
                  ? 'qualquer quantidade'
                  : '$chosen ou mais — '
                        '${facets.carriersOwning(name, chosen)} personagens',
              style: const TextStyle(fontSize: 11, color: PWColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Says that a counted line is still being checked against the game.
///
/// Outlined rather than filled, and the reason is measured: `accent` on
/// `accentDim` is 4.35 against `surface`'s 10.32, and the whole palette here
/// sits between 6.5 and 8. At 9 px the filled version was the one thing on the
/// panel nobody could read.
class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: PWColors.accent),
      borderRadius: BorderRadius.circular(5),
    ),
    child: const Text(
      'BETA TEST',
      style: TextStyle(
        color: PWColors.accent,
        fontSize: 9,
        letterSpacing: 0.8,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
