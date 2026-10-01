import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/detail_parser_126.dart';
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

  test('each version keeps its own state, or a collection would prune the '
      'other', () {
    // A shared state file means a pw126 run loads the pw187 state, sees
    // role ids it does not recognise, and `pruneTo` deletes every pw187
    // entry for not being on the 126 listing — forty minutes of collected
    // state gone with nothing on screen saying so.
    expect(
      Servidor.de('pw187').arquivoDoEstado,
      isNot(Servidor.de('pw126').arquivoDoEstado),
    );
    // pw187 keeps the path that already exists on disk today — changing it
    // would silently orphan the state already sitting on the collector's
    // machine.
    expect(Servidor.de('pw187').arquivoDoEstado, 'tool/.collect_state.json');
  });

  test('each version reads its own published index', () {
    // Otherwise a pw126 run compares the 126 market against the 187 index,
    // producing first-seen and price-drop records that are pure nonsense.
    expect(
      Servidor.de('pw187').indicePublicado,
      isNot(Servidor.de('pw126').indicePublicado),
    );
    expect(
      Servidor.de('pw187').indicePublicado,
      'https://portalpw.net/market_index.json',
    );
  });

  test('each version carries its own origin', () {
    final pw187 = Servidor.de('pw187');
    expect(pw187.chave, 'pw187');
    expect(pw187.origem, 'https://marketplace.theclassic.games');

    final pw126 = Servidor.de('pw126');
    expect(pw126.chave, 'pw126');
    expect(pw126.origem, 'https://marketplace.theclassic.games');
  });

  test('each version wires its own item and sex parsers', () {
    // This is the seam BLOCKER B closed: before it, `tool/collect.dart`
    // called the 1.8.7 parser for every version, and a `--server pw126`
    // collection wrote eleven worn items with zero attributes each,
    // silently. Function identity is enough to prove the wiring — the
    // parsers' own behaviour is pinned in `detail_parser_test.dart` and
    // `detail_parser_126_test.dart`.
    expect(Servidor.de('pw187').itensEquipados, parseEquippedItems);
    expect(Servidor.de('pw126').itensEquipados, parseEquippedItems126);
    expect(Servidor.de('pw187').sexo, parseSex);
    expect(Servidor.de('pw126').sexo, parseSex126);
  });
}
