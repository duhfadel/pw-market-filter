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
    // 5.9:1, and the mascot's own blue rather than a blue chosen to look
    // well: it is the commonest saturated colour in the peacock itself,
    // measured off the art. The teals that scored higher on contrast drift
    // off the bird and towards [persybr]'s silver — at 136 and 64 ΔE from
    // the two accents already here, this is the one that stays furthest
    // from both, which is what a strip cycling between cards needs.
    'pavaotv': Color(0xFF2A95FF),
    // 7.6:1, and a decision rather than an extraction — the owner's, on
    // 2026-10-03, after the art was measured and gave nothing safe.
    //
    // **The moon's own two colours are the two forbidden neighbourhoods.**
    // Its lit limb is a copper that lands ΔE 38 from [PWColors.accent], the
    // money gold, where the closest accent already shipping sits at 61 — and
    // gold on a streamer card reads as paid placement, which is the one thing
    // this strip must never look like. Its shadowed disc is a 206° blue that
    // falls on top of [pavaotv]. Sweeping every hue under those bars left
    // only pinks, which are not that picture.
    //
    // So violet, which suits the name — and **his own violet, not the
    // fallback**. The fallback is what a channel wears when nobody has chosen
    // for it, and two channels already wear it; the strip shows two cards at
    // a time, so leaving him there would eventually put two identical violets
    // side by side, which is precisely what an accent exists to prevent. At
    // ΔE 30 from [fallback] this is unmistakably violet and unmistakably not
    // that one.
    'penumbrapw': Color(0xFFDB87F5),
  };

  /// The site's own violet, for anybody not yet in the table.
  ///
  /// A card with no colour at all would read as broken rather than neutral —
  /// every other card on the page wears one — so an unknown login still gets
  /// a colour instead of drawing nothing.
  static const fallback = PWColors.glowViolet;

  static Color of(String login) => _porLogin[login.toLowerCase()] ?? fallback;

  /// Every colour the table holds, so a rule about accents can be checked
  /// over all of them instead of over a list somebody has to remember to
  /// extend. The gold rule below is the one that matters, and a hand-written
  /// enumeration would stop covering the table on the first entry added
  /// after it — silently, which is the only way that kind of test fails.
  static Iterable<Color> get todas => _porLogin.values;
}
