# A memória do mercado — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The index remembers when each character was first seen and how its price has moved, so the site can say *"baixou de 500 para 400"* instead of showing the same screen every day.

**Architecture:** Each run fetches the site's own published `market_index.json`, carries four derived fields forward per character, and writes them back. The published index is therefore its own durable record — no database, no new service, and **the browser never queries anything**, so cost per visitor stays zero. The Actions cache keeps the collector state as a second copy.

**Tech Stack:** Dart (`lib/market/`, `lib/collector/`, `tool/collect.dart`), Flutter web for the card, `flutter test`.

**Spec:** `docs/superpowers/specs/2026-09-30-memoria-do-mercado-design.md`

## Scope

The spec describes the foundation **and** three screen features. This plan
builds the foundation plus the one screen change that makes it visible — a
complete, shippable increment. Two features get their own plans afterwards,
because each is a separate testable deliverable:

- *barato para o que carrega* — price against the median of the same weapon tier
- *novo desde a sua última visita* — per-browser, on `BrowserMemory`

## Global Constraints

- **`lib/` must never import `dart:io`.** The app is web; every socket and file lives in `tool/`. A stray import fails only at web build time, far from the mistake.
- **Repositories return `Result<T>`, never throw.** Failures are typed.
- **No inline colours.** Every colour is a `static const` in `PWColors`.
- **No new dependency without asking the user.**
- **UI strings are Portuguese.** Comments, docstrings and test names are English.
- **Never write a test that hits the live site.** Fixtures are the site.
- **Numbers never use `PWTheme.display`** (Marcellus draws Roman figures: `150 TCC` reads `I5O TCC`).
- `flutter analyze` must end with `No issues found!` before every commit.

---

### Task 1: `PriceHistory` and the rule that advances it

The pure core. No I/O, no Flutter — a model and one function, fully tested
before anything else depends on them.

**Files:**
- Create: `lib/market/price_history.dart`
- Test: `test/price_history_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class PriceHistory` with `final DateTime firstSeen`, `final int? previousPrice`, `final int lowestPrice`, `final int cuts`; `Map<String, dynamic> toJson()`; `factory PriceHistory.fromJson(Map<String, dynamic>)`; and the top-level `PriceHistory avancar(PriceHistory? antes, {required int preco, required int? precoAnterior, required DateTime agora})`.

- [ ] **Step 1: Write the failing test**

Create `test/price_history_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/price_history.dart';

final _hoje = DateTime.utc(2026, 10, 1);
final _ontem = DateTime.utc(2026, 9, 30);

void main() {
  test('a character never seen before starts its record today', () {
    final h = avancar(null, preco: 500, precoAnterior: null, agora: _hoje);

    expect(h.firstSeen, _hoje);
    expect(h.previousPrice, isNull);
    expect(h.lowestPrice, 500);
    expect(h.cuts, 0);
  });

  test('a price that falls is a cut, and the old price is kept to show', () {
    // The whole point: the card says "baixou de 500 para 400", so the 500 has
    // to survive somewhere.
    final antes = PriceHistory(firstSeen: _ontem, lowestPrice: 500);
    final h = avancar(antes, preco: 400, precoAnterior: 500, agora: _hoje);

    expect(h.firstSeen, _ontem, reason: 'first seen never moves');
    expect(h.previousPrice, 500);
    expect(h.lowestPrice, 400);
    expect(h.cuts, 1);
  });

  test('a price that rises is not a cut, and the floor does not move', () {
    final antes = PriceHistory(firstSeen: _ontem, lowestPrice: 400, cuts: 1);
    final h = avancar(antes, preco: 900, precoAnterior: 400, agora: _hoje);

    expect(h.previousPrice, 400);
    expect(h.lowestPrice, 400, reason: 'the cheapest it ever was');
    expect(h.cuts, 1, reason: 'a rise is not a cut');
  });

  test('a price that did not move changes nothing at all', () {
    // Most prices never move. If standing still wrote a row, the index would
    // grow by 1519 entries every fifteen minutes.
    final antes = PriceHistory(
      firstSeen: _ontem,
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 1,
    );
    final h = avancar(antes, preco: 400, precoAnterior: 400, agora: _hoje);

    expect(h.previousPrice, 500, reason: 'still the price before the last move');
    expect(h.lowestPrice, 400);
    expect(h.cuts, 1);
  });

  test('down, up and down again is two cuts, not three', () {
    var h = avancar(null, preco: 500, precoAnterior: null, agora: _ontem);
    h = avancar(h, preco: 400, precoAnterior: 500, agora: _hoje);
    h = avancar(h, preco: 600, precoAnterior: 400, agora: _hoje);
    h = avancar(h, preco: 450, precoAnterior: 600, agora: _hoje);

    expect(h.cuts, 2);
    expect(h.lowestPrice, 400, reason: 'the floor is the floor, not the last');
    expect(h.previousPrice, 600);
  });

  test('a record survives the round trip', () {
    final h = PriceHistory(
      firstSeen: _ontem,
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 2,
    );
    final volta = PriceHistory.fromJson(h.toJson());

    expect(volta.firstSeen, h.firstSeen);
    expect(volta.previousPrice, h.previousPrice);
    expect(volta.lowestPrice, h.lowestPrice);
    expect(volta.cuts, h.cuts);
  });

  test('a record that never moved writes no previousPrice', () {
    // Keeps the index small: four fields is the ceiling, and most characters
    // carry two.
    final h = PriceHistory(firstSeen: _ontem, lowestPrice: 400);

    expect(h.toJson().containsKey('previousPrice'), isFalse);
    expect(h.toJson()['cuts'], isNull, reason: 'zero is the default, not a row');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/price_history_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'pw_market_filter/market/price_history.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/market/price_history.dart`:

