# A home: o Cartaz e a Vitrine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The front page opens with class art running full-bleed behind a headline, and proves its claim underneath with three real characters from the current market.

**Architecture:** Two new widgets and a header, assembled into the existing `HomeView` list. The art already ships — seventeen files in `assets/images/classes/`, one per class, wired to nothing. The three characters come from the index the page already loads.

**Tech Stack:** Dart, Flutter web, the palette from `docs/superpowers/plans/2026-09-30-paleta-e-tipografia.md` (already landed).

**Spec:** `docs/superpowers/specs/2026-09-29-cara-nova-design.md`, the sections *The direction: Cartaz above, Vitrine below* and *The rest of the home*.

## Global Constraints

- **No inline colours.** Every colour is a `static const` in `PWColors`. The palette landed: `noite`, `painel`, `elevado`, `filete`, `apagado`, `papel`, `violeta`, `magenta`, plus the existing `accent`.
- **Gold is price and nothing else.** On this page `PWColors.accent` may appear on a price and on the search button, and nowhere else — no arrows, no badges, no section rules. This is the single highest-value rule in the spec.
- **Numbers never use `PWTheme.display`.** Marcellus draws Roman figures: `150 TCC` reads `I5O TCC`.
- **The accent rotates between `violeta` and `magenta` only.** Never `accent` — that is the money colour and an accent borrowing it breaks the rule above on the screen where it is most visible.
- `lib/` must NEVER import `dart:io`.
- Comments, docstrings and test names in **English**; UI strings in **Portuguese**.
- `flutter analyze` must end with `No issues found!` before every commit.
- Run `dart format lib/ test/` before committing.
- **Never write a test that hits the live site.**

## What does not move, and why

Recorded so no task "tidies" them:

- **The streamers sit below the tools and above the Discord.** That position already cost an error once, when the card came out so discreet the owner could not find it.
- **The news dot is marked read once per load, on the way open.** Re-reading would clear it in the same frame that revealed what it announced.
- **The `novo` badge expires by date**, not by a flag.
- **The footer's *projeto de fã* line stays in full.** It is the sentence the site's permission to exist is drawn on.
- **The scrollable is the full width with the cap inside it.** A wheel event lands on whatever is under the pointer; a narrower scrollable means the page does not move when the mouse is out in the margin. `first_fold_test` pins this.

---

### Task 1: Which art, and which accent, for a class

Pure. A map from the class name the index carries to the asset that stands for
it, and to one of the two accents.

**Files:**
- Create: `lib/features/home/domain/arte_da_classe.dart`
- Test: `test/home/arte_da_classe_test.dart`

**Interfaces:**
- Consumes: `PWColors.violeta`, `PWColors.magenta`.
- Produces: `String? arteDaClasse(String classe)` returning an asset path or `null`; `Color acentoDaClasse(String classe)`; and `const classesComArte` — the list of class names that have a file.

- [ ] **Step 1: Write the failing test**

Create `test/home/arte_da_classe_test.dart`:

```dart
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
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/home/arte_da_classe_test.dart`
Expected: FAIL — the library does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/home/domain/arte_da_classe.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/pw_colors.dart';

