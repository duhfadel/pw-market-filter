import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/browser_memory.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../market/market_index.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/arte_da_classe.dart';
import '../domain/tool.dart';
import '../domain/visit_label.dart';
import 'visit_counter_view_model.dart';
import '../domain/community.dart';
import '../domain/novidade.dart';
import '../../../core/widgets/brand_icon.dart';
import 'novidades_view_model.dart';
import 'widgets/ao_vivo_strip.dart';
import 'widgets/cabecalho.dart';
import 'widgets/cartaz.dart';
import 'widgets/discord_strip.dart';
import 'widgets/news_section.dart';
import 'widgets/tool_card.dart';
import 'widgets/tool_navigation.dart';
import 'widgets/vitrine_view.dart';

/// The Portal's front page: the mark, the Cartaz, the Vitrine, and the menu.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the Cartaz and the Vitrine are both drawn from it. The
/// Cartaz opens on a class's own art before a single number is known, so the
/// wait never blanks the fold — only the class-specific parts (the Cartaz's
/// class and the three Vitrine cards) wait on the load.
///
/// The tool cards do not wait for it either. They are the menu, and a menu
/// that appears a second late is a page that looks broken.
/// One store for the whole page, built once.
///
/// A fresh instance per rebuild would read `localStorage` on every frame,
/// which is the call the guard in `BrowserMemory` exists to keep cheap and
/// quiet — and the news bar reads its marker exactly once per load.
final _memoriaDasNovidades = BrowserMemory.platform(
  'portal_pw_ultima_novidade',
);

/// Which class the Cartaz wears this build.
///
/// Derived from `collectedAt` — never `Random()`, never the wall clock. The
/// same collection has to draw the same page, or a rebuild reads as a slot
/// machine instead of a site. While the index has not loaded yet there is no
/// `collectedAt` to read, so the Cartaz opens on the first class in the list
/// rather than waiting to show any art at all.
String _classeDoCartaz(MarketIndex? index) {
  if (index == null) return classesComArte.first;
  final posicao =
      index.collectedAt.millisecondsSinceEpoch % classesComArte.length;
  return classesComArte[posicao];
}

