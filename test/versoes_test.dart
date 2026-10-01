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

  test('replacing one version in the map leaves the other row untouched', () {
    // This is the shape `tool/collect.dart` relies on: read the file into
    // this map, replace the key for the version just collected, write the
    // map back. A run that collects pw126 must never touch pw187's row.
    final versoes = {
      'pw187': VersaoResumo(
        chave: 'pw187',
        nome: '1.8.7',
        personagens: 1666,
        coletadoEm: DateTime.utc(2026, 9, 30),
      ),
    };

    versoes['pw126'] = VersaoResumo(
      chave: 'pw126',
      nome: '1.2.6',
      personagens: 1308,
      coletadoEm: DateTime.utc(2026, 10, 1),
    );

    expect(versoes['pw187']!.personagens, 1666);
    expect(versoes['pw126']!.personagens, 1308);
  });
}
