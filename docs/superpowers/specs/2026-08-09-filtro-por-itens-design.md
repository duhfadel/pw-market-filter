# PW Market Filter — filtering the marketplace by item attributes

**Date:** 2026-08-09
**Status:** approved

## The problem

`marketplace.theclassic.games/pw187` lists 779 characters for sale on The
Classic PW 1.8.7. It lets you filter by class and by a coarse price bracket,
and by nothing else. What actually decides whether a character is worth buying
is the gear — and to see the gear you have to open all 779 pages by hand.

The gap is sharper than "there is no item filter". Item names actively mislead.
In a sample of 31 warriors, three different weapons share the word
*Dilacerador* and carry three different values of the attribute that matters:

| weapon | item id | Attack Level | seen | price range |
|---|---|---|---|---|
| ★★★Dilacerador Raivoso | 50206 | **70** | 1× | 1000 TCC |
| ★★★Dilacerador do Vento | 50205 | 40 | 10× | 90–500 TCC |
| ★★★Presas Laminais | 50145 | 40 | 5× | 100–250 TCC |
| ★★Dilacerador Gelado | 50204 | 30 | 5× | 45–150 TCC |
| ★★Presas de Navalha | 50144 | 30 | 1× | 40 TCC |
| ★★Geada Tardia / ★★Poeira Mundana | 50143 / 50203 | 0 | 9× | 40–50 TCC |

In that sample the attribute tracks the **item id**, not the individual
instance — it is a property of which weapon it is, not a roll. The sample is 31
of 779 and covers one class, so this is a working assumption, not a proven
fact; the full index will settle it. Either way the conclusion for the product
is the same: **the useful filter is on the attribute, not on the name.**

## What the site already has, and why it does not help

The listing page ships a hidden advanced search with four endpoints:

| endpoint | behavior on pw187 |
|---|---|
| `/pw187/advanced_filter?level_min=&price_max=&class_ids=…` | works, returns `roleids` |
| `/pw187/advanced_filter?item_ids=…` | accepts the parameter |
| `/pw187/advanced_item_list` | returns `[]` — **the item catalog is empty** |
| `/pw187/item_filter` | returns `{"success":true,"roleids":[]}` |
| `/pw187/refine_filter` | returns `{"success":true,"roleids":[]}` |

The shell exists; nothing was ever loaded behind it. There is no server-side
item index to reuse. We build our own.

## Where the data is

Both pages are fully server-rendered. Nothing needs a browser.

**Listing** — `GET /pw187`, 1.8 MB, all 779 cards in one response. Each card:

```html
<li class="character-card" data-occupation="11" data-price="80"
    data-level="101" data-roleid="354080">
  … <dd class="item-name">StormPower</dd> <dd class="item-type">Tormentador</dd>
    <dd>Leal</dd> <dd class="power">204237</dd>
```

**Detail** — `GET /details/pw187/<roleid>`, ~1.1 MB. Equipment appears **twice**,
and the difference matters:

- `<ul class="character-equip--list">` — the paper-doll. Carries only
  `data-pw187-tooltip`, human-readable text.
- `<h4 class="pw187-detail-section-title">Equipamento</h4>` inside the
  inventory panel — carries the real thing, one JSON object per item in a
  single-quoted, HTML-escaped `data-item` attribute:

```json
{ "id": 50206, "item_name": "★★★Dilacerador Raivoso", "refine_level": 12,
  "decoded": { "slots": { "slotStones": [51112, 51112] },
               "addons": { "count": 14, "addons": [
                 { "id": 2275, "effect": 1168 },
                 { "id": 2974, "effect": 70 }, … ] } } }
```

**The JSON is not the source, and finding out why changed the parser.** Two
problems, both discovered by testing against the fixture:

1. The `Equipamento` section carries **no slot number**, and it lists 31 items
   against the 14 that are worn — spares included. Only the paper doll says
   what is on the character.
2. Addon ids have no names, and the tooltip's `➜ Name +Value` lines cannot be
   zipped onto them. The weapon has **14 JSON addons and 11 tooltip lines**:
   the JSON also counts the refine bonus (`id 1745, effectBonus 12`) and the
   two socket stones (`id 478` twice), which the tooltip renders elsewhere. The
   extras sit at positions 8–10, in the middle — so a positional zip silently
   misnames every attribute after the eighth.

So the parser reads **the paper doll's tooltip and nothing else**. It carries
everything needed: the item name and refine in the `<strong>` title, the socket
stones as 16 px images, and the bonuses as `➜ Name +Value`. One source, no
join, no alignment — the three fragile steps disappear together, and the
attribute vocabulary is simply the set of names the site prints. Where the site
itself does not know a name it prints `Atributo #3818`; we inherit the gap and
show the same.

The cost is that attributes are keyed by name rather than by numeric id. That
buys nothing back in this product: the dropdown shows names, the filter
compares numbers, and an unnamed attribute already carries its id in its label.

