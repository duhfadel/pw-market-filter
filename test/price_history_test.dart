import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/price_history.dart';

final _hoje = DateTime.utc(2026, 10, 1);
final _ontem = DateTime.utc(2026, 9, 30);

void main() {
  test('a character never seen before starts its record today', () {
    final h = avancar(null, preco: 500, precoAnterior: null, agora: _hoje);

    expect(h.firstSeen, _hoje);
    expect(h.previousPrice, isNull);
    expect(h.lowestPrice, 500);
    expect(h.cuts, 0);
  });

  test('a price that falls is a cut, and the old price is kept to show', () {
    // The whole point: the card says "baixou de 500 para 400", so the 500 has
    // to survive somewhere.
    final antes = PriceHistory(firstSeen: _ontem, lowestPrice: 500);
    final h = avancar(antes, preco: 400, precoAnterior: 500, agora: _hoje);

    expect(h.firstSeen, _ontem, reason: 'first seen never moves');
    expect(h.previousPrice, 500);
    expect(h.lowestPrice, 400);
    expect(h.cuts, 1);
  });

  test('a price that rises is not a cut, and the floor does not move', () {
    final antes = PriceHistory(firstSeen: _ontem, lowestPrice: 400, cuts: 1);
    final h = avancar(antes, preco: 900, precoAnterior: 400, agora: _hoje);

    expect(h.previousPrice, 400);
    expect(h.lowestPrice, 400, reason: 'the cheapest it ever was');
    expect(h.cuts, 1, reason: 'a rise is not a cut');
  });

  test('a price that did not move changes nothing at all', () {
    // Most prices never move. If standing still wrote a row, the index would
    // grow by 1519 entries every fifteen minutes.
    final antes = PriceHistory(
      firstSeen: _ontem,
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 1,
    );
    final h = avancar(antes, preco: 400, precoAnterior: 400, agora: _hoje);

    expect(
      h.previousPrice,
      500,
      reason: 'still the price before the last move',
    );
    expect(h.lowestPrice, 400);
    expect(h.cuts, 1);
  });

  test('down, up and down again is two cuts, not three', () {
    var h = avancar(null, preco: 500, precoAnterior: null, agora: _ontem);
    h = avancar(h, preco: 400, precoAnterior: 500, agora: _hoje);
    h = avancar(h, preco: 600, precoAnterior: 400, agora: _hoje);
    h = avancar(h, preco: 450, precoAnterior: 600, agora: _hoje);

    expect(h.cuts, 2);
    expect(h.lowestPrice, 400, reason: 'the floor is the floor, not the last');
    expect(h.previousPrice, 600);
  });

  test('a record survives the round trip', () {
    final h = PriceHistory(
      firstSeen: _ontem,
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 2,
    );
    final volta = PriceHistory.fromJson(h.toJson());

    expect(volta.firstSeen, h.firstSeen);
    expect(volta.previousPrice, h.previousPrice);
    expect(volta.lowestPrice, h.lowestPrice);
    expect(volta.cuts, h.cuts);
  });

  test('a record that never moved writes no previousPrice', () {
    // Keeps the index small: four fields is the ceiling, and most characters
    // carry two.
    final h = PriceHistory(firstSeen: _ontem, lowestPrice: 400);

    expect(h.toJson().containsKey('previousPrice'), isFalse);
    expect(
      h.toJson()['cuts'],
      isNull,
      reason: 'zero is the default, not a row',
    );
  });
}
