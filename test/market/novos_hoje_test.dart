import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';
import 'package:pw_market_filter/market/versoes.dart';

/// The number the version's door announces, and the crossing it has to
/// survive.
///
/// **A new field is not done when the collector computes it; it is done when
/// a test sees it on the other side of the disk.** `require_level`, `sexo`,
/// `nivel`, `escada` and `bonusNaoResolvidos` all died in exactly that
/// crossing, and the codec is where a field goes to die.
void main() {
  final coleta = DateTime.utc(2026, 11, 9, 14);

  MarketCharacter quem(String nome, {required int diasNoMercado}) =>
      MarketCharacter(
        roleId: nome.hashCode & 0xffff,
        name: nome,
        characterClass: 'Bardo',
        occupation: 0,
        cultivation: '',
        level: 105,
        price: 100,
        fame: 0,
        equipped: const [],
        history: PriceHistory(
          firstSeen: coleta.subtract(Duration(days: diasNoMercado)),
          lowestPrice: 100,
        ),
      );

  MarketIndex mercado(List<MarketCharacter> gente) => MarketIndex(
    server: 'pw187',
    collectedAt: coleta,
    attributes: const [],
    items: const {},
    characters: gente,
  );

  test('conta quem entrou no dia da coleta', () {
    final index = mercado([
      quem('Hoje', diasNoMercado: 0),
      quem('TambemHoje', diasNoMercado: 0),
      quem('Ontem', diasNoMercado: 1),
      quem('Velho', diasNoMercado: 40),
    ]);
    expect(novosHojeEm(index), 2);
  });

  test('a porta e o filtro dão o mesmo número, porque é a mesma regra', () {
    // Duas contagens da mesma pergunta é como a porta anuncia um número e a
    // grelha, ao abrir, mostra outro.
    final index = mercado([
      quem('Hoje', diasNoMercado: 0),
      quem('Ontem', diasNoMercado: 1),
      quem('Velho', diasNoMercado: 40),
    ]);
    expect(
      novosHojeEm(index),
      runQuery(index, const SearchQuery(novosEmDias: 1)).length,
    );
  });

  test('quem não tem registo não conta, e não estoura', () {
    final index = mercado([
      quem('Hoje', diasNoMercado: 0),
      const MarketCharacter(
        roleId: 7,
        name: 'SemRegisto',
        characterClass: 'Bardo',
        occupation: 0,
        cultivation: '',
        level: 105,
        price: 100,
        fame: 0,
        equipped: [],
      ),
    ]);
    expect(novosHojeEm(index), 1);
  });

  test('um mercado sem histórico nenhum dá zero, não nulo', () {
    // A primeira coleta de sempre: ninguém «entrou hoje» porque não havia
    // ontem com que comparar. É um facto sobre o mercado, não uma linha velha
    // — a ausência fica reservada para o ficheiro que precede o campo.
    expect(novosHojeEm(mercado(const [])), 0);
  });

  group('a travessia do disco', () {
    test('o número sobrevive ao jsonEncode e ao jsonDecode', () {
      final antes = VersaoResumo.doIndice(
        mercado([quem('Hoje', diasNoMercado: 0)]),
        chave: 'pw187',
        nome: '1.8.7',
      );
      expect(antes.novosHoje, 1);

      final depois = versoesFromJson(
        jsonDecode(jsonEncode(versoesToJson({'pw187': antes})))
            as Map<String, dynamic>,
      )['pw187']!;
      expect(depois.novosHoje, 1);
      expect(depois.personagens, 1);
      expect(depois.coletadoEm, coleta);
    });

    test('um ficheiro anterior ao campo lê-se como nulo e não como zero', () {
      // Os `versoes.json` já publicados não têm a chave, portanto a ausência
      // é parte do contrato. Lida como zero, a porta anunciaria um mercado
      // parado onde o que há é um ficheiro velho.
      final velho = versoesFromJson(
        jsonDecode(
              '{"pw187":{"chave":"pw187","nome":"1.8.7","personagens":2626,'
              '"coletadoEm":"2026-10-28T12:08:21.516079Z"}}',
            )
            as Map<String, dynamic>,
      )['pw187']!;
      expect(velho.novosHoje, isNull);
      expect(velho.personagens, 2626);
    });

    test('nulo não é escrito, para não encher o ficheiro de nadas', () {
      final sem = VersaoResumo(
        chave: 'pw144',
        nome: '1.4.4',
        personagens: 0,
        coletadoEm: coleta,
      );
      expect(sem.toJson().containsKey('novosHoje'), isFalse);
    });

    test('zero é escrito, porque zero é uma resposta', () {
      final zero = VersaoResumo(
        chave: 'pw187',
        nome: '1.8.7',
        personagens: 10,
        coletadoEm: coleta,
        novosHoje: 0,
      );
      expect(zero.toJson()['novosHoje'], 0);
    });
  });
}
