import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
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
            if (tool.art != null)
              _Art(path: tool.art!, alignment: tool.artAlignment),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: ready ? () => _openTool(context, tool) : null,
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

/// Leaves for [Tool.href] in the same tab, or pushes [Tool.route] inside the
/// app. `_self` matters: a guide is part of this site, and a new tab for an
/// internal page turns the browser's back button into a dead end.
void _openTool(BuildContext context, Tool tool) {
  final href = tool.href;
  if (href != null) {
    unawaited(launchUrl(Uri.parse(href), webOnlyWindowName: '_self'));
    return;
  }
  Navigator.of(context).pushNamed(tool.route!);
}

/// The class art, pushed far back.
///
/// Two things keep it from eating the text. The art sits to the right, where
/// the card has no words — the character's face lands beside the tagline
/// instead of under it. And a gradient runs from the surface colour on the left
/// to nearly nothing on the right, so the left third, where every line of text
/// begins, is effectively flat.
class _Art extends StatelessWidget {
  const _Art({required this.path, required this.alignment});

  final String path;
  final Alignment alignment;

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
                // Whatever the tool asks for; the default and the reason for
                // it live on `Tool.artAlignment`. What is worth repeating here
                // is how the mistake showed up: a wrong alignment survives on
                // the half-width cards, whose art box is tall enough to reach
                // the subject anyway, and only breaks when a card goes full
                // width and the box becomes a 600×110 letterbox. Judge a new
                // art on the widest card it can land on.
                alignment: alignment,
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
              style: const TextStyle(
                fontFamily: PWTheme.display,
                fontSize: 18,
                letterSpacing: 0.2,
              ),
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
