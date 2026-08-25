import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/counted_items.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// The Feiticeira's two combat pets, as a list to tick.
///
/// A plain filter, and not the counted items' *mark to show, type to filter*:
/// a pet is a yes or a no, so there is no number to compare across characters
/// and nothing for a mark to add that passing the filter does not already say.
///
/// **No picture beside each name, on purpose.** The two eggs are the same
/// 32 px file — byte for byte, checked — because in the game the art belongs to
/// the creature and the item is the egg it comes out of. Two identical
/// pictures beside two different names would promise a difference that is not
/// there, which is the same defect as naming an item without its number. The
/// egg goes on the section's header instead, where it is true: it says
/// *mascotes*, which is the category.
class PetSection extends StatefulWidget {
  const PetSection({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<PetSection> createState() => _PetSectionState();
}

class _PetSectionState extends State<PetSection> {
  bool _open = false;

  SearchReady get state => widget.state;

  /// The pets this collection actually found, in the order they are written
  /// down rather than the order the crawl happened to meet them.
  ///
  /// One the market has none of gets no row: it could only ever return
  /// nothing, which reads as "the market has none of these" when it means
  /// "this collection never saw one".
  List<MapEntry<String, int>> get _pets => [
    for (final name in countedItemIds.keys)
      if (state.index.countedItems[name] != null)
        MapEntry(name, state.index.countedItems[name]!),
  ];

  @override
  Widget build(BuildContext context) {
    final pets = _pets;
    if (pets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(pets),
        if (_open) ...[
          for (final pet in pets) _row(pet.key),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _header(List<MapEntry<String, int>> pets) => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SectionHeader(
        title: 'Mascotes',
        emblem: pets.first.value,
        // Every tick here narrows the market, so all of them count.
        badge: state.query.pets.length,
        expanded: _open,
      ),
    ),
  );

  Widget _row(String label) => CheckboxListTile(
    value: state.query.pets.contains(label),
    onChanged: (v) => widget.viewModel.setPetRequired(label, v ?? false),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: PWColors.accent,
    checkColor: PWColors.background,
    title: Text(label, style: const TextStyle(fontSize: 13)),
  );
}