/// The seventeen classes the market lists, mapped to the art that stands for
/// each and to the accent the page wears while showing it.
///
/// **The file names carry no accents and the class names do.** The index says
/// `Bárbaro` and `Místico`; the files are `barbaro.webp` and `mistico.webp`,
/// because a filename with an accent is a filename somebody eventually
/// mistypes — and the art arrives from a person, by hand, one file at a time.
///
/// The accent is **always one of two**, never [PWColors.accent]: gold is the
/// money colour, and an accent borrowing it breaks the page's one rule on the
/// screen where it is most visible. Each class is paired with whichever of the
/// two sits with its art; a class nobody has mapped falls back to violet
/// rather than guessing.
const _classes = <String, ({String arquivo, bool magenta})>{
  'Andarilho': (arquivo: 'andarilho', magenta: false),
  'Arcano': (arquivo: 'arcano', magenta: false),
  'Arqueiro': (arquivo: 'arqueiro', magenta: false),
  'Atiradora': (arquivo: 'atiradora', magenta: true),
  'Bárbaro': (arquivo: 'barbaro', magenta: false),
  'Bardo': (arquivo: 'bardo', magenta: false),
  'Ceifador': (arquivo: 'ceifador', magenta: true),
  'Espiritualista': (arquivo: 'espiritualista', magenta: true),
  'Feiticeira': (arquivo: 'feiticeira', magenta: true),
  'Guerreiro': (arquivo: 'guerreiro', magenta: true),
  'Mago': (arquivo: 'mago', magenta: true),
  'Mercenário': (arquivo: 'mercenario', magenta: false),
  'Místico': (arquivo: 'mistico', magenta: true),
  'Paladino': (arquivo: 'paladino', magenta: false),
  'Retalhador': (arquivo: 'retalhador', magenta: false),
  'Sacerdote': (arquivo: 'sacerdote', magenta: false),
  'Tormentador': (arquivo: 'tormentador', magenta: true),
};

/// Every class that has a file, in the order the map declares them.
const classesComArte = [
  'Andarilho',
  'Arcano',
  'Arqueiro',
  'Atiradora',
  'Bárbaro',
  'Bardo',
  'Ceifador',
  'Espiritualista',
  'Feiticeira',
  'Guerreiro',
  'Mago',
  'Mercenário',
  'Místico',
  'Paladino',
  'Retalhador',
  'Sacerdote',
  'Tormentador',
];

/// The art for [classe], or `null` where none was ever supplied.
///
/// `null` draws the plain ground — the same silent fallback `ItemIcon` makes.
/// A hero showing somebody else's face would be worse than a hero showing no
/// face at all.
String? arteDaClasse(String classe) {
  final entrada = _classes[classe];
  return entrada == null
      ? null
      : 'assets/images/classes/${entrada.arquivo}.webp';
}

/// The accent the page wears while showing [classe].
Color acentoDaClasse(String classe) =>
    (_classes[classe]?.magenta ?? false) ? PWColors.magenta : PWColors.violeta;
```

- [ ] **Step 4: Run the test**

Run: `flutter test test/home/arte_da_classe_test.dart && flutter test`
Expected: both PASS. Nothing existing was touched.

- [ ] **Step 5: Prove every file actually exists**

The map names seventeen files. A typo would compile, pass every test above and
draw an empty hero in production. Check them for real:

```bash
for c in andarilho arcano arqueiro atiradora barbaro bardo ceifador \
         espiritualista feiticeira guerreiro mago mercenario mistico \
         paladino retalhador sacerdote tormentador; do
  [ -f "assets/images/classes/$c.webp" ] || echo "FALTA $c.webp"
done
echo "checked"
```

Expected: no `FALTA` lines. If one appears, stop and report it — the art is
content somebody supplied and a missing file is not something to work around.

- [ ] **Step 6: Commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/features/home/domain/arte_da_classe.dart test/home/arte_da_classe_test.dart
git commit -m "Qual arte e qual acento para cada classe

As dezessete artes estavam no repositorio desde 30/09 ligadas a coisa nenhuma.
Este e o mapa que as liga: nome da classe como o indice o escreve, arquivo sem
acento, e um dos dois acentos.

Os arquivos nao tem acento e os nomes de classe tem. A arte chega de uma pessoa,
a mao, um arquivo por vez, e nome de arquivo com acento e nome que alguem acaba
digitando errado.

O acento e sempre um dos dois e nunca o dourado: dourado e preco, e acento que
pega emprestada a cor do dinheiro quebra a unica regra da pagina justamente na
tela onde ela mais aparece."
```

---

### Task 2: O Cartaz

The hero. Class art full-bleed, the headline in its negative space, the accent
following the class.

**Files:**
- Create: `lib/features/home/ui/widgets/cartaz.dart`
- Test: `test/home/cartaz_test.dart`

**Interfaces:**
- Consumes: `arteDaClasse`, `acentoDaClasse`, `classesComArte` (Task 1).
- Produces: `class Cartaz extends StatelessWidget` taking `required String classe`, `required bool wide`, and `required VoidCallback aoBuscar`.

