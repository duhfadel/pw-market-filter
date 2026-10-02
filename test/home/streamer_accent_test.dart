import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/domain/streamer_accent.dart';

/// The colour a streamer's card wears.
///
/// The one rule worth losing sleep over: [PWColors.accent] is the money
/// colour, and it must never show up here — gold on a streamer card would
/// read as paid placement, which is the one thing this section must never
/// look like.
void main() {
  group('known streamers', () {
    test('gsafoot wears the measured green', () {
      expect(StreamerAccent.of('gsafoot'), const Color(0xFF18A818));
    });

    test('persybr wears silver, because the emblem itself is monochrome', () {
      expect(StreamerAccent.of('persybr'), const Color(0xFFC0C0C0));
    });

    test('pavaotv wears the blue measured off the mascot itself', () {
      expect(StreamerAccent.of('pavaotv'), const Color(0xFF2A95FF));
    });

    test('the login is matched case-insensitively', () {
      expect(StreamerAccent.of('GSAFOOT'), StreamerAccent.of('gsafoot'));
    });
  });

  group('an unknown login', () {
    test('falls back to the site violet rather than drawing nothing', () {
      expect(StreamerAccent.of('ningueminscrito'), StreamerAccent.fallback);
    });

    test(
      'the fallback is the existing glow violet, not an invented colour',
      () {
        expect(StreamerAccent.fallback, PWColors.glowViolet);
      },
    );
  });

  test('no entry is the money gold, known or fallback', () {
    // Read off the table rather than listed here: a hand-written list stops
    // covering the entry added after it, and says nothing while it does.
    for (final cor in [...StreamerAccent.todas, StreamerAccent.fallback]) {
      expect(cor, isNot(PWColors.accent));
    }
  });

  test('the table is not empty, so the rule above is not vacuous', () {
    expect(StreamerAccent.todas, isNotEmpty);
  });
}
