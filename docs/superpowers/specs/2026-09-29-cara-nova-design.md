# A cara nova: o Cartaz e a Vitrine

**Date:** 2026-09-29
**Status:** approved (design); not implemented

## The problem

The owner asked for a site that is **"mais inovador, mais ordenado, mais
profissional"** — and the three words are not synonyms. Two of them pull
against the first: innovation asks for risk, order and professionalism ask for
restraint. The reconciliation is the one this whole document is built on:
**spend the boldness in one place and keep everything around it quiet.** A page
with one memorable thing and rigorous surroundings reads as professional; one
with boldness scattered reads as amateur.

Measured against the published site on 2026-09-29, four things were wrong, and
only the first was ever named out loud:

1. **Two alignment systems, stacked.** Everything is centred from the logo down
   to the figures, and everything is left-aligned from the news bar down. This
   is the direct cause of the "not ordered" feeling, and nothing on screen says
   so.
2. **The logo is the largest element on the page and the least legible** — dark
   red fan art on dark violet, about 200 px tall before a single word.
3. **The figures orphan.** Five stats in a centred `Wrap` lay out 4+1 at
   1440 px; the sixth added on 29/09 made it 5+1. There is always one stranded
   on its own row.
4. **Gold marks everything, so it marks nothing.** `PWColors.accent` is on the
   button, on every figure, on every card arrow and on every badge.

A fifth, unnamed by anyone and visible only when sampled: **the page's chrome
and the page's art are not in the same colour world.** See *The palette* below.

## What was tried and rejected

Three directions were drawn and shown before the accepted one. Recording the
failures matters more than recording the winner, because the failures are what
bound the design.

| Direction | Verdict |
|---|---|
| **A · the night, executed properly** — keep the indigo, fix hierarchy and spacing only | not chosen; too little change to read as a new face |
| **B · Tinta e Jade** — ink-black ground, jade, vermillion, price as a seal | liked as an idea |
| **C · A Mesa** — trading instrument: dense, tabular, hairline rules | liked as an idea |
| **B+C merged** — the ink identity with the instrument's discipline | **rejected on sight** |

The merge failed for three reasons the owner gave, and all three are
constraints now:

- **The mockups had no game art at all.** The merge promised "the game's art is
  the only warm thing in the instrument" and then drew two screens with zero
  images. They became green spreadsheets. *The site lives on that art.*
- **The green palette is not Perfect World.**
- **It read cold — a bank terminal, not a portal for an MMO.**

The lesson is one line: **for this site, art is not decoration applied at the
end; it is the material the layout is made of.**

## The palette, and it was sampled rather than invented

Three class images that already ship in `assets/images/` were sampled at
120×120, dark pixels discarded:

| Image | Dominant hues |
|---|---|
| `espiritualista.webp` | 330°, 300°, 240° — magenta, purple, indigo |
| `sacerdote.webp` | 260°, 240°, 300° — violet, indigo, purple |
| `barbaro.webp` | near-neutral, with warm highlights near #F0D8D8 |

**Every hue lands between 240° and 330°**, with near-white highlights around
`#F0D8F0`. So the current indigo is in the right family — it is simply *flat*
next to art that is violet and magenta, and the gold accent is the only warm
thing on the page. That mismatch is why the art has always looked pasted on
rather than belonging.

The palette below is those colours, lifted to hold at 14 px on a dark ground.

| Token | Hex | Job — and it has exactly one |
|---|---|---|
| `noite` | `#12102A` | the page ground |
| `painel` | `#1B1738` | a card or panel |
| `elevado` | `#262046` | a panel on a panel |
| `filete` | `#2F2857` | every border and rule |
| `apagado` | `#9A93B8` | secondary text |
| `papel` | `#F0E6F2` | primary text |
| `violeta` | `#785ADC` | structure: links, focus; and one of the two class accents |
| `magenta` | `#D4609E` | the other class accent, and *novo* |
| `ouro` | `#FFB454` | **price, and nothing else** |

**`ouro` becoming price-only is a rule, not a preference**, and it is the
single highest-value change in this document. A colour that marks everything
marks nothing; the site is about money, so gold is money. The button, the
arrows and the badges give it up.

`PWColors.defenceTier` (`#6FCF97`) and the `gradeColors` ladder are untouched —
they were re-measured on 2026-09-29 and are recorded in `CLAUDE.md`.

## Typography

