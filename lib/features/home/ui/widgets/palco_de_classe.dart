/// O palco de uma classe: a arte a sangrar, as duas lavagens por cima, e o
/// que lhe derem alinhado à esquerda no espaço vazio que ela deixa.
///
/// **Extraído do `Cartaz` a 09/11/2026**, quando a raiz ganhou um herói
/// próprio. O dispositivo é o mesmo nas duas telas — arte como chão e não
/// como ilustração ao lado — e o que muda é a altura e o texto. Copiá-lo
/// seria a cópia que este repositório já pagou quatro vezes, a última no
/// cartão de vídeo.
///
/// **A altura é de quem chama.** O `Cartaz` mede 360 px porque foi medido
/// contra as fontes reais e a sub-linha dele; o herói da raiz é mais alto
/// porque é a primeira coisa que alguém vê e não tem Destaques logo abaixo a
/// disputar a dobra.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/arte_da_classe.dart';

class PalcoDeClasse extends StatelessWidget {
  const PalcoDeClasse({
    required this.classe,
    required this.altura,
    required this.margemHorizontal,
    required this.child,
    this.arteADireita = false,
    super.key,
  });

  /// A classe cuja arte serve de chão.
  final String classe;

  final double altura;

  /// O recuo lateral do conteúdo. O `Cartaz` usa 56/24; a raiz alinha o
  /// herói com a coluna de leitura dela.
  final double margemHorizontal;

  /// O que se escreve no espaço vazio da arte.
  final Widget child;

  /// Se a arte fica encostada à direita no formato dela, em vez de cobrir a
  /// caixa toda.
  ///
  /// **A diferença é a proporção da caixa contra a da fonte.** A arte é um
  /// retrato 480×720; num `Cartaz` de 1040×360 o `cover` ainda mostra figura,
  /// mas o herói da raiz é mais largo e mais alto e o mesmo `cover` amplia
  /// uma fatia vertical até não restar figura nenhuma — cabelo e pano, sem
  /// cara. É a armadilha que o cartão de largura inteira já pagou: *«o
  /// primeiro card de largura inteira transformou a caixa numa letterbox
  /// 600×110 e a faixa caiu na saia do sacerdote»*.
  ///
  /// Encostada, a arte ocupa a direita no formato em que foi desenhada e o
  /// resto é o chão liso — que é o que a maquete mostra e o que deixa a
  /// manchete ter espaço seu.
  final bool arteADireita;

  @override
  Widget build(BuildContext context) {
    final arte = arteVerticalDaClasse(classe, tamanho: TamanhoDaArte.cartaz);

    return SizedBox(
      width: double.infinity,
      height: altura,
      child: Stack(
        // Non-positioned children fill the box: the art, the two gradients
        // over it, and the text sit in one stack of full-size layers.
        fit: StackFit.expand,
        children: [
          if (arte != null)
            if (arteADireita)
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  // **Pouco mais de metade da largura, com recorte.** A
                  // primeira versão prendeu o painel ao formato da fonte
                  // (2:3), o que o deixava estreito — um quarto da dobra — e
                  // os outros três quartos vazios. O dono pôs a maquete ao
                  // lado e a diferença era essa: ali a arte é cheia e quente,
                  // aqui era um texto com uma ilustração ao canto.
                  //
                  // Largo, o `cover` corta a figura pelos pés em vez de a
                  // espremer, e é o corte certo: estas artes têm a cara no
                  // quinto superior — ver `arteVerticalDaClasse`.
                  widthFactor: 0.58,
                  alignment: Alignment.centerRight,
                  child: _ArteEncostada(caminho: arte),
                ),
              )
            else
              _Arte(caminho: arte),
          const _LavagemVertical(),
          const _LavagemHorizontal(),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: margemHorizontal,
              vertical: 24,
            ),
            child: Align(alignment: Alignment.centerLeft, child: child),
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
    // Not a guess: this is the 480x720 vertical crop, and its face sits much
    // higher than the square's did — `-0.6` was tuned for that square and
    // would land this art's face on its chest. `arteVerticalDaClasse`'s own
    // doc has the full reasoning for the second folder.
    alignment: const Alignment(0, -0.72),
    // A missing file leaves the plain ground rather than a broken box — the
    // same silent fallback `arteVerticalDaClasse` itself makes for an
    // unmapped class.
    errorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}

/// A vertical wash of `noite`, light at the top and heavier at the bottom —
/// what seats the hero against the header above it and the Destaques below.
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

/// A arte encostada à direita, com a borda esquerda a desvanecer.
///
/// **Sem isto ela corta a pique** e lê-se como uma imagem colada em cima do
/// fundo em vez do chão da página — foi o primeiro resultado ao encostá-la, e
/// só se viu renderizando. A lavagem horizontal do palco não serve aqui:
/// ela está medida para arte que cobre a caixa toda, portanto acaba muito
/// antes de chegar a esta.
class _ArteEncostada extends StatelessWidget {
  const _ArteEncostada({required this.caminho});

  final String caminho;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      _Arte(caminho: caminho),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            // Opaco na borda e nada a partir de um terço: o suficiente para
            // a junta desaparecer, pouco o bastante para a figura ficar
            // inteira — que é a razão de a arte ter sido encostada.
            stops: const [0, 0.34],
            colors: [PWColors.noite, PWColors.noite.withValues(alpha: 0)],
          ),
        ),
      ),
      // **E as bordas de cima e de baixo, pela mesma razão.** A fonte tem
      // fundo próprio, portanto onde ela acaba fica uma aresta horizontal
      // recta — visível no topo, onde a arte encontra a barra. Curtas de
      // propósito: a figura tem a cara no quinto superior e um desvanecer
      // largo comê-la-ia.
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.14, 0.86, 1],
            colors: [
              PWColors.noite,
              Color(0x0012102A),
              Color(0x0012102A),
              PWColors.noite,
            ],
          ),
        ),
      ),
    ],
  );
}
