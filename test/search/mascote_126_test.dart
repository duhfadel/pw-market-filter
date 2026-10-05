import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/counted_items.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// O mesmo controlo, duas origens.
///
/// **As duas versões publicam o mascote de maneiras diferentes, e isso não é
/// uma escolha nossa.** No 1.8.7 o dono baptiza o ovo — `38587` imprime
/// `Ovo de Harpia` em três pessoas e `GabirÚ` numa quarta — portanto só o id
/// sobrevive. No 1.2.6 a jaula escreve a espécie, `Ovo de Hércules`, e é esse
/// nome que o estado guarda. Copiar uma regra para a outra perde o mascote em
/// silêncio, nas duas direções.
void main() {
  MarketCharacter personagem(
    int roleId, {
    List<String> mascotes = const [],
    Map<int, int> counts = const {},
  }) => MarketCharacter(
    roleId: roleId,
    name: 'n$roleId',
    characterClass: 'Feiticeira',
    occupation: 1,
    level: 100,
    price: 500,
    fame: 0,
    cultivation: 'Leal',
    equipped: const [],
    mascotes: mascotes,
    counts: counts,
  );

  MarketIndex indice(List<MarketCharacter> cs, {bool com187 = false}) =>
      MarketIndex(
        server: com187 ? 'pw187' : 'pw126',
        collectedAt: DateTime.utc(2026, 10, 5),
        attributes: const [],
        items: const {},
        countedItems: com187
            ? const {
                'Hércules': [37905],
              }
            : const {},
        characters: cs,
      );

  test('o Hércules do 1.2.6 passa pelo nome da espécie', () {
    final tem = personagem(1, mascotes: const ['Ovo de Hércules']);
    final naoTem = personagem(2, mascotes: const ['Ovo de Fera Espiritual']);
    final idx = indice([tem, naoTem]);
    const busca = SearchQuery(pets: {'Hércules'});

    expect(matchesQuery(idx, tem, busca), isTrue);
    expect(matchesQuery(idx, naoTem, busca), isFalse);
  });

  test('o Hércules do 1.8.7 continua a passar pelo id do item', () {
    final tem = personagem(1, counts: const {37905: 1});
    final naoTem = personagem(2);
    final idx = indice([tem, naoTem], com187: true);
    const busca = SearchQuery(pets: {'Hércules'});

    expect(matchesQuery(idx, tem, busca), isTrue);
    expect(matchesQuery(idx, naoTem, busca), isFalse);
  });

  test('um personagem sem jaula nenhuma falha, nunca passa por omissão', () {
    // A mesma regra de um nome contado que a coleta nunca encontrou: ninguém
    // o tem, portanto ninguém passa. Saltar o filtro alargaria a busca por
    // baixo do próprio filtro de quem pergunta.
    final idx = indice([personagem(1)]);

    expect(
      matchesQuery(idx, personagem(1), const SearchQuery(pets: {'Hércules'})),
      isFalse,
    );
  });

  test('a tabela do 1.2.6 nomeia a espécie, não um id', () {
    expect(mascotes126['Hércules'], 'Ovo de Hércules');
    // E a do 1.8.7 continua a ser por id, porque ali o nome é do dono.
    expect(countedItemIds['Hércules'], 37905);
  });
}
