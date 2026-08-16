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
      opacity: ready ? 1 : 0.5,
      child: Material(
        color: PWColors.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            if (tool.art != null) _Art(path: tool.art!),
            InkWell(
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
                child: _Body(tool: tool, ready: ready),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The class art, pushed far back.
///
/// Two things keep it from eating the text. The art sits to the right, where
/// the card has no words — the character's face lands beside the tagline
/// instead of under it. And a gradient runs from the surface colour on the left
/// to nearly nothing on the right, so the left third, where every line of text
/// begins, is effectively flat.
class _Art extends StatelessWidget {
  const _Art({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.55,
              child: Image.asset(
                path,
                fit: BoxFit.cover,
                // All three crops put the face around a fifth of the way down,
                // not at the centre — `Alignment.center` was measured against
                // that assumption and it was wrong. It survived on the
                // half-width cards, whose art box is tall enough that the
                // visible band reaches the face anyway, and broke the moment a
                // card went full width: the box became a 600×110 letterbox and
                // the band landed on the priest's skirt. -0.6 puts the crop's
                // centre at 20% down, where the faces actually are.
                alignment: const Alignment(0, -0.6),
                // A missing file leaves the flat card rather than a broken box.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  PWColors.surface,
                  PWColors.surface,
                  Color(0xD913132A),
                  Color(0x8013132A),
                ],
                stops: [0, 0.34, 0.62, 1],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.tool, required this.ready});

  final Tool tool;
  final bool ready;

  @override
  Widget build(BuildContext context) => Column(
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (ready)
            const Icon(Icons.arrow_forward, size: 18, color: PWColors.accent)
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      // Held short of the art so a long line never runs into the character.
      FractionallySizedBox(
        widthFactor: 0.72,
        alignment: Alignment.centerLeft,
        child: Text(
          tool.tagline,
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ),
    ],
  );
}
