import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/market_index.dart';
import '../../../search/domain/search_query.dart';
import '../../domain/arte_da_classe.dart';
import '../../domain/destaques.dart';

/// The front page's argument, made of real people instead of a sentence: one
/// character per question about the market — six for 1.8.7 (`destaquesDe`),
/// two for 1.2.6 (`destaques126De`, [pw126]) — drawn full-bleed so the art
/// itself is the card, the same reasoning the Cartaz already carries, one
/// size down.
///
/// Draws nothing when the market answers no cards at all: a section with a
/// frame and no content inside it would be a claim this collection cannot
/// back up. A market that answers fewer cards than the question set asks —
/// a class collision with no untaken class left, or a tier the collection
/// never reached — draws fewer rather than a gap, which is the chosen
/// function's own rule and not repeated here.
///
/// **On a phone the six scroll sideways in one row instead of wrapping to
/// three** — the owner's own call, 01/10/2026, over the grid's three rows of
/// two eating roughly 800 px of height there. Wide screens are untouched; see
/// [_Carrossel].
class DestaquesView extends StatelessWidget {
  const DestaquesView({
    required this.index,
    required this.wide,
    required this.onAbrir,
    this.pw126 = false,
    super.key,
  });

  final MarketIndex index;

  /// Reads `destaques126De` instead of `destaquesDe` — two cards instead of
  /// six, since nobody has studied the 1.2.6 market enough yet to ask it the
  /// other four questions. See `destaques.dart` for the reasoning; this flag
  /// only chooses which function this widget calls.
  final bool pw126;

  /// Whether the page has room for the wide layout. The grid itself reads its
  /// own available width to pick a column count — see [_columnsFor] — so this
  /// only steers the spacing between cards, the way every other section on
  /// this page uses it for its own padding.
  final bool wide;

  /// Called with the query behind whichever card was tapped. Every card is a
  /// door into the filter that produced it.
  final void Function(SearchQuery) onAbrir;

  /// Six columns on a wide screen, three in the middle band — above this, a
  /// grid. Below it, a phone, where a 2:3 card at ~180 px wide still eats
  /// about 800 px of height across three rows; [build] reads this same
  /// threshold to switch to the carousel instead of drawing two columns of
  /// it. **Never one column**, in either shape: a single column on a grid
  /// would be six screens of scrolling, and a carousel is exactly the fix for
  /// that, not a narrower case of it.
  ///
  /// Read from the grid's own constraints rather than from [wide]: this
  /// widget can sit inside a narrower column than the page itself allows (a
  /// side margin, a reading width cap), and asking the real box is what the
  /// results grid already does for the same reason.
  static int _columnsFor(double width) {
    if (width >= 760) return 6;
    if (width >= 440) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final destaques = pw126 ? destaques126De(index) : destaquesDe(index);
    if (destaques.isEmpty) return const SizedBox.shrink();

    final spacing = wide ? 14.0 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The phone case: three rows of two columns ate ~800 px of height,
        // roughly three screens before the next section even started. One
        // row that scrolls sideways is the owner's own call, 01/10/2026 —
        // wide screens keep the grid untouched below.
        if (_columnsFor(constraints.maxWidth) == 2) {
          return _Carrossel(
            destaques: destaques,
            onAbrir: onAbrir,
            spacing: spacing,
            largura: constraints.maxWidth,
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnsFor(constraints.maxWidth),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            // The proportion the brief sets: the art is the card.
            childAspectRatio: 2 / 3,
          ),
          itemCount: destaques.length,
          itemBuilder: (context, i) =>
              _Carta(destaque: destaques[i], onAbrir: onAbrir),
        );
      },
    );
  }
}

/// One row, swiping through all six, on a phone.
///
/// **The last visible card is deliberately cut, not flush with the
/// margin.** A row that ends flush reads as "this is everything the section
/// has"; the clipped edge is what tells a thumb there is more to drag. Each
/// card's width is a fixed fraction of the viewport rather than whatever
/// would divide it evenly, so the cut is true at every phone width this runs
/// at rather than true by luck at one of them.
class _Carrossel extends StatelessWidget {
  const _Carrossel({
    required this.destaques,
    required this.onAbrir,
    required this.spacing,
    required this.largura,
  });

  final List<Destaque> destaques;
  final void Function(SearchQuery) onAbrir;
  final double spacing;

  /// The viewport's own measured width — not `MediaQuery`, for the same
  /// reason [DestaquesView._columnsFor] reads its constraints instead of
  /// [DestaquesView.wide]: this section does not always sit at the page's
  /// full width.
  final double largura;

