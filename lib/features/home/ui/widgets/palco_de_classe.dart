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

import '../../../../core/theme/medidas_da_maquete.dart';
import '../../../../core/theme/pw_colors.dart';
import '../../domain/arte_da_classe.dart';

class PalcoDeClasse extends StatelessWidget {
  const PalcoDeClasse({
    required this.classe,
    required this.altura,
    required this.margemHorizontal,
    required this.child,
    this.enquadramento = EnquadramentoDaArte.cartaz,
    this.capa = false,
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

  /// Como a arte é enquadrada e lavada. Ver [EnquadramentoDaArte].
  final EnquadramentoDaArte enquadramento;

  /// Desenhar [capaDasClasses] — as dezassete de pé — em vez da arte de
  /// [classe].
  ///
  /// **Um parâmetro e não uma dedução do enquadramento**, porque os dois
  /// chamadores passam o mesmo enquadramento e só um quer isto. A primeira
  /// versão inferiu-o de `EnquadramentoDaArte.heroi` e apanhou o `Cartaz`
  /// junto — matando-lhe a rotação por coleta, que é o que faz a tela de
  /// versão mudar de cara entre visitas. Uma bandeira explícita faz essa
  /// escolha ser visível na chamada.
  ///
  /// A raiz pode porque já não roda: o herói dela é sempre o Guerreiro, por
  /// decisão do dono — *«usa a mesma imagem»*. Ali não há rotação a perder.
  final bool capa;

  @override
  Widget build(BuildContext context) {
    final arte = capa ? capaDasClasses : arteVerticalDaClasse(classe);

    return SizedBox(
      width: double.infinity,
      height: altura,
      child: Stack(
        // Non-positioned children fill the box: the art, the two gradients
        // over it, and the text sit in one stack of full-size layers.
        fit: StackFit.expand,
        children: [
          if (arte != null)
            _Arte(
              caminho: arte,
              // **A capa encosta à esquerda, e no desktop isso não muda
              // nada.** A 1420 px ela encaixa exacta — 2840×1520 a meia
              // escala é a caixa inteira — portanto não há corte nenhum para
              // alinhar. Só importa no estreito, onde o `cover` corta pelos
              // lados: com o alinhamento da maquete (0,52) o telemóvel
              // mostrava as tiras do meio, que são as claras, e a manchete
              // ficava a competir com elas. À esquerda mostra as escuras, que
              // é para onde `capa.py` as ordenou de propósito.
              alinhamento: capa
                  ? Alignment(-1, enquadramento.alinhamento.y)
                  : enquadramento.alinhamento,
            ),
          if (enquadramento == EnquadramentoDaArte.cartaz) ...[
            const _LavagemVertical(),
            const _LavagemHorizontal(),
          ] else ...[
            const _VeuDoHeroi(),
            const _VeuDeBaixo(),
          ],
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
  const _Arte({required this.caminho, required this.alinhamento});

  final String caminho;
  final Alignment alinhamento;

  @override
  Widget build(BuildContext context) => Image.asset(
    caminho,
    fit: BoxFit.cover,
    alignment: alinhamento,
    // **`high` fica, e agora é a rede e não o remédio.** Com a capa de pé a
    // ampliação é 1,06×, mas o `Cartaz` continua a deitar uma arte só e a
    // esticá-la; e acima de 1420 px de janela a própria capa passa a ser
    // ampliada. `high` usa reamostragem cúbica — não inventa detalhe, só
    // deixa de o destruir.
    filterQuality: FilterQuality.high,
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

/// Como a arte é enquadrada, e qual par de lavagens a segura.
///
/// **Os dois casos são a mesma arte vista de duas distâncias.** O `Cartaz`
/// mede 1040×360 e abre uma faixa; o herói da raiz mede a largura toda por
/// 760 e abre uma dobra. A mesma fonte 480×720 precisa de recortes
/// diferentes, e o par de lavagens vai junto porque uma lavagem medida para
/// um recorte deixa o outro ilegível.
enum EnquadramentoDaArte {
  /// O recorte do `Cartaz`, medido contra a faixa dele.
  cartaz(Alignment(0, -0.72)),

  /// **O recorte da maquete, lido do CSS dela**: `object-position: 76% 20%`.
  ///
  /// Em CSS, `20%` quer dizer *põe o ponto a 20% da imagem a 20% da caixa*; o
  /// equivalente em Flutter é `2 × 0,20 − 1 = −0,6`. O `76%` só conta quando
  /// a caixa é mais estreita do que a imagem escalada, o que acontece abaixo
  /// de uma janela quadrada.
  ///
  /// **Houve uma volta errada no meio, e vale dizer qual.** Experimentei isto
  /// com o Arqueiro, vi cabelo e pano sem cara, e concluí que o `cover` não
  /// servia num herói largo — a conclusão certa teria sido que o
  /// enquadramento estava mal. Daí saiu um painel encostado à direita que o
  /// dono viu logo como errado. A maquete sempre fez `cover` na largura
  /// toda; só faltava ler o CSS dela em vez de deduzir.
  heroi(Alignment(0.52, -0.6));

  const EnquadramentoDaArte(this._alinhamento);

  final Alignment _alinhamento;

  /// O do herói vem de `Maquete`, que é o ficheiro que o teste confronta com
  /// o CSS. O do `Cartaz` é nosso e fica aqui.
  Alignment get alinhamento => this == EnquadramentoDaArte.heroi
      ? Maquete.alinhamentoDaArte
      : _alinhamento;
}

/// A primeira lavagem do herói, copiada da maquete:
/// `linear-gradient(100deg, #0B0B1A 4%, rgba(11,11,26,.86) 36%,
/// rgba(11,11,26,.1) 66%, rgba(11,11,26,.5) 100%)`.
///
/// **`background` e não `noite`.** O `--noite` da maquete é `#0B0B1A`, que
/// aqui se chama `PWColors.background`; `PWColors.noite` é `#12102A`, cinco
/// pontos de luminância mais claro. Com o nome errado o herói inteiro saía
/// uniformemente mais claro do que a maquete — a medição deu +4 a +12 em
/// todos os pontos, que é a assinatura de um desvio constante e não de um
/// gradiente mal montado.
///
/// **A última paragem sobe outra vez**, de 10% para 50%: escurece a borda
/// direita para a figura não encostar acesa ao fim do ecrã. Era o que faltava
/// à minha versão, que clareava até ao fim.
class _VeuDoHeroi extends StatelessWidget {
  const _VeuDoHeroi();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        // 100° em CSS é da esquerda para a direita, ligeiramente a descer.
        begin: const Alignment(-1, -0.17),
        end: const Alignment(1, 0.17),
        stops: Maquete.veuParagens,
        colors: [
          for (final opacidade in Maquete.veuOpacidades)
            PWColors.background.withValues(alpha: opacidade),
        ],
      ),
    ),
  );
}

/// A segunda: `linear-gradient(to top, noite, transparent 34%)` — o que
/// assenta o herói na secção abaixo em vez de o cortar a direito.
class _VeuDeBaixo extends StatelessWidget {
  const _VeuDeBaixo();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        stops: const [0, Maquete.veuDeBaixoAte],
        colors: [PWColors.background, PWColors.background.withValues(alpha: 0)],
      ),
    ),
  );
}
