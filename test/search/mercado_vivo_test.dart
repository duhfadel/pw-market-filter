import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/active_filters.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

/// As duas perguntas que a faixa viva faz ao mercado.
///
/// Os dados existem desde 30/09/2026 e nunca apareceram na tela: `firstSeen`
/// em toda a gente e `previousPrice` em quem mexeu no preço. O que faltava
/// era o filtro saber perguntar.
void main() {
  final hoje = DateTime.utc(2026, 11, 9, 12);

  MarketCharacter quem(
    String nome, {
    required int preco,
    required int diasNoMercado,
    int? precoAntes,
  }) => MarketCharacter(
    roleId: nome.hashCode & 0xffff,
    name: nome,
    characterClass: 'Bardo',
    occupation: 0,
    cultivation: '',
    level: 105,
    price: preco,
    fame: 0,
    equipped: const [],
    history: PriceHistory(
      firstSeen: hoje.subtract(Duration(days: diasNoMercado)),
      previousPrice: precoAntes,
      lowestPrice: preco,
    ),
  );

  final entrouHoje = quem('EntrouHoje', preco: 100, diasNoMercado: 0);
  final ontem = quem('Ontem', preco: 100, diasNoMercado: 1);
  final velho = quem('Velho', preco: 100, diasNoMercado: 40);
  final baixou = quem('Baixou', preco: 400, diasNoMercado: 10, precoAntes: 500);
  final subiu = quem('Subiu', preco: 400, diasNoMercado: 10, precoAntes: 300);
  final semHistorico = MarketCharacter(
    roleId: 99,
    name: 'SemHistorico',
    characterClass: 'Bardo',
    occupation: 0,
    cultivation: '',
    level: 105,
    price: 100,
    fame: 0,
    equipped: const [],
  );

  final mercado = MarketIndex(
    server: 'pw187',
    collectedAt: hoje,
    attributes: const [],
    items: const {},
    characters: [entrouHoje, ontem, velho, baixou, subiu, semHistorico],
  );

  List<String> quemPassa(SearchQuery q) =>
      runQuery(mercado, q).map((c) => c.name).toList();

  group('entraram há pouco', () {
    test('um dia apanha só quem entrou hoje', () {
      expect(quemPassa(const SearchQuery(novosEmDias: 1)), ['EntrouHoje']);
    });

    test('sete dias apanha hoje e ontem, não o de quarenta', () {
      expect(
        quemPassa(const SearchQuery(novosEmDias: 7)),
        containsAll(['EntrouHoje', 'Ontem']),
      );
      expect(quemPassa(const SearchQuery(novosEmDias: 7)), hasLength(2));
    });

    test('quem não tem registo nunca passa por novo', () {
      // Um índice colhido antes de haver memória não sabe quando alguém
      // entrou, e chamar-lhe novo seria afirmar o que ninguém mediu.
      expect(
        quemPassa(const SearchQuery(novosEmDias: 365)),
        isNot(contains('SemHistorico')),
      );
    });
  });

  group('baixaram o preço', () {
    test('aceita quem desceu', () {
      expect(quemPassa(const SearchQuery(soComQueda: true)), ['Baixou']);
    });

    test('quem subiu não entra, mesmo tendo preço anterior', () {
      // `previousPrice` é escrito em qualquer movimento. É a comparação com o
      // preço de agora que o confina à descida — a mesma regra que o card usa.
      expect(
        quemPassa(const SearchQuery(soComQueda: true)),
        isNot(contains('Subiu')),
      );
    });
  });

  test('as duas perguntas juntas são um e, como todo o resto do filtro', () {
    final recenteEBaixou = quem(
      'Ambos',
      preco: 400,
      diasNoMercado: 0,
      precoAntes: 900,
    );
    final m = MarketIndex(
      server: 'pw187',
      collectedAt: hoje,
      attributes: const [],
      items: const {},
      characters: [entrouHoje, baixou, recenteEBaixou],
    );
    expect(
      runQuery(
        m,
        const SearchQuery(novosEmDias: 1, soComQueda: true),
      ).map((c) => c.name),
      ['Ambos'],
    );
  });

  test('sem nenhuma das duas, a busca continua vazia', () {
    expect(const SearchQuery().isEmpty, isTrue);
    expect(const SearchQuery(soComQueda: true).isEmpty, isFalse);
    expect(const SearchQuery(novosEmDias: 1).isEmpty, isFalse);
  });

  group('o link', () {
    SearchQuery volta(SearchQuery q) => decodeQuery(
      Uri.parse('?${encodeQuery(q, mercado)}').queryParametersAll,
      mercado,
    );

    test('leva as duas perguntas e trá-las de volta', () {
      final q = volta(const SearchQuery(novosEmDias: 7, soComQueda: true));
      expect(q.novosEmDias, 7);
      expect(q.soComQueda, isTrue);
    });

    test('uma busca vazia não escreve nenhum dos dois', () {
      expect(encodeQuery(const SearchQuery(), mercado), isEmpty);
    });

    test('zero dias é descartado, não aceite', () {
      // «entrou há menos de zero dias» não tem resposta, e deixá-lo passar
      // esvaziaria a grelha sem dizer porquê.
      final q = decodeQuery(Uri.parse('?novos=0').queryParametersAll, mercado);
      expect(q.novosEmDias, isNull);
      expect(q.isEmpty, isTrue);
    });
  });

  group('os chips', () {
    test('cada pergunta ganha o seu, e o chip desfá-la', () {
      final chips = activeFilters(
        mercado,
        const SearchQuery(novosEmDias: 1, soComQueda: true),
      );
      expect(
        chips.map((c) => c.label),
        containsAll(['entraram hoje', 'baixaram o preço']),
      );

      final semNovos = chips
          .firstWhere((c) => c.label == 'entraram hoje')
          .remove(const SearchQuery(novosEmDias: 1, soComQueda: true));
      expect(semNovos.novosEmDias, isNull);
      expect(
        semNovos.soComQueda,
        isTrue,
        reason: 'tirar um não pode levar o outro',
      );
    });

    test('mais de um dia diz quantos', () {
      final chips = activeFilters(mercado, const SearchQuery(novosEmDias: 7));
      expect(chips.single.label, 'entraram em 7 dias');
    });
  });
}
