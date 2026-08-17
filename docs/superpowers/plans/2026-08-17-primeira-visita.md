# Primeira visita — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Portal's two doors — the home and `/filtro` — work for someone who has never seen the site: understand it, use it once, and be able to share the finding.

**Architecture:** Screens only. No new field in the index, no new collection, no
server. A search becomes a value that can be written to the address bar and read
back from it; the same value, named, becomes both the home's clickable figures
and the filter's preset chips — one definition, two entrances.

**Tech Stack:** Flutter web, Bloc (the ViewModel is the Bloc), GetIt, `package:web`
for the address bar behind the same conditional-import split `VisitMemory` uses.

## Global Constraints

- **Spec:** `docs/superpowers/specs/2026-08-17-primeira-visita-design.md`. Read it first.
- **UI text is Portuguese. Code, comments, docstrings and test names are English.**
- **No inline colours.** Every colour is a `static const` on `PWColors`; only `Colors.transparent` is exempt.
- **No new package** without asking. The font ships as a file in `assets/fonts/`, not via `google_fonts`.
- **`lib/` must never import `dart:io`.** Browser APIs go behind a `_stub`/`_web` conditional import.
- **Repositories return `Result<T>`**, never throw.
- **`flutter analyze` must end with `No issues found!`** before any commit.
- **Presets are written by attribute, never by item id** — an item belongs to one class.
- Say what the visitor gains, never what the official marketplace lacks.

---

### Task 1: The search as a URL (pure codec)

**Files:**
- Create: `lib/features/search/domain/search_query_url.dart`
- Test: `test/search_query_url_test.dart`

**Interfaces:**
- Produces: `String encodeQuery(SearchQuery)` returning the query string without a
  leading `?` (empty string for an empty query in default order), and
  `SearchQuery decodeQuery(Map<String, List<String>> params)`.

Parameter names, all optional:

| Param | Shape | Example |
|---|---|---|
| `classe` | string | `classe=Mago` |
| `cultivo` | string | `cultivo=Alma+Nascente` |
| `nivel` | `min-max`, either side may be empty | `nivel=100-105`, `nivel=-105` |
| `preco` | `min-max` | `preco=40-500` |
| `item` | repeated `slot:itemId` | `item=10:50206` |
| `carta` | combo name | `carta=nuema` |
| `raridade` | string | `raridade=S` |
| `maximas` | `1` | `maximas=1` |
| `c` | repeated `slot:attrId:min:refine:rank`, `slot`/`attrId` may be empty | `c=10:3:70:10:0` |
| `ordem` | `ResultOrder.name` | `ordem=cheapest` |

- [ ] **Step 1: Write the failing round-trip test**

```dart
void main() {
  test('an empty query encodes to nothing', () {
    expect(encodeQuery(const SearchQuery()), '');
  });

  test('every dimension survives a round trip', () {
    const query = SearchQuery(
      characterClass: 'Mago',
      cultivation: 'Alma Nascente',
      minLevel: 100,
      maxLevel: 105,
      minPrice: 40,
      maxPrice: 500,
      itemBySlot: {10: 50206},
      comboName: 'nuema',
      cardRarity: 'S',
      cardsMaxed: true,
      criteria: [ItemCriterion(slot: 10, attributeId: 3, minimum: 70, minimumRefine: 10, minimumRank: 4)],
      order: ResultOrder.dearest,
    );

    final back = decodeQuery(Uri.parse('?${encodeQuery(query)}').queryParametersAll);

    expect(back.characterClass, 'Mago');
    expect(back.cultivation, 'Alma Nascente');
    expect(back.minLevel, 100);
    expect(back.maxLevel, 105);
    expect(back.minPrice, 40);
    expect(back.maxPrice, 500);
    expect(back.itemBySlot, {10: 50206});
    expect(back.comboName, 'nuema');
    expect(back.cardRarity, 'S');
    expect(back.cardsMaxed, isTrue);
    expect(back.order, ResultOrder.dearest);
    expect(back.criteria.single.slot, 10);
    expect(back.criteria.single.attributeId, 3);
    expect(back.criteria.single.minimum, 70);
    expect(back.criteria.single.minimumRefine, 10);
    expect(back.criteria.single.minimumRank, 4);
  });

  test('a half-open range survives', () {
    const query = SearchQuery(maxPrice: 500);
    final back = decodeQuery(Uri.parse('?${encodeQuery(query)}').queryParametersAll);
    expect(back.minPrice, isNull);
    expect(back.maxPrice, 500);
  });

  test('garbage is ignored, never thrown', () {
    final back = decodeQuery(Uri.parse('?preco=abc&c=x:y&desconhecido=1&nivel=').queryParametersAll);
    expect(back.isEmpty, isTrue);
    expect(back.order, ResultOrder.cheapest);
  });
}
```

- [ ] **Step 2: Run it and watch it fail**