/// Opens a character's own page on the real marketplace.
///
/// The site already draws the character sheet well, so the Vitrine links out
/// to it instead of rebuilding it — the same address and the same reasoning
/// `CharacterCard._open` uses for the results grid.
void _abrirPersonagem(MarketIndex index, MarketCharacter character) {
  unawaited(
    launchUrl(
      Uri.parse(
        'https://marketplace.theclassic.games/'
        '${index.server}/details/${character.roleId}',
      ),
      mode: LaunchMode.externalApplication,
    ),
  );
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Below this the grid becomes a column.
  static const _twoColumnWidth = 680.0;

  /// Above this the page is not competing for space, and holding the layout at
  /// its tablet size leaves the mark reading as a small card adrift in black —
  /// on a 1920 monitor the logo was 18% of the width. Everything grows a step.
  static const _largeWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= _twoColumnWidth;
    final large = width >= _largeWidth;
    // 1040 and not 900 at the top step, and the reason is one line of type:
    // at 900 the old headline broke with "usando" alone on a second line at
    // every desktop size measured — 1366 and 1920 both.
    final maxWidth = large ? 1040.0 : 780.0;

    return Scaffold(
      body: Stack(
        children: [
          // Behind everything and touching nothing: the light is decoration,
          // and decoration that eats a tap is a bug.
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(child: _Aurora()),
          ),
          SafeArea(
            // Centred across, pinned to the **top** down the page. It used to
            // be a plain `Center`, from when the front page was a logo, a
            // headline and three cards: short enough that sitting in the
            // middle of the window looked composed rather than adrift.
            //
            // The page has grown since — the Vitrine, the news panel — and on
            // a tall window the same rule opened a screen and a half of empty
            // sky above the logo before anything was readable. Vertical
            // centring is a rule about short pages, and this one stopped being
            // one.
            // **The scrollable is the whole width, and the cap lives inside
            // it.** It was the other way round — a 1040-wide `ListView`
            // centred in the window — and a wheel event lands on whatever is
            // under the pointer: out in the margins that was the background,
            // so the page did not move at all. It reads as a broken site
            // rather than as a layout choice, and it was reported that way.
            //
            // The scrollbar hugging the column instead of the window's edge
            // was the same fact wearing a different face. Both are gone.
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    // Vertical padding only, applied once for the whole
                    // column. Horizontal padding is per-section instead —
                    // see `_ComMargem` — because the Cartaz and the Vitrine
                    // carry their own, wider than the rest of the page, and
                    // a shared side padding here would either pinch them or
                    // leave every other section without one.
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: wide ? 44 : 28),
                      child: Column(
                        // A `ListView` stretches its children across and a
                        // `Column` centres them, so the menu and the news bar
                        // would have shrunk to their own width without this.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ComMargem(
                            wide: wide,
                            child: Cabecalho(wide: wide),
                          ),
                          SizedBox(height: wide ? 22 : 16),
                          // **The Cartaz bleeds to the reading column's own
                          // edges.** It is not an image beside the content,
                          // it is the ground the content stands on, and a
                          // side margin around it would say otherwise — so,
                          // unlike everything else on this page, it carries
                          // no `_ComMargem` and touches the column's edges
                          // directly. Its own internal padding is what keeps
                          // its text off them.
                          BlocBuilder<SearchViewModel, SearchState>(
                            builder: (context, state) {
                              final ready = state is SearchReady ? state : null;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Cartaz(
                                    classe: _classeDoCartaz(ready?.index),
                                    // `large`, not `wide`. Both were built and
                                    // measured at 1200 px — close to this
                                    // page's `large` step (1280) — and their
                                    // "wide" typography does not fit the
                                    // tablet band between 680 and 1279: at
                                    // 780 px the Cartaz's own 40 px headline
                                    // overflowed its box by 36 px. Below
                                    // `large`, both fall back to their
                                    // compact layout instead of the rest of
                                    // the page's `wide` one.
                                    wide: large,
                                    aoBuscar: () => Navigator.of(
                                      context,
                                    ).pushNamed('/filtro'),
                                  ),
                                  if (ready != null) ...[
                                    SizedBox(height: wide ? 8 : 4),
                                    VitrineView(
                                      index: ready.index,
                                      wide: large,
                                      aoTocar: (character) => _abrirPersonagem(
                                        ready.index,
                                        character,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                          _ComMargem(
                            wide: wide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Menu(wide: wide),
                                SizedBox(height: wide ? 6 : 4),
                                const _Guias(),
                              ],
                            ),
                          ),
                          SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                          _ComMargem(
                            wide: wide,
                            child:
                                BlocBuilder<NovidadesViewModel, List<Novidade>>(
                                  builder: (context, novidades) => NewsSection(
                                    entries: novidades,
                                    wide: wide,
                                    memoria: _memoriaDasNovidades,
                                  ),
                                ),
                          ),
                          // Depois das ferramentas e antes da comunidade. É o
                          // lugar que combina com o que a coisa é: cortesia a
                          // quem transmite, não o motivo de alguém ter vindo.
                          // Em cima disputaria com as ferramentas; no rodapé
                          // ninguém veria.
                          _ComMargem(
                            wide: wide,
                            child: AoVivoStrip(wide: wide),
                          ),
                          SizedBox(height: wide ? 26 : 20),
                          _ComMargem(
                            wide: wide,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _Secao(nome: 'Comunidade'),
                                SizedBox(height: wide ? 12 : 10),
                                DiscordStrip(wide: wide),
                              ],
                            ),
                          ),
                          SizedBox(height: wide ? 28 : 22),
                          _ComMargem(wide: wide, child: const _Footer()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The light behind the front page.
///
/// Three layers, and the order is the whole trick: a violet sky at the top
/// fading into the page's own black, then two soft lights over it — one violet
/// high and centred, one gold low and to the left, which is where the eye
/// already is because that is where the reading starts.
///
/// It costs nothing to download. The alternative tried first was a blurred
/// screenshot of the game, which works and weighs 5 KB, but the greens and
/// browns of a grass valley fight an indigo palette; a gradient cannot go off
/// palette because it is made of the palette.
///
/// It does not scroll. On a phone the page is longer than the screen, and a
/// light that slides up with the content reads as a picture coming loose.
class _Aurora extends StatelessWidget {
  const _Aurora();

  /// Tall enough to cover the fold on a desktop and to fade out before the
  /// cards on a phone.
  static const _height = 900.0;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: _height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [PWColors.nightTop, PWColors.background],
              stops: [0, 0.78],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.85),
              radius: 0.9,
              colors: [
                PWColors.glowViolet.withValues(alpha: 0.22),
                PWColors.glowDeep.withValues(alpha: 0.10),
                PWColors.background.withValues(alpha: 0),
              ],
              stops: const [0, 0.45, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.6, -0.2),
              radius: 0.7,
              colors: [
                PWColors.accent.withValues(alpha: 0.09),
                PWColors.accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

/// The page's ordinary side margin, applied one section at a time.
///
/// Everything on the page carries it except the Cartaz, which bleeds to the
/// reading column's own edges on purpose — see the comment at its call site.
/// A margin shared by every child of one `Column` would have pinched the
/// Cartaz along with the rest; wrapping each section individually is what
/// lets the hero opt out.
class _ComMargem extends StatelessWidget {
  const _ComMargem({required this.wide, required this.child});

  final bool wide;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: wide ? 40 : 20),
    child: child,
  );
}

/// The tools, under the first section's own heading — `secoesDaHome.first`,
/// which is `Ferramentas`.
///
/// A grid rather than a list because it is meant to be scanned, not read: four
/// cards side by side answer "what is here?" in one glance, where four
/// full-width rows answer it in four.
///
/// **Only the first section gets this treatment.** Every section past it is
/// a guide, and `_Guias` draws those instead — one full section header and a
/// grid for the tools, one line each for the rest. Filed together under one
/// undivided menu, the page said "here are four things"; split like this, it
/// says "here are the tools, and here is what they explain".
class _Menu extends StatelessWidget {
  const _Menu({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final principal = secoesDaHome.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Secao(nome: principal),
        SizedBox(height: wide ? 12 : 10),
        _Cards(tools: toolsDe(principal), wide: wide),
      ],
    );
  }
}

/// The guides, one line each — not a second section.
///
/// A single card under a full section header with its own rule was more
/// chrome than content: one entry does not earn a rule of its own. `GUIA`
/// carries the same weight `_Secao`'s label does, just not stretched across
/// the page.
///
/// Reads every section past the first (`secoesDaHome.skip(1)`) rather than a
/// literal `'Guias'`, so a future second guide falls into the same line
/// without this file changing — though today there is exactly one.
class _Guias extends StatelessWidget {
  const _Guias();

  @override
  Widget build(BuildContext context) {
    final entradas = [
      for (final secao in secoesDaHome.skip(1))
        ...toolsDe(secao).where((t) => t.isReady),
    ];
    if (entradas.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final tool in entradas) _LinhaDeGuia(tool: tool)],
    );
  }
}

/// One guide, as a single tappable row: the `GUIA` tag, the name and the
/// tagline on one line, an arrow. No card, no border, no heading above it.
class _LinhaDeGuia extends StatelessWidget {
  const _LinhaDeGuia({required this.tool});

  final Tool tool;

  @override
  Widget build(BuildContext context) => Material(
    // The one exception to "no inline colours": transparent is the absence
    // of a colour, not a choice of one.
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => abrirTool(context, tool),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Text(
              'GUIA',
              style: TextStyle(
                color: PWColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: tool.name,
                      style: const TextStyle(
                        color: PWColors.papel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: ' — ${tool.tagline}'),
                  ],
                ),
                style: const TextStyle(
                  color: PWColors.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 16, color: PWColors.accent),
          ],
        ),
      ),
    ),
  );
}

