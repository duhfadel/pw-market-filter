# Registros de Assimilação: a janela do NPC na web

**Date:** 2026-09-19
**Status:** awaiting approval

## The problem

The game has an NPC whose *Fabricar* window trades **Páginas de Registro:
Assimilação** for permanent stat bonuses. It is one of the few systems in the
game that permanently raises a character's numbers without costing gold, and
the player cannot compare its options from inside the game.

Three things make it opaque:

1. **The window shows 32 identical icons.** Every recipe in a tab draws the
   same blue page art. Telling them apart means hovering one at a time.
2. **The chain is three links long.** `Página de Registro: Assimilação` →
   `Registro: <lugar>` → nine or so titles → the stats. The stats are on the
   titles, and the window never sums them.
3. **The cost varies by a factor of a hundred and the reward does too**, and
   the two are not correlated. Nothing on screen says which trade is good.

Measured across the six tabs (126 recipes):

| | pontos | páginas | pontos por página |
|---|---|---|---|
| `Registro: Mundo Primitivo` | 118 | 1 | **118** |
| `Registro: Rio Congelado` | 107 | 1 | 107 |
| … | | | |
| `Registro: Canônico` | 24 | 20 | 1,2 |
| `Registro: Jogador Número Um` | 90 | 100 | **0,9** |

A player spending pages in the order the NPC lists them is giving away more
than a hundredfold of value, with nothing on screen to say so. This is the
same shape as the weapon that sells for 130 TCC and for 8000 — which is the
problem this whole site exists for.

## Where the data comes from, and where it does not

**Not from the item database.** The chain was followed to the end against
`pwdatabase.theclassic.games` (version `vtheclassicpw187`, which the search
requires as a context before it answers):

- `83070` — Página de Registro: Assimilação. Its page lists the recipes.
- `83004`…— `Registro: Cidade do Dragão` and the rest, sequential ids.
- The titles — **absent**. Searching `Mestre Desbravador` answers
  *"Nenhum item encontrado"*: the database indexes items, and a title is not
  one.

So the numbers exist in exactly one place: a spreadsheet the player keeps by
hand. That is a fact about this feature and it shapes everything below — the
tool is only ever as complete as what somebody types, and it must therefore be
honest about what it does not know.

### What the spreadsheet holds

Six sheets, 126 recipes. Read from the workbook, not from a single CSV export
— the first attempt fetched `gid=0` and reported one tab, which was wrong:

| aba | receitas | grade | páginas | sem bônus |
|---|---|---|---|---|
| Área 1 | 32 | 4 × 8 | 1 | — |
| Área 2 | 32 | 4 × 8 | 1 a 100 | 7 |
| Coletar | 16 | 2 × 8 | 2 a 65 | 1 |
| Avançado | 17 | 3 × 8 | 6 e 12 | — |
| M/A | 18 | 3 × 8 | 1 a 20 | 6 |
| Casal | 11 | 2 × 8 | 1 a 10 | 11 |
| | **126** | | | **25** |

**Twenty-five recipes have no bonus recorded**, including all of Casal. The
owner's decision is to ship them empty rather than guess, and the screen says
so rather than hiding them: a row that vanishes reads as a recipe that does
not exist, and the gaps are also the worklist for filling them in.

Two cells are wrong at the source and also ship empty — `Arqueólogo Esp.`
carries `1.0` in the bonus column (the page count, one column across) and
`Reino Ocidental III` carries `*`.

### Reading the bonus text

The bonus is free text written by a person: `Atk F +3, Atk M +5, Def F + 29`,
with `Atk f` lowercased, `esquiva` lowercased, a full stop where a comma was
meant, and spaces inside `+ 29`. A tolerant parser reads all 101 non-empty
cells across seven attributes — **Atk F, Atk M, Def F, Def M, Acerto, Esquiva,
HP**. HP was missed on the first pass and found by the parser reporting what
it could not read, which is why the parser reports rather than skips.

Parsing happens **once, on the way in**. The table stores numbers.

## The design

### Where it lives

A new tool at `/registros`, with a card on the front page's menu. The owner
chose a Flutter screen over a static page with the trade-off stated: a static
page would weigh 26 KB against the app's 825 KB and would be findable in
search, where a canvas is not. Inside the app the screen is instant for anyone
already on the site, and it reuses the theme and the filtering idiom.

### The screen

**The grid, as the game draws it.** Eight slots per row, in the NPC's own
order — `ordem` in the table exists so slot 1 is slot 1, and never
alphabetical. Six tabs across the top, named as the game names them.

**Each slot carries its name underneath.** The game does not, and that is the
one place this deliberately departs from it: 32 identical icons is a
limitation to leave behind, not to reproduce. A phone has no hover, so a
faithful copy would cost 32 taps to find one recipe.

**Clicking a slot fills a panel below the grid** — the same place the game
puts *Requer / Habilidade / Item*. Clicking another slot swaps the panel, so
two recipes can be compared without opening and closing anything.

**The filter is by attribute**: seven toggles. Turning on *Esquiva* dims every
slot that does not give it; two on means "either". It dims rather than removes
so the grid keeps the game's shape and positions — which is the whole point of
drawing a grid instead of a list.

### What the grid can say that the game cannot

`pontos por página` is offered as an **ordering**, not as the default. The
list is born in the game's order, which is what was asked for; a visitor who
wants the other reading asks for it. Ordering changes which slot sits where,
so it is the one control that breaks the grid's fidelity on purpose and says
so.

### The data at runtime

A `registros` table in Supabase, read by the browser on load:

```
aba text, ordem int, nome text, paginas int,
atk_f int, atk_m int, def_f int, def_m int, acerto int, esquiva int, hp int
```

`null` in an attribute means *not recorded*, and is not the same as `0`, which
would mean *recorded as giving none*. The screen prints the first as an
absence and the second as a zero — the same distinction `counts` already makes
in the market index.

**Read open, write closed**, like `territorios`: a `select` policy for `anon`
and no insert, update or delete policy at all. Fixing a value is editing a row
in the dashboard — no commit, no deploy, no CI.

Two things already known from the map and not to be rediscovered: PostgREST
reads an unknown query parameter as a filter on a column of that name, so the
`?t=` cache-buster used for the market index answers `PGRST100` here — it is
`cache: 'no-store'`. And an anon `PATCH` answers **204, not 403**, because RLS
filters the row out rather than refusing the verb; believe the follow-up
`select`.

The payload is **2 KB gzipped** for all 126 rows. At 1000 visits a day that is
63 MB a month against a 5 GB allowance.

### Seeding

A one-off script reads the workbook, parses the bonus text, and writes the 126
rows. After that the spreadsheet is out of the loop — one source, which is the
table. The script stays in `tool/` so a future re-seed is reproducible, and it
refuses to run against a non-empty table rather than duplicating rows.

## What this does not do

- **No "how many pages do I have" calculator.** It would be the natural next
  feature and it is a different question: this one is *what does each trade
  give*, and answering two questions in one screen is how a form stops being
  scannable.
- **No title-by-title breakdown.** The titles are not in any database reachable
  from here; only the summed bonus is known.
- **No unlock order.** Whether a recipe requires an earlier one is unknown, and
  guessing would make the ordering advice wrong rather than incomplete.

## Testing

- The parser, against the real strings, including the lowercase, the stray full
  stop, the space inside `+ 29`, and HP. It reports what it cannot read.
- `null` versus `0` survives the round trip and draws differently.
- The grid keeps the game's order and its eight-wide shape, including the tabs
  whose last row is short.
- A tab whose recipes are all without bonuses still draws its slots.
- The attribute filter dims rather than removes, and two toggles mean "either".
