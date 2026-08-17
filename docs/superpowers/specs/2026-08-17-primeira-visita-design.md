# Portal PW — the first visit

**Date:** 2026-08-17
**Status:** approved

## The problem

The Portal stopped being a tool for one person. It has a domain, a visit
counter reading 44, three sections on the front page and a link that gets
pasted into the server's community. What it does not have is anything designed
for the person on the other end of that link.

Two doors receive first-time visitors, and only those two:

- **the home**, from a link shared in the community;
- **`/filtro`**, from word of mouth — "this site finds cheap 70 weapons".

Three things have to happen to that visitor: use the filter well **once**, have
a reason to **come back** as the market moves, and want to **send it to someone
else**. Everything below serves one of those three.

### What the published site does today

Measured on 2026-08-17 against `portalpw.net`, at 1440 px and at 390 px.

| Observation | Consequence |
|---|---|
| The logo is 440/340/260 px wide and is the whole first fold on a phone | The visitor scrolls before learning what the site does. The mark states a name, not a promise |
| `web/index.html` carries no `og:` tag at all | A link pasted in Discord or WhatsApp renders as a bare line, competing against screenshots of the game |
| The filter's mobile controls are two unlabelled icons | The screen opens with 968 results and nothing says it can be narrowed. The one thing the site does best is invisible on the surface that word of mouth lands on |
| No search can be linked | "Send it to a friend" can only send the site, never the finding — and the finding is the argument |
| The filter suggests no first question | Every visitor must invent a criterion before seeing the tool work |
| The disclaimer occupies three lines at the top on a phone | The most expensive strip of the screen, spent on a legal note, on every visit |
| Each collection overwrites the last | The site has no memory, so it has no news, so it has no reason to be visited twice |

## Scope

**This spec is phase A: the visit.** It touches screens only. No new data, no
new field in the index, no server.

**Phase B, named here and deliberately not specified:** the market with a
memory. The collector's state file already stores `roleId` and `price` per
character, so recording *first seen* and *previous price* costs no extra
request — and it unlocks a "new today" badge, a price-drop line on the card,
and a dated headline on the home. That is the piece that earns a second visit;
it is deferred because it changes the contract between the two programs and
because it is worthless until someone visits the first time.

**Out of scope:** restyling the guides, a full type scale, ads, any character
detail screen.

## Design

### 1. The first fold

The order becomes: mark, promise, action, proof.

- **The logo shrinks** to roughly 260/210/170 px (large/wide/narrow), from
  440/340/260. It stays the mark and stops being the content.
- **A real headline** replaces the 13 px muted subtitle:
  *"Ache o personagem certo pelo que ele está usando"*, with a supporting line
  naming what can be filtered — weapon, cards, refine, attributes.
- **One primary action**, a filled `PWColors.accent` button, *Buscar
  personagens*. Today the only path into the filter is a card that reads as
  decoration.
- **The four figures become links**, and on a phone they sit 2×2 so the fold
  holds mark, promise, button and proof together.

The wording above is a first draft to be tuned in the user's voice, and it
follows the standing rule: say what the visitor gains, never what the official
marketplace lacks.

Each figure carries the visitor into the filter with the matching search
already applied:

| Figure | Lands on |
|---|---|
| `968` personagens à venda | the filter with no criterion |
| `306` com arma de 70 de ataque | Nível de Ataque ≥ 70 on the weapon slot |
| `150 TCC` o mais barato deles | the same, ordered by lowest price |
| `76` com o Portal de Nuema | the Nuema card combo |

Two existing rules survive untouched: every figure stays **computed from the
index**, never written down; and `MarketPulse` keeps reserving its height while
the index loads, so the button below it does not jump when the numbers arrive.

### 2. Preset searches

A row of chips under the filter's header, at every width, each holding a whole
search:

> `Arma de 70 até 500 TCC` · `Portal de Nuema` · `Refino +10` ·
> `Rank 4 na arma` · `Até 200 TCC`

One tap and the tool demonstrates itself; nobody has to understand what a
criterion is to see what the site is for.

**Presets are written by attribute, never by item id.** An item belongs to one
class — a preset built on item `50206` is a preset that works for Guerreiro and
silently returns nothing for the other sixteen classes.

Tapping a preset **replaces** the current query rather than adding to it, and
the active chip is highlighted; tapping it again clears. Accumulating presets
would produce combinations nobody asked for, with no way to see which chip
emptied the results.

Presets live in `features/search/domain/presets.dart` as named `SearchQuery`
values, so **the home's clickable figures and the filter's chips are the same
objects** — one definition, two entrances.

### 3. The filter on a phone

The pair of mute icons is replaced by a labelled bar under the app bar:

```
←  968 de 968
┌───────────┐ ┌──────────────┐
│ ☲ Filtros │ │ Menor preço ▾│
└───────────┘ └──────────────┘
```

- **`Filtros · N`** carries the number of active criteria, for the same reason
  a collapsed section already carries its count: a filter in force with nothing
  on screen saying so makes the results look wrong for no visible reason.