**Slot names are ours, not the site's.** The page labels slots nowhere — the
paper doll only carries `data-item-type="slot-10"`. `lib/market/slot_names.dart`
names the ones the collected data makes unambiguous (Arma, Elmo, Armadura,
Coxote, Caneleiras, Capa, Braçadeiras); the rest read `Slot N` in the dropdown,
followed by the item most often found there. That hint comes from the index, so
it is always right, and it identifies the slot well enough to filter on before
anybody writes the proper name down.

## The site blocks

Measured, not guessed:

- 15 detail pages fetched sequentially: **30 s, all succeeded**.
- 91 detail pages with 4 concurrent workers: **31 succeeded, 60 failed**, and
  the IP was refused (`Errno 61 Connection refused`) for **20+ minutes
  afterwards** — including single requests from `curl`.

A full pass is 779 pages, ~680 MB, ~40 min at a polite pace. On-demand
scraping from the app is therefore impossible, and so is any parallel
collector.

## Architecture

Two programs, one repository, one file between them.

```
site  ──►  tool/collect.dart  ──►  assets/market_index.json  ──►  Flutter web app
           dart:io, ~40 min          the contract                 in memory, ms
```

The collector never knows what a filter is. The app never knows what HTML is.
The site changing touches only the collector; the screen changing does not
reach the collector at all.

**The `dart:io` rule.** The app targets web and cannot import `dart:io`. So the
parsers live in `lib/collector/` as pure Dart — no `dart:io`, no Flutter — and
every side effect (HTTP, pacing, files) lives in `tool/collect.dart`. Tests
exercise the parsers directly; the app never drags `dart:io` into its bundle.

```
lib/
├── core/
│   ├── di/          # GetIt + injectable
│   ├── result/      # Result<T>, AppFailure
│   └── theme/       # PWColors, PWTheme
├── market/          # the index model — shared by both programs
├── collector/       # listing_parser.dart, detail_parser.dart (pure Dart)
└── features/search/
    ├── domain/      # Criterion, SearchQuery, the matcher
    └── ui/          # SearchView, SearchViewModel (Bloc), widgets/
tool/collect.dart    # dart:io: HTTP, pacing, resume, writing the file
test/fixtures/       # the two real pages, saved
```

State is Bloc, as in baby_control. The ViewModel **is** the Bloc; there is no
UseCases layer.

## The collector

One pass: fetch `/pw187`, extract the 779 cards, then walk the details one at a
time.

**Pacing:** one request at a time, ~3 s apart. Exponential backoff on error, and
a long pause on `Connection refused`, which is what the block looks like.

**Resume:** `.collect_state.json` records what has been read. Power cut, block,
Ctrl-C — the next run continues where it stopped. A character that fails is
recorded as failed and does not bring the pass down.

**Report at the end:** read, failed, and **how many came back with zero
equipped items**. That last number is the alarm for "the site changed its
HTML" — a character on sale with no gear at all is rare, and 779 of them is
impossible.

## The index format

Normalized into three parts so no text repeats 779 times.

```jsonc
{
  "formatVersion": 1,
  "server": "pw187", "collectedAt": "2026-08-09T14:00:00Z",
  "attributes": ["Nível de Ataque", "Nível de Guarda", "HP"],
  "items":      { "50206": { "name": "★★★Dilacerador Raivoso", "grade": 6 } },
  "characters": [
    { "roleId": 64112, "name": "Leandrim", "class": "Guerreiro",
      "occupation": 1, "level": 105, "price": 1000, "fame": 204237,
      "cultivation": "Leal",
      "equipped": [
        { "slot": 10, "item": 50206, "refine": 12, "stones": [51112, 51112],
          "attributes": { "0": 70, "1": 350, "2": 800 } } ] } ]
}
```

An item's `attributes` keys are positions in the shared `attributes` list.

**A repeated attribute reduces by rule, and the rule is per attribute.**
`HP +500, +150, +150` is one pool and totals to 800. `Nível de Ataque +70`
followed by `+1` is a principal and a minor roll, and the weapon is a **70** —
summing sorts it above every genuine 70 and labels it with a number no other
copy of that weapon has. `IndexBuilder.attributeRules` holds the exceptions
(attack, defence and guard level take the principal); everything else totals.

The collector's state file therefore stores **every occurrence**, not the
reduced number, and `--rebuild` rewrites the index from it offline. That is the
difference between a rule change costing seconds and costing a fresh crawl of
all 771 pages — learned the second way.

**An unnamed attribute keeps its number.** No invented names.

Measured, not estimated: the roster of 779 with one character's gear comes to
111 KB, so a full collection lands in the low single-digit megabytes — well
under the 4–8 MB first guessed, because interning removed most of it. It loads
instantly off local disk and nothing needs optimizing.

## The screen

One screen, split: the form on the left, the cards on the right.

