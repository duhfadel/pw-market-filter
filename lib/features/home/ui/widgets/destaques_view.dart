import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../market/market_index.dart';
import '../../../search/domain/search_query.dart';
import '../../domain/arte_da_classe.dart';
import '../../domain/destaques.dart';

/// The front page's argument, made of six real people instead of a sentence:
/// one character per question about the market (`destaquesDe`), drawn
/// full-bleed so the art itself is the card — the same reasoning the Cartaz
/// already carries, one size down.
///
/// Draws nothing when the market answers no cards at all: a section with a
/// frame and no content inside it would be a claim this collection cannot
/// back up. A market that answers fewer than six — a class collision with no
/// untaken class left, or a tier the collection never reached — draws fewer
/// cards rather than a gap, which is `destaquesDe`'s own rule and not
/// repeated here.
class DestaquesView extends StatelessWidget {
  const DestaquesView({
    required this.index,
    required this.wide,
    required this.onAbrir,
    super.key,
  });

  final MarketIndex index;

  /// Whether the page has room for the wide layout. The grid itself reads its
  /// own available width to pick a column count — see [_columnsFor] — so this
  /// only steers the spacing between cards, the way every other section on
  /// this page uses it for its own padding.
  final bool wide;

  /// Called with the query behind whichever card was tapped. Every card is a
  /// door into the filter that produced it.
  final void Function(SearchQuery) onAbrir;

  /// Six columns on a wide screen, three in the middle band, two on a
  /// phone — **never one**. Two 2:3 cards side by side at 390 px still show
  /// the body; one column would be six screens of scrolling to see them all.
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
    final destaques = destaquesDe(index);
    if (destaques.isEmpty) return const SizedBox.shrink();

    final spacing = wide ? 14.0 : 10.0;

    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
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
      child: InkWell(
        onTap: () => onAbrir(destaque.busca),
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
          ],
        ),
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
        colors: [
          Colors.transparent,
          Colors.transparent,
          PWColors.noite.withValues(alpha: 0.92),
        ],
        stops: const [0, 0.62, 1],
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
