import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'number_field.dart';
import 'section_header.dart';

/// One question about the runes: **how many, of which colour, from which
/// level up.**
///
/// The quantity is what makes it a filter worth having. Measured across the
/// market's dearest characters, *at least one rune of level 7+* took 93% of
/// them — a filter that leaves the market on screen teaches nothing, which is
/// the same bar the preset chips have to clear. Three of them halves it.
///
/// The level starts at 7 and stops at 10 because below that it does not
/// separate anybody: level 5 is the commonest rune in the market and 6 is
/// nearly universal.
class RuneSection extends StatefulWidget {
  const RuneSection({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<RuneSection> createState() => _RuneSectionState();
}

class _RuneSectionState extends State<RuneSection> {
  bool _open = false;

  SearchReady get state => widget.state;
  RuneCriterion? get _asked => state.query.runes;

  /// The colours this collection actually found, so the list never offers one
  /// the market has none of.
  List<String> get _colours =>
      (state.index.runes.values.map((r) => r.type).toSet().toList())..sort();

  /// A rune of the market's own, to stand for the section. Whichever the
  /// collection met first is as good as any: they are all runes.
  int? get _emblem =>
      state.index.runes.keys.isEmpty ? null : state.index.runes.keys.first;

  @override
  Widget build(BuildContext context) {
    if (state.index.runes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        if (_open) ...[
          const SizedBox(height: 10),
          _quantity(),
          const SizedBox(height: 10),
          _colour(),
          const SizedBox(height: 10),
          _level(),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _header() => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SectionHeader(
        title: 'Runas',
        emblem: _emblem,
        badge: _asked == null ? 0 : 1,
        expanded: _open,
      ),
    ),
  );

  /// Emptying the quantity puts the whole question away, rather than leaving a
  /// colour and a level in force asking for at least zero runes — which every
  /// character in the market answers.
  Widget _quantity() => NumberField(
    label: 'Pelo menos',
    hint: '3 já corta o mercado ao meio',
    value: _asked?.minimum,
    onChanged: (value) => widget.viewModel.setRunes(
      value == null || value <= 0
          ? null
          : (_asked ?? const RuneCriterion()).copyWith(minimum: value),
    ),
  );

  Widget _colour() => DropdownButtonFormField<String?>(
    initialValue: _asked?.type,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Cor'),
    dropdownColor: PWColors.surfaceRaised,
    items: [
      const DropdownMenuItem(value: null, child: Text('Qualquer cor')),
      for (final colour in _colours)
        DropdownMenuItem(value: colour, child: Text(colour)),
    ],
    onChanged: (colour) => widget.viewModel.setRunes(
      (_asked ?? const RuneCriterion()).copyWith(type: () => colour),
    ),
  );

  Widget _level() => DropdownButtonFormField<int>(
    initialValue: _asked?.minimumLevel ?? 7,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Do nível'),
    dropdownColor: PWColors.surfaceRaised,
    items: [
      for (final level in const [7, 8, 9, 10])
        DropdownMenuItem(value: level, child: Text('$level ou mais')),
    ],
    onChanged: (level) => widget.viewModel.setRunes(
      (_asked ?? const RuneCriterion()).copyWith(minimumLevel: level ?? 7),
    ),
  );
}
