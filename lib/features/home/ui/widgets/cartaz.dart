import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../domain/arte_da_classe.dart';

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
    super.key,
  });

  /// The class whose art and accent the hero wears this visit.
  final String classe;

  /// Whether the page has room for the wide layout.
  final bool wide;

  /// Called when the one button on the hero is pressed.
  final VoidCallback aoBuscar;

  @override
  Widget build(BuildContext context) {
    final arte = arteDaClasse(classe);
    final acento = acentoDaClasse(classe);

    return SizedBox(
      width: double.infinity,
      height: wide ? 320 : 260,
      child: Stack(
        // Non-positioned children fill the box: the art, the two gradients
        // over it, and the text sit in one stack of full-size layers.
        fit: StackFit.expand,
        children: [
          if (arte != null) _Arte(caminho: arte),
          const _LavagemVertical(),
          const _LavagemHorizontal(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: wide ? 56 : 24,
              vertical: 24,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Conteudo(acento: acento, wide: wide, aoBuscar: aoBuscar),
            ),
          ),
        ],
      ),
    );
  }
}

/// The bottom layer: the class's own art, cropped to where its face is.
class _Arte extends StatelessWidget {
  const _Arte({required this.caminho});

  final String caminho;

  @override
  Widget build(BuildContext context) => Image.asset(
    caminho,
    fit: BoxFit.cover,
    // Not a guess: the class arts carry their faces about a fifth of the way
    // down, and `Alignment.center` once landed the visible band on a
    // priest's skirt — on the widest card the site draws, which is where a
    // bad crop shows first. This hero is wider than that card.
    alignment: const Alignment(0, -0.6),
    // A missing file leaves the plain ground rather than a broken box — the
    // same silent fallback `arteDaClasse` itself makes for an unmapped class.
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// A vertical wash of `noite`, light at the top and heavier at the bottom —
/// what seats the hero against the header above it and the Vitrine below.
class _LavagemVertical extends StatelessWidget {
  const _LavagemVertical();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          PWColors.noite.withValues(alpha: 0.18),
          PWColors.noite.withValues(alpha: 0.55),
        ],
      ),
    ),
  );
}

/// A horizontal wash of `noite`, opaque over the text side and gone by the
/// time it reaches the art — what keeps the headline readable without
/// muddying the picture that carries it.
class _LavagemHorizontal extends StatelessWidget {
  const _LavagemHorizontal();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          PWColors.noite,
          PWColors.noite,
          PWColors.noite.withValues(alpha: 0),
        ],
        stops: const [0, 0.24, 0.76],
      ),
    ),
  );
}

/// The top layer: eyebrow, headline, sub-line and the one button, all
/// left-aligned in the art's negative space.
class _Conteudo extends StatelessWidget {
  const _Conteudo({
    required this.acento,
    required this.wide,
    required this.aoBuscar,
  });

  final Color acento;
  final bool wide;
  final VoidCallback aoBuscar;

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
      const SizedBox(
        width: 430,
        child: Text(
          'Arma, cartas, relíquias, essências, runas — o que o marketplace '
          'guarda no inventário e não deixa procurar.',
          style: TextStyle(
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
            icon: const Icon(Icons.search, size: 20),
            label: const Text('Buscar personagens'),
            style: FilledButton.styleFrom(
              // The fill is gold because this is the call to action; the
              // label sits on it and must not be gold on gold.
              backgroundColor: PWColors.accent,
              foregroundColor: PWColors.noite,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
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
