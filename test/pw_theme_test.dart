import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';

void main() {
  test('the body face is named and is not the display face', () {
    expect(PWTheme.body, 'Inter');
    expect(PWTheme.body, isNot(PWTheme.display));
  });

  test('every text style carries tabular figures', () {
    // The site is a column of prices. Proportional figures make 1111 narrower
    // than 8888, so a column of them does not line up and comparing becomes
    // reading. This is the whole reason the face changed.
    final theme = PWTheme.build();
    final styles = [
      theme.textTheme.bodyMedium,
      theme.textTheme.bodyLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.labelLarge,
    ];

    for (final style in styles) {
      expect(
        style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'a figure in this style would not line up in a column',
      );
    }
  });

  test('the body face is the default and the display face is not', () {
    // Marcellus draws Roman figures — its 1 has no flag and its 0 is barely an
    // O, so `150 TCC` reads `I5O TCC`. Anything that might hold a number must
    // default to the body face; the display face is asked for by name.
    expect(PWTheme.build().textTheme.bodyMedium?.fontFamily, PWTheme.body);
  });

  test('the app is painted on the new ground', () {
    // The screens keep their own layout; what changes is the colour beneath
    // them. `noite` is warmer and more violet than the old flat indigo, which
    // is what stops the class art reading as pasted on.
    final theme = PWTheme.build();

    expect(theme.scaffoldBackgroundColor, PWColors.noite);
    expect(theme.cardTheme.color ?? theme.cardColor, PWColors.painel);
  });

  test('body text is paper, not pure white', () {
    // Pure white on a dark ground glares at 14 px. `papel` is the highlight
    // the class art itself carries.
    expect(PWTheme.build().textTheme.bodyMedium?.color, PWColors.papel);
  });
}
