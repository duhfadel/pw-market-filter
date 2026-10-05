import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../data/browser_memory.dart';
import '../../data/novidade_lida.dart';
import '../../domain/tool.dart';
import '../novidades_view_model.dart';
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
  const Cabecalho({
    required this.wide,
    this.versao,
    this.memoriaDeNovidades,
    super.key,
  });

  /// Below this, the pills do not fit in a row beside the mark, and
  /// `Cabecalho` collapses them into one overflow button instead — every
  /// screen that carries this widget reads its own `MediaQuery` width against
  /// this same number, so the menu never gains a second narrow shape
  /// depending on which screen is showing it.
  ///
  /// One constant, not four. `_larguraDoMenu` was this same number, copied by
  /// hand — three-line doc comment included — into `novidades_view.dart`,
  /// `registros_view.dart`, `runas_view.dart` and (as `_twoColumnWidth`)
  /// `home_view.dart`. Four hand-synced copies of one number is exactly how
  /// two of them drift apart in this codebase; it belongs on the widget whose
  /// breakpoint it actually is.
  ///
  /// **772, not 680 — and the consolidation itself had carried the wrong
  /// value.** Measured with real fonts, the wide row overflows from 680 up to
  /// roughly 712 inside a plain `AppBar` title and roughly 744 inside the
  /// home's own margins. `/filtro`'s `AppBar` is not plain — it carries its
  /// own `leading` back arrow, the one chrome none of the other four screens
  /// add, and that pushes its own clean width a few pixels past the other
  /// three: measured at exactly 768 it still overflowed, by 0.144 px. 772
  /// clears every context this widget is mounted in, with margin. A single
  /// source of truth is only as good as the number inside it, and
  /// consolidating four copies into one is not the same task as measuring
  /// what that one number should be — nor, it turned out, is measuring the
  /// four original screens the same task as measuring a fifth that joined
  /// them later with chrome the others do not have.
  static const larguraMinima = 772.0;

  /// Whether the page has room for one pill per section.
  ///
  /// On narrow, the pills would not fit in a row beside the mark — and a
  /// second navigation surface competing with the mobile filter sheet is not
  /// this site's shape. `mobile_filter_test` already records the rule: one
  /// panel at a time, so the menu collapses to a single overflow button
  /// instead.
  final bool wide;

  /// The game's own version beside the mark — `1.8.7`, `1.2.6` — or `null` to
  /// draw none at all.
  ///
  /// It was hard-coded to `1.8.7` until two marketplaces made that simply
  /// false on every 1.2.6 screen. Each screen now says which market it is —
  /// `HomeView` and `SearchView` read it off `MarketIndex.server`, the
  /// Supabase-backed tools (`/runas`, `/registros`) pass `1.8.7` because
  /// neither exists for the other market yet.
  ///
  /// **`null` on purpose for `/` and `/novidades`.** The chooser is the one
  /// screen that has not picked a marketplace yet — printing either version
  /// there would be the site answering a question nobody asked it — and
  /// `/novidades` serves the same announcements to both, so no single version
  /// is more true than the other for it either.
  final String? versao;

  /// Injected so the suite can prove the dot against a store nobody else
  /// touches; `null` — every real call site — reaches for the real browser
  /// storage `NovidadeLida` already defaults to. None of the five screens
  /// that carry this widget pass anything here, which is the point: the dot
  /// is wired once, in this file, rather than by every screen that happens
  /// to show a `Cabecalho`.
  final BrowserMemory? memoriaDeNovidades;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _Marca(key: const Key('cabecalho-marca'), versao: versao),
      const Spacer(),
      if (wide) ...[
        for (final secao in secoesDaHome)
          if (toolsDe(secao, versao: versao).isNotEmpty) ...[
            _SectionPill(secao: secao, versao: versao),
            const SizedBox(width: 8),
          ],
        _NovidadesPill(memoria: memoriaDeNovidades),
      ] else
        _OverflowMenu(versao: versao),
    ],
  );
}

