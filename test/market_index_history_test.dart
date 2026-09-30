import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

MarketCharacter _quem({PriceHistory? history}) => MarketCharacter(
  roleId: 1,
  name: 'tmzin',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 400,
  fame: 0,
  cultivation: 'Leal',
  equipped: const [],
  history: history,
);

MarketIndex _indice({DateTime? historyFrom, PriceHistory? history}) =>
    MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 1),
      attributes: const [],
      items: const {},
      characters: [_quem(history: history)],
      historyFrom: historyFrom,
    );

void main() {
  test('a record survives the index round trip', () {
    final h = PriceHistory(
      firstSeen: DateTime.utc(2026, 9, 20),
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 2,
    );
    final volta = MarketIndex.fromJson(
      _indice(historyFrom: DateTime.utc(2026, 9, 30), history: h).toJson(),
    );

    expect(volta.historyFrom, DateTime.utc(2026, 9, 30));
    expect(volta.characters.single.history?.firstSeen, h.firstSeen);
    expect(volta.characters.single.history?.previousPrice, 500);
    expect(volta.characters.single.history?.cuts, 2);
  });

  test('an index written before the record reads as having none', () {
    // The first run with this code fetches a published index at version 1.
    // It must open with the fields empty rather than throw, and so must the
    // app: the site serves whatever collection last landed.
    final antigo = _indice().toJson();
    antigo['formatVersion'] = 1;
    antigo.remove('historyFrom');

    final volta = MarketIndex.fromJson(antigo);

    expect(volta.historyFrom, isNull);
    expect(volta.characters.single.history, isNull);
  });

  test('a version nobody wrote is still refused', () {
    final futuro = _indice().toJson();
    futuro['formatVersion'] = 99;

    expect(
      () => MarketIndex.fromJson(futuro),
      throwsA(isA<IndexFormatException>()),
    );
  });

  test('a character with no record writes no key', () {
    expect(_quem().toJson().containsKey('history'), isFalse);
  });
}