```dart
/// What the market remembers about one character between collections.
///
/// Four numbers and nothing else, deliberately. A full price series per
/// character would grow the index without answering a question anybody asks:
/// the screen says *"baixou de 500 para 400, já cortou três vezes"*, and that
/// is four numbers.
class PriceHistory {
  const PriceHistory({
    required this.firstSeen,
    this.previousPrice,
    required this.lowestPrice,
    this.cuts = 0,
  });

  /// When this `roleId` was first met by a collection that was keeping
  /// records. **Never moves** — a character that leaves the market and comes
  /// back keeps the date, because forgetting it would call an old listing new.
  final DateTime firstSeen;

  /// What it asked immediately before the most recent change, or `null` while
  /// the price has never moved.
  ///
  /// The price *before the last move* rather than "yesterday's price": a
  /// character standing at 400 for a week should still be able to say it came
  /// down from 500.
  final int? previousPrice;

  /// The cheapest it has ever asked.
  final int lowestPrice;

  /// How many times the price has **fallen**. A rise is not a cut, which is
  /// why this is counted rather than derived from the two prices.
  final int cuts;

  Map<String, dynamic> toJson() => {
    'firstSeen': firstSeen.toUtc().toIso8601String(),
    if (previousPrice != null) 'previousPrice': previousPrice,
    'lowestPrice': lowestPrice,
    if (cuts > 0) 'cuts': cuts,
  };

  factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
    firstSeen: DateTime.parse(json['firstSeen'] as String).toUtc(),
    previousPrice: json['previousPrice'] as int?,
    lowestPrice: json['lowestPrice'] as int,
    cuts: json['cuts'] as int? ?? 0,
  );
}

/// Advances [antes] by one collection.
///
/// [precoAnterior] is what the character asked at the previous collection. It
/// lives on the character in the published index rather than in the record,
/// so it arrives as an argument — keeping it out of [PriceHistory] is what
/// stops the same number being written twice and drifting.
///
/// `antes == null` is a character this site has never recorded: the record
/// starts today, and **today is not the same as new** — see
/// `MarketIndex.historyFrom`, which is what lets the screen tell a first
/// sighting from a genuine arrival.
PriceHistory avancar(
  PriceHistory? antes, {
  required int preco,
  required int? precoAnterior,
  required DateTime agora,
}) {
  if (antes == null) {
    return PriceHistory(firstSeen: agora, lowestPrice: preco);
  }

  final menor = preco < antes.lowestPrice ? preco : antes.lowestPrice;

  // A price that did not move writes nothing. Most never do, and standing
  // still must not cost a row every fifteen minutes.
  if (precoAnterior == null || preco == precoAnterior) {
    return PriceHistory(
      firstSeen: antes.firstSeen,
      previousPrice: antes.previousPrice,
      lowestPrice: menor,
      cuts: antes.cuts,
    );
  }

  return PriceHistory(
    firstSeen: antes.firstSeen,
    previousPrice: precoAnterior,
    lowestPrice: menor,
    cuts: preco < precoAnterior ? antes.cuts + 1 : antes.cuts,
  );
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/price_history_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Analyze and commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/market/price_history.dart test/price_history_test.dart
git commit -m "O que o mercado lembra de um personagem entre coletas

Quatro numeros e mais nada: primeira vez visto, o preco antes da ultima
mudanca, o menor de todos e quantas vezes caiu. Uma serie completa por
personagem engordaria o indice sem responder pergunta que alguem faca -- a tela
diz \"baixou de 500 para 400, ja cortou tres vezes\", e isso sao quatro numeros.

Alta nao e corte, por isso cortes e contado e nao derivado dos dois precos. E
preco parado nao escreve nada: a maioria nunca se move, e ficar parado nao pode
custar uma linha a cada quinze minutos."
```

