import 'package:flutter/material.dart';

/// Every colour in the app. No `Color(0xFF…)` anywhere else.
///
/// The palette follows the marketplace itself — a deep indigo night with a
/// warm gold for what matters — so a card here and a card there read as the
/// same object.
abstract final class PWColors {
  static const background = Color(0xFF0B0B1A);
  static const surface = Color(0xFF13132A);
  static const surfaceRaised = Color(0xFF1C1C38);
  static const border = Color(0xFF2C2C4E);

  static const text = Color(0xFFE8E8F4);
  static const textMuted = Color(0xFF8F9BB8);

  static const accent = Color(0xFFFFB454);

  /// The night the front page's light is painted over.
  ///
  /// The page used to sit on a flat [background] at every size, and on a wide
  /// monitor that is a 1040 px column of content inside a 1920 px field of one
  /// colour — the content reads as floating rather than placed. These three
  /// are the top of that light, and they are deliberately violet rather than
  /// a lift of the same indigo: a gradient between two shades of one colour is
  /// a stain, and a shift in hue is a sky.
  static const nightTop = Color(0xFF16143A);
  static const glowViolet = Color(0xFF785ADC);
  static const glowDeep = Color(0xFF5A46C8);
  static const accentDim = Color(0xFF6B4E1F);

  /// The two sexes the site prints, and nothing else — a value it does not
  /// print draws no glyph rather than a third colour.
  ///
  /// Blue and pink because the convention is instant and this is a badge read
  /// at a glance in a grid of forty cards; both are lifted towards the light
  /// end so they hold against [surface] at 14 px, where a saturated hue goes
  /// muddy.
  static const male = Color(0xFF62A8F0);
  static const female = Color(0xFFF07AB4);

  static const danger = Color(0xFFFF6B6B);
  static const ok = Color(0xFF5FBAB9);

  /// Item grades, following the game's own rarity colours.
  static const gradeColors = <int, Color>{
    0: Color(0xFFB9C0D4),
    1: Color(0xFF6FCF97),
    2: Color(0xFF56A8F5),
    3: Color(0xFFB57BEE),
    4: Color(0xFFFFB454),
    5: Color(0xFFFF8C42),
    6: Color(0xFFFF5C5C),
  };

  static Color grade(int grade) => gradeColors[grade] ?? textMuted;
}
