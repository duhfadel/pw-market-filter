import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../home/ui/widgets/tool_navigation.dart';
import '../../../../core/theme/pw_theme.dart';
import '../../../../core/ui/cabeca_de_seccao.dart';
import '../../domain/guia.dart';

/// Os guias desta versão, na tela da versão.
///
/// **Lê de `guiasDe(versao)` e não de uma lista própria.** Já houve duas
/// listas de guias que não sabiam uma da outra, e o guia das runas ficou dias
/// publicado sem caminho a partir do site — é a mesma fonte que gera
/// `web/guias/index.html`.
///
/// **Não mostra minutos, ao contrário da página `/guias/`.** O tempo de
/// leitura é medido do próprio ficheiro, e medir ficheiros é `dart:io`, que
/// `lib/` não importa. A alternativa era guardar os minutos à mão na
/// declaração — o mesmo facto em dois sítios, que divergem no dia em que
/// alguém acrescenta um parágrafo. Aqui a pergunta também é outra: nesta tela
/// os guias são uma secção, e é na lista inteira que alguém escolhe o que ler.
///
/// **A etiqueta da versão diz o que difere do escopo da página, e nada
/// mais.** Numa tela de 1.8.7, escrever `1.8.7` em sete de oito cartas é
/// ruído — ali o que vale dizer é qual serve *todas* as versões, porque essa
/// é a que não é de cá. Na raiz é o contrário: ela não tem versão nenhuma,
/// portanto a versão de cada guia é precisamente a informação que falta, e
/// todas as cartas a levam.
class GuiasSecao extends StatelessWidget {
  const GuiasSecao({
    required this.versao,
    required this.wide,
    this.limite = 6,
    super.key,
  });

  /// `1.8.7`, `1.2.6`, `1.4.4` — ou **nulo na raiz**, que serve as três e por
  /// isso lista todos.
  ///
  /// Era obrigatório até 09/11/2026, quando a raiz deixou de ser um
  /// torniquete e passou a ter secções próprias. A regra não mudou, só ganhou
  /// o caso de fora: *todos os guias* é simplesmente não filtrar.
  final String? versao;

  final bool wide;

  /// Quantos cabem na secção antes de a porta levar ao resto.
  ///
  /// **Seis e não oito, pedido do dono a 10/11/2026.** A grelha é de três
  /// colunas no largo, portanto seis são duas filas cheias e oito deixam uma
  /// fila coxa com duas cartas e um buraco de uma.
  ///
  /// A consequência a saber: o corte leva os **últimos** da declaração, e o
  /// último é *Multi contas* — o único guia que serve as três versões, e
  /// portanto o único que na raiz traz a etiqueta *todas as versões*. Movê-lo
  /// para cima em `guia.dart` é o que o põe de volta à vista; a porta leva
  /// lá de qualquer maneira.
  final int limite;

