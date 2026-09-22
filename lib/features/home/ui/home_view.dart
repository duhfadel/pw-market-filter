import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/browser_memory.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../core/theme/pw_theme.dart';
import '../../search/ui/search_state.dart';
import '../../ads/ad_slot.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/tool.dart';
import '../domain/visit_label.dart';
import 'visit_counter_view_model.dart';
import '../domain/community.dart';
import '../domain/novidade.dart';
import '../../../core/widgets/brand_icon.dart';
import 'novidades_view_model.dart';
import 'widgets/ao_vivo_strip.dart';
import 'widgets/discord_strip.dart';
import 'widgets/news_section.dart';
import 'widgets/market_pulse.dart';
import 'widgets/tool_card.dart';

/// The Portal's front page: the mark, what the place is, live numbers, and the
/// menu.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the numbers here are the argument. "830 à venda, 205 com
/// arma de 70, o mais barato a 120 TCC" says what the site is for in a way no
/// tagline does — and it is only true because the index exists.
///
/// The cards do not wait for it. They are the menu, and a menu that appears a
/// second late is a page that looks broken.
/// One store for the whole page, built once.
///
/// A fresh instance per rebuild would read `localStorage` on every frame,
/// which is the call the guard in `BrowserMemory` exists to keep cheap and
/// quiet — and the news bar reads its marker exactly once per load.
final _memoriaDasNovidades = BrowserMemory.platform(
  'portal_pw_ultima_novidade',
);

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
            // The page has grown since — figures, the news panel — and on a
            // tall window the same rule opened a screen and a half of empty
            // sky above the logo before anything was readable. Vertical
            // centring is a rule about short pages, and this one stopped being
            // one.
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                // 1040 and not 900 at the top step, and the reason is one line of
                // type: at 900 the headline broke with "usando" alone on a second
                // line at every desktop size measured — 1366 and 1920 both. The
                // first sentence a visitor reads is not a good place to hyphenate
                // the argument.
                constraints: BoxConstraints(maxWidth: large ? 1040 : 780),
                child: ListView(
                  // Shrink-wrapped so a short menu sits in the middle of the page
                  // instead of clinging to the top with a screen of nothing under
                  // it — and it still scrolls once the list outgrows the window.
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 20,
                    vertical: wide ? 44 : 28,
                  ),
                  children: [
                    DiscordStrip(wide: wide),
                    SizedBox(height: wide ? 10 : 6),
                    Center(
                      child: Image.asset(
                        'assets/images/portal-pw-logo-v2.webp',
                        // Two thirds of what it was. The mark says the name of the
                        // site and nothing about what it does, and at 440 px it was
                        // the entire first fold of a phone — the visitor scrolled
                        // before learning there was anything here to use.
                        //
                        // The numbers dropped a step when the wordmark lost its
                        // ".net": the new drawing is squarer (1.39 against 1.52),
                        // so the same width would have made it 9% taller and
                        // quietly undone the fold this was measured for. These
                        // widths hold the height where it was.
                        width: large ? 280 : (wide ? 215 : 168),
                        filterQuality: FilterQuality.medium,
                        // The logo is the one asset whose absence would be
                        // baffling rather than cosmetic, so it falls back to the
                        // name rather than to a gap.
                        errorBuilder: (_, _, _) => Text(
                          'PORTAL PW',
                          style: TextStyle(
                            fontSize: wide ? 34 : 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: wide ? 18 : 14),
                    Center(
                      child: Text(
                        'Ache o personagem certo pelo que ele está usando',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: PWTheme.display,
                          color: PWColors.text,
                          // Marcellus is lighter and wider than Roboto at the same
                          // size, so the headline gains a couple of points and
                          // loses the extra weight it needed as a sans.
                          fontSize: large ? 38 : (wide ? 31 : 25),
                          height: 1.25,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    SizedBox(height: wide ? 12 : 10),
                    Center(
                      child: Text(
                        'Filtre os personagens à venda do The Classic PW 1.8.7 por '
                        'arma, cartas, refino e atributos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: PWColors.textMuted,
                          fontSize: large ? 17 : (wide ? 15 : 13),
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: large ? 28 : (wide ? 24 : 20)),
                    const Center(child: _SearchButton()),
                    SizedBox(height: large ? 30 : (wide ? 24 : 20)),
                    BlocBuilder<SearchViewModel, SearchState>(
                      builder: (context, state) => MarketPulse(
                        state: state is SearchReady ? state : null,
                        wide: wide,
                        large: large,
                      ),
                    ),
                    SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                    BlocBuilder<NovidadesViewModel, List<Novidade>>(
                      builder: (context, novidades) => NewsSection(
                        entries: novidades,
                        wide: wide,
                        memoria: _memoriaDasNovidades,
                      ),
                    ),
                    SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                    _Menu(wide: wide),
                    // Depois das ferramentas e antes da publicidade. É o
                    // lugar que combina com o que a coisa é: cortesia a quem
                    // transmite, não o motivo de alguém ter vindo. Em cima
                    // disputaria com as ferramentas; no rodapé ninguém veria.
                    AoVivoStrip(wide: wide),
                    const AdSlot(),
                    SizedBox(height: wide ? 28 : 22),
                    const _Footer(),
                  ],
                ),
              ),
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

/// The menu, under one heading per section.
///
/// A grid rather than a list because it is meant to be scanned, not read: four
/// cards side by side answer "what is here?" in one glance, where four
/// full-width rows answer it in four.
///
/// **The headings separate what the site does from what it explains.** Filed
/// together, the menu said "here are four things"; split, it says "here are
/// the tools, and here is what they are about" — and a guide stops competing
/// with a tool for the same attention.
class _Menu extends StatelessWidget {
  const _Menu({required this.wide});

  final bool wide;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final secao in secoesDaHome) ...[
        _Secao(nome: secao),
        SizedBox(height: wide ? 12 : 10),
        _Cards(tools: toolsDe(secao), wide: wide),
        SizedBox(height: wide ? 26 : 20),
      ],
    ],
  );
}

/// The rule above a group of cards.
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

/// The one primary action on the page.
///
/// Before it the only way into the filter was a card that reads as an
/// illustration, which asks a first-time visitor to guess that the picture is a
/// door.
class _SearchButton extends StatelessWidget {
  const _SearchButton();

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: () => Navigator.of(context).pushNamed('/filtro'),
    icon: const Icon(Icons.search, size: 20),
    label: const Text('Buscar personagens'),
    style: FilledButton.styleFrom(
      backgroundColor: PWColors.accent,
      foregroundColor: PWColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );
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
      const _VisitCount(),
      // The mark alone, in the corner. The invitation is spelled out three
      // times higher up the page; a fourth would be nagging. What a footer
      // icon is for is the visitor who has already decided and is looking for
      // the door — and it carries a tooltip and a semantic label, because a
      // lone glyph with no words is exactly the thing a screen reader cannot
      // guess.
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
