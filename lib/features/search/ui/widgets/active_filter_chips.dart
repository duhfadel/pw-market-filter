import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/active_filters.dart';
import '../search_state.dart';
import '../search_view_model.dart';

/// What the form is asking, at the top of the panel, each with a way out.
///
/// It closes a dead end. The sections read their options from the characters
/// that pass every *other* filter, which is right — but when a search finds
/// nobody, every one of those lists is empty, the sections collapse, and a
/// control disappears while its filter is still in force. A weapon could be
/// filtering the market with no weapon dropdown anywhere on screen, and the
/// only way out was *limpar tudo*.
///
/// These chips come from the query, never from the market, so they cannot go
/// missing — and each one removes exactly itself.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final filters = activeFilters(state.index, state.query);
    if (filters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                filters.length == 1 ? '1 FILTRO' : '${filters.length} FILTROS',
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              // Beside the chips rather than at the foot of a long panel: this
              // is where somebody looks when the answer is "nobody".
              TextButton.icon(
                onPressed: viewModel.clear,
                icon: const Icon(Icons.delete_outline, size: 15),
                label: const Text('limpar tudo'),
                style: TextButton.styleFrom(
                  foregroundColor: PWColors.textMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final filter in filters) _chip(filter)],
          ),
        ],
      ),
    );
  }

  Widget _chip(ActiveFilter filter) => Material(
    color: PWColors.surfaceRaised,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => viewModel.request(filter.remove(state.query)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 7, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Text(
                filter.label,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.close, size: 13, color: PWColors.textMuted),
          ],
        ),
      ),
    ),
  );
}
