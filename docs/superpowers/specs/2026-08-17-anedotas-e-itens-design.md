# Filtros por anedotas e por itens do inventário

**Date:** 2026-08-17
**Status:** approved

## The problem

Two filters were asked for by people using the site — the first requests that
came from outside the person who built it:

1. **How many Anedotas a character has completed.** The game shows it as a
   pair, `1265/2756`.
2. **How many of certain items a character is carrying**: the three
   `Relíquia Maravilha` (Artefato, Arma, Armadura) and the `Chave da Sorte`.

Neither is answerable today. The index carries a character's fourteen worn
items and six worn cards, and nothing else about what they own.

### What the page already holds

Both live on the detail page the collector already fetches — verified against
`test/fixtures/detail_64112.html`, not assumed:

| Data | Where | Shape |
|---|---|---|
| Anedotas | the `anecdote` tab | `Progresso total 1265/2756`, `Linhas 107` |
| Item counts | `data-item` JSON in the inventory | `{"id":54687,"item_name":"Relíquia Maravilha: Artefato","count":22}` |

The fixture's character carries 22 Artefato, 16 Arma, 16 Armadura. He carries
no `Chave da Sorte`, so that one is unverified until a collection runs — which
is exactly why the design below counts by **name** rather than by id.

### What it costs

The collector's state stores three things per character — `items`, `cards`,
`sex` — and not the page. So this is **not** a `--rebuild`: all ~950 detail
pages must be fetched again at one request every three seconds, about **50
minutes**, and it has to happen in CI because that is where the state lives.

That makes this the re-collection `CLAUDE.md` has been waiting for. Two were
already paid for by taking one field at a time, and the rule written after them
is to take everything the page offers in one pass.

## Design

### 1. The parser takes everything, the index carries almost nothing

`detail_parser.dart` gains two readers, and the **state** stores their full
output:

- `anecdotes`: `{done, total, lines}`.
- `inventory`: every `data-item` in the inventory as `{id, name, count}`,
  summed per id — a character can hold the same item in several slots.
- while the page is open: `require_level` and `weapon_level` per equipped
  piece, the two other fields `CLAUDE.md` names as discarded.

The **index** carries only what the screen filters on: `anecdotes: {done,
total}` and a small `counts` map. Five or six numbers per character, invisible
against the 199 KB the index compresses to today. Everything else waits in the
state, where a future filter costs `--rebuild` — seconds — instead of another
fifty minutes.

### 2. Counted items are named, not numbered

`IndexBuilder` holds a list of **names**:

```
Relíquia Maravilha: Artefato
Relíquia Maravilha: Arma
Relíquia Maravilha: Armadura
Chave da Sorte
```

and resolves each to the id the collected inventories actually used. Two
reasons, and the second is the important one:

- the `Chave da Sorte`'s id is unknown — no character in the fixture carries
  one, and the item database needs a game-context cookie before it will search.
  A list of names finds it the moment the collection sees it, with no id to
  guess at;
- a guessed id yields a filter that quietly matches nobody, which is the exact
  failure `combo_test.dart` exists to prevent for card combos.

A test pins the same way: every name in the list must resolve against the
collected market, or the suite fails and says which name found nothing.

**This does not contradict "the item name lies".** That rule is about
equipment, where three weapons share the word *Dilacerador* and carry three
different attack levels — a name there does not identify the thing that
matters. For a consumable being counted, the name is the identity.

### 3. The screen

Two additions to `FilterPanel`, both starting empty and therefore asking
nothing until used:

- **Progresso** — one number field, *anedotas a partir de*, carrying the same
  facet hint the price and level ranges already show, so the visitor can see
  the range on offer before typing.
- **Relíquias e chaves** — one number field per counted item, *pelo menos N*.

On the result card the figure appears **only when it is being filtered on**,
which is the rule the matched item already follows: a card states what answered
the question, not everything it knows.

### 4. The migration runs itself

An entry in the state written before this change has no `anecdotes` key. The
collector treats such an entry as stale and re-fetches it, so the migration
needs nobody to clear a cache by hand, and an interrupted run resumes where it
stopped.

The workflow's `timeout-minutes: 50` is raised to **75** for the run that pays
this, since ~50 minutes of fetching plus analyze, test, build and deploy will
not fit in fifty.

While the collection is in flight the market is mixed: some characters carry
the new fields and some do not. A character without them simply fails the new
filters, which is why they ask nothing until a number is typed.

## Testing

- **The parser, against the fixture, with exact numbers** — `1265/2756`, 107
  lines, and `{54687: 22, 50410: 16, 70020: 16}`. `isNotEmpty` is what let a
  parser read one item where fourteen exist.
- **Every counted name resolves** against the collected index, the way
  `combo_test.dart` pins card ids.
- **The matcher**: a minimum of anecdotes admits the character above it and
  refuses the one below; a count filter does the same.
- **A character collected before the change** — no anecdotes, no counts —
  passes an empty query and fails a filtered one, rather than throwing.

## Risks

- **Fifty minutes is one run of a workflow that also runs every twenty
  minutes.** The concurrency group already makes a run in flight win, so the
  schedule will skip rather than pile up.
- **The `Chave da Sorte` may not be in the market at all.** If no character
  carries one, the name resolves to nothing and the test fails loudly, which is
  the correct outcome: better a red suite than a filter that silently answers
  "nobody has one".
- **The inventory JSON is the source `CLAUDE.md` warns against** — for worn
  equipment, because it carries no slot number and lists spares. Counting is
  the one job it is right for, and the paper doll stays the only source for
  what is worn.
