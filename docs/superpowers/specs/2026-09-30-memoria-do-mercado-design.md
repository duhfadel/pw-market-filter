# A memória do mercado

**Date:** 2026-09-30
**Status:** approved (design); not implemented

## The problem

**Every collection overwrites the last.** The site knows how the market stands
now and nothing about how it stood yesterday. Three questions a buyer would ask
have no answer:

- *what came in today?* — a character listed since yesterday looks identical to
  one listed three weeks ago
- *did this one drop?* — a character that fell from 500 to 400 TCC is
  indistinguishable from one that always asked 400
- *is the one I saw still there?* — if it left, it left no trace

And the consequence that matters more than any of them: **there is no reason to
come back tomorrow.** Whoever opened the site today has seen everything it has
to say; returning shows the same screen with no way to tell what moved.

`CLAUDE.md` has carried this as the open gap since 2026-08-17, and the site
that copied this project's combo names has shipped `firstSeen` while we have
not.

## The collector already computes this and throws it away

The irritating part. Every run of `tool/collect.dart` does this:

```dart
final listing = await _fetchListing(client);   // one request, all 1519, with price
final delisted = state.pruneTo(listing);       // deletes whoever left — and counts them
state.listing = listing;                       // overwrites yesterday's prices
final pending = listing.where((c) => !state.isDone(c.roleId));  // whoever is new
```

`pending` **is** the list of arrivals and `delisted` **is** the count of
departures — the collector even prints them, *"X já no índice, Y saíram do
mercado, Z a buscar"*. Then it discards both: `pruneTo` deletes the departed
and `state.listing = listing` replaces the old prices before anything compares
them. **The information is computed and dropped in the same paragraph.**

`ListingCard` already carries `roleId`, `name`, `characterClass`, `level`,
`price`, `fame` and `cultivation`. Nothing extra needs fetching.

## Where the memory lives: the published index is its own record

The owner's question decided the architecture: *which option stays free as
traffic grows?*

**Storage is free in every option; what costs money as traffic grows is
serving.** Today a visitor downloads one static file from the CDN and nothing
else, which is why the site carries any traffic for nothing. So the rule is:
**the browser never queries a database for this.** History is read at
collection time and only the *conclusions* are written into
`assets/market_index.json` — four small fields per character, about 40 KB on a
3 MB file, **1% more**. Zero cost per visit, permanently.

What does not fit is a price series per character. Nobody needs one: the screen
says *"baixou de 500 para 400, já cortou três vezes"*, and that is four
numbers.

And then the elegant part. **If the conclusions live in the index, and the
index is published at `portalpw.net`, the published index is already the
durable record.** Each run begins by fetching the site's own index, carries the
fields forward and updates them.

| | costs per visit? | survives? | new moving part? |
|---|---|---|---|
| **the index as its own memory** | **no** | as long as the site exists | none |
| the Actions cache alone | no | **no** — evicted after 7 days unused | none |
| Supabase | no, if only the collector reads | yes | table + service key in CI |
| committed to the repo | no | yes | publishes a price database, and a commit every 15 min |

The Actions cache is where the state lives today (`actions/cache@v4`, key
`collect-state-${{ github.run_id }}`). That is right for resuming a crawl —
losing it costs forty minutes — and **wrong for history**, because a cache that
evicts silently would make the site announce 1519 new characters one random
morning. It stays as the second copy: if a bad deploy publishes a broken index,
the state file still holds the fields.

**One dependency nobody would guess, so it is written down:** the published
index is served `cf-cache-status: DYNAMIC` — Cloudflare does not cache it at
the edge — so the collector fetching it always gets the real current file and
never a ten-minute-old one. Measured on 2026-09-30. If that ever changes, the
collector needs the `?t=<millis>` buster the app already uses.

## What goes in the index

Four fields per character, all derived at collection time:

| field | meaning |
|---|---|
| `firstSeen` | the date this `roleId` was first met |
| `previousPrice` | the price at the previous run, when it differed |
| `lowestPrice` | the cheapest this character has ever asked |
| `cuts` | how many times the price has fallen |

`MarketIndex._formatVersion` goes from 1 to 2. An index at version 1 loads as
having no history rather than failing — the app must open on a stale index, and
a missing field is *unknown*, never *new*.

## Better than `firstSeen`, and the reason we can be

The competitor shows when a listing appeared. That is the floor. **This site
knows what every character is wearing** — it pays forty minutes a day for
exactly that — and crossing equipment with price history is the thing that is
hard to copy.

### 1. Price in motion, not a date of arrival

A price series (changes only; most prices never move) gives *"pedia 8000 há
três semanas, hoje pede 3000, já cortou três vezes"*. **A seller who keeps
cutting wants out**, and that is a buying signal the marketplace itself shows
nowhere.

### 2. "Barato para o que carrega" — the one that wins

> *40% abaixo da mediana de quem tem arma de 70*
> *o mais barato com Portal de Nuema que já apareceu*

`firstSeen` answers **when**. This answers **whether it is worth it**, which is
the question a buyer actually has. Half of it works with no history at all —
the median of the current market — and history adds *and it is the cheapest it
has ever been*.

This is the site's whole thesis, made per-character: the front page says the
same weapon tier sells for 130 and 8000, and this says which side of that a
given character sits on.

### 3. "Novo desde a sua última visita" — personal, and free

Not a global *new today*, but **yours**. The browser records when this search
was last seen and the grid marks what appeared since. `BrowserMemory` already
does exactly this kind of keeping for the news dot.

No account, no server, no email. Somebody returning after five days sees *"7
novos desde 24/09"* on **their** search. A static site is rarely personal;
here it can be.

### What is deliberately not built

**Email or push alerts.** Accounts, a server and consent, for an order of
magnitude more work than (3), which delivers most of the value.

**Saying "vendido".** The site sees that a listing left, not why. Claiming a
sale would be inventing, and this project's rule is that zero results is an
answer and a guess is not.

## The three traps, named before they are hit

**The record starts empty.** On the first run with the fields, nobody has a
past — so everybody would read as new and the site would announce 1519
arrivals. There is a cutoff date, and *first seen on the run that created the
field* is **unknown**, never **new**. The screen has to be able to say "não sei
ainda" for the first week rather than invent.

**`pruneTo` deletes the departed.** Saying *saiu do mercado em 24/09* needs a
tombstone rather than a deletion — a small ring of recently-departed roleIds,
not a growing graveyard.

**A character re-geared while still listed is invisible.** The detail page is
only fetched for roleIds never seen, so a seller who swaps a weapon on a
standing listing passes unnoticed. `CLAUDE.md` already records this and it
stays true; the fix, if it ever matters, is an age per entry and a slow
re-check of the oldest.

## Testing

- **The cold start does not lie.** An index whose characters have no
  `firstSeen` reports them as unknown, and nothing on screen says *novo*.
- **A price that did not move writes no history**, so the index does not grow
  by a row a run.
- **A cut is a fall, not a change.** A price going 400 → 500 → 400 has one cut,
  not two.
- **`lowestPrice` survives a delisting and a return** — the same `roleId`
  coming back keeps its floor, because `pruneTo` forgetting a character must
  not reset what is known about it.
- **The index round-trips at version 2**, and a version 1 file loads with the
  fields empty rather than throwing — `CollectedPage`'s lesson, that a codec
  with no test is where a field goes to die.

## Open

**What "novo" means in days** is not decided here: a character listed six hours
ago is obviously new, one listed six days ago probably is not. It wants the
market's own rhythm — how long a listing typically stands — which is a number
this feature will produce and nobody has yet.
