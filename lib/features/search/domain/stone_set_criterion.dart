import '../../../market/market_index.dart';
import '../../../market/set_stones.dart';

/// O conjunto de pedras pedido: uma família e um nível mínimo.
///
/// **É um mínimo entre peças, nunca uma soma**, e é essa a regra que o dono
/// descreveu: quem tem a maior parte das pedras em +1 e algumas em +2 aparece
/// no conjunto de +1 e **não** no de +2, porque ali não cumpre o requisito.
/// O nível de um personagem é o da pior peça dele.
class StoneSetCriterion {
  const StoneSetCriterion({required this.kind, required this.level});

  final StoneKind kind;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is StoneSetCriterion && other.kind == kind && other.level == level;

  @override
  int get hashCode => Object.hash(kind, level);

  @override
  String toString() => 'StoneSetCriterion(${setLabel(kind, level)})';
}

/// O nível do conjunto que [character] tem, ou `null` se lhe falta uma peça.
///
/// **Uma peça sem pedra da família derruba tudo**, que é o pedido: «se alguma
/// parte não tiver, não aparecerá». Devolver zero em vez de nulo faria o
/// personagem incompleto empatar com quem tem o conjunto no nível mais baixo,
/// e são coisas diferentes.
///
/// Uma peça pode ter mais de um encaixe, e aí vale **a melhor pedra daquela
/// peça** — ter uma Pedra do Demônio e uma Jade Preciosa no mesmo elmo não é
/// motivo para o elmo contar como o pior dos dois.
int? stoneSetLevel(MarketCharacter character, StoneKind kind) {
  final porSlot = <int, int>{};

  for (final item in character.equipped) {
    if (!setSlots.contains(item.slot)) continue;
    final precisaAcessorio = accessorySlots.contains(item.slot);

    for (final id in item.stones) {
      final pedra = stoneById[id];
      if (pedra == null) continue;
      if (pedra.kind != kind) continue;
      // **A família tem de bater com a peça.** A Pedra do Demônio e a Pedra
      // de Yan Luo são ambas Ataque +3 e não se substituem; aceitar a do
      // equipamento num colar contaria um conjunto que o jogo não permite.
      if (pedra.accessory != precisaAcessorio) continue;

      final atual = porSlot[item.slot];
      if (atual == null || pedra.level > atual) {
        porSlot[item.slot] = pedra.level;
      }
    }
  }

  if (porSlot.length != setSlots.length) return null;
  return porSlot.values.reduce((a, b) => a < b ? a : b);
}
