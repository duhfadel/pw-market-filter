import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/arte_da_classe.dart';
import 'palco_de_classe.dart';

/// The hero the front page now opens on: a class's own art, full-bleed, with
/// the claim written in the empty space it leaves.
///
/// It replaces the plain text header — the art is not a picture beside the
/// content, it is the ground the content stands on. The class changes what a
/// visitor sees on arrival, so two visits do not open the same page.
class Cartaz extends StatelessWidget {
  const Cartaz({
    required this.classe,
    required this.wide,
    required this.aoBuscar,
    required this.subtitulo,
    super.key,
  });

  /// The class whose art and accent the hero wears this visit.
  final String classe;

  /// Whether the page has room for the wide layout.
  final bool wide;

  /// Called when the one button on the hero is pressed.
  final VoidCallback aoBuscar;

  /// The claim under the headline — required rather than defaulted, because
  /// the two marketplaces this hero can open on do not carry the same
  /// families to promise. 1.2.6 has no cards, relics, essences or runes in
  /// its own filter (the pruning this branch exists for), so a caller that
  /// never says which market it is standing in is exactly how a 1.2.6 Cartaz
  /// once shipped advertising all four anyway.
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final acento = acentoDaClasse(classe);

    return PalcoDeClasse(
      classe: classe,
      // Measured against the real fonts, not guessed: `Cartaz` was tested
      // only at 1200 px wide (`cartaz_test.dart`) and never at `wide: false`
      // at all, so the fixed 320/260 pair overflowed the moment the front
      // page actually wired this widget in — 36 px over at `wide: true` and
      // 68 px over at `wide: false`, in both cases regardless of width,
      // because neither the eyebrow, the headline nor the 430 px sub-line
      // ever wrap differently above that width. These two numbers are the
      // old ones plus that overflow, rounded up for a margin.
      altura: wide ? 360 : 340,
      margemHorizontal: wide ? 56 : 24,
      child: _Conteudo(
        acento: acento,
        wide: wide,
        aoBuscar: aoBuscar,
        subtitulo: subtitulo,
      ),
    );
  }
}

/// The top layer: eyebrow, headline, sub-line and the one button, all
/// left-aligned in the art's negative space.
class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.acento,
    required this.wide,
    required this.aoBuscar,
    required this.subtitulo,
  });

  final Color acento;
  final bool wide;
  final VoidCallback aoBuscar;
  final String subtitulo;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MERCADO DE PERSONAGENS · THE CLASSIC',
        style: TextStyle(
          color: acento,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Ache o personagem\npelo que ele está usando',
        style: TextStyle(
          fontFamily: PWTheme.display,
          fontSize: wide ? 40 : 28,
          color: PWColors.papel,
          height: 1.15,
        ),
      ),
      const SizedBox(height: 14),
      // A ceiling, not a value gated on `wide`: the fixed `SizedBox(width:
      // 430)` this replaced was never exercised below that width until the
      // real page was pumped at phone size with a loaded index — `Cartaz`
      // sits outside any `BlocBuilder` gate, so it renders at every width
      // whether or not the market has loaded. Keying the fix off `wide`
      // (this widget's `wide` is the page's `large` flag, ≥1280) over-reached:
      // the 680–1279 tablet band has 732 px of its own content width to
      // offer and took it, running the line out to about 120 characters
      // where it was measured to 430. `ConstrainedBox` caps it at 430
      // everywhere above `large`'s step down to the narrow layout's own
      // 342 px, which is already below the cap and needs no gate at all.
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Text(
          subtitulo,
          style: const TextStyle(
            color: PWColors.apagado,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
      ),
      const SizedBox(height: 22),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: aoBuscar,
            icon: Icon(Icons.search, size: wide ? 20 : 18),
            label: const Text('Buscar personagens'),
            style: FilledButton.styleFrom(
              // The fill is gold because this is the call to action; the
              // label sits on it and must not be gold on gold.
              backgroundColor: PWColors.accent,
              foregroundColor: PWColors.noite,
              // Smaller at narrow: the same button at the wide padding and
              // type size overflowed the 342 px the narrow layout actually
              // has by 29 px, below `_twoColumnWidth` — never caught before
              // because nothing had pumped `Cartaz` with `wide: false`
              // inside the real page, only standalone at 1200 px.
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 26 : 18,
                vertical: wide ? 16 : 13,
              ),
              textStyle: TextStyle(
                fontSize: wide ? 16 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
