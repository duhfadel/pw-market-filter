import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/servidor.dart';
import 'package:pw_market_filter/market/endereco_do_mercado.dart';

/// The marketplace's own address shape, which is **inverted between the two
/// versions** — and which this repository spelled out in two places until one
/// of them was wrong.
///
/// Measured against the live site on 2026-10-01 and again on 2026-10-02:
/// `/pw187/details/<id>` answers 200 while `/details/pw187/<id>` answers 302
/// into it; `/details/pw126/<id>` answers 200 while `/pw126/details/<id>`
/// answers **404**. No test here may ever fetch those — the fixtures are the
/// site as far as the suite is concerned — so what is pinned is the shape.
void main() {
  group('the canonical shape per version', () {
    test('pw187 puts the version before the word', () {
      expect(
        enderecoDoPersonagem('pw187', 64112),
        'https://marketplace.theclassic.games/pw187/details/64112',
      );
    });

    test('pw126 puts the word before the version', () {
      // The defect the owner reported on 2026-10-02: the results card built
      // the 1.8.7 shape for both, so every *ver no marketplace* button on the
      // 1.2.6 side opened a 404 and nothing on screen said so.
      expect(
        enderecoDoPersonagem('pw126', 54049),
        'https://marketplace.theclassic.games/details/pw126/54049',
      );
    });

    test('the two are genuinely different, not one with a renamed segment', () {
      final a = enderecoDoPersonagem('pw187', 1).split('/');
      final b = enderecoDoPersonagem('pw126', 1).split('/');
      expect(a[a.length - 3], 'pw187');
      expect(b[b.length - 3], 'details');
    });
  });

  test('an unmeasured version falls back to the listing-link shape', () {
    // The shape the marketplace's own listing uses: canonical on pw126 and a
    // 302 into the canonical on pw187, so a browser lands right either way.
    // When 1.4.4 arrives the move is to measure it and add a row, not to
    // lean on this.
    expect(
      enderecoDoPersonagem('pw144', 7),
      'https://marketplace.theclassic.games/details/pw144/7',
    );
  });

  test('the collector and the screen read the same table', () {
    // They each had their own copy until 2026-10-02, and the copies
    // disagreed — which is the whole reason this file exists.
    for (final chave in ['pw187', 'pw126']) {
      expect(
        Servidor.de(chave).detalhe(123),
        enderecoDoPersonagem(chave, 123),
        reason:
            '$chave: the collector fetches a different page than the '
            'card sends somebody to',
      );
    }
  });
}