  /// A touch under half the viewport: two full cards and a clipped sliver of
  /// a third always fit, rather than however many happen to divide the
  /// screen evenly that day.
  ///
  /// **This number is a judgement call, not a measurement** — nobody timed a
  /// thumb against it the way the weapon tiers were measured off the market.
  /// What it must not break, whatever it is retuned to, is the one property
  /// the carousel exists for: the third card has to stay visibly cut, never
  /// flush with the margin, because the cut edge is what tells somebody
  /// there is more to drag. `destaques_view_test.dart` pins that as a range
  /// (a card between a third and a half of the viewport) rather than this
  /// exact fraction, on purpose — retune it within that range freely.
  static const _fracaoDoCard = 0.44;

  @override
  Widget build(BuildContext context) {
    final larguraDoCard = largura * _fracaoDoCard;
    final alturaDoCard = larguraDoCard * 3 / 2;

    return SizedBox(
      height: alturaDoCard,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: destaques.length,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: (context, i) => SizedBox(
          width: larguraDoCard,
          child: _Carta(destaque: destaques[i], onAbrir: onAbrir),
        ),
      ),
    );
  }
}

/// One of the six: a tall card whose background is the class's own art.
class _Carta extends StatelessWidget {
  const _Carta({required this.destaque, required this.onAbrir});

  final Destaque destaque;
  final void Function(SearchQuery) onAbrir;

  @override
  Widget build(BuildContext context) {
    final arte = arteVerticalDaClasse(destaque.personagem.characterClass);
    final cor = destaque.cor;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: PWColors.painel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // The plain border when the character carries no weapon tier at
        // all — a colour on somebody with no tier would be the lie, not the
        // omission. `destaque.cor` already made that call; this only draws
        // it.
        side: BorderSide(
          color: cor ?? PWColors.filete,
          width: cor == null ? 1 : 1.5,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A class with no art draws the plain ground, never a borrowed
          // face — the same silent fallback `arteVerticalDaClasse` itself
          // makes by returning null.
          if (arte != null)
            Image.asset(
              arte,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.76),
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),
          const _Veu(),
          if (destaque.selo != null) _Selo(texto: destaque.selo!),
          _Rodape(destaque: destaque),
          // The `InkWell` on top rather than wrapping the `Stack`: an
          // `InkWell` paints its splash on the nearest `Material` ancestor,
          // which is the `Card` itself here — *underneath* every child
          // painted after it, the full-bleed `Image` included. A card that
          // is entirely a link gave no visible press feedback for it. This
          // `Material` is its own ink surface, layered above the art and the
          // footer, so the splash is seen rather than hidden behind them.
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(onTap: () => onAbrir(destaque.busca)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Darkens only the card's lower third, so the footer's text has solid
/// ground to land on without flattening the art above it.
class _Veu extends StatelessWidget {
  const _Veu();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        // Four stops, not three, and the ramp starts at 38% rather than 62%.
        //
        // The label is the **first** line of the footer, so a veil that is
        // still nearly clear where the footer begins leaves it sitting on raw
        // artwork — and six classes means six different brightnesses behind
        // it. Measured on the published build: the first card read fine only
        // because that art happens to be dark there, while the other five
        // ellipsized into the picture. A gradient that depends on which
        // painting is behind it is not a gradient, it is a coincidence.
        colors: [
          Colors.transparent,
          PWColors.noite.withValues(alpha: 0.55),
          PWColors.noite.withValues(alpha: 0.88),
          PWColors.noite.withValues(alpha: 0.97),
        ],
        stops: const [0.38, 0.58, 0.78, 1],
      ),
    ),
  );
}

/// The corner badge — `ARMA 70`, the key count — when the question this card
/// answers has one.
class _Selo extends StatelessWidget {
  const _Selo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) => Positioned(
    left: 8,
    top: 8,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: PWColors.noite.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          color: PWColors.papel,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    ),
  );
}

/// The text over the veil, in the order the brief fixes: the question this
/// card answers, who answers it, what they are, what it costs, and the one
/// line that says why the number is believable.
///
/// Every number here stays off [PWTheme.display] — Marcellus draws Roman
/// figures, and this card's whole job is showing a price nobody can read as
/// `I5O TCC`. Not importing the face at all is what makes that true by
/// construction rather than by remembering not to set it.
class _Rodape extends StatelessWidget {
  const _Rodape({required this.destaque});

  final Destaque destaque;

  @override
  Widget build(BuildContext context) {
    final personagem = destaque.personagem;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              destaque.rotulo,
              style: const TextStyle(
                color: PWColors.apagado,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              personagem.name,
              style: const TextStyle(
                color: PWColors.papel,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'nv ${personagem.level} · ${personagem.characterClass}',
              style: const TextStyle(color: PWColors.apagado, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              '${personagem.price} TCC',
              style: const TextStyle(
                color: PWColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              destaque.nota,
              style: const TextStyle(color: PWColors.apagado, fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
