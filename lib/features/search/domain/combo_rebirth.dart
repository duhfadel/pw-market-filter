import '../../../market/card_combos.dart';
import '../../../market/market_index.dart';

/// O nível de renascimento de um combo num personagem: **o mínimo entre as
/// cartas do conjunto**, ou null quando ele não tem o combo inteiro.
///
/// É a mesma regra do conjunto de pedras, e foi o dono que a descreveu nos
/// mesmos termos: *«se o player tem as 6 cartas renascidas 2, aí mostramos em
/// rb2, se tem algumas rb2 e algumas rb1, mostra rb1, se tem rb1 e normais,
/// normais»*. Um combo vale pela pior carta dele, nunca pela melhor nem por
/// uma média — porque o que se procura é um conjunto que cumpre o requisito
/// todo, e uma carta atrás arrasta o conjunto para trás com ela.
///
/// **Null e zero são coisas diferentes, e a distinção é o que torna o filtro
/// honesto.** Null é *não tem o combo* e sai de qualquer um dos três filtros;
/// zero é *tem o combo e nenhuma carta renascida*, que é precisamente quem o
/// filtro simples existe para encontrar. Juntá-los faria o chip de renascidas
/// responder a uma pergunta sobre posse.
int? comboRebirthLevel(MarketCharacter character, CardCombo combo) {
  final porCarta = <int, int>{};
  for (final card in character.cards) {
    if (!combo.cardIds.contains(card.cardId)) continue;
    final atual = porCarta[card.cardId];
    // Uma carta por tipo, portanto nunca há duas iguais hoje; o máximo é o
    // mesmo cuidado que `stoneSetLevel` toma, e por de graça.
    if (atual == null || card.rebirths > atual) {
      porCarta[card.cardId] = card.rebirths;
    }
  }
  if (porCarta.length != combo.cardIds.length) return null;
  return porCarta.values.reduce((a, b) => a < b ? a : b);
}
