/// The rune ladder of The Classic PW 1.8.7.
///
/// A rune goes in the centre of the fusion window and up to **five** others
/// feed it. Each fuel rune adds a percentage; a hundred guarantees the level.
/// Fuel may never be above the centre's level, and **colour does not matter**
/// — a blue rune feeds a green one, and the centre's colour is what survives.
///
/// **The ladder is irregular, and that is the whole reason this file exists.**
/// A same-level fuel gives 50% at the bottom, 20% at level 3, 33.33% at 4 and
/// 5, 20% again at 6, then 25% to the top. Nothing about a level predicts its
/// neighbour: steps 3→4 and 6→7 each want five fuel runes where the ones
/// around them want three or four. Every number here was read off the game by
/// the owner and checked against the two cost lists the window prints.
///
/// One prediction was made during that reading and it was **wrong**: the
/// pattern 2,2,5 · 3,3,5 · 4,4,5 held for eight rungs and then 9→10 came back
/// as four, not five. A level 10 costs 648.000 level ones, not the 777.600 a
/// tidy formula gives. There is no formula. There is this table.
library;

/// How many fuel runes of the centre's own level a step needs.
///
/// Keyed by the level being **reached**, so `combustivelPara(4)` is the cost
/// of turning a 3 into a 4.
const _combustivel = <int, int>{
  2: 2,
  3: 2,
  4: 5,
  5: 3,
  6: 3,
  7: 5,
  8: 4,
  9: 4,
  10: 4,
};

/// The highest rune the game has.
const nivelMaximo = 10;

int combustivelPara(int nivel) => _combustivel[nivel]!;

/// What one fuel rune of the centre's own level contributes, as the game
/// prints it in the window.
///
/// Derived from [combustivelPara] rather than stored twice: the two are the
/// same fact, and a second table is how they come to disagree.
double porcentagemDoMesmoNivel(int nivel) => 100 / combustivelPara(nivel);

/// What a rune of [nivel] is worth in level-one runes.
///
/// A step consumes the centre plus its fuel, all of the same level, so each
/// rung multiplies the one below by `combustivel + 1`.
int custoEmNivel1(int nivel) {
  var valor = 1;
  for (var n = 2; n <= nivel; n++) {
    valor *= combustivelPara(n) + 1;
  }
  return valor;
}

/// The item whose art draws a rune of each level.
///
/// **A different colour at each level, cycling through all five, and that is
/// the message.** Fusion ignores colour entirely — a blue rune feeds a green
/// one — and a page that drew ten runes of one family would quietly suggest
/// otherwise to somebody holding a drawer of mixed colours.
///
/// It costs nothing, because the art brightens with the **level** regardless
/// of family: the tenth still reads as the most elaborate of the ten even
/// with the colours shuffled. The assignment is fixed rather than random, so
/// a level always draws the same way and nobody wonders whether the picture
/// changing means something.
///
/// The ids are pinned against the collected market by `runa_test`: an
/// invented id draws an empty box, which on a page whose whole job is telling
/// levels apart would be silently wrong.
const _arte = <int, int>{
  1: 52185, // Verdejante
  2: 52206, // Escarlate
  3: 52197, // Celeste
  4: 52178, // Áurea
  5: 52219, // Argêntea
  6: 52190, // Verdejante
  7: 52211, // Escarlate
  8: 52202, // Celeste
  9: 52183, // Áurea
  10: 52224, // Argêntea
};

int arteDaRuna(int nivel) => _arte[nivel]!;

/// The levels a result is worth spelling out in.
///
/// **One, five and seven, because those are what the game hands out.** It is
/// not about the size of the number: a player counts their stock in the
/// denominations they are given, and 125 runes of level 7 is a errand while
/// 648.000 of level 1 is only a feeling. Scales at or above the target are
/// dropped — telling somebody a level 5 costs one level 5 says nothing.
List<int> escalasPara(int alvo) =>
    [7, 5, 1].where((n) => n < alvo).toList(growable: false);
