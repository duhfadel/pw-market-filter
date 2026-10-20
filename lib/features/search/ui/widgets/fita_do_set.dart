import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/market_index.dart';
import '../../../../market/pedras.dart';
import '../../../../market/slot_names.dart';

/// Tudo o que o personagem traz vestido, numa fita no fim do card.
///
/// **O índice já tinha isto desde sempre e a tela mostrava uma peça.** Cada
/// personagem publicado traz as catorze peças com o item, o refino e as
/// pedras; o card nomeava só as que respondiam a um critério, porque foi para
/// isso que nasceu. A fita responde à outra pergunta, a que se faz a varrer
/// uma grelha: *o que é que este está a usar?*
///
/// **Duas filas de sete, e o número é medido.** O card tem 324 px de largura
/// útil; catorze ícones numa fila dariam 21 px cada, que é uma mancha de cor
/// e não um item reconhecível. Em duas filas cabem 30 px, onde a silhueta e a
/// cor de raridade já se lêem.
///
/// **Sem nome por baixo de ícone nenhum**, que é a regra desta casa ao
/// contrário do que parece: a proibição é nomear um item *sem o seu número*,
/// porque três armas chamadas `Dilacerador` dão 30, 40 e 70. Um ícone não
/// afirma nada — e quem quiser saber qual é passa o rato e lê o nome inteiro
/// com o refino e as pedras, que é precisamente o número que faltava.
class FitaDoSet extends StatelessWidget {
  const FitaDoSet({required this.character, required this.index, super.key});

  final MarketCharacter character;
  final MarketIndex index;

  /// As peças por slot, para as linhas poderem ir buscá-las por nome.
  Map<int, EquippedItem> get _porSlot => {
    for (final peca in character.equipped) peca.slot: peca,
  };

  @override
  Widget build(BuildContext context) {
    if (character.equipped.isEmpty) return const SizedBox.shrink();

    final porSlot = _porSlot;
    final linhas = [
      for (final linha in linhasDaFitaDe(index))
        [for (final slot in linha) ?porSlot[slot]],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final linha in linhas)
          if (linha.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  for (final peca in linha) ...[
                    _Peca(peca: peca, index: index),
                    const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
        // **Uma peça que não caiba em linha nenhuma desenha-se na mesma, no
        // fim** — menos a arma, que o bloco acima já nomeia com o seu número.
        // As linhas são a arrumação de hoje; um slot que o jogo acrescente
        // amanhã ficaria de fora em silêncio, e um personagem a usar uma peça
        // que o card não mostra é pior do que uma fila desarrumada.
        if (_orfas(porSlot, linhas) case final orfas when orfas.isNotEmpty)
          Row(
            children: [
              for (final peca in orfas) ...[
                _Peca(peca: peca, index: index),
                const SizedBox(width: 4),
              ],
            ],
          ),
      ],
    );
  }

  List<EquippedItem> _orfas(
    Map<int, EquippedItem> porSlot,
    List<List<EquippedItem>> linhas,
  ) {
    final arrumados = {
      for (final linha in linhas)
        for (final peca in linha) peca.slot,
    };
    final fora = [
      for (final e in porSlot.entries)
        if (!arrumados.contains(e.key) && e.key != weaponSlot) e.value,
    ]..sort((a, b) => a.slot.compareTo(b.slot));
    return fora;
  }
}

/// Uma peça: o ícone, o refino ao canto e um ponto por pedra encaixada.
class _Peca extends StatelessWidget {
  const _Peca({required this.peca, required this.index});

  final EquippedItem peca;
  final MarketIndex index;

  static const _lado = 30.0;

  @override
  Widget build(BuildContext context) => Tooltip(
    richMessage: _legenda(),
    // Larga porque o nome de uma pedra chega às sessenta letras — `Pedra
    // Suprema Frouxo: Reduz a velocidade de invocação do alvo. +200` — e
    // partido a meio não se lê.
    margin: const EdgeInsets.symmetric(horizontal: 12),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: PWColors.surfaceRaised,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: PWColors.border),
    ),
    // **Ao toque também, e não só ao rato.** No telemóvel não existe hover; o
    // dono disse que o computador é o que importa, mas `triggerMode` é uma
    // linha e a alternativa seria um card que no telemóvel desenha peças
    // sobre as quais não há como perguntar nada.
    triggerMode: TooltipTriggerMode.tap,
    waitDuration: const Duration(milliseconds: 250),
    child: SizedBox(
      width: _lado,
      height: _lado,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: PWColors.surface,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: PWColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1),
                child: ItemIcon(peca.itemId, size: _lado - 4),
              ),
            ),
          ),
          if (peca.refine > 0)
            Positioned(right: -1, bottom: -1, child: _Selo('+${peca.refine}')),
          // **Os pontos por pedra saíram, e a razão é a arte.** Havia um
          // ponto de 4 px por encaixe no topo de cada ícone: num ícone de 30
          // px, três pontos tomam 40% da aresta de cima e lêem-se como uma
          // barra que tapa a peça, vezes catorze ícones vezes quarenta cards.
          // O refino fica porque é um número sobre que alguém decide; quantos
          // encaixes uma peça tem não é, e o tooltip di-lo por palavras.
        ],
      ),
    ),
  );

  /// O nome da peça com o refino, e depois cada pedra com o seu.
  ///
  /// Uma pedra que a tabela não conheça entra como o seu número — `pedra
  /// 38404` — e não como um espaço em branco: o visitante fica a saber que há
  /// ali uma pedra e que nós não sabemos qual, que é a verdade.
  TextSpan _legenda() {
    final item = index.items[peca.itemId];
    final titulo = item?.name ?? 'item ${peca.itemId}';
    final refino = peca.refine > 0 ? ' +${peca.refine}' : '';

    return TextSpan(
      style: const TextStyle(color: PWColors.text, fontSize: 12, height: 1.45),
      children: [
        TextSpan(
          text: '$titulo$refino\n',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(
          text: slotLabel(peca.slot, index),
          style: const TextStyle(color: PWColors.textMuted, fontSize: 11),
        ),
        for (final pedra in peca.stones)
          TextSpan(
            text: '\n· ${nomesDasPedras[pedra] ?? 'pedra $pedra'}',
            style: const TextStyle(color: PWColors.papel, fontSize: 11),
          ),
      ],
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: PWColors.background,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: PWColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        texto,
        style: const TextStyle(
          color: PWColors.accent,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    ),
  );
}
