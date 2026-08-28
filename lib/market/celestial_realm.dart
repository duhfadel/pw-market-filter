/// The ten celestial realms, in the order the game advances through them.
///
/// **The order came from the player, and it had to.** The page lists the same
/// ten names as anecdote chapters in a completely different sequence — Real,
/// Oscilante, do Crepúsculo, Devoto, Astral, Ápice, Arcano, de Miragem — and
/// deriving the scale from that would have ordered the market wrongly with
/// nothing on screen to say so. Same shape as the rank rule: when the data
/// will not say, ask the person who plays.
///
/// Each realm has ten steps, written in Roman numerals, so the whole scale is
/// a hundred rungs and [CelestialRealm.ordinal] flattens it to one number.
const celestialTiers = <String>[
  'Arcano',
  'Miragem',
  'Astral',
  'Oscilante',
  'Crepúsculo',
  'Real',
  'Devoto',
  'Ápice',
  'Majestoso',
  'Soberano',
];

/// How the site writes a realm, for a screen that wants to offer the ten.
///
/// Only `Miragem` and `Crepúsculo` take an article, and this is the one place
/// that knows it — matching goes the other way, by the distinctive word alone.
String celestialTierLabel(String tier) => switch (tier) {
  'Miragem' => 'Céu da Miragem',
  'Crepúsculo' => 'Céu do Crepúsculo',
  _ => 'Céu $tier',
};

const _roman = <String, int>{
  'I': 1,
  'II': 2,
  'III': 3,
  'IV': 4,
  'V': 5,
  'VI': 6,
  'VII': 7,
  'VIII': 8,
  'IX': 9,
  'X': 10,
};

/// A character's position on the celestial scale.
class CelestialRealm {
  const CelestialRealm({required this.tier, required this.step});

  /// Index into [celestialTiers].
  final int tier;

  /// 1 to 10.
  final int step;

  /// One number for the whole scale, 1 to 100, so a minimum is a comparison
  /// and an ordering is a subtraction.
  int get ordinal => tier * 10 + step;

  /// Reads `Céu Ápice VIII`, or null for anything it cannot place.
  ///
  /// **Matched by the distinctive word, not by the whole phrase.** Eight of the
  /// ten tiers have never been seen on a real sheet — only Ápice, Majestoso
  /// and Oscilante have — so the exact wording of the rest is unverified, and
  /// `Céu da Miragem` against `Céu de Miragem` would drop a whole realm out of
  /// every ordering in silence. The word `Miragem` cannot be got wrong.
  ///
  /// Null rather than a guess: the collector prints every realm it could not
  /// place, so a spelling nobody predicted is reported on the first run
  /// instead of quietly sorting last for ever.
  static CelestialRealm? parse(String? text) {
    if (text == null) return null;

    for (var tier = 0; tier < celestialTiers.length; tier++) {
      if (!text.contains(celestialTiers[tier])) continue;

      final step = _roman[text.split(' ').last.trim()];
      if (step == null) return null;
      return CelestialRealm(tier: tier, step: step);
    }
    return null;
  }
}
