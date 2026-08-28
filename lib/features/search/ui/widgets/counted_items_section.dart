import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/counted_items.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// How many of the counted items a character is carrying — the three
/// `Relíquia Maravilha` and the `Chave da Sorte`.
///
/// One question per item: **show me how many of this each character carries.**
///
/// There was a *pelo menos N* field under each one and it was dropped. A relic
/// count is a number to compare, not a bar to clear — and *Mais relíquias*
/// already sorts by exactly what is marked here, which answers the question
/// without throwing anyone off the list. Two controls asked one question, and
/// the filtering half was the one nobody wanted.
///
/// So nothing here narrows the market. Everything starts unmarked, and the
/// section shows nothing until it is touched.
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
  List<MapEntry<String, int>> get _counted => [
    for (final name in countedItemNames)
      if (state.index.countedItems[name] != null)
        MapEntry(name, state.index.countedItems[name]!),
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
        // Counts what is being shown, not what is being filtered — nothing
        // in this section filters any more.
        badge: state.query.shownOwned.length,
        expanded: _open,
      ),
    ),
  );

  Widget _row(String name, int itemId) => CheckboxListTile(
    value: state.query.shownOwned.contains(name),
    onChanged: (v) => widget.viewModel.setOwnedShown(name, v ?? false),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: PWColors.accent,
    checkColor: PWColors.background,
    // The item's own art beside its name, for the same reason the section
    // headers carry one: four long names that begin with the same two words
    // are read by their pictures.
    secondary: ItemIcon(itemId, size: 26),
    title: Text(
      name,
      style: const TextStyle(fontSize: 13),
      overflow: TextOverflow.ellipsis,
    ),
  );
}
