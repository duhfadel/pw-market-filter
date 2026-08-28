import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/celestial_realm.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// The celestial realm, asked for as a floor: *a partir de*.
///
/// A floor and not an exact rung, because the question somebody shopping has
/// is "Majestoso for up", never "Majestoso II on the nose". The two dropdowns
/// are the two halves of how the game writes it — the realm and the step — and
/// they become one number, 1 to 100, the moment they leave this widget.
class RealmSection extends StatefulWidget {
  const RealmSection({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<RealmSection> createState() => _RealmSectionState();
}

class _RealmSectionState extends State<RealmSection> {
  bool _open = false;

  SearchReady get state => widget.state;

  int? get _tier {
    final rung = state.query.minRealm;
    return rung == null ? null : (rung - 1) ~/ 10;
  }

  int get _step {
    final rung = state.query.minRealm;
    return rung == null ? 1 : rung - ((rung - 1) ~/ 10) * 10;
  }

  @override
  Widget build(BuildContext context) {
    // An index collected before the field has no realms at all. Offering the
    // filter then would empty the market and read as a broken page.
    if (state.index.characters.every((c) => c.realm.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        if (_open) ...[
          const SizedBox(height: 10),
          _tierField(),
          const SizedBox(height: 10),
          _stepField(),
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
        title: 'Céu',
        // No item stands for a realm, so a glyph rather than a borrowed
        // picture that would mean something else.
        glyph: Icons.auto_awesome_outlined,
        badge: state.query.minRealm == null ? 0 : 1,
        expanded: _open,
      ),
    ),
  );

  Widget _tierField() => DropdownButtonFormField<int?>(
    initialValue: _tier,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'A partir de'),
    dropdownColor: PWColors.surfaceRaised,
    items: [
      const DropdownMenuItem(value: null, child: Text('Qualquer céu')),
      for (var i = 0; i < celestialTiers.length; i++)
        DropdownMenuItem(
          value: i,
          child: Text(celestialTierLabel(celestialTiers[i])),
        ),
    ],
    onChanged: (tier) =>
        widget.viewModel.setMinRealm(tier == null ? null : tier * 10 + _step),
  );

  /// Only offered once a realm is chosen: a step on its own means nothing, and
  /// a control that cannot do anything is worse than an absent one.
  Widget _stepField() {
    final tier = _tier;
    if (tier == null) return const SizedBox.shrink();

    return DropdownButtonFormField<int>(
      initialValue: _step,
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'Degrau'),
      dropdownColor: PWColors.surfaceRaised,
      items: [
        for (var step = 1; step <= 10; step++)
          DropdownMenuItem(value: step, child: Text(_romanOf(step))),
      ],
      onChanged: (step) =>
          widget.viewModel.setMinRealm(tier * 10 + (step ?? 1)),
    );
  }

  static String _romanOf(int step) => const [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
  ][step - 1];
}
