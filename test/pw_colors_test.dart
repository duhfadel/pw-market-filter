import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';

/// WCAG relative luminance, and then contrast, computed here rather than
/// trusted: the palette's whole claim is that these colours hold at 14 px on a
/// dark panel, and a claim nobody checks is a claim that drifts.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('the eight tokens exist and are distinct', () {
    final todas = <Color>{
      PWColors.noite,
      PWColors.painel,
      PWColors.elevado,
      PWColors.filete,
      PWColors.apagado,
      PWColors.papel,
      PWColors.violeta,
      PWColors.magenta,
    };

    expect(todas, hasLength(8), reason: 'two tokens share a value');
  });

  test('text holds against the panel it sits on', () {
    // 4.5:1 is WCAG AA for body text. `apagado` is secondary text and the
    // palette claims it clears the bar too — the existing `textMuted` does,
    // at 6.5, and this one must not be a step backwards.
    expect(_contrast(PWColors.papel, PWColors.painel), greaterThan(7));
    expect(_contrast(PWColors.apagado, PWColors.painel), greaterThan(4.5));
    expect(_contrast(PWColors.papel, PWColors.noite), greaterThan(7));
  });

  test('the two class accents hold at 14px on the panel', () {
    // These two carry the rotating accent, so both must clear the bar — not
    // just the one that happened to be sampled first.
    expect(_contrast(PWColors.violeta, PWColors.painel), greaterThan(3));
    expect(_contrast(PWColors.magenta, PWColors.painel), greaterThan(3));
  });

  test('the grounds are darker than what sits on them', () {
    // noite < painel < elevado, so a panel on a panel reads as raised rather
    // than as a different thing.
    expect(_luminance(PWColors.noite), lessThan(_luminance(PWColors.painel)));
    expect(_luminance(PWColors.painel), lessThan(_luminance(PWColors.elevado)));
  });

  test('gold is left exactly where it was', () {
    // `accent` is the money colour and does not move in this plan. The rule
    // that it stops marking everything else is enforced screen by screen, in
    // the plans that port them.
    expect(PWColors.accent, const Color(0xFFFFB454));
  });
}
