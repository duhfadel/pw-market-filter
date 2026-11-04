import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/set_stones.dart';
import '../../domain/search_query.dart';
import '../../domain/stone_set_criterion.dart';
import '../search_state.dart';
import '../search_view_model.dart';
import 'section_header.dart';

/// O conjunto de pedras de nível nas sete peças.
///
/// **Um conjunto é tudo ou nada**, e a frase sob o título diz isso porque a
/// regra não se adivinha olhando para os chips: faltar a pedra numa das sete
/// peças tira o personagem da lista, mesmo que as outras seis estejam no
/// nível pedido.
///
/// **E o nível é o da pior peça.** Quem tem seis pedras em +2 e uma em +1
/// aparece em *+1* e não em *+2* — pedido do dono, e a razão é que ali ele
/// não cumpre o requisito. Como os chips são um mínimo, o conjunto todo em
/// +3 também responde a *+1*: quem procura o mais barato que serve continua
/// a encontrar quem tem melhor.
///
/// **Defesa +1 não é oferecida porque a pedra não existe.** Zero encaixes em
/// 2.486 personagens, nem no equipamento nem no acessório. Um chip que não
/// pode dar resultado é pior do que chip nenhum — ver `setsDisponiveis`.
class StoneSetSection extends StatelessWidget {
  const StoneSetSection({
    required this.state,
    required this.viewModel,
    super.key,
  });

  final SearchReady state;
  final SearchViewModel viewModel;

  /// Quantos, no escopo, têm cada conjunto.
  ///
  /// Lido do escopo que exclui este próprio controlo, como todos os outros:
  /// senão escolher *Ataque +3* faria os outros chips contarem só dentro de
  /// quem já tem Ataque +3, e a volta para trás ficaria sem números.
  Map<(StoneKind, int), int> get _quantos {
    final conta = <(StoneKind, int), int>{};
    for (final c in state.facetsFor(FacetDimension.stoneSet).scope) {
      for (final kind in StoneKind.values) {
        final nivel = stoneSetLevel(c, kind);
        if (nivel == null) continue;
        for (final s in setsDisponiveis) {
          if (s.kind == kind && nivel >= s.level) {
            conta[(kind, s.level)] = (conta[(kind, s.level)] ?? 0) + 1;
          }
        }
      }
    }
    return conta;
  }

  @override
  Widget build(BuildContext context) {
    final conta = _quantos;
    // Um mercado onde ninguém tem conjunto nenhum não desenha a secção — a
    // mesma regra das perícias e dos mascotes, e o que mantém esta tela
    // igual nos dois mercados sem saber em qual está.
    if (conta.isEmpty) return const SizedBox.shrink();

    final escolhido = state.query.stoneSet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: SectionHeader(
            title: 'Pedras do set',
            emblem: stoneIcon,
            expanded: true,
          ),
        ),
        const Text(
          'Mostra só quem tem a pedra nas sete peças — elmo, peito, perneira, '
          'bota, luvas, colar e ornamento. Faltando uma, não aparece.',
          style: TextStyle(color: PWColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in setsDisponiveis)
              Builder(
                builder: (_) {
                  final n = conta[(s.kind, s.level)] ?? 0;
                  final ligado =
                      escolhido?.kind == s.kind && escolhido?.level == s.level;
                  return ChoiceChip(
                    // **Só o atributo, sem a contagem** — pedido do dono a
                    // 04/11/2026. A contagem estava lá para ninguém clicar
                    // num conjunto vazio sem saber; esse trabalho passa a
                    // ser todo do chip apagado, que é o sinal mais curto
                    // para a mesma coisa. Cinco chips com número viravam
                    // cinco linhas de dígitos num painel onde o preço e o
                    // nível já competem pela mesma atenção.
                    // **Uma pedra só, a do equipamento, sem moldura.**
                    //
                    // A pilha das duas foi tentada e rejeitada a
                    // 04/11/2026, e a razão é a arte e não o desenho: estes
                    // ícones são 32×32 **opacos**, com moldura e fundo
                    // próprio, portanto sobrepostos leem como duas caixas
                    // em cima uma da outra. Recortar o fundo foi medido em
                    // três tolerâncias e não sai limpo — a pedra tem brilho
                    // que se dissolve no fundo, e não há fronteira onde
                    // cortar sem deixar halo ou comer o brilho.
                    //
                    // A escolhida é a das cinco peças. O colar e o
                    // ornamento levam outra pedra, com outra arte; o chip
                    // aponta o conjunto, não a lista de compras.
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StoneIcon(equipmentStoneOf(s.kind, s.level).id, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          setLabel(s.kind, s.level),
                          style: TextStyle(
                            fontSize: 12,
                            color: ligado
                                ? PWColors.background
                                : n == 0
                                ? PWColors.textMuted
                                : PWColors.text,
                          ),
                        ),
                      ],
                    ),
                    selected: ligado,
                    // Um conjunto que ninguém tem fica apagado em vez de
                    // sumir: a ausência é informação, e um chip que
                    // desaparece quando o escopo muda lê como erro.
                    onSelected: n == 0 && !ligado
                        ? null
                        : (liga) => viewModel.setStoneSet(
                            liga
                                ? StoneSetCriterion(
                                    kind: s.kind,
                                    level: s.level,
                                  )
                                : null,
                          ),
                    selectedColor: PWColors.accent,
                    backgroundColor: PWColors.surfaceRaised,
                    showCheckmark: false,
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