---

### Task 2: The index carries the record, and still opens an old one

`formatVersion` goes to 2. The reader must accept **1 as well**, because the
first run with this code fetches a published index written at version 1 — and
because the site has to open on whatever collection last landed.

**Files:**
- Modify: `lib/market/market_index.dart` — `MarketCharacter` gains `history`; `MarketIndex` gains `historyFrom`; `_formatVersion` 1 → 2; the version guard accepts both.
- Test: `test/market_index_history_test.dart` (create)

**Interfaces:**
- Consumes: `PriceHistory`, `avancar` from Task 1.
- Produces: `MarketCharacter.history` (`PriceHistory?`), `MarketIndex.historyFrom` (`DateTime?`).

- [ ] **Step 1: Write the failing test**

Create `test/market_index_history_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

MarketCharacter _quem({PriceHistory? history}) => MarketCharacter(
  roleId: 1,
  name: 'tmzin',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 400,
  fame: 0,
  cultivation: 'Leal',
  equipped: const [],
  history: history,
);

MarketIndex _indice({DateTime? historyFrom, PriceHistory? history}) =>
    MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 1),
      attributes: const [],
      items: const {},
      characters: [_quem(history: history)],
      historyFrom: historyFrom,
    );

void main() {
  test('a record survives the index round trip', () {
    final h = PriceHistory(
      firstSeen: DateTime.utc(2026, 9, 20),
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 2,
    );
    final volta = MarketIndex.fromJson(
      _indice(historyFrom: DateTime.utc(2026, 9, 30), history: h).toJson(),
    );

    expect(volta.historyFrom, DateTime.utc(2026, 9, 30));
    expect(volta.characters.single.history?.firstSeen, h.firstSeen);
    expect(volta.characters.single.history?.previousPrice, 500);
    expect(volta.characters.single.history?.cuts, 2);
  });

  test('an index written before the record reads as having none', () {
    // The first run with this code fetches a published index at version 1.
    // It must open with the fields empty rather than throw, and so must the
    // app: the site serves whatever collection last landed.
    final antigo = _indice().toJson();
    antigo['formatVersion'] = 1;
    antigo.remove('historyFrom');

    final volta = MarketIndex.fromJson(antigo);

    expect(volta.historyFrom, isNull);
    expect(volta.characters.single.history, isNull);
  });

  test('a version nobody wrote is still refused', () {
    final futuro = _indice().toJson();
    futuro['formatVersion'] = 99;

    expect(
      () => MarketIndex.fromJson(futuro),
      throwsA(isA<IndexFormatException>()),
    );
  });

  test('a character with no record writes no key', () {
    expect(_quem().toJson().containsKey('history'), isFalse);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/market_index_history_test.dart`
Expected: FAIL — `No named parameter with the name 'history'`

- [ ] **Step 3: Write the implementation**

In `lib/market/market_index.dart`:

Add the import at the top, beside the other `market/` imports:

```dart
import 'price_history.dart';
```

In `MarketCharacter`, add the constructor parameter (after `runes`), the field, the `toJson` line and the `fromJson` line:

```dart
    this.history,
```

```dart
  /// What the market remembers about this character between collections, or
  /// `null` where no collection has recorded it yet.
  final PriceHistory? history;
```

```dart
    if (history != null) 'history': history!.toJson(),
```

