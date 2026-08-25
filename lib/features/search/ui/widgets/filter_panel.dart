import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/slot_names.dart';
import '../../domain/index_facets.dart';
import '../../domain/search_query.dart';
import '../../domain/item_criterion.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'card_section.dart';
import 'anecdote_section.dart';
import 'counted_items_section.dart';
import 'criterion_row.dart';
import 'number_field.dart';
import 'pet_section.dart';
import 'section_header.dart';
import 'slot_section.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final query = state.query;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _classDropdown(
          state.facetsFor(FacetDimension.characterClass),
          query.characterClass,
        ),
        const SizedBox(height: 10),
        _range(
          label: 'Preço (TCC)',
          min: query.minPrice,
          max: query.maxPrice,
          hintMin: state.facetsFor(FacetDimension.price).lowestPrice,
          hintMax: state.facetsFor(FacetDimension.price).highestPrice,
          onChanged: viewModel.setPriceRange,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < slotGroups.length; i++)
          SlotSection(
            group: slotGroups[i],
            state: state,
            viewModel: viewModel,
            // Only the weapon opens by itself. It is the slot that decides a
            // character's price, and fourteen dropdowns open at once is a wall.
            startsOpen: i == 0,
          ),
        CardSection(state: state, viewModel: viewModel),
        PetSection(state: state, viewModel: viewModel),
        CountedItemsSection(state: state, viewModel: viewModel),
        AnecdoteSection(state: state, viewModel: viewModel),
        const SizedBox(height: 12),
        const SectionHeader(title: 'Por atributo'),
        const SizedBox(height: 12),
        for (var i = 0; i < query.criteria.length; i++)
          CriterionRow(
            // The key is the position, so replacing a criterion in place does
            // not carry the previous row's text-field state along with it.
            key: ValueKey('criterion-$i'),
            criterion: query.criteria[i],
            facets: state.allFacets,
            onChanged: (criterion) => viewModel.replaceCriterion(i, criterion),
            onRemoved: () => viewModel.removeCriterion(i),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _canAddCriterion ? _addCriterion : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('adicionar critério'),
            style: TextButton.styleFrom(foregroundColor: PWColors.accent),
          ),
        ),
        if (!query.isEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: viewModel.clear,
              style: TextButton.styleFrom(foregroundColor: PWColors.textMuted),
              child: const Text('limpar tudo'),
            ),
          ),
        ],
      ],
    );
  }

  bool get _canAddCriterion => state.allFacets.slots.isNotEmpty;

  /// A new row starts on the weapon and asks nothing else. Pre-selecting an
  /// attribute — even the commonest one — puts a condition on screen that
  /// nobody asked for, and the user has to work out why it is there before
  /// they can start.
  void _addCriterion() =>
      viewModel.addCriterion(const ItemCriterion(slot: weaponSlot));

  /// The class picker, with each class's portrait beside its name. It is the
  /// first thing anybody sets, and it is what narrows every item list below —
  /// every class has its own weapons and its own best one among them.
  Widget _classDropdown(IndexFacets facets, String? value) =>
      DropdownButtonFormField<String?>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Classe'),
        dropdownColor: PWColors.surfaceRaised,
        items: [
          const DropdownMenuItem(value: null, child: Text('Todas as classes')),
          for (final name in facets.classes)
            DropdownMenuItem(
              value: name,
              child: Row(
                children: [
                  ClassIcon(facets.occupationOf[name] ?? -1, size: 22),
                  const SizedBox(width: 8),
                  Expanded(child: Text(name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
        ],
        onChanged: viewModel.setClass,
      );

  Widget _range({
    required String label,
    required int? min,
    required int? max,
    required int hintMin,
    required int hintMax,
    required void Function(int?, int?) onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
      ),
      const SizedBox(height: 6),
      Row(
        children: [
          Expanded(
            child: _number(
              value: min,
              hint: hintMin.toString(),
              onChanged: (v) => onChanged(v, max),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('—', style: TextStyle(color: PWColors.textMuted)),
          ),
          Expanded(
            child: _number(
              value: max,
              hint: hintMax.toString(),
              onChanged: (v) => onChanged(min, v),
            ),
          ),
        ],
      ),
    ],
  );

  /// An empty field means "no limit" — not zero. Reading blank as zero would
  /// silently exclude everything below it.
  Widget _number({
    required int? value,
    required String hint,
    required ValueChanged<int?> onChanged,
  }) => NumberField(value: value, hint: hint, onChanged: onChanged);
}
