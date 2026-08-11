# PW Market Filter

Filters the character marketplace of The Classic PW 1.8.7
(`marketplace.theclassic.games/pw187`) **by the attributes of the equipped
items** — the one thing the site itself cannot do. A local tool, for one user,
on one server.

Flutter web + Bloc + GetIt, fed by an offline index that a Dart CLI collects.

## Current state

| | Scope | Status |
|---|---|---|
| Collector | listing + detail parsers, pacing, resume, index writing | **Done** |
| Index | the JSON contract between collector and app | **Done** |
| Screen | criteria form, filtered cards, empty and stale states | **Done** |

The first full collection ran on 2026-08-09: 770 characters, no failures, 538
distinct items, 101 attributes, 1.0 MB of index. All fourteen slots are named.

What it confirmed, and what the product rests on: **every class has its own
weapon capping at exactly 70 attack level** — seventeen different names for the
same tier — and 139 of the 770 characters carry one, from 130 TCC (tmzin,
Tormentador) to 8000 (Gege, Espiritualista). Sixty times the price for the same
weapon tier is the gap this tool exists to show.

Open: results have no widget tests.

**Deferred on 2026-08-09, by the user's call: the character's sex.** It is on
the detail page (`Sexo / Masculino`) and nowhere else, so it costs a full
re-collection — about 28 minutes. Worth knowing before anyone tries a shortcut:
**it cannot be derived from the class.** Perfect World locks classes to a
gender and this server mostly follows, but sampling two characters of each of
the seventeen found **Bardo with both**, which is enough to kill the rule.
Andarilho, Arcano, Arqueiro, Bárbaro and Ceifador came back male; Atiradora,
Espiritualista and Feiticeira female.

When that re-collection happens, do it once and take everything the page offers
that is currently discarded — `require_level` per piece (60/80/100/105, which
would allow "level 105 gear"), `weapon_level`, and the sex — storing them raw in
the state file the way attribute occurrences already are. Two re-collections
were already paid on 2026-08-09 for exactly this reason.

**Read the spec before starting any feature:**
`docs/superpowers/specs/2026-08-09-filtro-por-itens-design.md`

The two real pages the whole parser rests on are already saved:
`test/fixtures/listing_pw187.html` (1.8 MB, 779 cards) and
`test/fixtures/detail_64112.html` (1.1 MB, the character Leandrim).

## Commands

| Command | Description |
|---------|-------------|
| `dart run tool/collect.dart` | Collects the market and writes `assets/market_index.json` (~40 min) |
| `dart run tool/collect.dart --resume` | Continues an interrupted collection |
| `dart run tool/collect.dart --rebuild` | Rewrites the index from the saved state — no network, seconds |
| `dart run tool/fetch_icons.dart` | Downloads class and item icons named by the index; skips what is already on disk |
| `dart run tool/build_fixture_index.dart` | Builds an index from the saved fixtures — no network, for working on the screen |
| `flutter run -d chrome` | Runs the app |
| `flutter test` | Runs every test |
| `flutter analyze` | Static analysis |
| `dart format lib/ test/ tool/` | Formats the code |

There is no codegen. DI is three registrations written by hand in
`core/di/injection.dart`; `injectable` and `freezed` would each add a
`build_runner` step to save a handful of lines.

## Architecture

Two programs, one repository, one file between them.

```
site  ──►  tool/collect.dart  ──►  assets/market_index.json  ──►  Flutter web app
           dart:io, ~40 min          the contract                 in memory, ms
```

The collector never knows what a filter is; the app never knows what HTML is.
The site changing touches only the collector.

```
lib/
├── core/
│   ├── di/          # GetIt + injectable
│   ├── result/      # Result<T>, AppFailure
│   └── theme/       # PWColors, PWTheme
├── market/          # the index model — the only thing both programs share
├── collector/       # listing_parser.dart, detail_parser.dart — pure Dart
└── features/search/
    ├── domain/      # Criterion, SearchQuery, the matcher
    └── ui/          # SearchView, SearchViewModel (Bloc), widgets/
tool/collect.dart    # dart:io: HTTP, pacing, resume, writing the file
```

