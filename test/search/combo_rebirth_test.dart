import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/features/search/domain/combo_rebirth.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/market/card_combos.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// O nível de um combo é o da **pior** carta dele, que é a regra que o dono
/// descreveu: seis renascidas 2 aparecem em RB2, uma mistura de 2 e 1 aparece
/// em RB1, e uma carta normal no meio leva o conjunto todo para o filtro
/// simples.
///
/// Os três casos existem em páginas reais e são estes três fixtures, o que é
/// raro o bastante para valer dizer: todos os três trazem o **Portal de
/// Nuema** completo, com renascimentos diferentes.
void main() {
  final nuema = cardCombos.singleWhere((c) => c.name == 'Portal de Nuema');

  var proximoId = 1;
  MarketCharacter personagem(String fixture, [String apelido = 'quem']) {
    final html = File('test/fixtures/$fixture').readAsStringSync();
    return MarketCharacter(
      roleId: proximoId++,
      name: apelido,
      characterClass: 'Guerreiro',
      occupation: 1,
      cultivation: '',
      level: 105,
      price: 100,
      fame: 0,
      equipped: const [],
      cards: parseEquippedCards(html)
          .map(
            (c) => EquippedCard(
              cardId: c.cardId,
              name: c.name,
              rarity: c.rarity,
              type: c.type,
              level: c.level,
              maxLevel: c.maxLevel,
              rebirths: c.rebirths,
            ),
          )
          .toList(),
    );
  }

  group('o nível de um combo', () {
    test('seis renascidas 2 dão 2', () {
      expect(comboRebirthLevel(personagem('detail_92624.html'), nuema), 2);
    });

    test('duas renascidas 1 no meio de quatro 2 dão 1', () {
      expect(comboRebirthLevel(personagem('detail_2192.html'), nuema), 1);
    });

    test('uma só carta renascida dá 0, porque cinco não renasceram', () {
      expect(comboRebirthLevel(personagem('detail_330640.html'), nuema), 0);
    });

    test('quem não tem o combo dá null, que não é zero', () {
      // Zero é *tem o combo e nenhuma renascida* — exactamente quem o filtro
      // simples procura. Null é *não tem o combo*. Juntá-los faria o chip de
      // renascimento responder a uma pergunta sobre posse.
      expect(comboRebirthLevel(personagem('detail_11076.html'), nuema), isNull);
    });
  });

  group('o filtro', () {
    final full2 = personagem('detail_92624.html', 'full2');
    final full1 = personagem('detail_2192.html', 'full1');
    final normal = personagem('detail_330640.html', 'normal');
    final semCombo = personagem('detail_11076.html', 'semCombo');

    final mercado = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 11, 5),
      attributes: const [],
      items: const {},
      characters: [full2, full1, normal, semCombo],
    );

    List<String> quemPassa(int? rb) => runQuery(
      mercado,
      SearchQuery(comboName: 'Portal de Nuema', comboMinRebirth: rb),
    ).map((c) => c.name).toList();

    test('RB2 aceita só quem tem as seis em 2', () {
      expect(quemPassa(2), ['full2']);
    });

    test('RB1 aceita quem tem 1 e também quem tem 2', () {
      // Um mínimo é um «pelo menos», portanto quem está acima não sai da
      // lista: seria dizer a quem procura RB1 que o combo melhor não serve.
      expect(quemPassa(1), containsAll(['full2', 'full1']));
      expect(quemPassa(1), hasLength(2));
    });

    test('o combo simples aceita os três que o têm, renascido ou não', () {
      expect(quemPassa(null), hasLength(3));
      expect(quemPassa(null), isNot(contains('semCombo')));
    });

    test('o link leva o renascimento e trá-lo de volta', () {
      const pedido = SearchQuery(
        comboName: 'Portal de Nuema',
        comboMinRebirth: 2,
      );
      final volta = decodeQuery(
        Uri.parse('?${encodeQuery(pedido, mercado)}').queryParametersAll,
        mercado,
      );

      expect(volta.comboName, 'Portal de Nuema');
      expect(volta.comboMinRebirth, 2);
    });

    test('um renascimento sem combo no link é descartado, nunca guardado', () {
      // O matcher nunca o leria e ele continuaria a viajar no endereço,
      // invisível — exactamente como um atributo que a colecta já não tem
      // deixa cair o seu critério em vez de recuar para o atributo zero.
      final volta = decodeQuery(
        Uri.parse('?renasc=2').queryParametersAll,
        mercado,
      );

      expect(volta.comboMinRebirth, isNull);
      expect(volta.isEmpty, isTrue);
    });

    test('um renascimento pedido sobre um combo que não existe não passa', () {
      expect(
        runQuery(
          mercado,
          const SearchQuery(
            comboName: 'Combo que ninguém escreveu',
            comboMinRebirth: 1,
          ),
        ),
        isEmpty,
      );
    });
  });
}
