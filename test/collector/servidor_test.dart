import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/servidor.dart';

void main() {
  test('the detail path is inverted between the two versions', () {
    // Measured 01/10/2026: `/pw126/details/<id>` answers 404 and the listing's
    // own form is the one that serves — the exact opposite of pw187, where the
    // listing's form redirects and following it doubles the request count.
    expect(
      Servidor.de('pw187').detalhe(64112),
      'https://marketplace.theclassic.games/pw187/details/64112',
    );
    expect(
      Servidor.de('pw126').detalhe(229217),
      'https://marketplace.theclassic.games/details/pw126/229217',
    );
  });

  test('each version writes its own index', () {
    expect(Servidor.de('pw187').arquivoDoIndice, 'web/market_index.json');
    expect(Servidor.de('pw126').arquivoDoIndice, 'web/market_index_126.json');
  });

  test('an unknown version is refused rather than guessed', () {
    // A typo must not silently collect nothing against a 404 for forty
    // minutes, which would then overwrite a good index with an empty market.
    expect(() => Servidor.de('pw144'), throwsArgumentError);
  });

  test('each version carries its own origin and CSS prefix', () {
    final pw187 = Servidor.de('pw187');
    expect(pw187.chave, 'pw187');
    expect(pw187.origem, 'https://marketplace.theclassic.games');
    expect(pw187.prefixoCss, 'pw187-');

    final pw126 = Servidor.de('pw126');
    expect(pw126.chave, 'pw126');
    expect(pw126.origem, 'https://marketplace.theclassic.games');
    expect(pw126.prefixoCss, 'pw126-');
  });
}
