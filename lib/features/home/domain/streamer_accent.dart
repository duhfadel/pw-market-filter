import 'package:flutter/material.dart';

import '../../../core/theme/pw_colors.dart';

/// The colour a streamer's card wears.
///
/// This is deliberately **not** in [PWColors]. That class holds the choices
/// this app makes about its own presentation — the same gold on every price,
/// the same grade ladder on every item. An accent here is a fact about one
/// streamer's own brand, keyed by their login the same way the streamer's art
/// address is: data that grows by one line per streamer, not a theme
/// decision.
///
/// A hardcoded table rather than extracting the colour from the art in the
/// browser. Extraction means a new streamer works the day they send art, with
/// no entry to write — but it costs a canvas read on every card, on every
/// load, for a colour nobody can correct if it comes out ugly, and this app
/// takes no new dependency without asking first. A table costs one line per
/// streamer and nothing at runtime, and a wrong colour is one edit away.
abstract final class StreamerAccent {
  /// Measured against [PWColors.surface], the panel every card sits on.
  static const _porLogin = <String, Color>{
    // 5.4:1 against the panel.
    'gsafoot': Color(0xFF18A818),
    // 9.4:1 — and silver is correct here, not a missed extraction: the
    // emblem itself is monochrome, so grey *is* the brand.
    'persybr': Color(0xFFC0C0C0),
  };

  /// The site's own violet, for anybody not yet in the table.
  ///
  /// A card with no colour at all would read as broken rather than neutral —
  /// every other card on the page wears one — so an unknown login still gets
  /// a colour instead of drawing nothing.
  static const fallback = PWColors.glowViolet;

  static Color of(String login) => _porLogin[login.toLowerCase()] ?? fallback;
}