```dart
        history: json['history'] == null
            ? null
            : PriceHistory.fromJson(json['history'] as Map<String, dynamic>),
```

In `MarketIndex`, add the constructor parameter, the field, the `toJson` line and the `fromJson` line:

```dart
    this.historyFrom,
```

```dart
  /// The first collection that kept records, or `null` before any did.
  ///
  /// **This is what stops the site announcing 1519 arrivals on day one.** On
  /// the first run with history every character gets a `firstSeen` of today,
  /// which means *first sighting*, not *new listing*. Only a character whose
  /// `firstSeen` is after this date genuinely arrived while we were watching;
  /// the rest are unknown, and unknown is never dressed up as new.
  final DateTime? historyFrom;
```

```dart
    if (historyFrom != null)
      'historyFrom': historyFrom!.toUtc().toIso8601String(),
```

```dart
      historyFrom: json['historyFrom'] == null
          ? null
          : DateTime.parse(json['historyFrom'] as String).toUtc(),
```

Bump the version and widen the guard:

```dart
  static const _formatVersion = 2;

  /// Versions this build knows how to read. **Two, not one**, and the older
  /// is not politeness: the first run of the history code fetches an index
  /// published at version 1, and the app has to open on whatever collection
  /// last landed. A version nobody wrote is still refused, because that is a
  /// file we cannot reason about.
  static const _readableVersions = {1, 2};
```

Replace the guard inside `fromJson`:

```dart
    final version = json['formatVersion'];
    if (!_readableVersions.contains(version)) {
      throw IndexFormatException(
        'formatVersion',
        'esperava um de $_readableVersions, veio $version',
      );
    }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/market_index_history_test.dart && flutter test`
Expected: both PASS. The whole suite must stay green — `MarketCharacter` gained an optional parameter, so no existing call site changes.

- [ ] **Step 5: Analyze and commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/market/market_index.dart test/market_index_history_test.dart
git commit -m "O indice carrega o registro, e ainda abre um antigo

formatVersion vai para 2 e o leitor passa a aceitar 1 tambem. Nao e polidez: a
primeira execucao do codigo de historia busca um indice publicado na versao 1,
e o app tem que abrir sobre qualquer coleta que tenha caido por ultimo. Uma
versao que ninguem escreveu continua recusada.

historyFrom e o que impede o site de anunciar 1519 novidades no primeiro dia.
Com a historia estreando, todo personagem ganha firstSeen de hoje -- e isso
quer dizer primeira vez visto, nao anuncio novo."
```

---

### Task 3: The builder accepts a record and stamps the index

**Files:**
- Modify: `lib/collector/index_builder.dart` — `add` gains `history:`, `build` gains `historyFrom:`
- Test: `test/collector/index_builder_test.dart` (append)

**Interfaces:**
- Consumes: `PriceHistory` (Task 1), `MarketCharacter.history` and `MarketIndex.historyFrom` (Task 2).
- Produces: `IndexBuilder.add(..., PriceHistory? history)` and `IndexBuilder.build({DateTime? historyFrom})`.

- [ ] **Step 1: Write the failing test**

Append inside the existing top-level `main()` of `test/collector/index_builder_test.dart`, before its closing brace. Read the top of that file first and reuse its existing `ListingCard` helper; if it builds cards inline, build one the same way here.

```dart
  test('the builder carries a record onto the character it belongs to', () {
    final builder = IndexBuilder(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 1),
    );
    final h = PriceHistory(
      firstSeen: DateTime.utc(2026, 9, 20),
      previousPrice: 500,
      lowestPrice: 400,
      cuts: 1,
    );

    builder.add(
      const ListingCard(
        roleId: 7,
        name: 'tmzin',
        characterClass: 'Guerreiro',
        occupation: 1,
        level: 105,
        price: 400,
        fame: 0,
        cultivation: 'Leal',
      ),
      const [],
      history: h,
    );

    final index = builder.build(historyFrom: DateTime.utc(2026, 9, 30));

    expect(index.historyFrom, DateTime.utc(2026, 9, 30));
    expect(index.characters.single.history?.previousPrice, 500);
    expect(index.characters.single.history?.cuts, 1);
  });

  test('a build with no record stamps nothing', () {
    // A `--rebuild` from a state file written before any of this must not
    // claim a date it does not have.
    final builder = IndexBuilder(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 1),
    );

    expect(builder.build().historyFrom, isNull);
  });