  @override
  Widget build(BuildContext context) {
    final deCa = guiasDe(versao);
    if (deCa.isEmpty) return const SizedBox.shrink();

    final mostrados = deCa.take(limite).toList();
    final cortou = mostrados.length < deCa.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CabecaDeSeccao(
          // **O título diz o escopo da secção, não o da outra página.** Na
          // raiz ela é mesmo toda a lista; numa tela de versão é um recorte,
          // e chamar-lhe *todos* seria afirmar que o site tem oito guias de
          // 1.2.6 quando tem um.
          //
          // E *desta versão* em vez de um `Guias` seco, que é o que a maquete
          // escreve: a secção é um recorte e o título é o único sítio onde
          // isso se diz. Sem ele, quem chega ao 1.2.6 e vê uma carta lê um
          // site que tem um guia, em vez de uma versão que tem um.
          // **E `Todos os guias` deixa de ser verdade quando a secção corta.**
          // Com seis de oito à vista, o título que diz *todos* mente — a
          // mesma razão pela qual a cabeça dos Destaques conta por extenso
          // em vez de cravar *Seis*.
          titulo: versao != null
              ? 'Guias desta versão'
              : cortou
              ? 'Guias'
              : 'Todos os guias',
          // **A porta diz *todos* e não um número, e aqui o número mentia.**
          // Era `os 8 →` numa tela de versão — o total do site, não o resto
          // desta versão —, e no 1.2.6 isso ficava a prometer oito guias
          // quando sete deles não servem aquele mercado. *Ver todos os
          // guias* é exactamente o que a outra página tem, em qualquer tela.
          //
          // É a razão pela qual a secção das guerras mantém o número: lá os
          // 47 são mesmo daquele mercado, portanto dizê-lo é informação e
          // não ruído. Pedido do dono a 10/11/2026, nas palavras dele —
          // *«Ver todos ao invés de Ver X»*.
          porta: 'ver todos os guias →',
          aoTocarNaPorta: () =>
              abrirEndereco(context, '/guias/', externo: true),
        ),
        // `.cab { margin-bottom: 22px }`.
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, limites) {
            // Pela largura disponível e não pelo `wide` da página — o mesmo
            // que a grelha de vídeos e a dos destaques fazem. Três cabem
            // acima de 900; uma só abaixo de 560, onde duas dariam 260 px e
            // o título partiria em três linhas.
            final colunas = limites.maxWidth >= 900
                ? 3
                : limites.maxWidth >= 560
                ? 2
                : 1;
            const espaco = 14.0;
            final largura =
                (limites.maxWidth - espaco * (colunas - 1)) / colunas;

            return Wrap(
              spacing: espaco,
              runSpacing: espaco,
              children: [
                for (final guia in mostrados)
                  SizedBox(
                    width: largura,
                    child: _Carta(guia: guia, versao: versao, wide: wide),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _Carta extends StatelessWidget {
  const _Carta({required this.guia, required this.versao, required this.wide});

  final Guia guia;

  /// A versão da **página**, não do guia — é contra ela que a etiqueta decide
  /// se diz algo. Nula na raiz.
  final String? versao;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    // Ver a nota da classe: a etiqueta diz o que difere do escopo da página.
    final String? etiqueta;
    if (guia.versoes.isEmpty) {
      etiqueta = 'todas as versões';
    } else if (versao == null) {
      etiqueta = guia.versoes.toList().join(' · ');
    } else {
      etiqueta = null;
    }

    return Material(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            abrirEndereco(context, guia.endereco, externo: !guia.noApp),
        child: Container(
          padding: EdgeInsets.all(wide ? 20 : 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PWColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **O chip no topo e não ao lado do título.** Ao lado, ele
              // disputava a largura com o nome e empurrava-o para duas
              // linhas nas cartas estreitas; em cima, tem a linha dele e o
              // título fica com a sua inteira.
              if (etiqueta != null) ...[
                _Etiqueta(texto: etiqueta, destacada: guia.versoes.isEmpty),
                // `.gc { gap: 7px }`.
                const SizedBox(height: 7),
              ],
              // **Marcellus no título, e é seguro aqui**: nenhum título de
              // guia tem algarismos — *Quanto custa uma runa nível 10* é a
              // excepção, e `_semAlgarismos` manda-a para a face do corpo.
              Text(
                guia.titulo,
                style: TextStyle(
                  fontFamily: _semAlgarismos(guia.titulo)
                      ? PWTheme.display
                      : null,
                  fontSize: wide ? 19 : 17,
                  fontWeight: _semAlgarismos(guia.titulo)
                      ? FontWeight.w400
                      : FontWeight.w600,
                  color: PWColors.papel,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                guia.linha,
                style: TextStyle(
                  color: PWColors.apagado,
                  fontSize: wide ? 13.5 : 12.5,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Marcellus desenha figuras romanas: `nível 10` sai **`nível IO`**. Um
  /// título com dígito fica na face do corpo — a mesma regra que a folha dos
  /// guias resolve com `.algarismos`, aqui resolvida escolhendo a face.
  static bool _semAlgarismos(String texto) => !RegExp(r'\d').hasMatch(texto);
}

/// O chip de versão.
///
/// **Só `todas as versões` sai na cor do acento.** É a etiqueta que diz
/// *isto serve-te, sejas de que versão fores*, e é a que vale destacar; uma
/// versão é uma distinção, não uma notícia maior — a mesma regra que os
/// marcadores dos recados já seguem.
class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, this.destacada = false});

  final String texto;
  final bool destacada;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
    decoration: BoxDecoration(
      // `.vtag` não tem fundo na maquete: é só moldura sobre o chão da carta.
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: destacada ? PWColors.accent : PWColors.border),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: destacada ? PWColors.accent : PWColors.textMuted,
        fontSize: 10.5,
        letterSpacing: 0.63,
      ),
    ),
  );
}
