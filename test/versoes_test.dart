import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/versoes.dart';

void main() {
  test('a row survives a round trip through JSON', () {
    final resumo = VersaoResumo(
      chave: 'pw126',
      nome: '1.2.6',
      personagens: 1308,
      coletadoEm: DateTime.utc(2026, 10, 1, 9),
    );

    final restored = VersaoResumo.fromJson(resumo.toJson());

    expect(restored.chave, 'pw126');
    expect(restored.nome, '1.2.6');
    expect(restored.personagens, 1308);
    expect(restored.coletadoEm, DateTime.utc(2026, 10, 1, 9));
  });

  test('the whole file survives a round trip, one key per version', () {
    final versoes = {
      'pw187': VersaoResumo(
        chave: 'pw187',
        nome: '1.8.7',
        personagens: 1666,
        coletadoEm: DateTime.utc(2026, 9, 30),
      ),
      'pw126': VersaoResumo(
        chave: 'pw126',
        nome: '1.2.6',
        personagens: 1308,
        coletadoEm: DateTime.utc(2026, 10, 1),
      ),
    };

    final restored = versoesFromJson(versoesToJson(versoes));

    expect(restored.keys, {'pw187', 'pw126'});
    expect(restored['pw187']!.personagens, 1666);
    expect(restored['pw126']!.personagens, 1308);
  });

  // The actual merge — read the file, replace one version's key, write it
  // back — lives in `tool/collect.dart`'s `escreverVersoes`, not here. This
  // file is `market/`, which depends on nothing and cannot touch `dart:io`;
  // `test/tool/escrever_versoes_test.dart` is what proves that function, on a
  // real file on disk, including the case this repository actually hit: a
  // bare CI checkout where the merge is correct and the file it is supposed
  // to merge with was never restored. See that file's and HIGH C's notes.
}
