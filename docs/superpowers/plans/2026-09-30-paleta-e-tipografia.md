# A paleta e a tipografia — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `PWColors` carries the palette sampled from the site's own class art, and every figure on the site is set in a face with tabular numerals, so a column of prices lines up.

**Architecture:** Additive first, then a sweep. New tokens land beside the old ones; the old ones keep their meaning until the screens that use them are ported in a later plan. The only behavioural change is the typeface and its numerals.

**Tech Stack:** Dart, Flutter web, `PWColors`, `PWTheme`, bundled font assets.

**Spec:** `docs/superpowers/specs/2026-09-29-cara-nova-design.md`, the sections *The palette, and it was sampled rather than invented* and *Typography*.

## Scope

This is the foundation of a four-plan sequence. It changes **no layout**. The
Cartaz, the Vitrine, the grouped menu, the Registros frame and the Runes window
each get their own plan and each consumes what lands here.

## Global Constraints

- **No inline colours.** Every colour is a `static const` in `PWColors`. The only exception is `Colors.transparent`, which is the absence of a colour.
- **Numbers never use `PWTheme.display`.** Marcellus draws Roman figures — its `1` has no flag and its `0` is barely an `O`, so `150 TCC` reads `I5O TCC`. Every price, count and attribute stays on the body face.
- **No new package dependency.** A bundled font file is not a package; `google_fonts` would be, and is forbidden — it adds a dependency and a runtime CDN round trip for something that weighs under 300 KB.
- **A bundled font ships its licence beside it**, as `assets/fonts/OFL.txt` already does for Marcellus. Redistributing the file is what that licence governs.
- `lib/` must NEVER import `dart:io`.
- Comments, docstrings and test names in **English**; UI strings in Portuguese.
- `flutter analyze` must end with `No issues found!` before every commit.
- Run `dart format lib/ test/ tool/` before committing.

---

### Task 1: The palette tokens

Eight tokens, each with the job it does and the measurement or decision behind
it. Nothing is renamed and nothing is deleted — the existing tokens stay until
the screens move.

**Files:**
- Modify: `lib/core/theme/pw_colors.dart`
- Test: `test/pw_colors_test.dart` (create)

**Interfaces:**
- Consumes: nothing.
- Produces: `PWColors.noite`, `.painel`, `.elevado`, `.filete`, `.apagado`, `.papel`, `.violeta`, `.magenta` — all `static const Color`.

- [ ] **Step 1: Write the failing test**

Create `test/pw_colors_test.dart`:

```dart
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
  return 0.2126 * channel(c.r) +
      0.7152 * channel(c.g) +
      0.0722 * channel(c.b);
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
    expect(
      _luminance(PWColors.painel),
      lessThan(_luminance(PWColors.elevado)),
    );
  });

  test('gold is left exactly where it was', () {
    // `accent` is the money colour and does not move in this plan. The rule
    // that it stops marking everything else is enforced screen by screen, in
    // the plans that port them.
    expect(PWColors.accent, const Color(0xFFFFB454));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pw_colors_test.dart`
Expected: FAIL — `The getter 'noite' isn't defined for the class 'PWColors'`

- [ ] **Step 3: Write the implementation**

In `lib/core/theme/pw_colors.dart`, add this block directly above the existing
`background` declaration. Nothing existing is touched.

```dart
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

```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/pw_colors_test.dart && flutter test`
Expected: both PASS. Nothing existing changed, so the whole suite must stay green.

- [ ] **Step 5: Analyze and commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/core/theme/pw_colors.dart test/pw_colors_test.dart
git commit -m "A paleta, amostrada da propria arte do site

As tres artes de classe foram amostradas a 120x120 com os pixels escuros fora,
e todo matiz dominante cai entre 240 e 330 graus -- violeta, purpura, magenta
-- com realces quase brancos. O indigo antigo esta nessa familia mas e chapado
ao lado de arte que e violeta e magenta, e o dourado era a unica coisa quente
da pagina. E por isso que a arte sempre pareceu colada em vez de colocada.

Os oito entram ao lado dos antigos e nao no lugar deles: uma tela migra quando
o plano dela a portar, e ate la as duas paletas valem e nada fica pela metade.

O teste calcula o contraste em vez de confiar nele. A promessa da paleta e que
estas cores se seguram a 14 px num painel escuro, e promessa que ninguem mede
e promessa que escorrega."
```

