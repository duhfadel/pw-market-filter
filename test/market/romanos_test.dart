import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/romanos.dart';

void main() {
  test('the ten rungs go both ways', () {
    for (var grau = 1; grau <= 10; grau++) {
      expect(grauDoRomano(romanoDe(grau)), grau);
    }
  });

  test('the figures are the ones the game prints', () {
    expect(romanoDe(1), 'I');
    expect(romanoDe(4), 'IV');
    expect(romanoDe(9), 'IX');
    expect(romanoDe(10), 'X');
  });

  test('an eleventh rung prints its own number rather than throwing', () {
    expect(romanoDe(11), '11');
    expect(romanoDe(0), '0');
  });

  test('a word that merely starts with a figure is not a figure', () {
    // `Fundador Ilustre` must never read as `Fundador I`.
    expect(grauDoRomano('Ilustre'), isNull);
    expect(grauDoRomano('i'), isNull);
    expect(grauDoRomano(''), isNull);
  });
}
