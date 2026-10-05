import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/alerta_de_entrada.dart';
import 'package:pw_market_filter/market/price_history.dart';

/// The private feed: a character that has just entered the market **and**
/// carries something off the watch list.
void main() {
  final agora = DateTime.utc(2026, 10, 3, 18);
  final antes = DateTime.utc(2026, 10, 1, 9);

  AnuncioNoMercado anuncio(int roleId, {int preco = 500}) => AnuncioNoMercado(
    roleId: roleId,
    nome: 'n$roleId',
    classe: 'Guerreiro',
    nivel: 105,
    preco: preco,
  );

  PriceHistory visto(DateTime quando) =>
      PriceHistory(firstSeen: quando, lowestPrice: 500);

  List<EntradaNova> correr({
    required Map<int, DateTime> vistos,
    required Map<int, Map<String, int>> inventarios,
  }) => entradasParaAvisar(
    anuncios: [for (final id in vistos.keys) anuncio(id)],
    inventarios: inventarios,
    memoria: {for (final e in vistos.entries) e.key: visto(e.value)},
    agora: agora,
  );

  group('what trips the watch', () {
    test('a new listing carrying a watched item', () {
      final saida = correr(
        vistos: {1: agora},
        inventarios: {
          1: const {'Essência Dracônica Bruta': 2},
        },
      );

      expect(saida, hasLength(1));
      expect(saida.single.achados, {'Essência Dracônica Bruta': 2});
    });

    test('one item is enough — the rule is an or', () {
      // The owner's words on 2026-10-03: *"se tiver um deles ao menos"*.
      final saida = correr(
        vistos: {1: agora},
        inventarios: {
          1: const {'Cartão Gente Boa': 1},
        },
      );

      expect(saida, hasLength(1));
    });

    test('and every match is named, not just the first', () {
      final saida = correr(
        vistos: {1: agora},
        inventarios: {
          1: const {
            'Cartão Gente Boa': 1,
            'Cartão Recompensa Homem Nobre': 2,
            'Pedra': 90,
          },
        },
      );

      expect(saida.single.achados, {
        'Cartão Recompensa Homem Nobre': 2,
        'Cartão Gente Boa': 1,
      });
    });
  });

  group('what stays quiet', () {
    test('a character who was already here, however rich', () {
      // The feed is about arrivals. Somebody who has carried a chest for a
      // week is not news, and announcing him on every run is how a channel
      // stops being read.
      final saida = correr(
        vistos: {1: antes},
        inventarios: {
          1: const {'Baú Essência Dracônica': 9},
        },
      );

      expect(saida, isEmpty);
    });

    test('a new listing carrying nothing on the list', () {
      // 239 of the 240 characters that entered in a day carried a relic and
      // 233 an essence. Alerting on those is alerting on everybody.
      final saida = correr(
        vistos: {1: agora},
        inventarios: {
          1: const {'Relíquia Maravilha: Arma': 120, 'Essência Dracônica': 11},
        },
      );

      expect(saida, isEmpty);
    });

    test('a character whose inventory was never read', () {
      expect(correr(vistos: {1: agora}, inventarios: const {}), isEmpty);
    });
  });

  test('only what the owner asked for is watched', () {
    // Three entries came off on 2026-10-03 because they were mine and not
    // his: the chest, the Harpia and the Hércules. A watch list that grows
    // by whoever is implementing it is a channel that fills with somebody
    // else's idea of interesting.
    expect(vigiaDeItens, isNot(contains('Baú Essência Dracônica')));
    expect(vigiaDeItens, isNot(contains('Cartão Gente Sortuda')));
    expect(vigiaDeItens.keys.any((n) => n.contains('Ovo')), isFalse);
  });

  test('o cupom de prata fica de fora, e o número diz porquê', () {
    // São itens diferentes e é o de prata que não serve — decisão do dono.
    // O número condenava-o de qualquer modo: 1.518 dos 1.648 carregam um,
    // p99 207, e mesmo com piso em 100 disparava em 361 pessoas.
    expect(vigiaDeItens, isNot(contains('Cupom Perfeito de Prata')));
    expect(vigiaDeItens, contains('Cupom Perfeito'));

    final saida = entradasParaAvisar(
      anuncios: [anuncio(1), anuncio(2)],
      inventarios: {
        1: const {'Cupom Perfeito de Prata': 298},
        2: const {'Cupom Perfeito': 1},
      },
      memoria: {1: visto(agora), 2: visto(agora)},
      agora: agora,
    );

    expect(saida.map((e) => e.roleId), [2]);
  });

  test('the count on the list is a floor, not a flag', () {
    // What lets a common item earn a place: the Chave fires on 147 arrivals a
    // day at one, and almost never at five hundred.
    final saida = entradasParaAvisar(
      anuncios: [anuncio(1), anuncio(2)],
      inventarios: {
        1: const {'Chave da Sorte': 4},
        2: const {'Chave da Sorte': 900},
      },
      memoria: {1: visto(agora), 2: visto(agora)},
      agora: agora,
    );

    // Neither fires today, because the Chave is not on the list at all — the
    // floor only matters for a name that is.
    expect(saida, isEmpty);
    expect(vigiaDeItens.containsKey('Chave da Sorte'), isFalse);
    // Every floor is at least one: a zero would fire on everybody alive.
    for (final minimo in vigiaDeItens.values) {
      expect(minimo, greaterThanOrEqualTo(1));
    }
  });

  group('names that never appear', () {
    test('a watched name nobody carries is reported, not assumed present', () {
      // The feed's worst failure: a misspelt name is an alert that never
      // fires while looking like it works, and from the channel that is
      // indistinguishable from a quiet market.
      final faltam = nomesNuncaVistos([
        const {'Essência Dracônica Bruta': 2, 'Relíquia Maravilha: Arma': 90},
      ]);

      expect(faltam, isNot(contains('Essência Dracônica Bruta')));
      expect(faltam, contains('Cartão Gente Boa'));
    });

    test('an empty market reports every watched name', () {
      expect(nomesNuncaVistos(const []), vigiaDeItens.keys.toSet());
    });

    test('both spellings of the card are carried, on purpose', () {
      // The game uses both shapes — `Cartão de Empolgação` has the
      // preposition, `Cartão Recompensa Cara Legal` does not — and no
      // collection has resolved either *Cartão Gente* name, so which one this
      // server prints is unknown. A name that matches nobody costs nothing.
      expect(vigiaDeItens, contains('Cartão Gente Boa'));
      expect(vigiaDeItens, contains('Cartão de Gente Boa'));
    });
  });

  group('the one-off catch-up', () {
    test('lists who carries it now, biggest stash first', () {
      // The feed answers "who just arrived" and cannot be made to answer
      // "who has one": announcing the people already here would repeat them
      // every half hour for ever.
      final lista = quemCarrega(
        item: 'Cartão Recompensa Homem Nobre',
        anuncios: [anuncio(1, preco: 900), anuncio(2, preco: 100), anuncio(3)],
        inventarios: const {
          1: {'Cartão Recompensa Homem Nobre': 1},
          2: {'Cartão Recompensa Homem Nobre': 4},
          3: {'Outra Coisa': 50},
        },
      );

      expect(lista.map((e) => e.roleId), [2, 1]);
      expect(lista.first.achados, {'Cartão Recompensa Homem Nobre': 4});
      expect(lista.first.preco, 100);
    });

    test('ignores when somebody arrived — that is the other question', () {
      // No `memoria` and no `agora`: a carrier counts whether they came
      // today or a month ago.
      final lista = quemCarrega(
        item: 'Baú Essência Dracônica',
        anuncios: [anuncio(1)],
        inventarios: const {
          1: {'Baú Essência Dracônica': 2},
        },
      );

      expect(lista, hasLength(1));
    });

    test('an item nobody carries lists nobody, rather than everybody', () {
      expect(
        quemCarrega(
          item: 'Cartão Gente Sortuda',
          anuncios: [anuncio(1)],
          inventarios: const {
            1: {'Cartão Recompensa Homem Nobre': 1},
          },
        ),
        isEmpty,
      );
    });
  });

  test('the flood valve is far above anything a market can do', () {
    // It guards against our own bookkeeping, not against the market: a lost
    // CI cache stamps every character alive with today's `firstSeen`.
    expect(limiteDeEnxurrada, greaterThan(20));
    expect(limiteDeEnxurrada, lessThan(200));
  });
}
