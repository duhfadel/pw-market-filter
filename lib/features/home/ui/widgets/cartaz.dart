import 'package:flutter/material.dart';

import '../../../../core/theme/medidas_da_maquete.dart';
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
    required this.aoVerGuias,
    required this.subtitulo,
    this.margemHorizontal = 24,
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

  /// Abre a lista de guias. **Dois botões e não um**, como na maquete: o
  /// cheio leva ao filtro, que é a razão da tela, e o de contorno aos guias,
  /// que é o que resta a quem não veio comprar.
  final VoidCallback aoVerGuias;

  /// O recuo lateral, para a manchete alinhar com o conteúdo abaixo.
  final double margemHorizontal;

  /// A mesma altura do herói da raiz: `min(86vh, 760px)`.
  static double alturaDoHeroi(bool wide, double alturaDaJanela) => wide
      ? (alturaDaJanela * Maquete.heroiFraccaoDaJanela).clamp(
          Maquete.heroiAlturaMinima,
          Maquete.heroiAlturaMaxima,
        )
      : 470;

  @override
  Widget build(BuildContext context) {
    final acento = acentoDaClasse(classe);

    return PalcoDeClasse(
      classe: classe,
      // **Era 360 px e passou a ser a dobra, a 09/11/2026.** O número antigo
      // estava medido contra as fontes reais e contra a sub-linha de 430 px,
      // e estava certo para o que ele era: uma faixa. A maquete da tela da
      // versão usa o mesmo `.heroi` da raiz — `min-height: min(86vh, 760px)`
      // — portanto deixa de ser faixa e passa a ser dobra.
      //
      // O preço é a faixa do mercado começar abaixo da dobra. Aceite: a
      // manchete diz o que o site faz em sete palavras, e quem rola uma vez
      // encontra os números.
      altura: alturaDoHeroi(wide, MediaQuery.sizeOf(context).height),
      margemHorizontal: margemHorizontal,
      enquadramento: EnquadramentoDaArte.heroi,
      // **A arte à altura em vez de esticada pela largura**, pedido do dono a
      // 10/11/2026 depois de ver as três saídas lado a lado. Troca presença
      // por nitidez: 1,06× em vez de 1,48×, e 507 px de arte em vez da caixa
      // toda. A raiz não faz isto — lá a capa das dezassete resolve a
      // nitidez sem abrir mão da arte a encher, e aqui não serviria porque
      // mataria a rotação de classe por coleta.
      semAmpliar: true,
      child: _Conteudo(
        acento: acento,
        wide: wide,
        aoBuscar: aoBuscar,
        aoVerGuias: aoVerGuias,
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
    required this.aoVerGuias,
    required this.subtitulo,
  });

  final Color acento;
  final bool wide;
  final VoidCallback aoBuscar;
  final VoidCallback aoVerGuias;
  final String subtitulo;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // `.sobre { font-size:11.5px; letter-spacing:.24em; color: magenta }`
      // — e o acento da classe continua a decidir a cor, que é o que faz a
      // sobrancelha pertencer à arte que está por trás dela.
      Text(
        'MERCADO DE PERSONAGENS · THE CLASSIC',
        style: TextStyle(
          color: acento,
          fontSize: wide ? 11.5 : 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.8,
        ),
      ),
      const SizedBox(height: 20),
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
      // **`Wrap` e não `Row`**: com o segundo botão, os dois lado a lado
      // transbordam 178 px num telemóvel de 390 — o `Wrap` põe-nos um sobre
      // o outro em vez de os cortar. A `Row` anterior servia porque havia um
      // botão só.
      Wrap(
        spacing: wide ? 12 : 8,
        runSpacing: 10,
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
          // `.bt2 { background: transparent; border: 1px solid
          // rgba(255,255,255,.28) }` — o segundo caminho, para quem não veio
          // comprar. **Nunca leva a um mercado**: os guias servem as três
          // versões, portanto não escolhe nada por quem clica.
          OutlinedButton(
            onPressed: aoVerGuias,
            style: OutlinedButton.styleFrom(
              foregroundColor: PWColors.text,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 22 : 16,
                vertical: wide ? 16 : 13,
              ),
              textStyle: TextStyle(fontSize: wide ? 15 : 13.5),
            ),
            child: const Text('Ver os guias'),
          ),
        ],
      ),
    ],
  );
}