- [ ] **Step 1: Write the failing test**

Create `test/home/cartaz_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cartaz.dart';

Future<void> _pump(
  WidgetTester tester, {
  String classe = 'Espiritualista',
  VoidCallback? aoBuscar,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1200,
          height: 400,
          child: Cartaz(
            classe: classe,
            wide: true,
            aoBuscar: aoBuscar ?? () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('it says what the site does before it says its name', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.textContaining('Ache o personagem'), findsOneWidget);
  });

  testWidgets('the search button is there and calls back', (tester) async {
    var chamou = false;
    await _pump(tester, aoBuscar: () => chamou = true);

    await tester.tap(find.text('Buscar personagens'));
    expect(chamou, isTrue);
  });

  testWidgets('it draws the art of the class it was given', (tester) async {
    await _pump(tester, classe: 'Bárbaro');

    final imagens = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => (i.image as AssetImage).assetName);

    expect(imagens, contains('assets/images/classes/barbaro.webp'));
  });

  testWidgets('a class with no art draws no image and does not crash', (
    tester,
  ) async {
    // The index could name a class the art never covered — a new one, or a
    // spelling nobody predicted. The hero falls back to the ground.
    await _pump(tester, classe: 'Necromante');

    expect(find.byType(Image), findsNothing);
    expect(find.textContaining('Ache o personagem'), findsOneWidget);
  });

  testWidgets('gold appears on the button and nowhere else', (tester) async {
    // The page's one rule. Gold is price and the call to action; an arrow or a
    // rule wearing it would spend the colour that has to mean money.
    await _pump(tester);

    final dourados = tester
        .widgetList<Text>(find.byType(Text))
        .where((t) => t.style?.color == PWColors.accent);

    expect(dourados, isEmpty, reason: 'no text on the Cartaz is gold');
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/home/cartaz_test.dart`
Expected: FAIL — `cartaz.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/home/ui/widgets/cartaz.dart`. The shape:

- a `SizedBox` of height 320 when `wide`, 260 otherwise, holding a `Stack`
- **bottom layer**: the art, `Image.asset(...)` with `fit: BoxFit.cover` and `alignment: const Alignment(0, -0.6)`, wrapped so a missing file draws nothing
- **middle layer**: two gradients. One horizontal, `noite` at full opacity to about 24% across, fading to transparent by 76% — this is what makes the text side readable while the art side stays clean. One vertical, a light wash of `noite` at the top and a heavier one at the bottom, so the hero seats against the header above and the Vitrine below.
- **top layer**: a left-aligned column holding
  - an eyebrow, `MERCADO DE PERSONAGENS · THE CLASSIC`, 9.5 px, letter-spaced, in `acentoDaClasse(classe)`
  - the headline `Ache o personagem\npelo que ele está usando`, in `PWTheme.display`, 40 px when wide and 28 otherwise, in `PWColors.papel`
  - the sub-line `Arma, cartas, relíquias, essências, runas — o que o marketplace guarda no inventário e não deixa procurar.`, 13.5 px, `PWColors.apagado`, capped at 430 px wide
  - a row with the search button and nothing else

**Two things the tests pin and the code must honour:**

`Alignment(0, -0.6)` is not a guess. `CLAUDE.md` records that the class arts
carry their faces about a fifth of the way down, and that `Alignment.center`
landed the visible band on a priest's skirt — on the widest card, which is
where a bad crop shows first. The Cartaz is the widest thing this site draws.

**No `Text` on this widget may be `PWColors.accent`.** The button's *fill* is
gold because it is the call to action; its label sits on gold and must be
`PWColors.noite`, not gold on gold.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/home/cartaz_test.dart && flutter test && flutter analyze`
Expected: all green.

- [ ] **Step 5: Commit**

```bash
dart format lib/ test/
git add lib/features/home/ui/widgets/cartaz.dart test/home/cartaz_test.dart
git commit -m "O Cartaz: a arte de classe sangra a primeira dobra

A arte ocupa o fundo inteiro e o texto vive no vazio dela. Nao e imagem ao lado
do conteudo -- ela e o chao.

