import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';

void main() {
  test('every class the market lists has art', () {
    // Seventeen files shipped in assets/images/classes/ on 30/09/2026, one per
    // class the collected market names. A class with no art would draw an
    // empty hero, which is worse than drawing somebody else's.
    expect(classesComArte, hasLength(17));
  });

  test('an accented class name still finds its file', () {
    // The index says `Bárbaro` and `Mercenário`; the files are named without
    // accents because a filename with one is a filename somebody will mistype.
    expect(arteDaClasse('Bárbaro'), 'assets/images/classes/barbaro.webp');
    expect(arteDaClasse('Mercenário'), 'assets/images/classes/mercenario.webp');
    expect(arteDaClasse('Místico'), 'assets/images/classes/mistico.webp');
  });

  test('a class nobody has art for draws nothing', () {
    // Silent, like ItemIcon's empty box. A hero with a missing image must fall
    // back to the plain ground, never to a broken box or somebody else's face.
    expect(arteDaClasse('Necromante'), isNull);
    expect(arteDaClasse(''), isNull);
  });

  test('the accent is only ever one of the two', () {
    // Never `accent`: that is the money colour, and an accent borrowing it
    // breaks the page's one rule on the screen where it shows most.
    for (final classe in classesComArte) {
      expect(
        acentoDaClasse(classe),
        anyOf(PWColors.violeta, PWColors.magenta),
        reason: classe,
      );
    }
  });

  test('an unmapped class falls back rather than guessing', () {
    expect(acentoDaClasse('Necromante'), PWColors.violeta);
  });

  test('both accents are actually used', () {
    // A map that answered violeta for all seventeen would pass the test above
    // and make the rotation a lie.
    final usados = classesComArte.map(acentoDaClasse).toSet();

    expect(usados, hasLength(2));
  });
}
