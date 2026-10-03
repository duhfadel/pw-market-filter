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
          1: const {'Cartão Gente Boa': 1, 'Ovo de Harpia': 3, 'Pedra': 90},
        },
      );

      expect(saida.single.achados, {'Cartão Gente Boa': 1, 'Ovo de Harpia': 3});
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

  test('a common item is watched by its quantity, never by its presence', () {
    // Three of the four real pages in `test/fixtures/` carry a
    // `Cupom Perfeito de Prata`, at 10, 28 and 33. At a floor of one this
    // would fire on nearly every arrival — the relics' defect, which is the
    // reason the floor exists at all.
    expect(vigiaDeItens['Cupom Perfeito de Prata'], greaterThan(33));

    final saida = entradasParaAvisar(
      anuncios: [anuncio(1), anuncio(2)],
      inventarios: {
        1: const {'Cupom Perfeito de Prata': 33},
        2: const {'Cupom Perfeito de Prata': 4000},
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

  test('the flood valve is far above anything a market can do', () {
    // It guards against our own bookkeeping, not against the market: a lost
    // CI cache stamps every character alive with today's `firstSeen`.
    expect(limiteDeEnxurrada, greaterThan(20));
    expect(limiteDeEnxurrada, lessThan(200));
  });
}
