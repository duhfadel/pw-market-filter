import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/celestial_realm.dart';

void main() {
  test('the scale runs from Arcano I to Soberano X', () {
    expect(CelestialRealm.parse('Céu Arcano I')?.ordinal, 1);
    expect(CelestialRealm.parse('Céu Soberano X')?.ordinal, 100);
  });

  test('the last step of a realm sits just below the first of the next', () {
    // Ápice X and Majestoso I are neighbours, which is what the market shows:
    // nobody was found between them.
    final apiceX = CelestialRealm.parse('Céu Ápice X')!.ordinal;
    final majestosoI = CelestialRealm.parse('Céu Majestoso I')!.ordinal;

    expect(majestosoI - apiceX, 1);
  });

  test('the real sheets are read as written', () {
    expect(CelestialRealm.parse('Céu Ápice VIII')?.tier, 7);
    expect(CelestialRealm.parse('Céu Ápice VIII')?.step, 8);
    expect(CelestialRealm.parse('Céu Oscilante X')?.tier, 3);
  });

  test('either article on Miragem and Crepúsculo reads the same', () {
    // Eight of the ten tiers have never been seen on a real sheet, so the
    // exact wording is unverified. Matching the distinctive word means a
    // guessed article cannot drop a whole realm out of the ordering.
    for (final texto in ['Céu da Miragem IV', 'Céu de Miragem IV']) {
      expect(CelestialRealm.parse(texto)?.tier, 1, reason: texto);
      expect(CelestialRealm.parse(texto)?.step, 4, reason: texto);
    }
    expect(CelestialRealm.parse('Céu do Crepúsculo I')?.tier, 4);
  });

  test('a realm it cannot place is null, never realm zero', () {
    // Realm zero would sort an unknown below Arcano I and above nothing, and
    // look exactly like a real answer.
    expect(CelestialRealm.parse('Céu Inventado IV'), isNull);
    expect(CelestialRealm.parse('Céu Ápice XII'), isNull);
    expect(CelestialRealm.parse(''), isNull);
    expect(CelestialRealm.parse(null), isNull);
  });

  test('the label puts the article back for the two that take one', () {
    expect(celestialTierLabel('Miragem'), 'Céu da Miragem');
    expect(celestialTierLabel('Crepúsculo'), 'Céu do Crepúsculo');
    expect(celestialTierLabel('Ápice'), 'Céu Ápice');
  });

  test('every tier the app offers can be read back', () {
    for (final tier in celestialTiers) {
      final texto = '${celestialTierLabel(tier)} V';
      expect(CelestialRealm.parse(texto)?.step, 5, reason: texto);
      expect(
        celestialTiers[CelestialRealm.parse(texto)!.tier],
        tier,
        reason: texto,
      );
    }
  });
}