O acento vem da classe, entao o site tem dezessete caras e duas visitas nao
abrem a mesma pagina. Custa nada: a arte ja estava no pacote.

O enquadramento e Alignment(0, -0.6) e nao e chute -- os rostos ficam a cerca de
um quinto do topo, e Alignment.center ja pos a faixa visivel na saia de um
sacerdote. O Cartaz e a coisa mais larga que este site desenha, que e onde corte
ruim aparece primeiro.

Nenhum texto aqui e dourado. Dourado e preco."
```

---

### Task 3: Which three characters the Vitrine shows

Pure domain. Given the index, which three prove the page's claim.

**Files:**
- Create: `lib/features/home/domain/vitrine.dart`
- Test: `test/home/vitrine_test.dart`

**Interfaces:**
- Consumes: `MarketIndex`, `MarketCharacter`, `runQuery`, `strongWeaponQuery` from `features/search/domain/`.
- Produces: `({MarketCharacter barato, MarketCharacter caro, MarketCharacter? raro})? vitrineDe(MarketIndex index)`.

- [ ] **Step 1: Write the failing test**

Create `test/home/vitrine_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/vitrine.dart';
import 'package:pw_market_filter/market/market_index.dart';

const _arma70 = EquippedItem(
  slot: 10,
  itemId: 50206,
  refine: 12,
  stones: [],
  attributes: {0: 70},
);
const _armaFraca = EquippedItem(
  slot: 10,
  itemId: 50100,
  refine: 0,
  stones: [],
  attributes: {0: 30},
);
const _armaDef80 = EquippedItem(
  slot: 10,
  itemId: 50300,
  refine: 12,
  stones: [],
  attributes: {1: 80},
);

MarketCharacter _quem(
  String nome,
  int preco, {
  List<EquippedItem> usa = const [_arma70],
}) => MarketCharacter(
  roleId: nome.hashCode,
  name: nome,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: preco,
  fame: 0,
  cultivation: 'Leal',
  equipped: usa,
);

MarketIndex _indice(List<MarketCharacter> quem) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 30),
  attributes: const ['Nível de Ataque', 'Nível de Defesa'],
  items: const {},
  characters: quem,
);

