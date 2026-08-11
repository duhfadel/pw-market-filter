import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/card_combos.dart';
import '../search_state.dart';
import '../search_view_model.dart';

/// Filters on the six War Avatar cards a character wears.
///
/// Two ways in, because the named combos are only as complete as a hand-written
/// table. `Combo` asks for a specific set; `Todas S` asks for six cards of a
/// rarity whatever the set is called, and that one keeps working for a combo
/// nobody has named yet.
class CardSection extends StatelessWidget {
  const CardSection({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final query = state.query;
    final anyCards = state.index.characters.any((c) => c.cards.isNotEmpty);
    // An index collected before cards existed has none. Offering the filter
    // then would return zero for everything, which reads like a broken market.
    if (!anyCards) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        const SizedBox(height: 10),
        _comboField(query.comboName),
        const SizedBox(height: 10),
        _rarityField(query.cardRarity),
        CheckboxListTile(
          value: query.cardsMaxed,
          onChanged: (v) => viewModel.setCardsMaxed(v ?? false),
          dense: true,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: PWColors.accent,
          checkColor: PWColors.background,
          title: const Text(
            'Todas no nível máximo',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      children: [
        const Text(
          'CARTAS',
          style: TextStyle(
            color: PWColors.textMuted,
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider()),
      ],
    ),
  );

  Widget _comboField(String? value) {
    // How many characters wear each combo, so a filter that will return three
    // results says so before it is applied.
    final wearers = {
      for (final combo in cardCombos)
        combo.name: state.index.characters
            .where(
              (c) => c.cards
                  .map((card) => card.cardId)
                  .toSet()
                  .containsAll(combo.cardIds),
            )
            .length,
    };

    return DropdownButtonFormField<String?>(
      initialValue: value,
      isExpanded: true,
      itemHeight: 58,
      decoration: const InputDecoration(labelText: 'Combo completo'),
      dropdownColor: PWColors.surfaceRaised,
      selectedItemBuilder: (_) => [
        const Align(alignment: Alignment.centerLeft, child: Text('Qualquer')),
        for (final combo in cardCombos)
          Align(alignment: Alignment.centerLeft, child: Text(combo.name)),
      ],
      items: [
        const DropdownMenuItem(value: null, child: Text('Qualquer')),
        for (final combo in cardCombos)
          DropdownMenuItem(
            value: combo.name,
            child: Row(
              children: [
                for (final id in combo.cardIds.take(3)) ...[
                  ItemIcon(id, size: 20),
                  const SizedBox(width: 2),
                ],
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(combo.name, overflow: TextOverflow.ellipsis),
                      Text(
                        'seis cartas ${combo.rarity}  ·  '
                        '${wearers[combo.name]} personagens',
                        style: const TextStyle(
                          fontSize: 11,
                          color: PWColors.ok,
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
      onChanged: viewModel.setCombo,
    );
  }

  Widget _rarityField(String? value) => DropdownButtonFormField<String?>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Raridade das seis'),
    dropdownColor: PWColors.surfaceRaised,
    items: const [
      DropdownMenuItem(value: null, child: Text('Qualquer')),
      DropdownMenuItem(value: 'S', child: Text('Todas S')),
      DropdownMenuItem(value: 'A', child: Text('Todas A')),
      DropdownMenuItem(value: 'B', child: Text('Todas B')),
    ],
    onChanged: viewModel.setCardRarity,
  );
}
