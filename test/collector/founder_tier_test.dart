import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';

/// The founder rung, where the raw title the page printed becomes a number.
///
/// It is read here and not in the parser on purpose: the ladder is a fact
/// about the game, and the state keeps `Fundador X` whole, so correcting this
/// is `--rebuild` — seconds — rather than another eighty-three-minute crawl.
void main() {
  ListingCard card(int roleId) => ListingCard(
    roleId: roleId,
    name: 'n$roleId',
    characterClass: 'Guerreiro',
    occupation: 0,
    level: 105,
    price: 100,
    fame: 0,
    cultivation: 'Majestoso X',
  );

  ParsedTitles titles(String founder) => ParsedTitles(
    decoded: 1,
    inOctet: 1,
    equipped: '',
    attributes: const {},
    founder: founder,
  );

  int? tierOf(ParsedTitles? t) {
    final builder = IndexBuilder(server: 'pw187', collectedAt: DateTime.now());
    builder.add(card(1), const [], titles: t);
    return builder.build().characters.single.founderTier;
  }

  test('each of the ten figures becomes its own rung', () {
    const figuras = [
      'I',
      'II',
      'III',
      'IV',
      'V',
      'VI',
      'VII',
      'VIII',
      'IX',
      'X',
    ];
    for (var i = 0; i < figuras.length; i++) {
      expect(tierOf(titles('Fundador ${figuras[i]}')), i + 1);
    }
  });

  test('no founder title is null, never nought', () {
    // Nought would read as a rung, and "has none" is not rung zero.
    expect(tierOf(titles('')), isNull);
    expect(tierOf(null), isNull);
  });

  test('a founder name the ladder cannot place is dropped, not guessed', () {
    // A wrong rung sorts somebody into a pack they never bought, which is
    // worse than saying nothing — the same call `CelestialRealm` makes.
    expect(tierOf(titles('Fundador Ilustre')), isNull);
    expect(tierOf(titles('Fundador XI')), isNull);
    expect(tierOf(titles('Fundador')), isNull);
  });

  test('a title that merely begins with the word is not a founder', () {
    expect(tierOf(titles('Fundadores da Cidade')), isNull);
  });

  test('the real page carries it all the way to the index', () {
    // Through the state's codec as well, because that is the trip that has
    // already lost a field once.
    final html = File('test/fixtures/detail_2192.html').readAsStringSync();
    final page = CollectedPage(
      items: const [],
      cards: const [],
      sex: '',
      titles: parseTitles(html),
    );
    final restored = CollectedPage.fromJson(page.toJson('pw187'), const {});

    expect(tierOf(restored.titles), 10);
  });

  test('com dois pacotes decodificados, vale o mais alto', () {
    // **O defeito que o dono apanhou a 10/11/2026.** A Madara tinha
    // `Fundador X` e `Fundador VII` no mesmo painel, e a primeira versão
    // devolvia o primeiro card do documento — que a página ordena por
    // equipado primeiro. Enquanto ela usava o VII, o índice dizia 7 e
    // procurar por *Fundador X* não a encontrava, apesar de ela ter o X.
    //
    // A fixture é o painel dela, recortado, **com o VII à frente** — que é
    // exactamente a ordem que produziu o erro. Posto o X primeiro, o teste
    // passaria com o código antigo e não provaria nada.
    final html = File(
      'test/fixtures/titulos_fundador_duplo.html',
    ).readAsStringSync();

    expect(parseTitles(html)!.founder, 'Fundador X');
  });

  test('e o equipado não é o que decide', () {
    // O filtro pergunta *Fundador N ou mais* — o que a pessoa comprou, não o
    // que está a vestir hoje. E o que está vestido muda sem o mercado mudar,
    // portanto seria a pior das duas coisas a guardar: o coletor não relê
    // quem fica anunciado, logo a leitura tem de ser a que não envelhece.
    final html = File(
      'test/fixtures/titulos_fundador_duplo.html',
    ).readAsStringSync();
    final titulos = parseTitles(html)!;

    expect(titulos.equipped, 'Fundador X');
    expect(titulos.founder, 'Fundador X');
  });
}