---

### Task 2: Inter, and figures that line up

The body face changes and every number gains tabular numerals. This is the
only task in the plan that changes what is on screen.

**Files:**
- Create: `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-SemiBold.ttf`, `assets/fonts/Inter-Bold.ttf`
- Modify: `assets/fonts/OFL.txt` (append Inter's licence), `pubspec.yaml`, `lib/core/theme/pw_theme.dart`
- Test: `test/pw_theme_test.dart` (create)

**Interfaces:**
- Consumes: nothing from Task 1.
- Produces: `PWTheme.body` (the family name string `'Inter'`), and `PWTheme.build()` returning a theme whose `textTheme` uses it with `FontFeature.tabularFigures()`.

**The builder is called `build()`, not `dark()`** — checked against the file.

- [ ] **Step 1: Fetch the font and its licence**

Inter is under the SIL Open Font License, the same licence Marcellus already
ships under. Download the three static weights and the licence:

```bash
cd /tmp && rm -rf inter && mkdir inter && cd inter
curl -sL -o inter.zip "https://github.com/rsms/inter/releases/download/v4.0/Inter-4.0.zip"
unzip -q inter.zip
find . -name "Inter-Regular.ttf" -o -name "Inter-SemiBold.ttf" -o -name "Inter-Bold.ttf" | head
```

Copy the three files into `assets/fonts/` and append the archive's `LICENSE.txt`
to `assets/fonts/OFL.txt` under a heading naming Inter, so the file covers both
faces. **If the URL 404s**, find the current release rather than guessing — and
if no static TTFs are published any more, report BLOCKED rather than shipping a
variable font, which Flutter web renders inconsistently across engines.

Check the sizes before committing: each weight should be roughly 300 KB or
less. Anything over 1 MB is the variable font wearing a static name.

- [ ] **Step 2: Write the failing test**

Create `test/pw_theme_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';

void main() {
  test('the body face is named and is not the display face', () {
    expect(PWTheme.body, 'Inter');
    expect(PWTheme.body, isNot(PWTheme.display));
  });

  test('every text style carries tabular figures', () {
    // The site is a column of prices. Proportional figures make 1111 narrower
    // than 8888, so a column of them does not line up and comparing becomes
    // reading. This is the whole reason the face changed.
    final theme = PWTheme.build();
    final styles = [
      theme.textTheme.bodyMedium,
      theme.textTheme.bodyLarge,
      theme.textTheme.titleMedium,
      theme.textTheme.labelLarge,
    ];

    for (final style in styles) {
      expect(
        style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
        reason: 'a figure in this style would not line up in a column',
      );
    }
  });

  test('the body face is the default and the display face is not', () {
    // Marcellus draws Roman figures — its 1 has no flag and its 0 is barely an
    // O, so `150 TCC` reads `I5O TCC`. Anything that might hold a number must
    // default to the body face; the display face is asked for by name.
    expect(PWTheme.build().textTheme.bodyMedium?.fontFamily, PWTheme.body);
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/pw_theme_test.dart`
Expected: FAIL — `The getter 'body' isn't defined for the class 'PWTheme'`

- [ ] **Step 4: Declare the fonts**

In `pubspec.yaml`, under the existing `fonts:` block, beside the Marcellus
entry:

```yaml
    - family: Inter
      fonts:
        - asset: assets/fonts/Inter-Regular.ttf
        - asset: assets/fonts/Inter-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Inter-Bold.ttf
          weight: 700
```

- [ ] **Step 5: Write the implementation**

Read `lib/core/theme/pw_theme.dart` first — it already builds a `ThemeData`
and already declares `display`. Add beside it:

```dart
  /// The body face, and every figure on the site.
  ///
  /// **Roboto was the face Flutter hands you when you have not chosen one**,
  /// and it was in every price, count and attribute here. Inter is a drop-in
  /// in metrics and texture but is drawn for screens, and it carries the
  /// feature below.
  static const body = 'Inter';
```

The existing `build()` does `base.textTheme.apply(bodyColor:, displayColor:)`.
**`apply` takes `fontFamily` but not `fontFeatures`**, so the feature has to be
copied onto the styles. Add this helper and run the applied theme through it:

```dart
  /// Figures that line up in a column.
  ///
  /// A site of prices lives or dies on this: with proportional figures `1111`
  /// is narrower than `8888`, so a column of them does not align and comparing
  /// two prices becomes reading them. `tnum` gives every digit the same
  /// advance width.
  ///
  /// Copied onto each style rather than passed to `TextTheme.apply`, which
  /// takes a family and colours but no font features.
  static const _figuras = [FontFeature.tabularFigures()];

  static TextTheme _comFiguras(TextTheme t) => TextTheme(
    displayLarge: t.displayLarge?.copyWith(fontFeatures: _figuras),
    displayMedium: t.displayMedium?.copyWith(fontFeatures: _figuras),
    displaySmall: t.displaySmall?.copyWith(fontFeatures: _figuras),
    headlineLarge: t.headlineLarge?.copyWith(fontFeatures: _figuras),
    headlineMedium: t.headlineMedium?.copyWith(fontFeatures: _figuras),
    headlineSmall: t.headlineSmall?.copyWith(fontFeatures: _figuras),
    titleLarge: t.titleLarge?.copyWith(fontFeatures: _figuras),
    titleMedium: t.titleMedium?.copyWith(fontFeatures: _figuras),
    titleSmall: t.titleSmall?.copyWith(fontFeatures: _figuras),
    bodyLarge: t.bodyLarge?.copyWith(fontFeatures: _figuras),
    bodyMedium: t.bodyMedium?.copyWith(fontFeatures: _figuras),
    bodySmall: t.bodySmall?.copyWith(fontFeatures: _figuras),
    labelLarge: t.labelLarge?.copyWith(fontFeatures: _figuras),
    labelMedium: t.labelMedium?.copyWith(fontFeatures: _figuras),
    labelSmall: t.labelSmall?.copyWith(fontFeatures: _figuras),
  );
```

and in `build()`:

```dart
      textTheme: _comFiguras(
        base.textTheme.apply(
          fontFamily: body,
          bodyColor: PWColors.text,
          displayColor: PWColors.text,
        ),
      ),
```

Note the colours stay on the **old** tokens here — Task 3 moves them. Doing
both in one task would make a failing colour test look like a font problem.

- [ ] **Step 6: Run the tests and look at it**

Run: `flutter test test/pw_theme_test.dart && flutter test && flutter analyze`
Expected: all PASS, analyze clean.

Then build and serve **on a port never used before**, and look at a column of
prices:

```bash
flutter build web
cd build/web && python3 -m http.server 9800
```

Open `http://localhost:9800/#/filtro`. The prices in the right-hand column of
the cards must line up on their digits. Compare `1000 TCC` against `8888 TCC`
if both are on screen — under the old face they were different widths.

Judge only that. Do not judge layout on `localhost`: this machine renders local
pages shifted right, and it is environmental.

- [ ] **Step 7: Commit**

```bash
dart format lib/ test/
git add assets/fonts/ pubspec.yaml lib/core/theme/pw_theme.dart test/pw_theme_test.dart
git commit -m "Inter no lugar do Roboto, e algarismos que se alinham

Roboto e a face que o Flutter entrega quando ninguem escolheu uma, e ela estava
em cada preco, contagem e atributo daqui. Inter e substituicao direta em
metrica e textura, desenhada para tela, e carrega tabular figures.

O alinhamento e o motivo de verdade: com algarismos proporcionais 1111 e mais
estreito que 8888, entao uma coluna de precos nao alinha e comparar dois vira
le-los. tnum da a todo digito a mesma largura, e este site e uma coluna de
precos.

A fonte vem empacotada e nao por google_fonts, que seria dependencia nova e uma
ida a CDN em tempo de execucao por algo que pesa menos de 300 KB. A licenca OFL
viaja junto, como a do Marcellus ja viaja."
```

---

### Task 3: The theme paints on the new ground

The app's scaffold, cards and panels move from the old tokens to the new ones.
This is the change that makes the site look different without any layout
moving.

**Files:**
- Modify: `lib/core/theme/pw_theme.dart`
- Test: `test/pw_theme_test.dart` (append)

**Interfaces:**
- Consumes: `PWColors.noite`, `.painel`, `.elevado`, `.filete`, `.papel`, `.apagado` (Task 1); `PWTheme.body` (Task 2).
- Produces: a `ThemeData` whose grounds are the new tokens.

- [ ] **Step 1: Write the failing test**

Append to `test/pw_theme_test.dart`:

```dart
  test('the app is painted on the new ground', () {
    // The screens keep their own layout; what changes is the colour beneath
    // them. `noite` is warmer and more violet than the old flat indigo, which
    // is what stops the class art reading as pasted on.
    final theme = PWTheme.build();

    expect(theme.scaffoldBackgroundColor, PWColors.noite);
    expect(theme.cardTheme.color ?? theme.cardColor, PWColors.painel);
  });

  test('body text is paper, not pure white', () {
    // Pure white on a dark ground glares at 14 px. `papel` is the highlight
    // the class art itself carries.
    expect(PWTheme.build().textTheme.bodyMedium?.color, PWColors.papel);
  });
```

Add the import:

```dart
import 'package:pw_market_filter/core/theme/pw_colors.dart';
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/pw_theme_test.dart`
Expected: FAIL — `scaffoldBackgroundColor` is still `PWColors.background`.

- [ ] **Step 3: Write the implementation**

In `lib/core/theme/pw_theme.dart`, swap the grounds:

- `scaffoldBackgroundColor: PWColors.background` → `PWColors.noite`
- any `PWColors.surface` used as a card or panel ground → `PWColors.painel`
- any `PWColors.surfaceRaised` → `PWColors.elevado`
- any `PWColors.border` in the theme → `PWColors.filete`
- body text colour `PWColors.text` → `PWColors.papel`
- secondary text `PWColors.textMuted` → `PWColors.apagado`

**Only inside `pw_theme.dart`.** Widgets that name `PWColors.surface`
directly are ported by the plan that owns their screen — changing them here
would paint half the site and leave the other half on the old ground, which
looks like a bug rather than a redesign.

- [ ] **Step 4: Run everything**

Run: `flutter test && flutter analyze && flutter build web`
Expected: all green.

**Some widget tests may fail on an exact colour.** That is the change working:
read each failure, and where a test asserted the old ground, update it to the
new token. Where a test asserted a colour this plan did not touch, leave it and
report it — that is a real regression.

- [ ] **Step 5: Look at it on a fresh port**

```bash
cd build/web && python3 -m http.server 9801
```

Every screen should be on the warmer violet ground, with nothing half-painted.
Report which screens still show the old flat indigo — those are widgets naming
`PWColors.surface` directly, and they belong to the later plans.

- [ ] **Step 6: Commit**

```bash
dart format lib/ test/
git add lib/core/theme/pw_theme.dart test/pw_theme_test.dart
git commit -m "O tema pinta no fundo novo

scaffold, cards e paineis passam para noite, painel e elevado. Nenhum layout se
move -- o que muda e a cor debaixo dele, e noite e mais quente e mais violeta
que o indigo chapado de antes, que e o que para de fazer a arte de classe
parecer colada.

So dentro de pw_theme.dart. Widget que nomeia PWColors.surface direto e portado
pelo plano que e dono da tela dele: mudar aqui pintaria metade do site e
deixaria a outra metade no fundo antigo, o que parece defeito e nao redesenho."
```

---

## What this plan deliberately does not do

- **No layout moves.** Not one widget changes position or size.
- **The old tokens are not deleted.** `background`, `surface`, `surfaceRaised`, `border`, `text`, `textMuted` all stay valid until the screens naming them are ported. Deleting them here would break every screen at once.
- **`accent` does not move.** Gold becoming price-only is enforced screen by screen, in the plans that port them — doing it here would leave buttons and arrows uncoloured on screens nobody has redesigned yet.
- **The Cartaz, the Vitrine, the grouped menu, the Registros frame and the Runes window** are the next three plans.

## After the last task

Nothing to update in `CLAUDE.md` yet: the palette is additive and the site
still looks like itself. The entry goes in when the home is ported and the
change becomes visible.
