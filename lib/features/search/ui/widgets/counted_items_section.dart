import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/counted_items.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'number_field.dart';
import 'section_header.dart';

/// How many of the counted items a character is carrying — the three
/// `Relíquia Maravilha` and the `Chave da Sorte`.
///
/// Two questions per item, and they are not the same one. **Marking shows the
/// number on every card; typing a minimum filters.** They used to be one
/// control, which meant the only way to see how many relics somebody carries
/// was to demand at least one and lose everybody else from the results.
///
/// The number field appears only once the item is marked: you say which items
/// interest you, and then, if you want, how many. Everything starts unmarked,
/// so the section asks nothing and shows nothing until it is touched.
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
        badge: state.query.minimumOwned.length,
        expanded: _open,
      ),
    ),
  );

  Widget _row(String name, int itemId) {
    final shown = state.query.shownOwned.contains(name);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: shown,
          onChanged: (v) => widget.viewModel.setOwnedShown(name, v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: PWColors.accent,
          checkColor: PWColors.background,
          // The item's own art beside its name, for the same reason the
          // section headers carry one: a column of four long names that begin
          // with the same two words is read by its pictures.
          secondary: ItemIcon(itemId, size: 26),
          title: Text(
            name,
            style: const TextStyle(fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (shown) ...[
          const SizedBox(height: 4),
          _minimum(name, itemId),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  /// The hint is the most anyone in the current results carries, so nobody
  /// types a number the market cannot meet.
  Widget _minimum(String name, int itemId) {
    final most = state.facetsFor(FacetDimension.owned).mostOwned(itemId);

    return NumberField(
      label: 'pelo menos',
      hint: most == 0 ? null : 'qualquer, até $most',
      value: state.query.minimumOwned[name],
      onChanged: (value) => widget.viewModel.setMinimumOwned(name, value),
    );
  }
}