/// Opens `/novidades`, the site's own screen of past announcements — guarded
/// against stacking it on top of itself.
///
/// It used to scroll to a section further down the front page; that stopped
/// being true the day `/novidades` got a screen of its own. Every entrance
/// to it reads through here now rather than each of the five screens that
/// carry `Cabecalho` writing its own `Navigator.pushNamed(context,
/// '/novidades')` — a sixth screen forgetting it used to mean an inert pill
/// with no compile error.
///
/// **M1** was this exact hop, with no guard: tapping *Novidades* while
/// already reading `/novidades` pushed a second, identical copy, so the
/// first press of "back" appeared to do nothing. Compared by path and not
/// by the whole route name, because `/filtro` can carry a query string no
/// other route here does — `/novidades` never does, but the comparison is
/// written the way `abrirTool` below needs it to be, for the same hazard.
void _abrirNovidades(BuildContext context) {
  final atual = ModalRoute.of(context)?.settings.name;
  if (atual != null && Uri.parse(atual).path == '/novidades') return;
  Navigator.of(context).pushNamed('/novidades');
}

/// The mark, the name and the game's version — and the way home from
/// anywhere on the site.
///
/// It replaces per-screen home links that existed before this widget reached
/// every page: tapping it never `push`es, because stacking the home page on
/// top of itself would leave the back button walking backwards through a
/// stack nobody built. `pushNamedAndRemoveUntil` clears the stack to just
/// `/` instead, which is also correct for a visitor who arrived straight at
/// a tool's deep link with no home beneath it to pop back to.
class _Marca extends StatelessWidget {
  const _Marca({this.versao, super.key});

  /// `Cabecalho.versao`, forwarded — `null` draws no version text at all,
  /// which is the chooser's and `/novidades`' own case.
  final String? versao;