| Role | Face | Why |
|---|---|---|
| Display | **Marcellus** — unchanged | It already ships, its accented capitals were already checked against the file, and nobody ever complained about it. Changing it would redo verified work for no stated reason. The rule in `PWTheme` stands: **never a number in it.** |
| Body | **Inter**, replacing Roboto | Roboto is the face Flutter hands you by default — it is in every price and count on the site, and it is literally the untouched default. Inter is a drop-in in metrics and texture but is drawn for screens. |
| Figures | **Inter with `FontFeature.tabularFigures()`** | A separate mono face was designed in and then dropped. Inter carries `tnum`, so a column of prices aligns without a second font download. Cheaper and better. |

## The direction: Cartaz above, Vitrine below

Two devices, and they take turns rather than compete.

### O Cartaz — the hero

The class art runs **full-bleed** behind the first fold, about 320 px tall, with
the headline living in its negative space. A gradient of `noite` enters from
the left at 24% and dies over the figure; a second, vertical, seats the art
against the header and the section below. The art is not an image beside the
content — it **is** the ground.

**The signature: the class rotates, and the accent rotates with it.** The site
has as many faces as the game has classes, and no two visits open the same
page. It costs nothing — the art is already in the bundle.

**The accent rotates between `magenta` and `violeta`, and never leaves those
two.** An earlier draft of this spec said "amber for the Bárbaro" and that was
a contradiction caught in review: amber *is* `ouro`, and `ouro` is price. An
accent that borrows the money colour breaks the one rule this palette is built
on, on the one screen where it is most visible. Two accents also kill the
alternative, which was seventeen colours needing seventeen contrast checks
against `noite`; both of these are already in the palette and already hold at
14 px. Each class is mapped to whichever of the two sits with its art — the
Espiritualista is magenta, the Sacerdote violet — and a class not yet mapped
falls back to `violeta`.

The headline is the site's job in one sentence, and the sub-line is the thing
only this site does: *"o que o marketplace guarda no inventário e não deixa
procurar"*.

### A Vitrine — the proof

Directly below, three **real characters from the current collection**, not
abstract figures:

| Slot | What it is | Why it is there |
|---|---|---|
| left | the cheapest with a 70 weapon | one end of the gap |
| centre | the dearest with the **same** weapon tier | the other end |
| right | the rarest — a `Def lvl UP5` carrier | the tier nobody could reach until 29/09 |

Between the first two, a vertical rule carrying **`60×`**. This is the site's
whole thesis, and today the home only *asserts* it in grey text.

**It is also the only thing on the page that earns a second visit**, which is
the gap `CLAUDE.md` has recorded as open since 2026-08-17: the market has no
memory and nothing changes between visits. The Vitrine changes every
collection, without needing the price history that gap really calls for.

The preset chips that sat under the figures are **removed**. They are the same
chips the `/filtro` screen already shows, and the three Vitrine cards are
themselves links into searches. It was duplication, and it put a dead step
between the Vitrine and the tools.

## The rest of the home

Order, top to bottom:

```
cabeçalho (marca + menu agrupado)
O Cartaz                      ~320 px, arte sangrada
A Vitrine                     três personagens reais
FERRAMENTAS                   2×2, cards de 72 px
GUIA                          uma linha, não uma seção
NOVIDADES                     barra fechada
AO VIVO NA TWITCH
COMUNIDADE (Discord)
rodapé                        aviso de projeto de fã + visitas
```

### The grouped menu

`Ferramentas ⌄` and `Guias ⌄` open a panel listing each tool with its **live
number** — *1519 à venda*, *126 receitas*. Three reasons, and the first is a
defect that exists today and nobody had reported: **from `/runas` there is no
way to reach `/registros` without going back to the home.** There is no
navigation on any page but the front one. Second, a menu that carries counts
informs as well as navigates. Third, a flat row does not survive a fifth tool.

The menu **adds to** the tool cards rather than replacing them. Replacing was
drawn and rejected: `lib/features/home/domain/tool.dart` exists so the page
"shows the shape of the place from the start" — a tool with a null route is
listed, dimmed and labelled *em breve*. Behind a dropdown, a first-time visitor
arriving from a Discord link sees a one-tool site, and the *em breve* announces
nothing to nobody.

### Guias stops being a section

One card under a full section header with its own rule is more chrome than
content. It becomes a single line under the tools grid.

### Two changes to settled decisions

Both were recommended by me, applied in the mockup, and approved.

