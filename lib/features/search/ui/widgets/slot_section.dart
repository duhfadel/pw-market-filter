import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/slot_names.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// A group of slots — Arma, Set, Acessórios — with one item picker each.
///
/// Collapsed by default except the weapon, because fourteen dropdowns open at
/// once is a wall. The header carries how many of the group's slots are being
/// filtered, so a collapsed section can never hide a condition that is in
/// force: the count is what makes closing it safe.
class SlotSection extends StatefulWidget {
  const SlotSection({
    required this.group,
    required this.state,
    required this.viewModel,
    required this.startsOpen,
    super.key,
  });

  final SlotGroup group;
  final SearchReady state;
  final SearchViewModel viewModel;
  final bool startsOpen;

  @override
  State<SlotSection> createState() => _SlotSectionState();
}

class _SlotSectionState extends State<SlotSection> {
  late bool _open = widget.startsOpen;

  @override
  Widget build(BuildContext context) {
    // A slot nobody in the market wears has nothing to offer, and an empty
    // dropdown is worse than no dropdown.
    final slots = widget.group.slots
        .where(
          (slot) => widget.state
              .facetsFor(FacetDimension.items)
              .itemsIn(slot)
              .isNotEmpty,
        )
        .toList(growable: false);
    if (slots.isEmpty) return const SizedBox.shrink();

    final active = slots
        .where((slot) => widget.state.query.itemBySlot.containsKey(slot))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: SectionHeader(
              title: widget.group.title,
              emblem: widget.group.emblem,
              badge: active,
              expanded: _open,
            ),
          ),
        ),
        if (_open)
          for (final slot in slots)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemPicker(
                slot: slot,
                state: widget.state,
                viewModel: widget.viewModel,
              ),
            ),
      ],
    );
  }
}

/// Picks the exact item worn in one slot.
///
/// Every row carries the item's picture and, for anything with one, its attack
/// level — the number is what separates two weapons whose names differ by a
/// single word.
class _ItemPicker extends StatelessWidget {
  const _ItemPicker({
    required this.slot,
    required this.state,
    required this.viewModel,
  });

  final int slot;
  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final items = state
        .facetsFor(FacetDimension.items)
        .itemsIn(slot, characterClass: state.query.characterClass);
    if (items.isEmpty) return const SizedBox.shrink();

    final label = slotLabel(slot);
    final chosen = state.query.itemBySlot[slot];
    final valid = items.any((i) => i.itemId == chosen) ? chosen : null;

    return DropdownButtonFormField<int?>(
      initialValue: valid,
      isExpanded: true,
      itemHeight: 58,
      decoration: InputDecoration(labelText: label),
      dropdownColor: PWColors.surfaceRaised,
      selectedItemBuilder: (_) => [
        _closed('Qualquer $label', null, null),
        for (final item in items)
          _closed(item.name, item.itemId, item.attackLevelText),
      ],
      items: [
        DropdownMenuItem(value: null, child: Text('Qualquer $label')),
        for (final item in items)
          DropdownMenuItem(
            value: item.itemId,
            child: Row(
              children: [
                ItemIcon(item.itemId),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(color: PWColors.grade(item.grade)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.detail,
                        style: TextStyle(
                          fontSize: 11,
                          color: item.attackLevel == null
                              ? PWColors.textMuted
                              : PWColors.ok,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: (itemId) => viewModel.setItemInSlot(slot, itemId),
    );
  }

  /// The closed field is one line: the picture, the name, and the attack level
  /// pinned to the right.
  ///
  /// Keeping the number out of the ellipsized text is the whole point. With it
  /// inside the label, a long item name eats it — and the number is the one
  /// thing the name cannot be trusted to tell you.
  Widget _closed(String text, int? itemId, String? attackLevel) => Row(
    children: [
      if (itemId != null) ...[
        ItemIcon(itemId, size: 22),
        const SizedBox(width: 8),
      ],
      Expanded(child: Text(text, overflow: TextOverflow.ellipsis, maxLines: 1)),
      if (attackLevel != null) ...[
        const SizedBox(width: 6),
        Text(
          attackLevel,
          style: const TextStyle(
            color: PWColors.ok,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ],
  );
}
