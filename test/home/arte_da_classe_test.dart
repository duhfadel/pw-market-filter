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

  test('the same collection always wears the same class', () {
    // Finding 4 of the 2026-09-30 review: nothing pinned this, so a slide
    // back to `DateTime.now()` — the likelier accident, since it would look
    // like "rotate the hero" — would keep every existing test green. Same
    // `collectedAt` in, same class out, twice, is what a regression to the
    // wall clock cannot survive.
    final quando = DateTime.utc(2026, 8, 9, 12, 30);

    expect(classeDoCartaz(quando), classeDoCartaz(quando));
  });

  test('a different collection can wear a different class', () {
    // Guards the other half: a `classeDoCartaz` that ignored its argument
    // entirely (always returning `classesComArte.first`) would also pass the
    // determinism test above without ever actually reading the collection.
    final a = classeDoCartaz(DateTime.utc(2026, 8, 9));
    final b = classeDoCartaz(DateTime.utc(2026, 9, 30));

    expect(a, isNot(b));
  });

  test('no collection loaded yet opens on the first class', () {
    expect(classeDoCartaz(null), classesComArte.first);
  });

  test('every class with square art also has vertical art', () {
    // The 480x720 crop re-cut for the tall cards, shipped 01/10/2026 under
    // the same file names as the square folder — a different picture, not a
    // resize, which is why both can share a class without sharing a file.
    for (final classe in classesComArte) {
      expect(arteVerticalDaClasse(classe), isNotNull, reason: classe);
      expect(arteVerticalDaClasse(classe), contains('classes-verticais'));
    }
  });

  test('a class nobody has art for draws nothing in the vertical crop too', () {
    expect(arteVerticalDaClasse('Necromante'), isNull);
  });
}