- Under it, when criteria exist, a scrollable row of **removable chips** naming
  what is applied.
- Tapping **Filtros** opens a near-full-height **bottom sheet** hosting the
  existing `FilterPanel` unchanged, with a pinned footer button reading
  **`Ver 128 personagens`** — a live count that updates on every change, so the
  effect of a criterion is visible before the panel closes. The `Drawer` on
  narrow widths goes away; the side panel at wide widths stays exactly as it is.

The panel itself is not rewritten. Only its container changes.

### 4. The search becomes a URL

Readable parameters, not an encoded blob — the link pasted in a group should
say what it does:

```
/#/filtro?classe=mago&preco=40-500&nivel=100-105
         &c=arma:ataque:70:r10&carta=nuema&ordem=preco
```

- Serialisation and parsing live in
  `features/search/domain/search_query_url.dart`, pure, with a round-trip test
  per dimension.
- The app **reads** the query on entry (`Uri.base.fragment` holds path *and*
  query under the default hash strategy — this must be verified before the rest
  is built) and **writes** it on change, replacing the history entry rather
  than pushing, debounced, so typing a price does not fill the back button with
  thirty states.
- A **copiar link** action in the header, with a confirmation snackbar.

An unparseable or stale parameter is ignored, never an error: a link shared
last month whose item no longer exists must still open the filter.

### 5. The link preview

`web/index.html` gains `og:title`, `og:description`, `og:url`, `og:image`,
`og:image:width`/`height` and `twitter:card=summary_large_image`; the guides
get the same, with their own titles.

The image is **1200×630**, composed from the assets already in the repository:
the Espiritualista art bleeding off the right, the logo, the headline and a row
of terms (arma · cartas · refino · atributos) — the composition rendered and
approved during this design.

Three constraints, each of which has broken a preview before:

- **PNG or JPG**, not WebP: WhatsApp is unreliable with WebP previews.
- **Under ~300 KB**, or WhatsApp gives up fetching and shows the bare link.
- **The headline must survive a square crop.** Several clients crop the sides,
  so nothing that must be read may sit in the outer thirds.

One gotcha to record when it ships: the site is behind Cloudflare and preview
scrapers cache aggressively. Replacing the art later means shipping it under a
**new filename**, not overwriting `og.png`.

### 6. Type

One display face for headlines only — the home's headline and card titles.
Body text, every figure and the whole filter stay on Roboto, whose density in
the result cards is correct and must not be disturbed.

- **Marcellus** (OFL) is the recommendation: it has true lowercase, which a
  sentence-length Portuguese headline needs. Cinzel is the alternative, and is
  better only for short uppercase labels such as section headers.
- The font ships as a file in `assets/fonts/`, declared in `pubspec.yaml`.
  **No new package**: `google_fonts` would add a dependency and fetch from a
  CDN at runtime, which is worse on both counts.
- The chosen face must be checked against accented capitals (Ê, Á, Ó) before it
  is adopted; the game's vocabulary is full of them.

### 7. The disclaimer moves

Off the top of the results and into their footer, keeping its wording. It is
worth saying and it is not worth the first fold of every visit.

### Colour: a decision that goes the other way

The logo is red and the app is gold, and the obvious move — adopt the logo's
red as a brand colour inside the app — is wrong. Red already means **grade 6**
in item names, which is why `★★Poeira Mundana` renders red on a result card,
and it is also `PWColors.danger`. A third meaning on the same screen would make
all three unreadable.

**The red stays the logo's. Gold stays the colour of what is worth something** —
figures, the primary action, highlights. No new colour is added.

## Testing

- **URL round trip**, pure and cheap: every dimension serialised and parsed
  back, including the empty query and a query carrying an unknown parameter.
- **Presets are pinned against the collected index**, the way `combo_test.dart`
  pins card combos: every preset must match at least one character. A preset
  that matches nobody is indistinguishable from a working filter with a sad
  answer, and it would ship unnoticed.
- **Home behaviour**, widget level: the four figures render from a stub index,
  and tapping one produces the expected `SearchQuery` on the view model.
- **The mobile sheet's count** matches the number of results the filter then
  shows — one rule read twice is the bug this test exists to catch.
- Layout itself is not asserted in tests. It is judged **on the published
  site**, never on `localhost`, and the `flutter-view` width ratio is the
  measurement that settles any "it looks the wrong size" argument.

## Risks

- **The hash strategy and query strings.** If `Uri.base.fragment` does not
  carry the query cleanly, section 4 needs a different scheme — and sections 1
  and 2 depend on it only for sharing, not for working. Verify first.
- **A ten-minute cache.** GitHub Pages sends `max-age=600`, so a returning
  visitor may see the old bundle for ten minutes. Nothing here changes that;
  it only means judging a deploy too quickly is a mistake.
- **The presets age.** `Arma de 70 até 500 TCC` matching nothing after a price
  swing is a believable answer and an invisible failure. The pinned test is the
  guard, and it only runs when someone runs it.