MVVM: the ViewModel **is** the Bloc. There is no UseCases layer and none should
be introduced — at this size it only breeds one-line classes that forward calls.

`market/` depends on nothing. `collector/` depends on `market/`. `features/`
depends on `market/` and `core/`, never on `collector/`. Nothing depends on
`tool/`.

## Gotchas

Each of these already cost something — measured on the live site, not guessed.

- **The site blocks, and the block outlives the run.** Fifteen detail pages
  fetched sequentially took 30 s and all succeeded. Ninety-one pages with four
  concurrent workers got 31 through, failed 60, and left the IP refused
  (`Errno 61 Connection refused`) for **more than twenty minutes afterwards** —
  a single `curl` could not get through either. So: **one request at a time,
  ~3 s apart**, exponential backoff on error, and a long pause when
  `Connection refused` shows up, because that is the block's face and retrying
  through it only extends it. There is no fast mode to add later; a full pass
  is 779 pages and ~40 min, and that is the design.
- **Never write a test that hits the live site.** It fails for reasons that have
  nothing to do with the code, and it earns the block above. The fixtures in
  `test/fixtures/` are the site, as far as the suite is concerned.
- **The same trap catches the cards, and it caught them.** The inventory has a
  `cards` panel holding the whole collection — 35 on one character, 60 on
  another. `<h4>Cartas equipadas</h4>` holds the six that are worn, one per
  type (Destruidor, Batalha, Durabilidade, Alma Primordial, Vida Primordial,
  Longevidade). Only the six matter; a combo is those six belonging to one set.
- **A card's combo is not on the page, and the tooltip pretends otherwise.**
  Every S card prints `Seis Soberanos da Chama da Vela (6)`, including on a
  character wearing thirty-four distinct S cards — a six-card set cannot hold
  thirty-four, so the line identifies nothing. The item database has no card
  category either. `lib/market/card_combos.dart` is hand-written, and
  `test/combo_test.dart` pins every id in it against the collected market
  because an invented id yields a filter that matches nobody, and "nobody has
  this combo" is a believable answer.
- **Frequency finds combos; it cannot name them.** Of 146 distinct six-card
  sets in the market, two are worn by 48 and 455 characters and the other 144
  appear once or twice — those are assemblies, not sets. What *named* the big
  S one was the sellers: 17% of its wearers put NUEMA in the character's
  nickname against 0% of everyone else. When the data will not say, look at
  what people called things.
- **Card icons are not item icons, and `index.items` holds only equipment.**
  Cards share the icon host and the id space but live in `character.cards`.
  Fetching icons from `items` alone left every card blank with a 404 per card
  in the console — silent on screen, because `ItemIcon` falls back to an empty
  box.
- **Equipment lives in the page twice, and the richer copy is the wrong one.**
  The inventory panel's `<h4>Equipamento</h4>` section holds real JSON per item
  in a `data-item` attribute — and it is a trap. It carries **no slot number**,
  and it lists 31 items where 14 are worn, spares included. The paper doll
  (`ul.character-equip--list`) is the only place that says what is on the
  character, so `detail_parser.dart` reads it and ignores the JSON entirely.
- **Do not try to zip the tooltip onto the JSON addons. It does not line up.**
  It is the obvious idea — the JSON gives `{"id": 2974, "effect": 70}` with no
  name, the tooltip gives `➜ Nível de Ataque +70` with no id, and the first
  eight pairs match perfectly. Then it breaks: the weapon in the fixture has
  **14 JSON addons and 11 tooltip lines**, because the JSON also counts the
  refine bonus (`id 1745, effectBonus 12`) and each socket stone (`id 478`,
  twice) as addons, while the tooltip renders those elsewhere. The three extras
  sit at positions 8, 9 and 10 — in the middle — so the zip does not fail, it
  quietly renames every attribute after the eighth to its neighbour.

  The tooltip alone has everything: name and refine in the `<strong>` title,
  stones as the 16 px images, bonuses as `➜ Name +Value`. One source, no join.
  Attributes are therefore keyed by **name**, and that is deliberate.
