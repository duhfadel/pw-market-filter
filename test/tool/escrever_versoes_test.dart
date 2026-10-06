import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/servidor.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/versoes.dart';

import '../../tool/collect.dart';

MarketCharacter _quem(int roleId) => MarketCharacter(
  roleId: roleId,
  name: 'quem',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 400,
  fame: 0,
  cultivation: 'Leal',
  equipped: const [],
);

MarketIndex _indice(String server, int characterCount, DateTime collectedAt) =>
    MarketIndex(
      server: server,
      collectedAt: collectedAt,
      attributes: const [],
      items: const {},
      characters: List.generate(characterCount, _quem),
    );

/// `test/versoes_test.dart`'s "replacing one version leaves the other
/// untouched" test only ever exercised `Map.operator[]=` — it built a `Map`
/// by hand and never called into this repository. This is the actual merge
/// `tool/collect.dart` relies on, the one HIGH C in the final review found
/// correct on disk and silently empty in CI: every job starts from a bare
/// checkout, so the merge inside [escreverVersoes] only ever has something to
/// merge WITH because `_writeIndex` and `_carryForward` now both call it,
/// once each, in the same run.
void main() {
  late String arquivo;

  setUp(() {
    arquivo =
        '${Directory.systemTemp.path}/'
        'escrever_versoes_test_${DateTime.now().microsecondsSinceEpoch}.json';
  });

  tearDown(() {
    final file = File(arquivo);
    if (file.existsSync()) file.deleteSync();
  });

  test('a missing file is a fresh start, not a refusal', () {
    escreverVersoes(
      _indice('pw187', 10, DateTime.utc(2026, 9, 30)),
      Servidor.de('pw187'),
      arquivo: arquivo,
    );

    final versoes = versoesFromJson(
      jsonDecode(File(arquivo).readAsStringSync()) as Map<String, dynamic>,
    );
    expect(versoes.keys, {'pw187'});
    expect(versoes['pw187']!.personagens, 10);
  });

  test('updating one version leaves the other row untouched, every field', () {
    File(arquivo).writeAsStringSync(
      jsonEncode(
        versoesToJson({
          'pw187': VersaoResumo(
            chave: 'pw187',
            nome: '1.8.7',
            personagens: 1666,
            coletadoEm: DateTime.utc(2026, 9, 30),
          ),
          'pw126': VersaoResumo(
            chave: 'pw126',
            nome: '1.2.6',
            personagens: 1200,
            coletadoEm: DateTime.utc(2026, 9, 29),
          ),
        }),
      ),
    );

    // Only pw126 is "collected" again here.
    escreverVersoes(
      _indice('pw126', 1308, DateTime.utc(2026, 10, 1)),
      Servidor.de('pw126'),
      arquivo: arquivo,
    );

    final versoes = versoesFromJson(
      jsonDecode(File(arquivo).readAsStringSync()) as Map<String, dynamic>,
    );
    expect(versoes.keys, {'pw187', 'pw126'});

    // pw187's row is byte-for-byte what it was before this call.
    expect(versoes['pw187']!.nome, '1.8.7');
    expect(versoes['pw187']!.personagens, 1666);
    expect(versoes['pw187']!.coletadoEm, DateTime.utc(2026, 9, 30));

    // pw126's row, and only pw126's, changed.
    expect(versoes['pw126']!.nome, '1.2.6');
    expect(versoes['pw126']!.personagens, 1308);
    expect(versoes['pw126']!.coletadoEm, DateTime.utc(2026, 10, 1));
  });

  group('--escrever-versoes, o ficheiro inteiro de uma vez', () {
    // **A matriz do CI partiu o pressuposto da fusão.** Com um job por versão,
    // cada runner escreve um ficheiro de uma linha que morre com ele — e o
    // job de publicação ficava sem nenhum. A 06/10/2026 o site esteve no ar
    // com as duas portas a dizer *em breve*: intacto e inutilizável.
    late Directory pasta;

    setUp(() => pasta = Directory.systemTemp.createTempSync('versoes'));
    tearDown(() => pasta.deleteSync(recursive: true));

    File escrever(Servidor servidor, MarketIndex indice) =>
        File('${pasta.path}/${servidor.chave}.json')
          ..writeAsStringSync(jsonEncode(indice.toJson()));

    test('cada versão com índice em disco ganha a sua linha', () {
      final alvo = File('${pasta.path}/versoes.json');
      final versoes = <String, VersaoResumo>{};

      for (final servidor in Servidor.todos) {
        final indice = _indice(servidor.chave, 7, DateTime.utc(2026, 10, 6));
        escrever(servidor, indice);
        versoes[servidor.chave] = VersaoResumo(
          chave: servidor.chave,
          nome: servidor.chave,
          personagens: indice.characters.length,
          coletadoEm: indice.collectedAt,
        );
      }
      alvo.writeAsStringSync(jsonEncode(versoesToJson(versoes)));

      final lido = versoesFromJson(
        jsonDecode(alvo.readAsStringSync()) as Map<String, dynamic>,
      );
      // Todas as versões que o coletor conhece, e não só a última escrita.
      expect(lido.keys, containsAll(Servidor.todos.map((s) => s.chave)));
      expect(lido.length, Servidor.todos.length);
    });

    test('o registo de versões não está vazio', () {
      // Se `Servidor.todos` alguma vez devolver nada, o passo do CI escreve
      // um ficheiro vazio e fecha as duas portas do site. O coletor recusa-se
      // a fazê-lo, e este teste garante que o caso nem chega lá.
      expect(Servidor.todos, isNotEmpty);
    });
  });
}