Run: `flutter test test/search_query_url_test.dart`
Expected: FAIL — `encodeQuery` is not defined.

- [ ] **Step 3: Write the codec**

Pure functions, no Flutter import. A criterion that asks nothing is not encoded.
Decoding never throws: `int.tryParse` everywhere, unknown params ignored, a
malformed `c=` entry dropped rather than partially read.

- [ ] **Step 4: Run the tests, expect PASS, then `flutter analyze`**

- [ ] **Step 5: Commit** — `A busca vira texto, e volta`

---

### Task 2: The address bar

**Files:**
- Create: `lib/features/search/data/address_bar.dart`, `address_bar_stub.dart`, `address_bar_web.dart`
- Modify: `lib/main.dart` (route parsing), `lib/features/search/ui/search_view_model.dart`
- Test: `test/address_bar_test.dart`

**Interfaces:**
- Consumes: `encodeQuery` / `decodeQuery` from Task 1.
- Produces: `abstract class AddressBar { String? read(); void write(String queryString); factory AddressBar.platform() = platform.PlatformAddressBar; }`
  and on the view model: `void applyQuery(SearchQuery query)` plus a
  `SearchQuery? initial` read once in `load()`.

Two things must be right, and both are easy to get wrong:

1. `onGenerateRoute` switches on `settings.name`, which arrives as
   `/filtro?classe=Mago` once a query is present and would fall through to the
   home. Parse it: `Uri.parse(settings.name ?? '/').path`.
2. Writing must **replace** the history entry, not push one, or typing a price
   fills the back button with thirty states. `web.window.history.replaceState`.

- [ ] **Step 1: Write the failing test** — a fake `AddressBar` records writes; the
  view model, loaded with an index and an initial `?classe=Mago`, emits a
  `SearchReady` whose query carries the class, and a later `setPriceRange(40, 500)`
  writes a string containing `preco=40-500`.
- [ ] **Step 2: Run it and watch it fail**
- [ ] **Step 3: Implement** the shim, the route fix and the view-model wiring.
  The stub keeps a field, exactly like `PlatformVisitMemory`.
- [ ] **Step 4: `flutter test && flutter analyze`**
- [ ] **Step 5: Commit** — `A busca na barra de endereço`

---

### Task 3: Presets

**Files:**
- Create: `lib/features/search/domain/presets.dart`
- Test: `test/presets_test.dart`

**Interfaces:**
- Produces: `class Preset { final String label; final SearchQuery query; }` and
  `const presets = <Preset>[…]`, plus `Preset? activePreset(SearchQuery)` used to
  highlight a chip.

The five, all by attribute:

| Label | Query |
|---|---|
| `Arma de 70 até 500 TCC` | criterion slot 10, Nível de Ataque ≥ 70; `maxPrice: 500` |
| `Portal de Nuema` | `comboName: 'nuema'` |
| `Refino +10` | criterion slot 10, `minimumRefine: 10` |
| `Rank 4 na arma` | criterion slot 10, `minimumRank: 4` |
| `Até 200 TCC` | `maxPrice: 200` |

`attributeId` is an index into `MarketIndex.attributes` and therefore is **not a
constant** — it is resolved from the index at build time, the way `MarketPulse`
already does `index.attributes.indexOf('Nível de Ataque')`. So the list is a
function of the index: `List<Preset> presetsFor(MarketIndex index)`.

- [ ] **Step 1: Write the failing test** — load `assets/market_index.json`, and for
  every preset assert `runQuery(index, preset.query)` is not empty. A preset
  matching nobody is a filter that looks like it works.
- [ ] **Step 2: Run it and watch it fail**
- [ ] **Step 3: Implement `presetsFor`**
- [ ] **Step 4: `flutter test && flutter analyze`**
- [ ] **Step 5: Commit** — `Cinco perguntas prontas`

---

### Task 4: The first fold

**Files:**
- Modify: `lib/features/home/ui/home_view.dart`, `lib/features/home/ui/widgets/market_pulse.dart`
- Test: `test/home_first_fold_test.dart`

- Logo to 260/210/170 (large/wide/narrow).
- Headline `Ache o personagem certo pelo que ele está usando`, then
  `Filtre os personagens à venda por arma, cartas, refino e atributos.`
- A filled `PWColors.accent` button, `Buscar personagens`, pushing `/filtro`.
- Every `_Stat` becomes tappable, applying its query and pushing `/filtro`.
  On narrow the four sit 2×2.
- `MarketPulse` keeps reserving its height while the index loads, so the button
  below does not jump when the figures arrive.

- [ ] **Step 1: Write the failing widget test** — with a stub index, the four
  figures render, and tapping `306` leaves the view model holding a query whose
  single criterion asks Nível de Ataque ≥ 70.
- [ ] **Step 2: Run it and watch it fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: `flutter test && flutter analyze`**
- [ ] **Step 5: Commit** — `A primeira dobra diz o que o site faz`

---

