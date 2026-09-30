import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/tool.dart';

/// The site's mark, and the whole menu behind it.
///
/// Every screen gets this, not just the front page — a visitor reading
/// `/runas` today has no way to reach `/registros` without going home first,
/// which is a gap nobody had named before this widget existed to close it.
///
/// **The mark shrinks, it is not discarded.** At 200 px of dark red on dark
/// violet the fan art was the largest element on the page and the least
/// legible thing on it. 26 px, beside the name it stands for, is the size at
/// which it reads as a mark instead of a poster.
class Cabecalho extends StatelessWidget {
  const Cabecalho({required this.wide, super.key});

  /// Whether the page has room for one button per section.
  ///
  /// On narrow, the section buttons would not fit in a row beside the mark —
  /// and a drawer is not this site's shape. `mobile_filter_test` already
  /// records the rule: one panel at a time, so the menu collapses to a
  /// single overflow button instead of a second navigation surface.
  final bool wide;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Image.asset(
        'assets/images/pw-mark.webp',
        height: 26,
        filterQuality: FilterQuality.medium,
        // A missing file leaves the name to carry the header alone rather
        // than a broken box — the same silent fallback the rest of the site
        // makes for art that failed to load.
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
      const SizedBox(width: 10),
      const Text(
        'PORTAL PW',
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: 18,
          letterSpacing: 0.6,
          color: PWColors.papel,
        ),
      ),
      const SizedBox(width: 8),
      // The game's own version, not this site's — nobody asks a tool site
      // "which release are you", they ask "which game". On Inter, never
      // Marcellus: it is a number, and Marcellus draws Roman figures.
      const Text(
        '1.8.7',
        style: TextStyle(color: PWColors.textMuted, fontSize: 11),
      ),
      const Spacer(),
      if (wide)
        for (final secao in secoesDaHome) _SectionMenu(secao: secao)
      else
        const _OverflowMenu(),
    ],
  );
}

/// One section's button, opening the tools filed under it.
///
/// Empty on purpose when a section has nothing ready to show — a button that
/// opens to an empty menu is worse than no button.
class _SectionMenu extends StatelessWidget {
  const _SectionMenu({required this.secao});

  final String secao;

  @override
  Widget build(BuildContext context) {
    final prontos = toolsDe(secao).where((t) => t.isReady).toList();
    if (prontos.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<Tool>(
      tooltip: secao,
      onSelected: (tool) => _abrir(context, tool),
      itemBuilder: (context) => [
        for (final tool in prontos)
          PopupMenuItem(value: tool, child: Text(tool.name)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Text(
          secao,
          style: const TextStyle(
            color: PWColors.papel,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// The narrow-screen stand-in for every [_SectionMenu] at once.
///
/// One button, one menu, section names as disabled headings inside it — the
/// same information the wide row offers, in the one panel this site allows
/// itself on a phone.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu();

  @override
  Widget build(BuildContext context) => PopupMenuButton<Tool>(
    tooltip: 'Menu',
    icon: const Icon(Icons.menu, color: PWColors.papel),
    onSelected: (tool) => _abrir(context, tool),
    itemBuilder: (context) => [
      for (final secao in secoesDaHome) ...[
        PopupMenuItem<Tool>(
          enabled: false,
          child: Text(
            secao.toUpperCase(),
            style: const TextStyle(
              color: PWColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        for (final tool in toolsDe(secao).where((t) => t.isReady))
          PopupMenuItem<Tool>(value: tool, child: Text(tool.name)),
      ],
    ],
  );
}

/// Leaves for [Tool.href] in the same tab, or pushes [Tool.route] inside the
/// app — the same rule `ToolCard` follows, so a tool opens the same way
/// wherever it was tapped from. Routing stays with `MaterialApp`, never a
/// nested `Navigator`: a page pushed any other way carries no link of its
/// own, and the browser's back button leaves the site instead of going home.
void _abrir(BuildContext context, Tool tool) {
  final href = tool.href;
  if (href != null) {
    unawaited(launchUrl(Uri.parse(href), webOnlyWindowName: '_self'));
    return;
  }
  Navigator.of(context).pushNamed(tool.route!);
}