```

Add the import at the top of the test file:

```dart
import 'package:pw_market_filter/market/price_history.dart';
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/collector/index_builder_test.dart`
Expected: FAIL — `No named parameter with the name 'history'`

- [ ] **Step 3: Write the implementation**

In `lib/collector/index_builder.dart`, add the import:

```dart
import '../market/price_history.dart';
```

Add the parameter to `add` (after `runes`):

```dart
    List<ParsedRune> runes = const [],
    PriceHistory? history,
```

Pass it into the `MarketCharacter(` it constructs, beside `runes:`:

```dart
        history: history,
```

Change the `build` signature and the `MarketIndex(` it returns:

```dart
  /// [historyFrom] is the date the site started keeping records, carried
  /// forward from the published index. `null` where nothing has been kept —
  /// a `--rebuild` from an old state file must not claim a date it never had.
  MarketIndex build({DateTime? historyFrom}) {
```

```dart
      historyFrom: historyFrom,
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/collector/ && flutter test`
Expected: both PASS.

- [ ] **Step 5: Analyze and commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/collector/index_builder.dart test/collector/index_builder_test.dart
git commit -m "O construtor aceita o registro e carimba o indice

add ganha history e build ganha historyFrom, os dois opcionais: um --rebuild a
partir de um arquivo de estado escrito antes disso nao pode reivindicar uma
data que nunca teve."
```

---

### Task 4: The collector reads the site's own index and carries the record forward

The task that makes it real. One extra HTTP request per run, to our own CDN.

**Files:**
- Create: `lib/collector/memoria.dart`
- Modify: `tool/collect.dart` — a fetch of the published index, and `_writeIndex` threading the record through
- Test: `test/collector/memoria_test.dart` (create) — tests the pure functions that merge, never the network

**Interfaces:**
- Consumes: everything from Tasks 1–3.
- Produces: `Map<int, PriceHistory> avancarTodos({required List<ListingCard> listing, required MarketIndex? publicado, required DateTime agora})` and `DateTime historyFromDe(MarketIndex? publicado, DateTime agora)`, both in **`lib/collector/memoria.dart`**.

**Why `collector/` and not `market/`:** these two need `ListingCard`, and
`CLAUDE.md` fixes the direction — *`market/` depends on nothing; `collector/`
depends on `market/`*. Putting them beside `PriceHistory` would invert that,
and the inversion compiles quietly. They stay in `lib/` rather than `tool/` so
they are testable; the socket stays in `tool/`.

- [ ] **Step 1: Write the failing test**

Create `test/collector/memoria_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/collector/memoria.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

final _hoje = DateTime.utc(2026, 10, 1);
final _ontem = DateTime.utc(2026, 9, 30);

ListingCard _card(int roleId, int price) => ListingCard(
  roleId: roleId,
  name: 'n$roleId',
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: price,
  fame: 0,
  cultivation: 'Leal',
);

MarketIndex _publicado(List<MarketCharacter> quem, {DateTime? desde}) =>
    MarketIndex(
      server: 'pw187',
      collectedAt: _ontem,
      attributes: const [],
      items: const {},
      characters: quem,
      historyFrom: desde,
    );

MarketCharacter _quem(int roleId, int price, {PriceHistory? history}) =>
    MarketCharacter(
      roleId: roleId,
      name: 'n$roleId',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: price,
      fame: 0,
      cultivation: 'Leal',
      equipped: const [],
      history: history,
    );

void main() {
  test('with no published index, everybody starts a record today', () {
    final r = avancarTodos(
      listing: [_card(1, 500), _card(2, 400)],
      publicado: null,
      agora: _hoje,
    );

    expect(r[1]!.firstSeen, _hoje);
    expect(r[2]!.lowestPrice, 400);
    expect(r[1]!.cuts, 0);
  });

  test('a price that fell since the published index is a cut', () {
    final publicado = _publicado([
      _quem(1, 500, history: PriceHistory(firstSeen: _ontem, lowestPrice: 500)),
    ], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(1, 400)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[1]!.previousPrice, 500);
    expect(r[1]!.lowestPrice, 400);
    expect(r[1]!.cuts, 1);
    expect(r[1]!.firstSeen, _ontem, reason: 'first seen never moves');
  });

  test('somebody who left and came back keeps their floor', () {
    // `pruneTo` forgets a departed character from the state file, but the
    // published index still holds them until the next publish. Losing the
    // floor would call an old listing new and reset what is known about it.
    final publicado = _publicado([
      _quem(
        9,
        800,
        history: PriceHistory(
          firstSeen: DateTime.utc(2026, 9, 1),
          lowestPrice: 300,
          cuts: 3,
        ),
      ),
    ], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(9, 800)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[9]!.firstSeen, DateTime.utc(2026, 9, 1));
    expect(r[9]!.lowestPrice, 300);
    expect(r[9]!.cuts, 3);
  });

  test('a character the published index never had starts fresh', () {
    final publicado = _publicado([_quem(1, 500)], desde: _ontem);

    final r = avancarTodos(
      listing: [_card(1, 500), _card(2, 120)],
      publicado: publicado,
      agora: _hoje,
    );

    expect(r[2]!.firstSeen, _hoje);
    expect(r[2]!.previousPrice, isNull);
  });

  test('the first run that keeps records is the date that is stamped', () {
    expect(historyFromDe(null, _hoje), _hoje);
    expect(historyFromDe(_publicado(const []), _hoje), _hoje);
  });

  test('a later run carries the original date forward, never today', () {
    // Restamping every run would make every character look like it arrived
    // before we were watching, for ever.
    final publicado = _publicado(const [], desde: DateTime.utc(2026, 9, 15));

    expect(historyFromDe(publicado, _hoje), DateTime.utc(2026, 9, 15));
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/collector/memoria_test.dart`
Expected: FAIL — `The function 'avancarTodos' isn't defined`

- [ ] **Step 3: Write the implementation**

Create `lib/collector/memoria.dart`:

```dart
import 'listing_parser.dart';
import '../market/market_index.dart';
import '../market/price_history.dart';
```

and then, in the same file:

```dart
/// The record for every character on the listing, carried forward from the
/// index the site is currently serving.
///
/// **The published index is the durable record**, which is why this reads a
/// `MarketIndex` rather than a state file: the Actions cache that holds the
/// collector's state is evicted after seven days unused, and a memory that
/// erases itself would have the site announce 1519 arrivals one random
/// morning. The cache stays as the second copy.
///
/// `precoAnterior` comes off the published character rather than out of
/// [PriceHistory], so the same number is never written twice.
Map<int, PriceHistory> avancarTodos({
  required List<ListingCard> listing,
  required MarketIndex? publicado,
  required DateTime agora,
}) {
  final antes = <int, MarketCharacter>{
    for (final c in publicado?.characters ?? const <MarketCharacter>[])
      c.roleId: c,
  };

  return {
    for (final card in listing)
      card.roleId: avancar(
        antes[card.roleId]?.history,
        preco: card.price,
        precoAnterior: antes[card.roleId]?.price,
        agora: agora,
      ),
  };
}

/// The date the site started keeping records.
///
/// Carried forward once set, and **never restamped**: writing today's date on
/// every run would put every character's `firstSeen` at or before it for ever,
/// and nothing would ever read as new.
DateTime historyFromDe(MarketIndex? publicado, DateTime agora) =>
    publicado?.historyFrom ?? agora;
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/collector/memoria_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Wire the collector**

In `tool/collect.dart`, add the fetch. Place it beside `_fetchListing`:

```dart
/// The index the site is currently serving, or `null` when it cannot be read.
///
/// **This is where the memory lives.** One request to our own CDN per run,
/// and the file is served `cf-cache-status: DYNAMIC` — Cloudflare does not
/// cache it at the edge — so what comes back is the real current file rather
/// than a ten-minute-old one. Measured 2026-09-30; if that ever changes, this
/// needs the `?t=<millis>` buster the app already uses.
///
/// A failure returns `null` and the run continues. Losing the record for one
/// collection costs a day of history; refusing to publish would cost the site.
/// The state file still holds the same fields as a second copy.
Future<MarketIndex?> _fetchPublishedIndex(HttpClient client) async {
  try {
    final request = await client.getUrl(
      Uri.parse('https://portalpw.net/market_index.json'),
    );
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    final response = await request.close();
    if (response.statusCode != 200) {
      stdout.writeln('Índice publicado respondeu ${response.statusCode}; '
          'esta coleta começa sem histórico.');
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    return MarketIndex.fromJson(jsonDecode(body) as Map<String, dynamic>);
  } catch (e) {
    stdout.writeln('Não deu para ler o índice publicado ($e); '
        'esta coleta começa sem histórico.');
    return null;
  }
}
```

Add the import at the top of `tool/collect.dart`:

```dart
import 'package:pw_market_filter/collector/memoria.dart';
```

Change `_writeIndex` to take the published index and thread the record
through. Its signature becomes:

```dart
void _writeIndex(
  List<ListingCard> listing,
  _CollectState state, {
  MarketIndex? publicado,
}) {
```

Immediately after the `IndexBuilder(` is constructed, add:

```dart
  final agora = DateTime.now().toUtc();
  final memoria = avancarTodos(
    listing: listing,
    publicado: publicado,
    agora: agora,
  );
```

Add `history: memoria[card.roleId],` to the `builder.add(` call, and change
the build line:

```dart
  final index = builder.build(historyFrom: historyFromDe(publicado, agora));
```

At both call sites of `_writeIndex`, pass the published index. In the main
collection path, fetch it once near where the listing is fetched:

```dart
  final publicado = await _fetchPublishedIndex(client);
```

and call `_writeIndex(listing, state, publicado: publicado);`.

**`--rebuild` passes nothing**, and that is deliberate: a rebuild has no
network by design, so it writes the index without history rather than
inventing one. Leave that call as `_writeIndex(listing, state);`.

- [ ] **Step 6: Verify the whole suite and the web build**

Run: `flutter analyze && flutter test && flutter build web`
Expected: `No issues found!`, all tests pass, `✓ Built build/web`.

The web build is the check that matters here: nothing under `lib/` may pull
`dart:io` in, and a stray import fails only at web build time — far from where
the mistake was made.

- [ ] **Step 7: Commit**

```bash
dart format lib/ test/ tool/
git add lib/collector/memoria.dart tool/collect.dart test/collector/memoria_test.dart
git commit -m "O coletor le o proprio indice publicado e carrega a historia

Uma requisicao a mais por execucao, ao nosso proprio CDN. O indice publicado e
o registro duravel, e nao o arquivo de estado: o cache do Actions e despejado
apos sete dias sem uso, e uma memoria que se apaga sozinha faria o site
anunciar 1519 novidades numa manha qualquer. O cache fica como segunda copia.

O arquivo e servido cf-cache-status DYNAMIC, entao o que volta e o arquivo real
e nao um de dez minutos atras. Se isso mudar, precisa do ?t= que o app ja usa.

Falha ao ler devolve null e a execucao segue: perder o registro de uma coleta
custa um dia de historia, recusar publicar custaria o site.

--rebuild nao passa indice nenhum, de proposito: ele nao tem rede por desenho,
entao escreve sem historia em vez de inventar uma."
```

---

### Task 5: The card says the price came down

The payoff. Without it the four previous tasks ship invisible plumbing.

**Files:**
- Modify: `lib/features/search/ui/widgets/character_card.dart` — a line under the price
- Test: `test/search/character_card_test.dart` (append)

**Interfaces:**
- Consumes: `MarketCharacter.history` (Task 2).
- Produces: nothing other tasks depend on.

- [ ] **Step 1: Give the test's character a record**

`test/search/character_card_test.dart` already has a `_character({...})`
helper and a `_pump(tester, character)`. Add one parameter to the helper —
read it first to confirm the shape, then add `PriceHistory? history` to its
named parameters and `history: history,` to the `MarketCharacter(` it builds.

Add the import to that file:

```dart
import 'package:pw_market_filter/market/price_history.dart';
```

- [ ] **Step 2: Write the failing test**

Append inside the existing `main()`:

```dart
  testWidgets('a price that came down says so', (tester) async {
    // The whole reason the history exists. A card that fell from 1200 to 1000
    // must not look like one that always asked 1000.
    await _pump(
      tester,
      _character(
        history: PriceHistory(
          firstSeen: DateTime.utc(2026, 9, 20),
          previousPrice: 1200,
          lowestPrice: 1000,
          cuts: 1,
        ),
      ),
    );

    expect(find.text('1200'), findsOneWidget);
  });

  testWidgets('a price that never moved says nothing', (tester) async {
    // Silence is the default: a line on every card would be noise on the
    // forty that never moved.
    await _pump(
      tester,
      _character(
        history: PriceHistory(
          firstSeen: DateTime.utc(2026, 9, 20),
          lowestPrice: 1000,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('queda')), findsNothing);
  });

  testWidgets('a character with no record says nothing', (tester) async {
    // An index collected before any of this must not grow a line.
    await _pump(tester, _character());

    expect(find.byKey(const ValueKey('queda')), findsNothing);
  });
```

Note the helper builds its character at `price: 1000`, which is why the old
price above is 1200 rather than 500.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/search/character_card_test.dart`
Expected: FAIL on the first test — the card draws no `500`.

- [ ] **Step 3: Write the implementation**

In `lib/features/search/ui/widgets/character_card.dart`, add the import:

```dart
import '../../../../market/price_history.dart';
```

Add this widget at the bottom of the file:

```dart
/// What the price used to be, under what it is now.
///
/// **Only when it fell, and only when it actually moved.** A line on every
/// card would be noise on the forty that never moved, and a rise is not news
/// a buyer can use — the question this site exists to answer is where the
/// cheap ones are.
///
/// The old price is struck through rather than labelled: *de 500* needs a
/// word, and the strike is the word every shop already uses.
class _Queda extends StatelessWidget {
  const _Queda({required this.history});

  final PriceHistory history;

  @override
  Widget build(BuildContext context) {
    final antes = history.previousPrice;
    if (antes == null) return const SizedBox.shrink();

    return Text(
      '$antes',
      key: const ValueKey('queda'),
      style: const TextStyle(
        color: PWColors.textMuted,
        fontSize: 11,
        decoration: TextDecoration.lineThrough,
      ),
    );
  }
}
```

Render it beside the price. Find where the card draws the price and add,
directly under it:

```dart
if (character.history != null) _Queda(history: character.history!),
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/search/character_card_test.dart && flutter test`
Expected: both PASS.

- [ ] **Step 5: Look at it before believing it**

```bash
flutter build web
cd build/web && python3 -m http.server 9401
```

Open `http://localhost:9401/#/filtro` — **on a port never used before**, which
is the house rule for judging a rebuilt bundle. The index on disk has no
history yet, so **no card should show a struck-through price**. That is the
check: the line must be absent rather than showing `null` or `0`.

Judge the layout on the published site, never on `localhost` — this machine
renders local pages shifted right, and it is environmental.

- [ ] **Step 6: Commit**

```bash
dart format lib/ test/
flutter analyze
git add lib/features/search/ui/widgets/character_card.dart test/search/character_card_test.dart
git commit -m "O card diz que o preco caiu

So quando caiu, e so quando se moveu mesmo: uma linha em todo card seria ruido
nos quarenta que nunca se mexeram, e alta nao e noticia que o comprador use --
a pergunta que este site existe para responder e onde estao os baratos.

O preco antigo vai riscado em vez de rotulado: 'de 500' precisa de uma palavra,
e o risco e a palavra que toda loja ja usa."
```

---

## What this plan deliberately does not build

Recorded so nobody adds them here and so the next plan knows where to start:

- **"Barato para o que carrega"** — price against the median of the same weapon tier. Its own plan: it needs a median per tier computed at build time and a second line on the card, and it is the feature that beats the competitor rather than matching them.
- **"Novo desde a sua última visita"** — per-browser marking on `BrowserMemory`. Its own plan.
- **Tombstones for departures.** `pruneTo` still deletes, so *saiu do mercado em 24/09* is unanswerable. It needs a ring of recently-departed roleIds and a decision about how long to keep them.
- **Anything about "vendido".** The site sees that a listing left, not why. Claiming a sale would be inventing, and zero results being an honest answer is a rule here.
- **Re-gearing on a standing listing.** The detail page is only fetched for roleIds never seen, so a seller swapping a weapon passes unnoticed. Already recorded in `CLAUDE.md`; the fix is an age per entry and a slow re-check of the oldest.

## After the last task

Update `CLAUDE.md`: the market having no memory is listed as the open gap that
earns a second visit, and after this it is half closed — the price moves, the
arrivals do not yet.
