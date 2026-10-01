import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/tool.dart';
import 'tool_navigation.dart';

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
///
/// **Every entry is a pill, bordered and with its own ground — never grey
/// text in a corner.** *Ferramentas* and *Guias* open their drawer **on tap,
/// never only on hover**: half of whoever arrives came from a link pasted in
/// Discord, on a phone, where hover does not exist. Tapping outside a drawer
/// closes it and so does `Esc` — both come for free from
/// [PopupMenuButton]'s own [PopupRoute], which already wires a dismiss
/// barrier and a `DismissIntent` binding for exactly this.
class Cabecalho extends StatelessWidget {
  const Cabecalho({required this.wide, this.aoAbrirNovidades, super.key});

  /// Whether the page has room for one pill per section.
  ///
  /// On narrow, the pills would not fit in a row beside the mark — and a
  /// second navigation surface competing with the mobile filter sheet is not
  /// this site's shape. `mobile_filter_test` already records the rule: one
  /// panel at a time, so the menu collapses to a single overflow button
  /// instead.
  final bool wide;

  /// Called when *Novidades* is tapped. It stays a plain link rather than a
  /// drawer — there is nothing inside it to list, only a section further
  /// down this same page to jump to. `null` leaves the entry inert, which is
  /// what every test that is not about it gets.
  final VoidCallback? aoAbrirNovidades;

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
      if (wide) ...[
        for (final secao in secoesDaHome) ...[
          _SectionPill(secao: secao),
          const SizedBox(width: 8),
        ],
        _NovidadesPill(onTap: aoAbrirNovidades),
      ] else
        _OverflowMenu(aoAbrirNovidades: aoAbrirNovidades),
    ],
  );
}

/// The bordered, own-ground chip every entry in the bar wears. [count], when
/// given, is its own [Text] — never folded into the label's string — because
/// what the pill promises is specifically "how many tools answer", and that
/// number has to be readable on its own by anything scanning the bar for it.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: PWColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PWColors.papel,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: PWColors.surfaceRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            // The body face, never Marcellus: this is a count, and
            // Marcellus's `0` barely reads as an `O` and its `1` carries no
            // flag — a number nobody is deciding money on, but a number all
            // the same, and every number on this site stays off that face.
            child: Text(
              '$count',
              style: const TextStyle(
                color: PWColors.apagado,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

/// One section's pill, opening a drawer of every tool filed under it — the
/// ones that work and the ones that do not, in that order.
///
/// Empty on purpose when a section has nothing at all: a pill that opens to
/// an empty drawer is worse than no pill.
class _SectionPill extends StatelessWidget {
  const _SectionPill({required this.secao});

  final String secao;

  @override
  Widget build(BuildContext context) {
    final itens = toolsDe(secao);
    if (itens.isEmpty) return const SizedBox.shrink();

    // Counts only what is ready: a pill promising three and a drawer
    // delivering two is the pill lying about its own number.
    final prontos = itens.where((t) => t.isReady).length;

    return PopupMenuButton<Tool?>(
      tooltip: secao,
      onSelected: (tool) {
        if (tool != null) abrirTool(context, tool);
      },
      itemBuilder: (context) => [
        for (final tool in itens)
          PopupMenuItem<Tool?>(
            value: tool,
            enabled: tool.isReady,
            child: GavetaItem(tool: tool),
          ),
      ],
      child: _Pill(label: secao, count: prontos),
    );
  }
}

/// *Novidades*, as a plain link rather than a pill with a drawer — there is
/// nothing under it to list, only a section further down the page to jump
/// to.
class _NovidadesPill extends StatelessWidget {
  const _NovidadesPill({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    // The one exception to "no inline colours": transparent is the absence
    // of a colour, not a choice of one.
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: const _Pill(label: 'Novidades'),
    ),
  );
}

/// One row inside a drawer: the tool's name, its one-line description, and —
/// for whatever is not built yet — the *em breve* badge.
///
/// A tool that is not ready is still listed here, dimmed, rather than
/// hidden: a menu that shows only what is finished makes the site look like
/// it stopped growing. Public, and not a private class nested in this file,
/// because it is the one piece of this widget worth proving in isolation —
/// the real [tools] list carries nothing unready today, so a test that wants
/// to see the dimmed state has to hand one in itself.
class GavetaItem extends StatelessWidget {
  const GavetaItem({required this.tool, super.key});

  final Tool tool;

  @override
  Widget build(BuildContext context) {
    final ready = tool.isReady;

    return Opacity(
      opacity: ready ? 1 : 0.5,
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tool.name,
                    style: const TextStyle(
                      color: PWColors.papel,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!ready) ...[
                  const SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 2),
            // *Títulos* alone says nothing to somebody who has never used
            // it — the tagline is what the tool actually gives, and it
            // already lives on `Tool` for the card grid further down the
            // page, so the drawer reads it rather than inventing a second
            // description to keep in agreement with the first.
            Text(
              tool.tagline,
              style: const TextStyle(
                color: PWColors.textMuted,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// The narrow-screen stand-in for every [_SectionPill] and the *Novidades*
/// link at once.
///
/// One button, one menu, section names as disabled headings inside it — the
/// same information the wide row offers, in the one panel this site allows
/// itself on a phone.
class _OverflowMenu extends StatelessWidget {
  const _OverflowMenu({this.aoAbrirNovidades});

  final VoidCallback? aoAbrirNovidades;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Tool?>(
    tooltip: 'Menu',
    icon: const Icon(Icons.menu, color: PWColors.papel),
    onSelected: (tool) {
      if (tool != null) abrirTool(context, tool);
    },
    itemBuilder: (context) => [
      for (final secao in secoesDaHome) ...[
        PopupMenuItem<Tool?>(
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
        for (final tool in toolsDe(secao))
          PopupMenuItem<Tool?>(
            value: tool,
            enabled: tool.isReady,
            child: GavetaItem(tool: tool),
          ),
      ],
      PopupMenuItem<Tool?>(
        onTap: aoAbrirNovidades,
        child: const Text(
          'Novidades',
          style: TextStyle(color: PWColors.papel, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
