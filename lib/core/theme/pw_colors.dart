import 'package:flutter/material.dart';

/// Every colour in the app. No `Color(0xFF…)` anywhere else.
///
/// The palette follows the marketplace itself — a deep indigo night with a
/// warm gold for what matters — so a card here and a card there read as the
/// same object.
abstract final class PWColors {
  /// The palette the redesign is built on, **sampled from the site's own art
  /// rather than invented**.
  ///
  /// The three class portraits were sampled at 120×120 with the dark pixels
  /// discarded, and every dominant hue lands between **240° and 330°** —
  /// violet, purple, magenta — with near-white highlights around `#F0D8F0`.
  /// The old indigo is in that family but *flat* beside art that is violet and
  /// magenta, and the gold accent was the only warm thing on the page. That
  /// mismatch is why the art always looked pasted on rather than placed.
  ///
  /// These live beside the old tokens rather than replacing them. A screen
  /// moves to them when its own plan ports it; until then both palettes are
  /// valid and nothing is half-painted.
  static const noite = Color(0xFF12102A);
  static const painel = Color(0xFF1B1738);
  static const elevado = Color(0xFF262046);
  static const filete = Color(0xFF2F2857);
  static const apagado = Color(0xFF9A93B8);
  static const papel = Color(0xFFF0E6F2);

  /// Structure — links, focus — and **one of the two class accents**.
  static const violeta = Color(0xFF785ADC);

  /// The other class accent, and the *novo* badge.
  ///
  /// **The accent rotates between these two and never leaves them.** An
  /// earlier draft said "amber for the Bárbaro" and that was a contradiction:
  /// amber *is* [accent], and [accent] is price. An accent borrowing the money
  /// colour breaks the one rule this palette is built on, on the screen where
  /// it is most visible. Two accents also kill the alternative — seventeen
  /// colours needing seventeen contrast checks — and both of these already
  /// hold at 14 px against [painel].
  static const magenta = Color(0xFFD4609E);

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

  /// The two paths, on the badge beside the name.
  ///
  /// A badge and not a tinted card, which was tried and dropped: the card
  /// already spends red and blue on item grades, so a red card buries the red
  /// of a grade-6 name, and a character whose path was never read would become
  /// a third state by accident — the one with no tint. The badge also carries
  /// the word, so the colour is a shortcut rather than the only message.
  static const god = Color(0xFF62A8F0);
  static const evil = Color(0xFFFF6B6B);

  static const danger = Color(0xFFFF6B6B);
  static const ok = Color(0xFF5FBAB9);

  /// Uma loja de itens que ainda tem espaço, nos cartões do 1.2.6.
  ///
  /// **Fica a ΔE 26 de [male], e isso é o mais longe que um segundo azul
  /// chega.** O glifo de sexo já veste um azul no mesmo cartão, e a menor
  /// separação que este site aceita noutro lado é 38 — portanto as duas
  /// coisas são parecidas e só a forma as separa: um símbolo minúsculo ao
  /// lado do nome contra um par ícone-e-número mais abaixo. Foi decisão do
  /// dono pedir azul; a alternativa que não colide é não pintar nada quando
  /// a loja não está cheia, deixando o verde ser o único sinal.
  static const espacoLivre = Color(0xFF7C93FF);

  /// The dot that says somebody is streaming *now*.
  ///
  /// A green of its own rather than [ok], which is a teal and reads as
  /// "correct" instead of "online" — green is the signal everybody already
  /// knows from every chat app, and borrowing the wrong one costs the whole
  /// message.
  ///
  /// Lifted towards the light end like every colour here: at 7.6 against
  /// `surface` it sits between [textMuted] (6.5) and [ok] (8.0), where
  /// Discord's own #3BA55D would land at 5.8 and go muddy on a dark panel.
  static const live = Color(0xFF5FBA7D);

  /// The frame of a character wearing the **defensive** UP5.
  ///
  /// The other four rungs of the card's frame are one ladder — how much the
  /// weapon gives — and they take the game's rarity colours in order of how
  /// much that is. This one is not a rung: it is the same top tier asked in
  /// the other currency, and a player hunting a defensive weapon is not
  /// shopping for a cheaper attacking one. Eight characters in 1519 carry it.
  ///
  /// **Green rather than the blue that was asked for, and the measurement is
  /// why.** Composited at the border's 55% over [surface], blue `#56A8F5`
  /// lands 27.9 ΔE from the 40-69 purple — the shortest distance in the whole
  /// ladder, and closer than the red/amber pair already in it, against a
  /// purple that holds 24% of the grid. This green's worst neighbour is amber
  /// at 41.8. The same trap caught the first version of the ladder, which
  /// used two neighbouring ambers and blurred UP5 against 70.
  ///
  /// It is the green of [gradeColors] rung 1 to the byte, and that costs
  /// nothing: a rank-1 item and a defensive weapon never share a card's
  /// frame — the frame draws one colour, chosen here.
  static const defenceTier = Color(0xFF6FCF97);

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
