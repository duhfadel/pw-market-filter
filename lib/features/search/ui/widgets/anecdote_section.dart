import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'number_field.dart';
import 'section_header.dart';

/// How far through the game's anecdotes a character is.
///
/// Its own section, and not a line inside the items one, because it is a
/// different kind of fact: everything else in this form is something the
/// character owns or wears and can be bought with it. The anecdotes are time
/// spent, and they do not come with the account in the same way.
///
/// Two questions, as with the counted items: **marking prints the number on
/// every card, typing a minimum filters.** The minimum appears only once it is
/// marked, so seeing how far along somebody is never costs the rest of the
/// results.
///
/// Everything starts unmarked and empty, which is what makes it safe to ship
/// while a collection is still in flight: half the market has no anecdotes
/// read yet, and a filter nobody has set cannot refuse them.
class AnecdoteSection extends StatefulWidget {
  const AnecdoteSection({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  State<AnecdoteSection> createState() => _AnecdoteSectionState();
}

class _AnecdoteSectionState extends State<AnecdoteSection> {
  bool _open = false;

  SearchReady get state => widget.state;

  @override
  Widget build(BuildContext context) {
    // An index collected before the field has none. Offering the filter then
    // would return zero for everything, which reads as a broken market rather
    // than an old collection.
    if (state.index.characters.every((c) => c.anecdotes == null)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        if (_open) ...[
          _mark(),
          if (state.query.showsAnecdotes) ...[
            const SizedBox(height: 4),
            _field(),
          ],
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
        title: 'Anedotas',
        // A book, because there is no item to show: the anecdotes are a tab on
        // the character's page, not something in a bag.
        glyph: Icons.auto_stories_outlined,
        // Same job as the count on a slot group: a closed section must say
        // what it is holding, or the results look wrong with nothing on screen
        // explaining why.
        // The badge counts filters, not marks: marking narrows nothing and
        // must not read as a filter in force.
        badge: state.query.minAnecdotes != null ? 1 : 0,
        expanded: _open,
      ),
    ),
  );

  /// Ticked by anything that puts the number on the cards, so the box never
  /// sits unticked beside a line it is supposed to govern.
  Widget _mark() => CheckboxListTile(
    value: state.query.showsAnecdotes,
    onChanged: (v) => widget.viewModel.setAnecdotesShown(v ?? false),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    activeColor: PWColors.accent,
    checkColor: PWColors.background,
    title: const Text('Mostrar no card', style: TextStyle(fontSize: 13)),
  );

  /// The hint is the range the current results actually cover — the same
  /// service the price and level ranges do, so nobody types a number the
  /// market cannot meet.
  Widget _field() {
    final facets = state.facetsFor(FacetDimension.anecdotes);

    return NumberField(
      label: 'Anedotas a partir de',
      hint: facets.highestAnecdotes == 0
          ? null
          : '${facets.lowestAnecdotes} a ${facets.highestAnecdotes}',
      value: state.query.minAnecdotes,
      onChanged: widget.viewModel.setMinAnecdotes,
    );
  }
}
