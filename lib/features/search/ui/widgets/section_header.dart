import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';

/// The rule above a group of filters: an emblem, the name, an optional count,
/// and a line to the right edge.
///
/// The emblem is a real item out of the market rather than a Material glyph —
/// the game's own art for a weapon, a chestpiece, a necklace, a card. A form
/// this long is scanned before it is read, and a picture of the thing is what
/// the eye finds; `Icons.shield_outlined` would only say "some section".
///
/// [badge] is how many slots inside the group are being filtered, and it is
/// what makes a collapsed section safe to leave closed.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.emblem,
    this.badge = 0,
    this.expanded,
    super.key,
  });

  final String title;

  /// Item id whose picture stands for the group. `null` draws no emblem, and
  /// so does an id whose file was never fetched — `ItemIcon` falls back to an
  /// empty box, which costs a little space and never a broken row.
  final int? emblem;

  final int badge;

  /// `null` for a header that does not collapse; otherwise the chevron follows
  /// it.
  final bool? expanded;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (expanded != null) ...[
        Icon(
          expanded! ? Icons.expand_more : Icons.chevron_right,
          size: 18,
          color: PWColors.textMuted,
        ),
        const SizedBox(width: 4),
      ],
      if (emblem != null) ...[
        ItemIcon(emblem!, size: 22),
        const SizedBox(width: 8),
      ],
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 8),
      if (badge > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: PWColors.accentDim,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '$badge',
            style: const TextStyle(
              color: PWColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      const Expanded(child: Divider(indent: 10)),
    ],
  );
}