  @override
  Widget build(BuildContext context) => Material(
    // The one exception to "no inline colours": transparent is the absence
    // of a colour, not a choice of one. Without it, the home page's own
    // `_Aurora` paints over the splash — `_Marca` sat inside an `AppBar`'s
    // own `Material` on the tool screens and only the home page ever showed
    // the gap, which is exactly how it went unnoticed.
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () =>
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/pw-mark.webp',
              height: 26,
              filterQuality: FilterQuality.medium,
              // A missing file leaves the name to carry the header alone
              // rather than a broken box — the same silent fallback the rest
              // of the site makes for art that failed to load.
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
            // The game's own version, not this site's — nobody asks a tool
            // site "which release are you", they ask "which game". On
            // Inter, never Marcellus: it is a number, and Marcellus draws
            // Roman figures. Absent on the chooser and on `/novidades`,
            // neither of which has picked (or speaks for) one market.
            if (versao != null) ...[
              const SizedBox(width: 8),
              Text(
                versao!,
                style: const TextStyle(color: PWColors.textMuted, fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// The bordered, own-ground chip every entry in the bar wears. [count], when
/// given, is its own [Text] — never folded into the label's string — because
/// what the pill promises is specifically "how many tools answer", and that
/// number has to be readable on its own by anything scanning the bar for it.
///
/// [dot] is the Novidades pill's own unread marker — a plain circle rather
/// than a count, because the fact it reports is "something new", not a
/// quantity. No pill wears both [count] and [dot] today, but nothing stops
/// one that did.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.count, this.dot = false});

  final String label;
  final int? count;
  final bool dot;

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
        if (dot) ...[
          const SizedBox(width: 6),
          // Lit only while this browser has not opened `/novidades` since
          // the newest entry was posted. A dot still on after it has been
          // read teaches the reader to stop seeing it — the same failure
          // the `novo` badge's own expiry date exists to avoid.
          Container(
            key: const Key('novidade-nao-lida'),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: PWColors.accent,
              shape: BoxShape.circle,
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
  const _SectionPill({required this.secao, this.versao});

  final String secao;

  /// A versão em que o visitante está, ou `null` no seletor. Uma secção sem
  /// nada para esta versão não desenha pílula nenhuma — o mesmo motivo de
  /// uma secção vazia não a desenhar: uma pílula que abre uma gaveta vazia é
  /// pior do que nenhuma pílula.
  final String? versao;

  @override
  Widget build(BuildContext context) {
    final itens = toolsDe(secao, versao: versao);
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

/// *Novidades*, as a plain link rather than a pill with a drawer — it opens
/// the `/novidades` screen directly, and there is nothing to list in a
/// drawer first.
///
/// **It carries the unread dot the front page's news bar used to own**,
/// moved here on 01/10/2026 when `/novidades` got a screen of its own: a
/// closed accordion on the home page was a second surface for the same
/// thing the pill already opens, and the owner's call was to keep one. The
/// rules the dot followed there still hold, just read from a different
/// place: it lights while this browser has not opened `/novidades` since the
/// newest entry was posted, a browser that has never opened it counts as
/// having something new (the useful direction to be wrong in), and it is
/// marked read on the way in — now at the moment `/novidades` itself opens
/// (`novidades_view.dart`), rather than when this particular pill is tapped,
/// so a shared link straight to `/novidades` clears it too.
///
/// **What this move costs, on purpose rather than quietly:** the bar's
/// closed header showed the latest entry's own title and date, so a
/// returning visitor could tell *whether* the thing inside was the one they
/// had already read. A pill has room for a label and a dot, not a headline —
/// that teaser is gone, and the owner accepted the trade.
///
/// The dot is read fresh on every build rather than cached, and that is
/// *not* the same rule the old bar followed — it cannot be, because the
/// write that used to share this widget now happens on a different screen
/// entirely. The old caching guarded against this very widget writing and
/// then immediately re-reading its own write inside one build; nothing here
/// writes at all any more, so there is no such write to chase and a plain
/// read is both simpler and correct, including the moment a visitor returns
/// from `/novidades` and this pill must stop lighting without needing a new
/// widget instance to notice.
class _NovidadesPill extends StatelessWidget {
  const _NovidadesPill({this.memoria});

  final BrowserMemory? memoria;

  @override
  Widget build(BuildContext context) {
    // No fallback for a missing provider, on purpose — `BlocProvider.of`
    // throws a clear `FlutterError` naming the missing type, and that is
    // exactly what should happen: every real route sits under `main.dart`'s
    // `MultiBlocProvider`, so this can only be reached by a screen that
    // genuinely forgot it, and a test that wants to mount `Cabecalho` on its
    // own needs to supply one (`test/support/novidades_test_support.dart`).
    //
    // A catch here was tried and removed. `CLAUDE.md` already records why:
    // `VisitRepository` once swallowed every exception so a counter could
    // never take a page down, and that same catch quietly swallowed a real
    // `MissingPluginException` along with it — the counter miscounted for
    // who knows how long, and the suite stayed green because its mock never
    // exercised the failure. A catch written to keep one feature quiet keeps
    // its bugs quiet too; better for this to fail loudly in a test (and be
    // fixed by adding the provider) than to fail silently in production.
    final entradas = BlocProvider.of<NovidadesViewModel>(
      context,
      listen: true,
    ).state;

    return Material(
      // The one exception to "no inline colours": transparent is the absence
      // of a colour, not a choice of one.
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _abrirNovidades(context),
        child: _Pill(
          label: 'Novidades',
          dot: NovidadeLida(memoria).existeNaoLida(entradas),
        ),
      ),
    );
  }
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
                // Both badges moved here on 01/10/2026, the day the front
                // page's tool cards left — `ToolCard` used to carry them, and
                // a badge nobody can see is a badge that does not exist. This
                // drawer row is the one surface a tool still has.
                if (tool.beta) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: PWColors.accent),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'BETA',
                      style: TextStyle(
                        color: PWColors.accent,
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                // Outlined where `novo` is filled, so the two never read as
                // the same kind of news: one is an invitation, the other a
                // caveat — the same contrast `ToolCard` drew.
                if (tool.novoEm(DateTime.now())) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: PWColors.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'novo',
                      style: TextStyle(
                        color: PWColors.background,
                        fontSize: 10,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
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
            // already lives on `Tool` for this same row, so the drawer reads
            // it rather than inventing a second description to keep in
            // agreement with the first.
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
  const _OverflowMenu({this.versao});

  /// A mesma versão que as pílulas usam no largo. O menu estreito é a mesma
  /// navegação noutro invólucro, e uma das duas a mostrar ferramentas de
  /// outro mercado seria a barra a discordar de si própria consoante a
  /// largura da janela.
  final String? versao;

  @override
  Widget build(BuildContext context) => PopupMenuButton<Tool?>(
    tooltip: 'Menu',
    icon: const Icon(Icons.menu, color: PWColors.papel),
    onSelected: (tool) {
      if (tool != null) abrirTool(context, tool);
    },
    itemBuilder: (context) => [
      for (final secao in secoesDaHome)
        if (toolsDe(secao, versao: versao).isNotEmpty) ...[
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
          for (final tool in toolsDe(secao, versao: versao))
            PopupMenuItem<Tool?>(
              value: tool,
              enabled: tool.isReady,
              child: GavetaItem(tool: tool),
            ),
        ],
      PopupMenuItem<Tool?>(
        onTap: () => _abrirNovidades(context),
        child: const Text(
          'Novidades',
          style: TextStyle(color: PWColors.papel, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}
