import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/browser_memory.dart';
import '../../../core/theme/pw_colors.dart';
import '../../../market/market_index.dart';
import '../../search/domain/search_query.dart';
import '../../search/domain/search_query_url.dart';
import '../../search/ui/search_state.dart';
import '../../search/ui/search_view_model.dart';
import '../domain/arte_da_classe.dart';
import '../domain/visit_label.dart';
import 'visit_counter_view_model.dart';
import '../domain/community.dart';
import '../domain/novidade.dart';
import '../../../core/widgets/brand_icon.dart';
import 'novidades_view_model.dart';
import 'widgets/ao_vivo_strip.dart';
import 'widgets/cabecalho.dart';
import 'widgets/cartaz.dart';
import 'widgets/destaques_view.dart';
import 'widgets/discord_strip.dart';
import 'widgets/news_section.dart';

/// The Portal's front page: the mark, the Cartaz, the Destaques, Novidades,
/// Streamers and Comunidade.
///
/// It loads the market index like the filter does, and for the same reason it
/// is worth the wait: the Cartaz and the Destaques are both drawn from it. The
/// Cartaz opens on a class's own art before a single number is known, so the
/// wait never blanks the fold — only the class-specific parts (the Cartaz's
/// class and the six Destaques cards) wait on the load.
///
/// **The tool cards that used to sit below the Destaques are gone.**
/// `Cabecalho`'s pills, on every screen, already list the same tools and the
/// same guide — a second navigation surface for the same set, on the same
/// page, was the thing the owner called out on 01/10/2026: "não acho que
/// valha a pena duplicar".
/// One store for the whole page, built once.
///
/// A fresh instance per rebuild would read `localStorage` on every frame,
/// which is the call the guard in `BrowserMemory` exists to keep cheap and
/// quiet — and the news bar reads its marker exactly once per load.
final _memoriaDasNovidades = BrowserMemory.platform(
  'portal_pw_ultima_novidade',
);

/// Opens the filter already answering [query] — every Destaques card is a
/// door into the search that produced it, encoded the same way a shared
/// link is so the filter screen reads it back with `requestUrl`.
void _abrirBusca(BuildContext context, MarketIndex index, SearchQuery query) {
  final q = encodeQuery(query, index);
  Navigator.of(context).pushNamed(q.isEmpty ? '/filtro' : '/filtro?$q');
}

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  /// Above this the page is not competing for space, and holding the layout at
  /// its tablet size leaves the mark reading as a small card adrift in black —
  /// on a 1920 monitor the logo was 18% of the width. Everything grows a step.
  static const _largeWidth = 1280.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // The grid becomes a column below this — the same number as
    // `Cabecalho.larguraMinima`, where its own pills collapse into the
    // overflow menu. One breakpoint, read from the one place it is defined.
    final wide = width >= Cabecalho.larguraMinima;
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
            // The page has grown since — the Destaques, the news panel — and on
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
                    // see `_ComMargem` — because the Cartaz bleeds to the
                    // column's own edges, and a shared side padding here
                    // would either pinch it or leave every other section
                    // without one.
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
                            child: Cabecalho(
                              wide: wide,
                              aoAbrirNovidades: () =>
                                  Navigator.of(context).pushNamed('/novidades'),
                            ),
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
                                    classe: classeDoCartaz(
                                      ready?.index.collectedAt,
                                    ),
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
                                    _ComMargem(
                                      wide: wide,
                                      child: DestaquesView(
                                        index: ready.index,
                                        wide: large,
                                        onAbrir: (query) => _abrirBusca(
                                          context,
                                          ready.index,
                                          query,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                          // The tool cards and the guide line used to sit
                          // here, under a `FERRAMENTAS`/`GUIA` heading. They
                          // left on 01/10/2026: `Cabecalho`'s pills, on every
                          // screen, already list the same tools and the same
                          // guide — a card sold them with art and a tagline,
                          // a pill only lists them, but keeping both put two
                          // navigation surfaces for one set on the same page,
                          // one above the other. "não acho que valha a pena
                          // duplicar" is the owner's own call, 01/10/2026. The
                          // *novo* badge that lived on the Títulos card moved
                          // to `GavetaItem`, the drawer row each pill opens —
                          // the one place left that can still show it.
                          SizedBox(height: large ? 32 : (wide ? 26 : 20)),
                          _ComMargem(
                            // The teaser the bar's *Novidades* pill no longer
                            // needs to scroll to — it opens `/novidades`
                            // directly now. This stays as a closed accordion
                            // that a returning visitor can glance at without
                            // leaving the front page.
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

/// The rule above the Comunidade section.
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