```
┌─ filtros ──────────────────┐  ┌─ 3 de 779 personagens ──────────────┐
│ Classe   [Guerreiro ▾]     │  │ ┌────────┐ ┌────────┐ ┌────────┐   │
│ Nível     101 ──────  105  │  │ │Leandrim│ │  ...   │ │  ...   │   │
│ Preço      40 ──── 4999    │  │ │ lv105  │ │        │ │        │   │
│ Cultivo  [todos ▾]         │  │ │1000 TCC│ │        │ │        │   │
│ ─────────── itens ──────── │  │ └────────┘ └────────┘ └────────┘   │
│ Arma ▾ Nível de Ataque ▾   │  └─────────────────────────────────────┘
│        mín. [ 70 ]      ✕  │
│ Elmo ▾ Nível de Guarda ▾   │
│        mín. [350 ]      ✕  │
│ + adicionar critério       │
└────────────────────────────┘
```

There are two ways in, and the shortcut comes first.

**The weapon dropdown** lists the weapons worn in the market, best attack level
first, each labelled with the number: `★★★Dilacerador Raivoso · +70`, and on a
second line `+70 nível de ataque · 3 personagens`. Picking one filters to the
characters wearing that exact item id. It answers the original question without
anybody having to learn what an attribute is — the number is in the name, so
the three weapons called *Dilacerador* stop being indistinguishable. The model
behind it is `slot → item id`, so adding an "Elmo" dropdown later is one more
widget and no model change.

**It follows the class filter, and that is not cosmetic.** Every class has its
own weapons and its own +70 among them — there is no single best weapon on the
server, there are seventeen. Unscoped, the list buries the entry you want among
sixteen you can never equip, and it lets you pair Guerreiro with a Mago weapon:
zero results, no explanation. So the list is scoped to the chosen class, and
changing the class drops a weapon that class never wears.

**The criteria rows** are the general form underneath it, for the questions the
dropdown cannot phrase: "any piece with 70 attack level", "a helm above 350
guard level", two conditions at once.

A **criterion** is `(slot, attribute, minimum, minimum refine)`. The list of
criteria is an AND: a character passes when **every** criterion finds, in the
slot it names, an item whose attribute meets the minimum. The refine is read off
that same item — checking the two against different items in the slot would let
a spare vouch for the piece being worn.

The slot accepts "any", so `(any slot, Attack Level, ≥70)` answers "who has 70
attack level on any piece" at no extra cost. The attribute does not: "any
attribute above 70" would mix Attack Level with HP and mean nothing.

Each result card shows, for every criterion in force, the item that satisfied it
and by how much. Without that the list answers "these match" and leaves you
opening pages to find out which weapon it was — the exact work this removes.

The dropdowns are built from the index, not hardcoded. The attribute dropdown
shows only the attributes that **exist** in the chosen slot, each with how many
characters have it. Nobody has to know Attack Level exists in order to find it,
and nobody wastes a query on an attribute that slot never carries.

Clicking a card opens the real marketplace page in a new tab. We do not rebuild
the character sheet; the site already does that well.

The UI is Portuguese only. No ARB, no localization machinery — the game data is
Portuguese and there is one user.

## Failure

Three failures, three different answers.

**No index** — you cloned the repo and have not collected yet. The screen says
so and shows the command. Not an error; it is first use.

**Stale index** — the collection date is always on screen. Past a week it is
highlighted. Market prices age fast, and a perfect filter over last month's data
is worse than no filter, because it looks right.

**Corrupt or unknown format** — the app refuses and names the field it could not
read, instead of opening empty. The repository returns `Result<T>` with a typed
failure; no exception reaches the screen.

**A filter matching nobody is not a failure** — it is the most useful answer
there is ("nobody on the server has a +70 weapon under 500 TCC"). The cards
disappear and the sentence appears, with no error styling.

## Testing

TDD where things break silently: the parser and the filter.

**Parser** — the two real pages are fixtures in `test/fixtures/`. Assertions are
exact, never "found something": Leandrim has **14** equipped items, the weapon is
**50206** at refine **12** with two **51112** stones and addon **2974 = 70**; the
listing yields exactly **779** cards. A loose assertion here is the same defect
as baby_control's `findsWidgets` — green with the parser reading half the page.

A `pipeline_test.dart` runs the whole chain over the fixtures with no network —
listing → detail → index → JSON → query — and ends on the question the product
exists to answer: filtering the weapon slot for Attack Level ≥ 70 returns
Leandrim and nobody else. The seams between the parsers, the builder and the
matcher are where an index comes out empty while every unit test stays green.

**Filter** — synthetic data, no HTML. The cases that matter: two criteria on the
same slot; a criterion matching one item but not the other in the same slot;
repeated addons summing; an empty slot; and **zero results**.

**Screen** — skeleton only: the form emits the right criterion, the count is
right, the empty state appears. No coverage target.

**Not tested:** the collector hitting the live site. A test that depends on
somebody else's network fails for the wrong reason — and here it also earns an
IP block.

## Out of scope

Price history, alerts, servers other than pw187, inventory/bag items, pets,
mounts, titles, cards, and hosting the app anywhere. Equipped items only, local
only.