/// The rule above a group of cards, or above the Discord strip.
class _Secao extends StatelessWidget {
  const _Secao({required this.nome});

  final String nome;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        nome.toUpperCase(),
        style: const TextStyle(
          color: PWColors.textMuted,
          fontSize: 11,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: PWColors.border, height: 1)),
    ],
  );
}

class _Cards extends StatelessWidget {
  const _Cards({required this.tools, required this.wide});

  final List<Tool> tools;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (final tool in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ToolCard(tool: tool, wide: false),
            ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < tools.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            // An odd tool at the end takes the whole row rather than half of
            // it. Left at half width it sat beside an empty square, and an
            // empty square in a grid reads as a card that failed to load — the
            // full-width one reads as a decision.
            child: i + 1 < tools.length
                // `stretch` needs a bounded height to stretch to, and inside a
                // shrink-wrapped list there is none: the cards were handed an
                // infinite height and stopped painting their own background.
                // IntrinsicHeight measures the taller card first, which is
                // also what makes a pair line up when their taglines differ in
                // length.
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: ToolCard(tool: tools[i], wide: true)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ToolCard(tool: tools[i + 1], wide: true),
                        ),
                      ],
                    ),
                  )
                : ToolCard(tool: tools[i], wide: true),
          ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Text(
        'Projeto de fã, sem vínculo com o The Classic Games. Lê apenas páginas '
        'públicas do marketplace.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PWColors.textMuted, fontSize: 12, height: 1.5),
      ),
      const SizedBox(height: 8),
      // **A licença cobre o repositório; esta linha cobre a página.** Quem
      // copia não clona o repositório — olha o site, e em 29/09/2026 onze dos
      // nossos quinze nomes de combo apareceram no bundle de outro site. Sem
      // nada escrito aqui, "não sabia" é uma defesa disponível.
      //
      // Duas frases e não uma, porque elas dizem coisas opostas e juntá-las
      // seria reivindicar o que não é nosso: o que reservamos são as
      // compilações — os combos, a escada das runas, as 126 receitas —, e
      // nomes, arte e dados do jogo são da The Classic. Reivindicar esses
      // seria falso e enfraqueceria o resto.
      const Text(
        '© 2026 Portal PW · todos os direitos reservados sobre o código e as '
        'compilações deste site.\nNomes, atributos e arte do jogo pertencem à '
        'The Classic Games.',
        textAlign: TextAlign.center,
        style: TextStyle(color: PWColors.textMuted, fontSize: 11, height: 1.5),
      ),
      const _VisitCount(),
      // The mark alone, in the corner. The invitation is spelled out in its
      // own section higher up the page; a second one here would be nagging.
      // What a footer icon is for is the visitor who has already decided and
      // is looking for the door — and it carries a tooltip and a semantic
      // label, because a lone glyph with no words is exactly the thing a
      // screen reader cannot guess.
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
          onPressed: () => unawaited(
            launchUrl(
              Uri.parse(discordInvite),
              mode: LaunchMode.externalApplication,
            ),
          ),
          tooltip: 'Discord do Portal PW',
          icon: const DiscordIcon(size: 19, color: PWColors.textMuted),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(),
        ),
      ),
    ],
  );
}

/// Visits, once they are known.
///
/// It says *visitas* and not *pessoas* because that is what it counts: one per
/// browser per day. Claiming people would be a small lie that grows with the
/// number.
///
/// Nothing is drawn while the count is unknown — no spinner, no dash, no
/// "carregando". Whoever reads a footer is not waiting on it, and a counter
/// that fails should look like a page that never had one.
class _VisitCount extends StatelessWidget {
  const _VisitCount();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<VisitCounterViewModel, int?>(
        builder: (context, total) => total == null
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  visitLabel(total),
                  style: const TextStyle(
                    color: PWColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
      );
}
