import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/tool.dart';

/// One tool in the menu.
///
/// A tool that is not built yet is shown and dimmed rather than hidden: it
/// tells a visitor the place is growing, and it costs one line to switch on.
/// It is not tappable, and it says *em breve* — a card that looks clickable and
/// does nothing is worse than one that admits it.
class ToolCard extends StatelessWidget {
  const ToolCard({required this.tool, required this.wide, super.key});

  final Tool tool;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final ready = tool.isReady;

    return Opacity(
      opacity: ready ? 1 : 0.42,
      child: Material(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: ready
              ? () => Navigator.of(context).pushNamed(tool.route!)
              : null,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ready ? PWColors.accentDim : PWColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: PWColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        tool.icon,
                        color: ready ? PWColors.accent : PWColors.textMuted,
                        size: 21,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tool.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (ready)
                      const Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: PWColors.accent,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: PWColors.surfaceRaised,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'em breve',
                          style: TextStyle(
                            fontSize: 10,
                            color: PWColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tool.tagline,
                  style: const TextStyle(
                    color: PWColors.textMuted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