- **The item name lies; the attribute does not.** Three weapons share the word
  *Dilacerador* and carry Attack Level 30, 40 and 70 — the 70 one sells for
  1000 TCC and the 40 ones for 90. That is the whole reason this project
  exists, and it is a warning against any feature that filters or groups by
  name.

  The cure in the UI is not to hide names but to **never show one without its
  number**: the weapon dropdown labels every entry `name · +70`, and spells out
  `+70 nível de ataque · 3 personagens` on a second line. Anything that lists
  items has to carry the attribute along, or it hands back the same confusion
  the tool was built to remove. Because of that, the terse label is what the
  closed field shows — the number is the one part that must never be the piece
  that gets ellipsized.
- **Every class has its own weapons, and its own best one among them.** There
  is no single "+70 weapon": there are seventeen, one per class. So an item
  dropdown that ignores the chosen class is wrong twice over — the entry you
  want is buried among sixteen you can never equip, and nothing stops you
  pairing Guerreiro with a Mago weapon, which returns zero results and explains
  nothing. `IndexFacets.itemsIn` takes a `characterClass` and its cache is
  keyed by slot **and** class; `SearchViewModel.setClass` drops any chosen item
  the new class never wears. Any future dropdown over items inherits both
  duties — and any prose that reasons from the *Dilacerador* alone is reasoning
  about one class out of seventeen.
- **An attribute the site cannot name is printed as its number.** The real page
  contains `➜ Atributo #3818 +13`. Do not invent a label and do not drop the
  row — carry `3818` through and show what the site shows.
- **`Movimento m/seg. +1036831949` is a float wearing an integer's clothes.**
  `1036831949` is `0x3DCCCCCD`, the 32-bit float `0.1`. The site prints the raw
  bits for that attribute, so a `≥` filter on it compares nonsense to nonsense.
  It is left as the site shows it; if it ever needs fixing, the fix is
  reinterpreting the bits, not clamping the number.
- **Rank is the stars in the item's name, and the site publishes it nowhere
  else.** No field in the HTML, none in the item JSON, and the word "Rank"
  appears exactly once on a whole character page — as flavour text on a bag
  item. The rule (no stars is rank 1, `★★★` is rank 4) came from the player,
  and `rankFromName` applies it. Checked across all 538 collected items: stars
  are always a prefix, never elsewhere, never more than three.

  Two dead ends worth not repeating: `weapon_level` in the item JSON is 17 for
  every common endgame weapon including one that gives **zero** attack level,
  so it is a crafting tier and not a quality rank; and `require_level` is
  60/80/100/105, which is not the scale either.

  Rank is **independent of attack level** — ★★★Dilacerador Raivoso gives 70 and
  ★★★Geada Tardia gives none, both rank 4 — so a rank filter is not an
  attack-level filter in disguise, and neither substitutes for the other.

  It needed no collection: the stars were already in the index, spelled
  differently. When a new attribute of an item is asked for, look for it in
  what is already stored before reaching for the crawler.
- **Icons come from two hosts, neither of which is the marketplace.** Class art
  is `theclassic.games/assets/img/pw_roles/occu_<occupation>.png` (100×100) and
  item art is
  `pwdatabase.theclassic.games/assets/img/vtheclassicpw187/<itemId>.png`
  (32×32). Both are named by numbers the index already holds, so
  `fetch_icons.dart` needs no crawling to know what to ask for, and it skips
  files already on disk — a re-run after a collection costs only what is new.
  `ItemIcon` and `ClassIcon` fall back to an empty box of the same size: an
  item that entered the market since the last fetch leaves a gap, never a
  broken layout.
- **The number must never be the part that gets ellipsized.** In a 340 px
  panel an item name eats the line, and the attack level is exactly what the
  name cannot be trusted to tell you. The closed item field lays out icon,
  name (ellipsizing) and the attack level pinned right — not one string. Same
  rule anywhere an item is named next to its number.