**Novidades moves below the tools.** `CLAUDE.md` justifies its position above
them, but read closely the justification is about the panel being **open** —
three entries ran to a thousand pixels and pushed `FERRAMENTAS` to y≈1740.
Closed at ~90 px that reason expired. Whoever arrives for the first time came
for the tool, not for a notice; news serves the returning visitor, and the
returning visitor scrolls. The dot, its read-once marking, and the header
carrying the latest entry's own title and date are all unchanged.

**The Discord stops being labelled `PUBLICIDADE`.** It is not advertising, it
is the owner's own channel — and readers are trained to skip whatever sits
under that word, so the label was costing the thing it was meant to present.
It becomes a `COMUNIDADE` section in the same language as the others. If a paid
placement ever appears, it gets the honest label back, and it gets its own slot.

### The logo is kept, and that is what fixes it

`pw-mark.png` goes in the header at ~26 px, beside `PORTAL PW` set in Marcellus
with `1.8.7` as a muted eyebrow. The fan art is not discarded — it is moved to
the size at which it works. A mark at 26 px reads; a 200 px wordmark of dark
red on dark violet does not.

## What the other screens inherit

No mockups were drawn for these, deliberately: the design would never leave the
drawing board. They inherit the tokens and the rules, and each gets its own
pass at implementation time.

- **`/filtro`** — the biggest of the four, and the one where people spend their
  time. It takes the palette, the tabular figures and the header with the
  grouped menu. **The weapon-tier frames are untouched** — they were measured
  and re-measured on 2026-09-29 and the green was chosen against a ΔE
  measurement. `PWColors.gradeColors` does not move.
- **`/registros`** — palette and type only. The eight-column grid, the gaps at
  unclaimed slot numbers and the dimming-not-removing rule all stand.
- **`/runas`** — palette and type only.
- **`/guerras`** — static HTML with its own stylesheet; it takes the palette by
  hand.

## What this deliberately does not change

Recorded so a later pass does not "fix" them:

- The weapon-tier frame ladder and `defenceTier`.
- Streamers sit **below the tools and above the Discord**. That position
  already cost an error once, when the card came out so discreet the owner
  could not find it.
- The news dot's read-once marking.
- The `novo` badge expiring by date rather than by a flag.
- The footer's *projeto de fã* line. It is the sentence the site's permission
  to exist is drawn on, and it stays in full.
- Everything in `market/`, `collector/` and `features/search/domain/`. This is
  a change of surface, not of behaviour.

## Risks, named

- **The 320 px Cartaz is unverified.** Every mockup here was judged in a
  browser on a local server, and `CLAUDE.md` is explicit that layout on this
  machine's `localhost` renders shifted and must not be judged. The hero has to
  be checked on the published site.
- **The crop will be wrong before it is right.** `CLAUDE.md` records that the
  three class arts have their faces about a fifth of the way down, not at the
  centre, and that a bad crop shows first on the **widest** card. The Cartaz is
  the widest thing the site has ever drawn. `Alignment(0, -0.6)` is the
  starting point, not the answer.
- **The class-to-accent map has to be written by hand**, seventeen entries
  against two colours, and each one is a judgement about whether magenta or
  violet sits with that art. It is cheap but it is not automatic, and a class
  added later falls back to `violeta` rather than guessing.
- **This is a large implementation.** New tokens touch `PWColors` and every
  screen; the Cartaz, the Vitrine and the grouped menu are widgets that do not
  exist; the menu is new navigation on every page.

## Testing

Following the repository's rule that the screen gets tests where they earn
their keep, and no coverage target:

- **The Vitrine picks real characters**, and the test pins that it picks the
  cheapest and the dearest *of the same weapon tier* — the pair is the claim,
  and a Vitrine showing the cheapest of the market against the dearest of the
  market would be a different and false statement.
- **The Vitrine degrades.** A collection where nobody carries a 70 weapon must
  draw something rather than three empty cards or a crash.
- **`ouro` appears only on price.** A widget test that walks the home and fails
  on `PWColors.ouro` used anywhere but a price is the only way the one rule
  worth having here survives a later change.
- **The grouped menu offers every tool with a route**, and dims exactly those
  without one — the invariant `tool.dart` already carries, now reachable from
  two places.
- `first_fold_test` keeps its wheel-at-40-px-from-the-right assertion. The full
  width still has to be what scrolls.

## Open, and deliberately not answered here

The **market's memory** — first-seen, price movement, "dropped from 500 to
400" — is still the gap `CLAUDE.md` names as the only thing that earns a
second visit. The Vitrine borrows against it by changing every collection, but
it does not close it. It stays its own spec.