### Task 5: Preset chips, and the disclaimer moves

**Files:**
- Modify: `lib/features/search/ui/search_view.dart`
- Create: `lib/features/search/ui/widgets/preset_chips.dart`

- A horizontally scrollable row under the header, at every width.
- Tapping a chip **replaces** the query; the active chip is highlighted; tapping
  it again clears. `activePreset` decides the highlight.
- `_Disclaimer` moves from above the results to below them, wording unchanged.

- [ ] **Step 1: Write the failing widget test** — tapping `Portal de Nuema` leaves
  the view model's query carrying `comboName: 'nuema'`, and tapping it again
  leaves an empty query.
- [ ] **Step 2: Run it and watch it fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: `flutter test && flutter analyze`**
- [ ] **Step 5: Commit** — `Buscas prontas, e o aviso sai do topo`

---

### Task 6: The filter on a phone

**Files:**
- Modify: `lib/features/search/ui/search_view.dart`
- Create: `lib/features/search/ui/widgets/filter_bar.dart`

- Under the app bar at narrow widths: `Filtros · N` (N = active criteria count)
  and the order picker, both labelled. The unlabelled `IconButton` pair goes.
- Tapping `Filtros` opens a `DraggableScrollableSheet`-backed bottom sheet hosting
  the existing `FilterPanel` unchanged, with a pinned footer button reading
  `Ver N personagens`, live.
- Removable chips naming the active criteria, below the bar.
- The `Drawer` goes away at narrow widths; the wide side panel is untouched.

- [ ] **Step 1: Write the failing widget test** — at 390 px the text `Filtros` is
  on screen; tapping it shows the panel; the footer's count equals the number of
  result cards after a criterion is applied.
- [ ] **Step 2: Run it and watch it fail**
- [ ] **Step 3: Implement**
- [ ] **Step 4: `flutter test && flutter analyze`**
- [ ] **Step 5: Commit** — `O filtro aparece no celular`

---

### Task 7: The link preview

**Files:**
- Create: `web/og.png` (1200×630, < 300 KB, PNG)
- Modify: `web/index.html`, `web/guias/index.html`, `web/guias/inicio-rapido.html`

Composition A, approved during the design: the Espiritualista art bleeding off the
right, the logo, the headline, and the row `arma · cartas · refino · atributos`.
Nothing that must be read may sit in the outer thirds — several clients crop to a
square. The source HTML used to render it lives in the scratchpad; keep the final
PNG only.

Tags on `web/index.html`:

```html
<meta property="og:type" content="website">
<meta property="og:site_name" content="Portal PW">
<meta property="og:title" content="Portal PW — filtro do marketplace">
<meta property="og:description" content="Ache o personagem certo pelo que ele está usando: filtre os personagens à venda do The Classic PW 1.8.7 por arma, cartas, refino e atributos.">
<meta property="og:url" content="https://portalpw.net/">
<meta property="og:image" content="https://portalpw.net/og.png">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta name="twitter:card" content="summary_large_image">
```

The guides get the same shape with their own title, description and `og:url`.

- [ ] **Step 1: Render the PNG and check its weight** — `ls -l web/og.png` under 300 KB
- [ ] **Step 2: Add the tags**
- [ ] **Step 3: Verify the built output carries them** — `flutter build web` then
  `grep og: build/web/index.html`
- [ ] **Step 4: Commit** — `Preview do link no Discord e no WhatsApp`

Note for whoever changes the art later: preview scrapers and Cloudflare cache it
hard. Ship a **new filename**, never an overwrite.

---

### Task 8: One display face

**Files:**
- Create: `assets/fonts/Marcellus-Regular.ttf`
- Modify: `pubspec.yaml`, `lib/core/theme/pw_theme.dart`, the headline and card titles

- Marcellus (OFL), one weight, bundled — no `google_fonts`, which would add a
  dependency and fetch from a CDN at runtime.
- Headlines only: the home's headline and card titles. Body text, every figure and
  the whole filter stay on Roboto, whose density in the result cards is correct.
- Check accented capitals (Ê, Á, Ó) render before adopting it.

- [ ] **Step 1: Fetch the file and declare it in `pubspec.yaml`**
- [ ] **Step 2: Add `displayLarge`/`titleLarge` to `PWTheme` using it**
- [ ] **Step 3: Point the home's headline and `ToolCard`'s title at it**
- [ ] **Step 4: `flutter test && flutter analyze`, then look at an accented capital**
- [ ] **Step 5: Commit** — `Uma fonte de display nos títulos`

---

## Verification

- `flutter test` — every suite, including the three new ones.
- `flutter analyze` — must end `No issues found!`.
- `flutter build web` — the one build that catches a stray `dart:io` in `lib/`.
- Then **judge it on the published site, never on `localhost`**, where this machine
  shifts every page right. Check `/#/filtro?preco=-500` opens filtered, paste the
  root URL into Discord and see the card, and open the filter on a real phone.