- **A collapsed filter section must show what it is hiding.** The slot groups
  start closed except the weapon, and the header carries a count of the slots
  being filtered inside. Without that count, a closed section can hold a
  condition in force with nothing on screen saying so, and the results look
  wrong for no visible reason.
- **A criterion may name no attribute, and that is the point.** "Any attribute
  above 70" mixes attack level with HP and means nothing, so the *minimum*
  needs an attribute. But "a rank 4 weapon at +11" is about the piece itself,
  and while every criterion was forced to name an attribute it could not be
  asked at all. `ItemCriterion.attributeId` is nullable for that reason.
- **The card and the filter must read one rule.** `bestMatchFor` in
  `matcher.dart` is what the results card calls to say *which* piece answered a
  criterion, and it shares `_satisfies` with the filter itself. The card
  originally reimplemented the test inline; a card naming an item the filter
  did not accept is worse than a card naming nothing.
- **Slots have no names in the HTML.** The paper doll gives
  `data-item-type="slot-10"` and nothing else — no `aria-label`, no title, no
  CSS rule naming it. `lib/market/slot_names.dart` names the seven that the
  data makes unambiguous; the rest fall back to `Slot N` plus the commonest
  item found there, which is derived from the index and therefore always right.
  Do not guess the missing ones from PW conventions — slot numbering here does
  not match the standard client's.
- **A `GridView` tile cannot size itself, so the card's height follows the
  criteria.** `mainAxisExtent` is one number for every tile. Fixed at the
  tallest case, a card with no matched items sits in three times its own height
  of empty space — which is exactly how it first shipped. See `_Grid`.
- **`TextFormField(initialValue:)` reads its argument once and then ignores
  it.** A field written that way keeps whatever was typed after "limpar tudo"
  empties the query, so the screen shows a filter that is no longer in force,
  with nothing to warn you. `NumberField` holds a controller and re-syncs only
  when the incoming value stops agreeing with the text — comparing parsed
  values, not strings, so typing `07` does not jump the caret.
- **Changing a criterion's slot can orphan its attribute.** The attribute list
  is rebuilt per slot, and a `DropdownButtonFormField` whose value is absent
  from its own items throws. `CriterionRow` falls back to the new slot's
  commonest attribute on the way through.
- **A repeated attribute reduces differently depending on which attribute it
  is, and the parser must not decide.** One item can list `HP +500`, `+150`,
  `+150` — one pool, 800 HP, so it totals. The same item can list
  `Nível de Ataque +70` and then `+1` — a principal and a minor roll, and the
  weapon is a **70**, not a 71. Summing there is not a rounding error: it sorts
  that weapon above every genuine 70 in the dropdown and labels it with a
  number no other copy has.

  So `ParsedItem.attributes` is a `Map<String, List<int>>` holding **every
  occurrence in tooltip order**, and `IndexBuilder.attributeRules` reduces —
  `principal` (the largest line) for Nível de Ataque, Defesa and Guarda,
  `total` for everything else, which is the safe default for an attribute
  nobody has classified yet.

  The reason the split matters is cost, not tidiness: the collector's state
  file keeps the occurrences, so changing a rule is
  `dart run tool/collect.dart --rebuild` — seconds, no network. Reducing inside
  the parser made the first correction cost a fresh crawl of all 771 pages,
  which is how this rule was learned.
- **The app is web, so `lib/` must never import `dart:io`.** The parsers are
  pure Dart precisely so the tests can call them and the app can share the
  model; every socket and file lives in `tool/`. A stray `dart:io` import in
  `lib/` does not fail `flutter test` — it fails only when you build for web,
  far from where the mistake was made.
