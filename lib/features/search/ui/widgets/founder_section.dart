import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/romanos.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// The founder packs, asked for as a floor: *a partir de*.
///
/// **It draws nothing at all when the market holds no founder.** Every index
/// collected before 2026-10-02 has the field on nobody, and a menu whose only
/// entry empties the results reads as a broken page rather than as an honest
/// one — the same guard [RealmSection] makes for an index with no realms.
///
/// The menu is built from [IndexFacets.founderTiers], so it can only ever
/// offer packs somebody on screen actually bought. A hardcoded I-to-X list
/// would offer ten rungs where the market has one.
class FounderSection extends StatefulWidget {
  const FounderSection({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<FounderSection> createState() => _FounderSectionState();
}

class _FounderSectionState extends State<FounderSection> {
  bool _open = false;

  SearchReady get state => widget.state;

  @override
  Widget build(BuildContext context) {
    final degraus = state.facetsFor(FacetDimension.founder).founderTiers;
    if (degraus.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        if (_open) ...[
          const SizedBox(height: 10),
          _campo(degraus),
          const SizedBox(height: 6),
          _nota(),
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
        title: 'Fundador',
        // A glyph and not a borrowed item picture: the title is not an item,
        // and the mount that came with the pack would stand for one pack.
        glyph: Icons.workspace_premium_outlined,
        badge: state.query.minFounderTier == null ? 0 : 1,
        expanded: _open,
      ),
    ),
  );

  /// One menu, not a tick plus a rung. *Qualquer* is the floor at its lowest,
  /// so one control covers both "a founder, any" and "a Fundador X" — and a
  /// second control for the same idea is how two of them come to disagree.
  ///
  /// **The lowest pack the market holds is not listed**, because *qualquer
  /// fundador* already is it: with IV the cheapest on screen, an entry for IV
  /// would return exactly what the entry above it returns, and two controls
  /// giving one answer is how a form walks somebody in a circle.
  Widget _campo(List<int> degraus) {
    final oferecidos = [
      for (final g in degraus)
        if (g > degraus.first) g,
    ];

    return DropdownButtonFormField<int?>(
      initialValue: _escolhido(degraus, oferecidos),
      isExpanded: true,
      decoration: const InputDecoration(labelText: 'A partir de'),
      dropdownColor: PWColors.surfaceRaised,
      items: [
        const DropdownMenuItem(value: null, child: Text('Ninguém em especial')),
        const DropdownMenuItem(value: 1, child: Text('Qualquer fundador')),
        for (final grau in oferecidos)
          DropdownMenuItem(
            value: grau,
            child: Text('Fundador ${romanoDe(grau)}'),
          ),
      ],
      onChanged: widget.viewModel.setMinFounderTier,
    );
  }

  /// Which entry to show as chosen — never a value the menu does not carry.
  ///
  /// A `DropdownButton` asserts when its value is absent from its own items,
  /// and the door into that here is a month-old link: `fundador=IV` against a
  /// market whose cheapest pack has since become IV itself, or VII after the
  /// last VII left. Anything at or below the floor shows as *qualquer*, which
  /// is what it now means; anything the market no longer holds falls back to
  /// the same, which widens by one rung rather than throwing the page away.
  int? _escolhido(List<int> degraus, List<int> oferecidos) {
    final pedido = state.query.minFounderTier;
    if (pedido == null) return null;
    return oferecidos.contains(pedido) ? pedido : 1;
  }

  /// Why the filter is worth using, in the game's own words.
  ///
  /// **"Recompensa exclusiva de pré-lançamento" is what the title itself
  /// says**, and that is deliberately not the same sentence as "these can no
  /// longer be obtained". The second is a claim about what The Classic will
  /// do next, and this site speaks for nobody but itself — the line the
  /// permission to exist is drawn on. The first is quoted, checkable, and
  /// says the same thing to anyone who reads it.
  ///
  /// The mounts and flights are not decoration either: both characters
  /// measured carry items whose own description reads *"Montaria exclusiva do
  /// pacote Fundador…"* and *"Voo exclusiva do pacote Fundador…"*. Voos and
  /// not asas, because the two seen are a fox and a Gu Diao beast.
  Widget _nota() => const Padding(
    padding: EdgeInsets.only(right: 4, bottom: 2),
    child: Text(
      'Recompensa exclusiva de pré-lançamento. Quem tem um título de '
      'Fundador carrega montarias, voos e outros itens do pacote.',
      style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.4),
    ),
  );
}
