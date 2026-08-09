import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/slot_names.dart';
import '../../domain/index_facets.dart';
import '../../domain/item_criterion.dart';
import 'number_field.dart';

/// One line of the item filter: slot, attribute, minimum, minimum refine.
///
/// The attribute list is rebuilt from the chosen slot, so it never offers a
/// bonus that slot does not carry. Each entry says how many characters have it
/// and how high it goes, which is what stops you typing a minimum nobody meets.
class CriterionRow extends StatelessWidget {
  const CriterionRow({
    required this.criterion,
    required this.facets,
    required this.onChanged,
    required this.onRemoved,
    super.key,
  });

  final ItemCriterion criterion;
  final IndexFacets facets;
  final ValueChanged<ItemCriterion> onChanged;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    final attributes = facets.attributesIn(criterion.slot);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PWColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _slotField()),
              IconButton(
                onPressed: onRemoved,
                icon: const Icon(Icons.close, size: 18),
                color: PWColors.textMuted,
                tooltip: 'Remover critério',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _rankField()),
              const SizedBox(width: 8),
              Expanded(child: _refineField()),
            ],
          ),
          const SizedBox(height: 8),
          _attributeField(attributes),
          if (criterion.attributeId != null) ...[
            const SizedBox(height: 8),
            _minimumField(),
          ],
        ],
      ),
    );
  }

  Widget _slotField() => DropdownButtonFormField<int?>(
    initialValue: criterion.slot,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Slot'),
    dropdownColor: PWColors.surfaceRaised,
    items: [
      const DropdownMenuItem(value: null, child: Text('Qualquer slot')),
      for (final slot in facets.slots)
        DropdownMenuItem(value: slot, child: Text(_slotText(slot))),
    ],
    onChanged: (slot) {
      // The attribute may not exist in the new slot. Keeping it would show a
      // dropdown with a value that is not in its own list, and Flutter throws
      // on that — so fall back to the commonest attribute the slot does have.
      final available = facets.attributesIn(slot);
      final keeps = available.any(
        (a) => a.attributeId == criterion.attributeId,
      );
      // An attribute the new slot does not carry has to go: keeping it would
      // leave the dropdown showing a value absent from its own items, which
      // Flutter throws on. Falling back to "no attribute" rather than to some
      // other one keeps the criterion asking only what the user asked.
      onChanged(
        criterion.copyWith(
          slot: () => slot,
          attributeId: () => keeps ? criterion.attributeId : null,
        ),
      );
    },
  );

  /// An unnamed slot is identified by what is usually found in it — always
  /// right, because it comes from the collected data.
  String _slotText(int slot) {
    final label = slotLabel(slot);
    if (slotNames.containsKey(slot)) return label;
    final example = facets.exampleItemIn(slot);
    return example.isEmpty ? label : '$label · ex.: $example';
  }

  /// Rank is the stars in the item's name: no stars is 1, `★★★` is 4. It says
  /// nothing about the attribute — ★★★Dilacerador Raivoso gives 70 attack
  /// level and ★★★Geada Tardia gives none — so it earns its own field.
  Widget _rankField() => DropdownButtonFormField<int>(
    initialValue: criterion.minimumRank,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Rank mín.'),
    dropdownColor: PWColors.surfaceRaised,
    items: const [
      DropdownMenuItem(value: 0, child: Text('Qualquer')),
      DropdownMenuItem(value: 2, child: Text('★ rank 2')),
      DropdownMenuItem(value: 3, child: Text('★★ rank 3')),
      DropdownMenuItem(value: 4, child: Text('★★★ rank 4')),
    ],
    onChanged: (rank) => onChanged(criterion.copyWith(minimumRank: rank ?? 0)),
  );

  Widget _attributeField(List<AttributeFacet> attributes) {
    if (attributes.isEmpty) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Nenhum atributo neste slot.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 12),
        ),
      );
    }

    final selected =
        attributes.any((a) => a.attributeId == criterion.attributeId)
        ? criterion.attributeId
        : null;

    return DropdownButtonFormField<int?>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Atributo'),
      dropdownColor: PWColors.surfaceRaised,
      items: [
        // Without this the criterion cannot ask about the item alone — "a rank
        // 4 weapon at +11" needs no attribute, and demanding one turns a real
        // question into an unaskable one.
        const DropdownMenuItem(value: null, child: Text('Nenhum')),
        for (final attribute in attributes)
          DropdownMenuItem(
            value: attribute.attributeId,
            child: Text(
              '${attribute.name}  ·  ${attribute.characterCount} '
              '(máx ${attribute.highestValue})',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (id) => onChanged(criterion.copyWith(attributeId: () => id)),
    );
  }

  Widget _minimumField() => NumberField(
    value: criterion.minimum,
    label: 'Mínimo',
    onChanged: (value) => onChanged(criterion.copyWith(minimum: value ?? 0)),
  );

  Widget _refineField() => NumberField(
    value: criterion.minimumRefine,
    label: 'Refino mín.',
    onChanged: (value) =>
        onChanged(criterion.copyWith(minimumRefine: value ?? 0)),
  );
}