- **The site's own item filter is a shell with nothing behind it, and it fails
  in the way that looks like success.** `/pw187/advanced_item_list` returns
  `[]` and `/pw187/item_filter` returns zero roleids — those are obvious. The
  trap is `/pw187/advanced_filter?item_ids=50206`, which answers **200 with a
  long list of roleids** and looks exactly like a working bulk item search.

  It is not. It **ignores the parameter**: measured on 2026-08-10, three
  different weapons each returned the identical set of **842** roleids, which
  is also what the endpoint returns with no filter at all — and 842 is more
  than the 770 the listing page had, so it is not even the live market. Believe
  the comparison, not the status code. `advanced_filter` does work for level,
  price and class.
- **There is no bulk source for equipment. One page per character is the
  method, and it is not for lack of looking.** Probed and 404: `api/characters`,
  `characters.json`, `export`, `api/marketplace/pw187`. No `robots.txt`, no
  sitemap. What makes this affordable is not a shortcut but never repeating
  work — the listing is one request for everybody, and the state file means a
  refresh fetches only role ids never seen.
- **The listing page is the cheap half.** One request returns all 779 cards,
  server-rendered, with `data-roleid`, `data-price`, `data-level`,
  `data-occupation`, name, class, cultivation and fame. Only the per-character
  gear needs the slow walk. Never re-fetch the listing per character.
- **Fetch `/pw187/details/<roleid>`, never `/details/pw187/<roleid>`.** The
  listing's own links use the second form and it answers **302**, redirecting
  to the first. Following it doubles the request count for the whole
  collection — and a rate limiter counts redirects, so the wasted half also
  buys you half the budget's worth of block risk. Copying the href off the page
  is the natural mistake; the canonical URL is the one to use.
- **The server gzips, and you have to ask.** A detail page is 1.13 MB plain and
  **116 KB** compressed, arriving in two thirds of the time. Dart's
  `HttpClient` sets `autoUncompress`, so the only thing needed is the
  `Accept-Encoding: gzip` header and the bytes stay transparent.
- **A refresh is not a collection.** What changes minute to minute is *who is
  on the list*, and the whole list — with price, level, class, fame and
  cultivation — arrives in one request. A character's gear does not change
  while he is on sale. So `--resume` against an existing state is the refresh:
  one listing request, detail pages only for role ids never seen, and
  `pruneTo` forgets whoever left. Forty minutes is the price of the first pass
  only; after that an update is seconds. Anything that re-fetches all 770 to
  pick up a handful of new listings is doing forty minutes of work for ten
  seconds of news.

  What this deliberately does not catch is a seller re-gearing a character that
  stays listed. If that turns out to matter, the fix is an age per entry and a
  slow re-check of the oldest — not a full crawl.
- **A loose assertion in the parser passes with the parser reading half the
  page.** `isNotEmpty` on the item list is green when 14 items come back as 1.
  Assert exact numbers against the fixture: 779 cards in the listing; 14
  equipped items on Leandrim; weapon `50206`, refine `12`, stones
  `[51112, 51112]`, addon `2974 = 70`.
- **Zero results is an answer, not an error.** "Nobody has a +70 weapon under
  500 TCC" is the most valuable thing this tool can say. It gets its own state
  and its own test, and it is never styled as a failure.
- **A stale index looks exactly like a fresh one.** Prices move; a perfect
  filter over last month's data is worse than no filter because it reads as
  correct. The collection date is always on screen, and past a week it is
  highlighted.
- **Repositories return `Result<T>`,** never throw. Failures are typed, never
  strings.
- **State is Bloc.** `setState` only for state that is purely visual and local
  to the widget.
- **No inline colors.** Every color lives in `PWColors` as a `static const`.
  The one exception is `Colors.transparent`, which is the absence of a color.
- **No new dependency without asking the user.**
- **The UI is Portuguese only** — the game data is Portuguese and there is one
  user. No ARB, no localization machinery. Comments, docstrings and test names
  are written in **English**, as is the conversation's output into the
  repository; the conversation with the user stays in Portuguese.

## Task Workflow

1. Read the spec before writing code
2. TDD on the parser and the filter — Red → Green → Refactor. The screen gets
   tests where they earn their keep, with no coverage target
3. `flutter analyze` has to end with `No issues found!`
