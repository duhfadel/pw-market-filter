import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/presets.dart';
import '../../domain/search_query.dart';
import '../search_state.dart';
import '../search_view_model.dart';

/// The ready-made searches, as a row of chips over the results.
///
/// The filter used to open on the whole market and a form nobody had filled
/// in, which asks a first-time visitor to invent a question before the tool has
/// shown it can answer one. One tap here and the market is cut to a tenth, with
/// the form filled in behind it saying how.
///
/// A tap **replaces** the current search rather than adding to it. Two presets
/// at once produce a combination nobody asked for and no way to see which of
/// them emptied the screen. Tapping the active chip clears it, so every chip is
/// also its own way out.
///
/// The row lives above the results and outside them, so it survives a search
/// that finds nobody: the chip that emptied the screen is precisely the one
/// that has to still be on it.
class PresetChips extends StatelessWidget {
  const PresetChips({required this.state, required this.viewModel, super.key});

  final SearchReady state;
  final SearchViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final presets = presetsFor(state.index);
    final active = activePreset(presets, state.query);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        itemCount: presets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final preset = presets[i];
          final isActive = preset.label == active?.label;

          return _Chip(
            label: preset.label,
            isActive: isActive,
            // Clearing keeps the ordering: it is how the list is read, not
            // something that was asked for.
            onTap: () => viewModel.request(
              isActive
                  ? SearchQuery(order: state.query.order)
                  : preset.query.copyWith(order: state.query.order),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: isActive ? PWColors.accentDim : PWColors.surfaceRaised,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? PWColors.accent : PWColors.border,
          ),
        ),
        // `Align` with a width factor, not `alignment:` on the Container. A
        // horizontal list hands its items an unbounded width, and a box told
        // to align its child inside unbounded constraints has no width to
        // align within. The factor pins the chip to its text and still centres
        // the text in the row's height.
        child: Align(
          widthFactor: 1,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isActive ? PWColors.accent : PWColors.text,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    ),
  );
}
