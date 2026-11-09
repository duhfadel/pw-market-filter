import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../home/ui/widgets/tool_navigation.dart';
import '../../../../core/theme/pw_theme.dart';
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
  const GuiasSecao({required this.versao, required this.wide, super.key});

  /// `1.8.7`, `1.2.6`, `1.4.4` — ou **nulo na raiz**, que serve as três e por
  /// isso lista todos.
  ///
  /// Era obrigatório até 09/11/2026, quando a raiz deixou de ser um
  /// torniquete e passou a ter secções próprias. A regra não mudou, só ganhou
  /// o caso de fora: *todos os guias* é simplesmente não filtrar.
  final String? versao;

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final deCa = guiasDe(versao);
    if (deCa.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Cabeca(
          // **O título diz o escopo da secção, não o da outra página.** Na
          // raiz ela é mesmo toda a lista; numa tela de versão é um recorte,
          // e chamar-lhe *todos* seria afirmar que o site tem oito guias de
          // 1.2.6 quando tem um.
          titulo: versao == null ? 'TODOS OS GUIAS' : 'GUIAS',
          // E a porta diz o que a outra página acrescenta, em vez de repetir
          // o que esta já mostra.
          porta: versao == null
              ? 'com tempo de leitura →'
              : 'os ${guias.length} →',
          aoVerTodos: () => abrirEndereco(context, '/guias/', externo: true),
        ),
        SizedBox(height: wide ? 16 : 12),
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
                for (final guia in deCa)
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

class _Cabeca extends StatelessWidget {
  const _Cabeca({
    required this.titulo,
    required this.porta,
    required this.aoVerTodos,
  });

  final String titulo;
  final String porta;
  final VoidCallback aoVerTodos;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        titulo,
        style: const TextStyle(
          color: PWColors.apagado,
          fontSize: 11,
          letterSpacing: 2,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 14),
      const Expanded(child: Divider(color: PWColors.border, height: 1)),
      const SizedBox(width: 14),
      // **A porta para a lista vive na cabeça e não no fim.** Em baixo, ela
      // aparecia depois de oito cartas e só a encontrava quem rolasse até
      // lá; aqui está onde alguém olha para decidir se vale a pena rolar.
      InkWell(
        onTap: aoVerTodos,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            porta,
            style: const TextStyle(color: PWColors.accent, fontSize: 12.5),
          ),
        ),
      ),
    ],
  );
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
          padding: EdgeInsets.all(wide ? 18 : 14),
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
                SizedBox(height: wide ? 12 : 10),
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
              SizedBox(height: wide ? 8 : 6),
              Text(
                guia.linha,
                style: TextStyle(
                  color: PWColors.apagado,
                  fontSize: wide ? 13 : 12.5,
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
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: destacada
          ? PWColors.accent.withValues(alpha: 0.12)
          : PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: destacada ? PWColors.accent : PWColors.border),
    ),
    child: Text(
      texto,
      style: TextStyle(
        color: destacada ? PWColors.accent : PWColors.textMuted,
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    ),
  );
}