void main() {
  test('it picks the cheapest and the dearest of the SAME weapon tier', () {
    // The claim is "the same weapon, sixty times the price". Cheapest of the
    // whole market against dearest of the whole market would be a different
    // and false statement — they would not be carrying the same thing.
    final v = vitrineDe(
      _indice([
        _quem('barato', 130),
        _quem('meio', 900),
        _quem('caro', 8000),
        _quem('sem arma', 40, usa: const [_armaFraca]),
      ]),
    )!;

    expect(v.barato.name, 'barato');
    expect(v.caro.name, 'caro');
  });

  test('the rare one carries the defensive tier when anybody does', () {
    final v = vitrineDe(
      _indice([
        _quem('barato', 130),
        _quem('caro', 8000),
        _quem('raro', 2200, usa: const [_armaDef80]),
      ]),
    )!;

    expect(v.raro?.name, 'raro');
  });

  test('no rare one is null, not a stand-in', () {
    // A market with nobody on the defensive tier must draw two cards, never
    // three with the third repeating somebody.
    final v = vitrineDe(_indice([_quem('barato', 130), _quem('caro', 8000)]))!;

    expect(v.raro, isNull);
  });

  test('a market where nobody carries the tier shows no vitrine at all', () {
    // Better nothing than a claim about a pair that does not exist.
    expect(
      vitrineDe(_indice([_quem('a', 40, usa: const [_armaFraca])])),
      isNull,
    );
  });

  test('one carrier alone is not a spread and draws nothing', () {
    // "Sixty times the price" needs two people. One would make the cheapest
    // and the dearest the same character, which is not an argument.
    expect(vitrineDe(_indice([_quem('sozinho', 500)])), isNull);
  });

  test('an empty market is silent', () {
    expect(vitrineDe(_indice(const [])), isNull);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/home/vitrine_test.dart`
Expected: FAIL — `vitrine.dart` does not exist.

- [ ] **Step 3: Write the implementation**

Create `lib/features/home/domain/vitrine.dart`. It must:

- build the 70-attack-level weapon query with `strongWeaponQuery(index)` from `features/search/domain/presets.dart` — **do not rebuild that query by hand**; it already exists, it asks by attribute rather than by item id, and a hand-built copy would drift from the chip that opens the same search
- run it with `runQuery`, which orders by cheapest first
- return `null` when fewer than **two** characters carry the tier
- take the first as `barato` and the last as `caro`
- for `raro`, run `weaponQuery(index, 'Nível de Defesa', 80)` and take the cheapest, or `null` where the query is null or empty

Return a record: `({MarketCharacter barato, MarketCharacter caro, MarketCharacter? raro})?`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/home/vitrine_test.dart && flutter test && flutter analyze`

- [ ] **Step 5: Commit**

```bash
dart format lib/ test/
git add lib/features/home/domain/vitrine.dart test/home/vitrine_test.dart
git commit -m "Quais tres personagens a Vitrine mostra

O mais barato e o mais caro com a MESMA arma de 70, mais o patamar defensivo
quando alguem o carrega. O mais barato do mercado contra o mais caro do mercado
seria outra afirmacao, e falsa: eles nao estariam carregando a mesma coisa.

A consulta vem de strongWeaponQuery e nao e reconstruida aqui. Ela pergunta por
atributo e nao por id de item, porque cada classe tem a sua arma -- e uma copia
feita a mao acabaria divergindo do chip que abre a mesma busca.

Menos de dois carregando o patamar nao desenha nada. Sessenta vezes o preco
precisa de duas pessoas; com uma, o mais barato e o mais caro sao a mesma, o que
nao e argumento."
```

---

### Task 4: A Vitrine

The three cards, and the `60×` between the first two.

**Files:**
- Create: `lib/features/home/ui/widgets/vitrine_view.dart`
- Test: `test/home/vitrine_view_test.dart`

**Interfaces:**
- Consumes: `vitrineDe` (Task 3), `MarketIndex`.
- Produces: `class VitrineView extends StatelessWidget` taking `required MarketIndex index`, `required bool wide`, and `required void Function(MarketCharacter) aoTocar`.

- [ ] **Step 1: Write the failing test**

Create `test/home/vitrine_view_test.dart`. Build an index the same way
`test/home/vitrine_test.dart` does — copy those helpers rather than importing
them, because a test helper shared between files is a test helper that gets
changed for one and breaks the other.

```dart
  testWidgets('it prints the spread between the two prices', (tester) async {
    // The whole argument in one number. 130 and 8000 is sixty-one times, and
    // the card rounds down to the honest whole: saying 61.5 would dress a
    // rough truth as a precise one.
    await _pump(tester, [
      _quem('barato', 130),
      _quem('caro', 8000),
    ]);

    expect(find.textContaining('60'), findsWidgets);
  });

  testWidgets('both prices are on screen', (tester) async {
    await _pump(tester, [_quem('barato', 130), _quem('caro', 8000)]);

    expect(find.textContaining('130'), findsOneWidget);
    expect(find.textContaining('8000'), findsOneWidget);
  });

  testWidgets('tapping a card hands back the character', (tester) async {
    MarketCharacter? tocado;
    await _pump(
      tester,
      [_quem('barato', 130), _quem('caro', 8000)],
      aoTocar: (c) => tocado = c,
    );

    await tester.tap(find.textContaining('130'));
    expect(tocado?.name, 'barato');
  });

  testWidgets('a market with no pair draws nothing at all', (tester) async {
    await _pump(tester, [_quem('sozinho', 500)]);

    expect(find.textContaining('mesma arma'), findsNothing);
  });
```

Write `_pump` to wrap `VitrineView` in a `MaterialApp`/`Scaffold` with a width
of 1200 and a height of 400, and reuse the character helpers from Task 3's
test file verbatim.

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/home/vitrine_view_test.dart`

- [ ] **Step 3: Write the implementation**

Create `lib/features/home/ui/widgets/vitrine_view.dart`:

- calls `vitrineDe(index)`; returns `const SizedBox.shrink()` when it answers `null`
- a heading `A mesma arma de 70` in `PWTheme.display`, and a sub-line naming how many carry it and the spread
- a `Row` of the two or three cards, with a narrow column between the first two holding a hairline above, the `60×` in `PWColors.magenta`, and a hairline below
- each card: the class art at the top with a gradient into `PWColors.painel`, a corner label (`O MAIS BARATO`, `O MAIS CARO`, `O MAIS RARO`), the nickname, `nv 105 · Classe`, the weapon line, and the price in `PWColors.accent`
- the whole card is tappable and calls `aoTocar(character)`
- **the spread is computed, never written down**: `caro.price ~/ barato.price`, printed as `${n}×`. A hardcoded `60×` would be a lie the day the market moves, which is every fifteen minutes.

Use `arteDaClasse(c.characterClass)` for each card's art, and draw nothing where
it answers `null`.

- [ ] **Step 4: Run the tests and commit**

```bash
flutter test && flutter analyze && dart format lib/ test/
git add lib/features/home/ui/widgets/vitrine_view.dart test/home/vitrine_view_test.dart
git commit -m "A Vitrine: tres pessoas de verdade, nao numeros soltos

O mais barato, o mais caro com a mesma arma, e o patamar defensivo. Lado a lado
eles SAO o argumento -- ninguem precisa que a frase explique.

O multiplo e calculado e nunca escrito: 60x fixo seria mentira no dia em que o
mercado se mexer, o que e a cada quinze minutos."
```

---

### Task 5: The header, with the grouped menu

**Files:**
- Create: `lib/features/home/ui/widgets/cabecalho.dart`
- Test: `test/home/cabecalho_test.dart`

**Interfaces:**
- Consumes: `tools`, `toolsDe`, `secoesDaHome` from `features/home/domain/tool.dart`.
- Produces: `class Cabecalho extends StatelessWidget` taking `required bool wide`.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the mark is small and the name is beside it', (tester) async {
    // The fan art is not discarded — it is moved to the size at which it
    // reads. At 200 px of dark red on dark violet it was the largest element
    // on the page and the least legible.
    await _pump(tester);

    final marca = tester.widget<Image>(find.byType(Image).first);
    expect((marca.image as AssetImage).assetName, contains('pw-mark'));
    expect(marca.height, lessThan(40));
    expect(find.text('PORTAL PW'), findsOneWidget);
  });

  testWidgets('the menu offers every tool that has a route', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    expect(find.text('Filtro do Marketplace'), findsOneWidget);
    expect(find.text('Títulos'), findsOneWidget);
  });

  testWidgets('it never offers a tool with no route', (tester) async {
    // `Tool.isReady` is the existing invariant. A menu entry that goes
    // nowhere is worse than an absent one.
    await _pump(tester);
    await tester.tap(find.text('Ferramentas'));
    await tester.pumpAndSettle();

    for (final tool in tools.where((t) => !t.isReady)) {
      expect(find.text(tool.name), findsNothing, reason: tool.name);
    }
  });
```

- [ ] **Step 2: Run it, then implement**

A `Row`: the mark at 26 px from `assets/images/pw-mark.webp`, `PORTAL PW` in
`PWTheme.display`, `1.8.7` muted, then on the right a `PopupMenuButton` per
section in `secoesDaHome`, offering `toolsDe(secao).where((t) => t.isReady)`.

On narrow, the menus collapse to a single overflow button — do not attempt a
drawer; `mobile_filter_test` records that one panel at a time is the rule here.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/ui/widgets/cabecalho.dart test/home/cabecalho_test.dart
git commit -m "O cabecalho, com o menu agrupado

Navegacao em toda pagina, e nao so na home: hoje quem esta no /runas nao chega
nos Titulos sem voltar. Isso e uma falha que ja existe e que ninguem tinha
apontado.

A marca entra a 26 px, que e o tamanho em que ela se le. A arte de fa nao foi
descartada -- foi movida para onde funciona."
```

---

### Task 6: The page, assembled

The last task. `HomeView` stops being a logo and a row of figures and becomes
the page the spec describes.

**Files:**
- Modify: `lib/features/home/ui/home_view.dart`
- Modify: `lib/features/home/ui/widgets/discord_strip.dart` (the label only)
- Test: `test/home/home_ordem_test.dart` (create)

**Interfaces:**
- Consumes: everything from Tasks 1–5.

- [ ] **Step 1: Write the failing test**

```dart
  testWidgets('the sections come in the order the spec fixed', (tester) async {
    // Two of these positions already cost an error and are recorded in
    // CLAUDE.md: the streamers sit below the tools and above the Discord, and
    // the news is closed. What changed on 30/09 is only that the news moved
    // below the tools — whoever arrives for the first time came for the tool,
    // not for a notice.
    await _pumpHome(tester);

    final ordem = [
      find.text('FERRAMENTAS'),
      find.text('NOVIDADES DO PORTAL'),
      find.text('AO VIVO NA TWITCH'),
      find.text('COMUNIDADE'),
    ].map((f) => tester.getTopLeft(f).dy).toList();

    expect(ordem, orderedEquals([...ordem]..sort()));
  });

  testWidgets('the Discord is no longer labelled advertising', (tester) async {
    await _pumpHome(tester);

    expect(find.text('PUBLICIDADE'), findsNothing);
    expect(find.text('COMUNIDADE'), findsOneWidget);
  });

  testWidgets('the guides are a line, not a section', (tester) async {
    // One card under a full section header with its own rule is more chrome
    // than content.
    await _pumpHome(tester);

    expect(find.text('GUIAS'), findsNothing);
    expect(find.text('GUIA'), findsOneWidget);
  });
```

- [ ] **Step 2: Assemble**

In `home_view.dart`, replace the logo image, headline, sub-line, search button
and `MarketPulse` with `Cabecalho`, `Cartaz` and `VitrineView`. Keep everything
below in this order: tools, the guide line, news, streamers, Discord, footer.

The Cartaz's class is picked once per page build from `classesComArte` — use
the index's `collectedAt` to choose, not `Random()`, so the same collection
shows the same face and a rebuild is not a slot machine.

**`first_fold_test` must keep passing.** It sends a wheel event 40 px from the
right edge and asserts the offset moved — the full-width scrollable with the
cap inside it is not negotiable.

**Delete `MarketPulse` only if nothing else uses it.** Check first; the spec
replaced its job with the Vitrine, but a widget deleted while still referenced
is a build failure the tests will not catch until they run.

- [ ] **Step 3: Everything, then look at it**

```bash
flutter test && flutter analyze && flutter build web
cd build/web && python3 -m http.server 9900
```

Report the first fold at 1440 and at 390: what leads, whether the art crops at
the face, and whether anything gold appears that is not a price or the search
button.

- [ ] **Step 4: Commit**

```bash
git add lib/features/home/ lib/features/home/ui/widgets/discord_strip.dart test/home/
git commit -m "A home montada: Cartaz, Vitrine, e a ordem nova

O Cartaz diz o que o site e em tres segundos e a Vitrine prova logo abaixo, com
gente do mercado de agora.

As novidades descem para depois das ferramentas. A razao registrada para elas
ficarem em cima era o painel ABERTO engolindo a dobra; fechada em 90 px essa
razao deixou de existir, e quem chega pela primeira vez veio pela ferramenta.

O Discord deixa de se chamar PUBLICIDADE. Nao e anuncio, e seu -- e sob aquele
rotulo o visitante aprende a nao ler."
```

---

## What this plan deliberately leaves out

- **The Registros frame** and **the Runes window** are the next two plans.
- **The tool cards keep their current look.** Porting them is a smaller job that belongs with whatever plan next touches that file.
- **Nothing about price history.** The Vitrine reads today's market; *barato para o que carrega* is its own spec and its own plan.

## After the last task

`CLAUDE.md` gains the entry the palette plan deliberately postponed: the front
page changed, and the reasons — the art as ground rather than decoration, gold
meaning price only, the news moving and why the old reason expired.
