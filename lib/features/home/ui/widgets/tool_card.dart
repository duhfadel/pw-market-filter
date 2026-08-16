import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/tool.dart';

/// One tool on the front page.
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
      opacity: ready ? 1 : 0.45,
      child: Material(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: ready
              ? () => Navigator.of(context).pushNamed(tool.route!)
              : null,
          child: Container(
            padding: EdgeInsets.all(wide ? 22 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: ready && tool.featured
                    ? PWColors.accentDim
                    : PWColors.border,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: wide ? 52 : 44,
                  height: wide ? 52 : 44,
                  decoration: BoxDecoration(
                    color: PWColors.surfaceRaised,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    tool.icon,
                    color: ready ? PWColors.accent : PWColors.textMuted,
                    size: wide ? 26 : 22,
                  ),
                ),
                SizedBox(width: wide ? 18 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tool.name,
                              style: TextStyle(
                                fontSize: wide ? 19 : 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!ready) ...[
                            const SizedBox(width: 10),
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
                                  fontSize: 11,
                                  color: PWColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.tagline,
                        style: TextStyle(
                          color: PWColors.textMuted,
                          fontSize: wide ? 14 : 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (ready) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.arrow_forward,
                    size: 20,
                    color: PWColors.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
