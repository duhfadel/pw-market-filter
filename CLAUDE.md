# Portal PW

A hub of tools for The Classic PW 1.8.7. One exists so far — the **Market
Filter** — and `lib/features/home/domain/tool.dart` is the menu: a tool with a
null route is listed, dimmed and labelled *em breve*, so the page shows the
shape of the place from the start and shipping a tool is a one-line change.

## Market Filter

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
| First visit | front page, preset chips, phone filters, shareable link, preview | **Done** |
| Anedotas e itens | progresso, contagem de relíquias e chaves, no índice e na tela | **Done, awaiting the collection** |

The first full collection ran on 2026-08-09: 770 characters, no failures, 538
distinct items, 101 attributes, 1.0 MB of index. All fourteen slots are named.

What it confirmed, and what the product rests on: **every class has its own
weapon capping at exactly 70 attack level** — seventeen different names for the
same tier — and 139 of the 770 characters carry one, from 130 TCC (tmzin,
Tormentador) to 8000 (Gege, Espiritualista). Sixty times the price for the same
weapon tier is the gap this tool exists to show.

Open: the results grid has no widget tests beyond the card itself.

**The visit, done on 2026-08-17.** The site now receives people who have never
seen it, through two doors and only two — the front page, from a link pasted in
the community, and `/filtro`, from word of mouth. What that round added: a front
page that says what the site does before it says its name, with every figure a
link into the search that produced it; five preset chips that are the same
`SearchQuery` objects those figures use (`domain/presets.dart`); a labelled
filter entrance and a bottom sheet with a live count on phones; a search that
writes itself into the address bar and reads itself back (`search_query_url.dart`);
and `og:` tags, without which a link pasted in Discord arrived as a bare line.

Still open from that round, and named on purpose: **the market has no memory.**
Each collection overwrites the last, so there is no "new today", no "dropped
from 500 to 400", and therefore no reason to come back tomorrow. It is cheap —
the collector's state file already keeps `roleId` and `price` per character, so
recording first-seen and previous price costs no extra request — and it is the
only thing here that earns a second visit. Spec:
`docs/superpowers/specs/2026-08-17-primeira-visita-design.md`.

**The two filters from outside, written on 2026-08-19.** The first requests
that came from someone other than the person who built the site: how many
Anedotas a character has completed (`Progresso total 1265/2756`, in the
`anecdote` panel) and how many of the counted items he carries — the three
`Relíquia Maravilha` and the `Chave da Sorte`, out of the inventory's
`data-item` JSON. Spec:
`docs/superpowers/specs/2026-08-17-anedotas-e-itens-design.md`.

The code is shipped and the **collection is what is still owed**: neither field
is in any state file written before them, so `CollectedPage.version` marks
every stored entry stale and the next CI run re-fetches the whole market —
about forty minutes, which is why `timeout-minutes` is 75. Until that run
lands, `countedItems` is empty, the filters draw no section, and
`counted_items_test` skips: an index that predates the fields must not fail the
suite for being old.

That run also takes everything else the page offers, as the rule says: the
whole inventory — 292 distinct stacks on the fixture's character — stored by
id so the next counted item costs `--rebuild` and no network, and
`require_level` and `weapon_level` per worn piece, which the parser had been
reading since 2026-08-09 and the **state had been throwing away**. The index
made that visible and nothing else did: 969 characters carried a sex and only
88 carried a `requireLevel`, because a live fetch kept it and every reload of
the state lost it. A codec with no test is where a field goes to die, which is
why `CollectedPage` now lives in `lib/` and has one.

**The sex is on the card as a glyph**, blue or pink, beside `nv 105 · Bardo`
and outside the text that ellipsizes — nine letters of `· Feminino` is what
tips that line over on a narrow card, and 14 px is not. `PWColors.male` and
`PWColors.female` are lifted towards the light end for the same reason every
colour here is: at 7.3 and 7.1 against `surface` they sit with `textMuted`
(6.5) and `ok` (8.0), where a saturated blue or pink would go muddy at 14 px.
A value the site does not print draws nothing rather than a third colour, and
the glyph carries `semanticLabel` because the colour is the whole message and
it is the one thing on the card written nowhere. It was collected in August and
shown nowhere until 2026-08-19 — which is worth noticing as a shape of waste:
a field can sit correct and complete in the index, costing a full crawl, and
answer nobody. It cannot be derived from the class either: Perfect World locks
classes to a gender and this server mostly follows, but sampling two
characters of each of the seventeen found **Bardo with both**, which is enough
to kill the rule. Andarilho, Arcano, Arqueiro, Bárbaro and Ceifador came back
male; Atiradora, Espiritualista and Feiticeira female.

**Read the spec before starting any feature:**
`docs/superpowers/specs/2026-08-09-filtro-por-itens-design.md`

The three real pages the whole parser rests on are already saved:
`test/fixtures/listing_pw187.html` (1.8 MB, 779 cards),
`test/fixtures/detail_64112.html` (1.1 MB, the Guerreiro Leandrim) and
`test/fixtures/detail_330640.html` (1.4 MB, the Feiticeira LeRato, who carries
both legendary pets and has renamed both).

## Commands

| Command | Description |
|---------|-------------|
| `dart run tool/collect.dart` | Collects the market and writes `assets/market_index.json` (~40 min) |
| `dart run tool/collect.dart --resume` | Continues an interrupted collection |
| `dart run tool/collect.dart --rebuild` | Rewrites the index from the saved state — no network, seconds |
| `dart run tool/fetch_icons.dart` | Downloads class and item icons named by the index; skips what is already on disk |
| `dart run tool/build_fixture_index.dart` | Builds an index from the saved fixtures — no network, for working on the screen |
| `python3 tool/mapa/pagina.py` | Rebuilds both pages of `web/guerras/` from the map's SVG and the models in `tool/mapa/` |
| `gh workflow run publish.yml` | Collects and publishes now, when the schedule has gone quiet |
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
│   ├── di/          # GetIt, by hand
│   ├── result/      # Result<T>, AppFailure
│   └── theme/       # PWColors, PWTheme
├── market/          # the index model — the only thing both programs share
├── collector/       # listing_parser.dart, detail_parser.dart — pure Dart
├── features/home/
│   ├── data/        # VisitRepository, VisitMemory (conditional import)
│   ├── domain/      # the menu, the visit label
│   └── ui/          # HomeView, VisitCounterViewModel, widgets/
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

### The one server

Everything above is static. The exceptions are the visit counter in the footer,
which a static site cannot compute, and the territory map's owners, which
change weekly and must not cost a deploy. Both live in a Supabase project
called `portal-pw` (`yadfbwsolmkcaylbxviw`, São Paulo).

Four tables and a view, and **the two halves are opposite on purpose**, which is the part
to read before changing either.

#### The counter: RLS with no policy

`visit_days (day, hits)`, plus two functions.
The publishable key is compiled into every visitor's browser and there is no
hiding it, so the table — not the key — is what holds the line: RLS is on with
**no policy at all**, which denies the anon role every direct read, insert and
delete. The two `security definer` functions are the only door, and they are
granted `execute` deliberately:

- `register_visit()` — adds one to today, returns the running total
- `visit_total()` — returns the total, changes nothing

Both were probed with curl before shipping; a direct insert answers `42501`.
The Supabase linter reports five warnings about exactly this arrangement
(`rls_enabled_no_policy`, and `anon`/`authenticated` executing definer
functions). They are the design, not findings — it cannot tell an intentional
public endpoint from an accident. Do not "fix" them by adding a policy.

A day is Brazil's day, in both places: the SQL uses
`now() at time zone 'America/Sao_Paulo'` and `VisitRepository._today()`
subtracts three hours from UTC. If one is ever changed, change both, or a
browser will ask `visit_total` for a day the server has not opened yet.

Nothing prevents someone calling `register_visit` in a loop. On a static site
there is no session and no server to rate-limit at, and the cost of being wrong
is a wrong number in a footer, so it is accepted; `visit_days` at least keeps
the damage to one dated row.

#### The map: RLS with a read policy, on purpose

`territorios (numero, nome, capital, gold, guilda, em_guerra, comentario,
comentario_por, resumo, + three dates)`, `guildas (nome, cor, brasao)` and
`streamers (territorio, nome, url, ordem)` are the other case, and copying the
counter's arrangement onto them would be wrong. Here the rows **are** the page's content, so both
carry `for select to anon, authenticated using (true)` and an explicit
`grant select`. What stays shut is writing: no insert, update or delete policy
exists, so the anon role changes nothing and updating a conquest is editing a
row in the dashboard — no build, no CI, no deploy.

Probed with curl before shipping, and the probe has a trap worth remembering:
an anon `PATCH` or `DELETE` answers **204, not 403**, because RLS filters the
row out rather than refusing the verb, and PostgREST reports zero rows changed
as success. Believe the follow-up `select`, not the status code — the row was
read back intact and the count was still 52.

`atualizado_em` is maintained by a trigger that fires **only when `guilda`
actually changes**, so it dates the conquest and not the last time somebody
touched the table. The page shows that date, and shows it only when at least
one territory has an owner: on the day the table was created every row was
"updated today" while nothing had been conquered. `texto_em` is the same
trigger for `texto`, and it is a second column rather than a reuse of the
first because a corrected comma is not a conquest.

**`public.mapa` is a view, and it exists to answer one question cheaply.**
The map page needs to know which territories are worth clicking — that is
`tem_ficha` — and computing it in the browser would mean downloading the
comment and the summary of all 52 just to find out which are empty: paying for
the whole text in order to show none of it. The view carries
`security_invoker = true`, without which a view ignores RLS and becomes the
back door to the tables it reads.

`tem_ficha` must agree exactly with what the ficha will render, and the first
version did not: it counted a territory's streamers whether or not there was a
war, while the page only lists them *during* one. A territory with a streamer
and no war was therefore clickable and opened an empty page — precisely the
defect the rule exists to prevent. When a section's visibility gains a
condition, the flag gains the same one.

`streamers.url` becomes an `href`, and it is checked **twice on purpose**. The
table refuses anything that is not `http(s)`, and the page checks the scheme
again before rendering — otherwise the protection lives in one system and the
risk in the other, and dropping the constraint would silently open the hole.
Escaping does not help here: `javascript:alert(1)` contains none of the
characters an HTML escaper replaces, so it would travel intact into the `href`.
`enderecoWeb()` parses with `new URL` and keeps only `http:`/`https:`, which
also turns away `data:`, `vbscript:`, `file:`, leading whitespace and mixed
case. A streamer that fails is dropped rather than pointed at `#`: a dead link
promises a broadcast that does not exist.

`guildas.brasao` holds a **file name**, not an image. The art lives in
`web/guerras/icones/` and ships in the deploy; the row says which file to use.
So changing a guild's crest stays a dashboard edit and only *adding* new art
costs a commit — the right frequency, since a guild is born far less often
than a territory changes hands. A missing file leaves the territory with its
colour and no symbol, never a broken box.

**`comentario` and `resumo` are written in the dashboard and rendered in the
browser, so they are escaped and then given back a three-item vocabulary** —
paragraph, `**bold**`, `[text](url)`. Accepting raw HTML there would hand
anyone who can write to those columns a script tag on the page. Probed with
`<img onerror>` and `<script>` in both: they come out as visible text, the
title stays put, and no element is created.

A single newline collapses to a space and only a blank line starts a
paragraph — markdown's rule, and not the obvious `<br>`. Text pasted out of
Discord arrives hard-wrapped at that window's width, and `<br>` reproduced
those breaks as a staircase in a 760 px column.

They are two columns and not one because they are two voices: the owner
talking, and the account of what happened. Merged, a reader cannot tell which
sentence comes from the interested party — which is why the page also quotes
the comment and signs it.

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
- **`schedule` is best effort, and on 2026-08-29 it was hours late, not
  minutes.** The workflow asked for `*/20` and never once got twenty minutes:
  measured over 26–29/08, the gap between scheduled runs grew from ~45 minutes
  to two hours to ten, with one stretch of **12h15 without a run**. Nothing
  failed and nothing was cancelled — GitHub simply did not fire it, and the
  site sat five hours stale before anyone noticed.

  What it is **not**: the repository is public, so Actions minutes are
  unlimited; the workflow is `active`; the concurrency group cancels nothing
  (a cancelled run would show as cancelled, and none did). It is GitHub
  shedding load, and a busier cron is the first thing it sheds.

  The cron now asks for thirty minutes at `:07` and `:37`, off the top of the
  hour that GitHub names as its worst window. **Neither change is a
  guarantee.** If the gaps stay in hours, the fix is not in that file — it is
  an external cron calling `workflow_dispatch`, and the natural home is a
  Cloudflare Worker, since the site is already behind Cloudflare and the token
  would stay in the same hands as the domain.

  **The clock is Cloudflare's now**, and the measurement settles it. Deployed
  on 2026-08-29, the Worker in `tool/cron/` fired at `08:07:49` and `08:37:49`
  — thirty minutes apart to the second, the same 49 s of lag both times, which
  is what a real scheduler looks like. Against GitHub's own median of 49 min
  and worst case of 12h14 that morning.

  Two things that only showed up on the way in, both in `tool/cron/LEIA-ME.md`:
  the account needs a `workers.dev` subdomain to exist before Cloudflare will
  accept **any** trigger, cron included and `workers_dev = false`
  notwithstanding (error `10063`, fixable by one API call and no dashboard);
  and the fine-grained token expires, after which the Worker takes a 401 and
  the site stops updating **silently** — the same symptom, a different cause,
  and the first place to look.

  GitHub's `schedule` stays in the workflow as a slow fallback, and
  `gh workflow run publish.yml` is still the manual push.
- **A failed deploy is usually GitHub, and `gh run rerun --failed` makes it
  worse.** On 2026-08-17 the collect, analyze, test and build steps all passed
  and `actions/deploy-pages` answered **503 — "No server is currently available"**;
  `githubstatus.com` was reporting a major outage on Actions and API Requests.
  Re-running only the failed jobs uploaded a *second* artifact named
  `github-pages`, and the next attempt died on
  `Multiple artifacts named "github-pages" were unexpectedly found`. The clean
  move is a fresh run — `gh workflow run publish.yml` — which starts with an
  empty artifact slate. Check the status page before assuming the repository
  broke something.

- **A deploy can land and the site still serve the old bundle for ten
  minutes.** Cloudflare's *edge* cache is separate from the browser TTL that
  "Respect existing headers" governs: after a successful deploy the asset the
  build just added answered 200 while `main.dart.js` still came back
  `cf-cache-status: HIT` with an `age` under 600 and the previous
  `last-modified`. It expires on its own. The way to tell "still propagating"
  from "actually broken" is to compare `md5` of the served bundle against
  `build/web/main.dart.js`, not to look at the page.

- **Never write a test that hits the live site.** It fails for reasons that have
  nothing to do with the code, and it earns the block above. The fixtures in
  `test/fixtures/` are the site, as far as the suite is concerned.
- **The same trap catches the cards, and it caught them.** The inventory has a
  `cards` panel holding the whole collection — 35 on one character, 60 on
  another. `<h4>Cartas equipadas</h4>` holds the six that are worn, one per
  type (Destruidor, Batalha, Durabilidade, Alma Primordial, Vida Primordial,
  Longevidade). Only the six matter; a combo is those six belonging to one set.
- **A card's combo is not on the page, and the tooltip pretends otherwise.**
  Proven to the end on 2026-08-28: **Hokka**, whose set the player names as
  *Senhor de Todas as Feras*, prints `Seis Soberanos da Chama da Vela (6)` —
  the same line every S, A and B card prints, 1142 times across fourteen
  pages. The `(6)` is not that card's set size; it is part of a fixed string.
  The game client shows the set in each card's description; this site does not,
  and the item database has no card category to ask.

  Every S card prints `Seis Soberanos da Chama da Vela (6)`, including on a
  character wearing thirty-four distinct S cards — a six-card set cannot hold
  thirty-four, so the line identifies nothing. The item database has no card
  category either. `lib/market/card_combos.dart` is hand-written, and
  `test/combo_test.dart` pins every id in it against the collected market
  because an invented id yields a filter that matches nobody, and "nobody has
  this combo" is a believable answer.
- **A combo is two, four or six cards — six was our sample, not the game.**
  The six slots hold one six, or a four and a two, or three twos. The table
  demanded six until 2026-08-28 purely because the only two known combos had
  six; `isComplete` now accepts the three real sizes. The wiki also kills the
  companion assumption: *"é normal existir combos com cartas de diferentes
  Ranks"*, so nothing may depend on a combo being of one rarity, however true
  that happens to be of all eleven.

  With eleven entries a new mistake became possible that two could not make —
  a card in two combos — so `combo_test` now forbids it.
- **Naming the combos took five sources, and the market arbitrated between
  them.** PWpedia's card list is the only published source that names the sets
  and gives their members; a Trivia PW article lists which cards pair up
  without naming the pairs; the player supplied the Portuguese; frequency
  confirmed membership; and id blocks framed the search.

  Two traps came out of it. **Type cannot be the join key with PWpedia** — it
  is PWI data and this is a 1.8.7 build: Tsen is Vida Primordial here and
  *Soulprime* there, Fen is Longevidade here and *Lifeprime* there. Match by
  name. And **where the article and the market disagreed, the market won**: the
  article pairs *Cidade das Espadas* with *Cidade do Dragão*, and no character
  in the market wears those two together, while Cidade Universal with Cidade do
  Dragão is the commonest pair there is — and is the player's *Observador do
  Mundo*.

  Card art does not help here either: `41801` and `41826` serve the same file
  byte for byte, so a dropdown of combos has to carry the weight in the name.
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
- **The inventory JSON is the wrong source for equipment and the right one for
  counting, and the difference is not a matter of taste.** The same
  `data-item` attributes that must never say what is *worn* — no slot number,
  31 entries where 14 are worn, spares included — are the only place that says
  what a character *owns*, with a `count` per stack. `parseInventory` reads
  every one of them on the page: 311 stacks over 292 distinct ids on the
  fixture, because a stack in the bag and another in the bank are the same
  item and have to be summed. The paper doll stays the only source for the
  fourteen worn pieces.

  Two things came off the same JSON while it was open. `require_level` is
  60/80/100/105 and joins by item id — and the fixture's weapon requires
  **100, not 105**, which is worth knowing before writing that expectation
  from memory. `weapon_level` is 17 for every common endgame weapon including
  one that gives no attack level, so it is a crafting tier, not a rank; it is
  stored raw and nothing filters on it.
- **The celestial realm's order came from the player, and the page's own order
  is a trap.** `Reino Celestial` sits on the character sheet beside `Classe`
  and `Sexo` — the same three-row list `parseSex` reads — and prints
  `Céu Ápice VIII`. The ten realms also appear as anecdote chapters, listed in
  a **completely different sequence**, and deriving the scale from that would
  have ordered the market wrongly with nothing on screen to say so. The true
  order is `celestialTiers`; each realm has ten steps, so the scale is a
  hundred rungs and `CelestialRealm.ordinal` flattens it to one number.

  Matching is by the distinctive word — `Miragem`, `Astral` — never the whole
  phrase: eight of the ten have never been seen on a real sheet, so
  `Céu da Miragem` against `Céu de Miragem` would drop a realm out of every
  ordering in silence. The collector prints any realm the scale cannot place,
  so an unforeseen spelling is reported on the first run.
- **God and Evil are not a field; they are a skill's name.** The sheet has no
  row for the path — `Sagrado` and `Demoníaco` appear only as item names — but
  **Evil has `Erupção Demoníaca` and God has `Erupção Celestial`**, which is
  the player's own test and the one the parser uses. The page carries a second
  signal that agrees: path skills are prefixed `●`/`Φ` for God and `○`/`Ω` for
  Evil, the God ones also carrying the CSS class `--sage`. Across fifteen
  pages the two agreed every time, and the eruption is what is pinned, because
  a name the game shows outlives a class name a redesign can rewrite.

  Nobody mixes: fourteen of fifteen were wholly one or the other, and the
  fifteenth was mid-conversion with the path already decided. A character with
  neither eruption is **unknown**, never God by omission.

  Read it through the parser, not over the source: the page writes
  `Erup&ccedil;&atilde;o`, so `contains` on the raw HTML finds nothing and
  reports the whole market as pathless.
- **A rune is identified by its label and drawn by its id, and both matter.**
  Six slots is common, nine exists, and each slot pairs a rune with the skill
  it empowers. The level comes in two spellings on the same page — `Nv. 6` and
  `Nível 8` — and reading only the first drops every level 8, which is the
  band anyone filtering on runes cares about.

  The same rune has two item ids: `Áurea 5` is both `52179` and `200359`,
  serving byte-identical art. So `MarketIndex.runes` maps id to kind, and every
  comparison goes through it — matching on ids would count one rune as two.
  The art is worth fetching: unlike the pet eggs, each colour **and each level**
  draws differently, so the strip on the card is read before it is counted.

  *At least one rune of level 7+* took 93% of the market's dearest characters —
  a filter that leaves the market on screen teaches nothing. Three of them
  halves it, which is why the control asks for a quantity and offers no level
  below 7.
- **A pet is found by its id, because its name belongs to its owner — the
  exact reverse of the counted items, in the same table.** `38587` prints as
  *Ovo de Harpia* on three characters and as *GabirÚ* on a fourth, and
  `item_name`, `name` and `title` in the JSON all carry the nickname. Filtering
  by name would therefore miss precisely the people who own one, since naming
  the pet is what you do when you have it. The species does survive, on a line
  of the tooltip the JSON does not have — `Espécie: Ovo de Harpia` — but the id
  says the same thing and is already in the state, so the id is what
  `countedItemIds` holds.

  `Hércules` is the community's word; the game calls the species *Ovo Mascote
  Gigante Celestial*, and the Feiticeira's own Hero Saga names the pet "Gigante
  Celestial Hércules", which is what ties them together. Neither id was
  guessed — both were read off pages of characters on sale, and
  `test/fixtures/detail_330640.html` is a Feiticeira carrying **both, both
  renamed**, kept for exactly that reason.
- **Every pet egg shares one picture, so art beside a pet name lies.** `37905`
  and `38587` serve the same 32 px file, byte for byte — in the game the art
  belongs to the creature and the item is the egg it comes out of, and none of
  the two hosts publishes the creature (`/item/`, `/items/`, `/mob/`, `/pet/`
  and `pw_pets/` all answer 404). Two identical eggs beside two different names
  promise a difference that is not there, which is the same defect as naming an
  item without its number. The egg sits on the section header, where it means
  *mascotes* and is true; the rows carry names alone.
- **Presence filters; quantity marks.** The pets are a plain checklist that
  narrows the market, and not the counted items' *mark to show, type to
  filter*, because a pet is a yes or a no: there is no number to compare across
  characters, so a "show it" mark would add nothing that passing the filter
  does not already say. Two controls of the same shape mean different things
  one section apart, and that is the reason — quantity is worth showing, mere
  presence is not.

  It also needs no rule about classes: only the Feiticeira has combat pets, so
  asking for one narrows to her by itself.
- **A counted item is found by name, and the name is the identity — which does
  not contradict "the item name lies".** That rule is about worn equipment,
  where three weapons share the word *Dilacerador* and give 30, 40 and 70. For
  a consumable being counted there is no such ambiguity, and a name is the
  only thing that can find an item whose id nobody knows: the `Chave da
  Sorte`'s id was unavailable — no character in the fixture carries one and the
  item database wants a game-context cookie before it will search — so a table
  of ids would have had to guess, and a guessed id yields a filter that
  matches nobody while looking like an answer.

  `countedItemNames` is the list and `confirmedCountedItems` is the half a real
  page has been seen to print. The split is the deploy: a confirmed name that
  stops resolving is a bug and turns the suite red, while an unconfirmed one
  finding nothing is a fact about a market that changes every twenty minutes,
  and freezing the site for a sale would be the wrong trade. The collector
  prints one line per counted name at the end of a run, and that is where the
  question "does the Chave exist?" gets answered.
- **The relics ended with no filter at all, and that was the right end.** The
  *pelo menos N* field went away on the player's call: a relic count is a
  number to compare, not a bar to clear, and *Mais relíquias* already sorts by
  exactly what is marked. The whole `minimumOwned` half went with it — query
  field, `tem=` link parameter, view-model setter and matcher branch — leaving
  marking as the only relic concept.

  It also removed the reason the two ever needed reconciling:
- **Marking is not filtering, and they were one control until they had to be
  two.** A counted item answers two different questions: *how many does each of
  these carry* and *only show me who carries five*. While the number field was
  the only control, the first question could not be asked — seeing anybody's
  relic count meant demanding at least one and losing everyone else from the
  results. So the item is marked first (`SearchQuery.shownOwned`, a checkbox,
  prints the number on every card) and the minimum appears only after that.

  `shownOwned` is deliberately outside `isEmpty` and outside the count of
  filters in force, for the same reason `order` is: it is how the list is read,
  not something asked of the market. A minimum implies its own item is marked —
  a card that will not say why a character passed is worse than one that says
  nothing — and unmarking takes the minimum with it, because a filter in force
  on an item the card no longer names is a result nobody can explain.
- **The anecdotes have the same checkbox, and unmarking has to undo whatever
  was forcing the line.** Three things put the number on a card — the mark, a
  minimum, and ordering by it — so the box is ticked by `showsAnecdotes` rather
  than by its own field, and unticking it clears the minimum and drops the
  order back to cheapest. Without that the box comes unticked with the number
  still on screen, which is a control that visibly does not control what it
  names.

  In a link it rides in `mostra`, whose value `anedotas` is reserved for it —
  `mostra` means "what the card prints", and a second parameter for the same
  idea would be worse. Nothing can collide: every counted item is named
  `Relíquia …` or `Chave …`.
- **Ordering by something counts as asking for it.** The card's rule is that
  it states what answered the question, and a sort is a question: with the list
  ordered by anecdotes, the count is *why* a card sits where it does, so the
  line is drawn without any minimum being set. Requiring a filter as well —
  only to see the number — would throw away every result below the cut. That is
  `SearchQuery.showsAnecdotes`, and the grid that sizes the cards reads the
  same getter, because a card taller than its tile is clipped and one shorter
  floats in a hole.

  The line carries the share as well as the pair: `1265 de 2756 · 46%`. The
  total is the same number for everybody, so the fraction is the only part that
  separates one character from another, and nobody divides in their head while
  scanning forty cards.
- **The two new orders read the character's page, and one of them needs the
  marks to mean anything.** *Mais anedotas* is straightforward. *Mais
  relíquias* adds up the counted items that are **marked** — the market has
  three of them and an order that picked one on the visitor's behalf would be
  ordering by a question nobody asked. So it is offered only while something is
  marked, and unmarking the last one puts the order back to cheapest rather
  than leaving the list sorted by a number that is the same for everybody.

  Both tie constantly — hundreds of characters carry none — so both fall back
  to the price, which is the question the default order exists to answer.

  `_OrderPicker` always offers whatever is in force, even when it makes no
  sense here: a `DropdownButton` throws when its value is absent from its own
  items, and `ordem=mostOwned` in a month-old link with nothing marked is
  exactly how that happens. Same trap the class and item dropdowns already
  guard against, arriving by a different door.
- **`counts` carries an explicit zero, and that costs a second pass in
  `IndexBuilder.build`.** "Carries none of them" and "the page was never read"
  have to be different on screen: the first prints `carrega 0` and the second
  prints no line at all. They were the same empty map until the zeros were
  filled in, and they cannot be filled on the way in — a counted name is
  resolved the first time the crawl meets it, so a character read before anyone
  was seen carrying the relic does not yet know the id to write a zero under.
  `_readCounts` holds the same map objects the characters hold, so finishing
  them there finishes theirs.
- **The collector's state file is stamped, and an unstamped entry is refetched
  rather than adapted.** `CollectedPage.version` is what makes a re-collection
  happen by itself: an entry written before the anecdotes existed cannot be
  patched into one that has them, so it is dropped on load and its page is
  fetched again. The stamp is deliberate rather than "is the anecdotes key
  missing?" — a page may legitimately have no anecdote panel, and that
  character would then be re-fetched on every run for ever.

  It has one consequence worth guarding, and it is guarded: right after such a
  change `--rebuild` has nothing left to build from, and writing the index
  anyway would replace a good market with an empty one — which reads exactly
  like everybody having left. It refuses and says to run `--resume` instead.
- **Names in the state file live in one table, not in every character.** The
  same three hundred item names repeat across 950 inventories; written out per
  character they would be most of the file and none of the information.
  `itemNamesOf` builds the table on save and `CollectedPage.fromJson` takes it
  back on load — so the two halves have to be written together, and the round
  trip is pinned by `collected_page_test`.
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
- **An attribute's id is a position, and the position is not stable.**
  `IndexBuilder` numbers attributes with `putIfAbsent(name, () => length)` — in
  the order the crawl happens to meet them — so two collections a week apart
  disagree about what attribute `0` is. Nothing inside one index notices;
  everything is consistent with itself. What it breaks is anything that outlives
  a collection, and the first such thing was the **shared link**: `c=10~0~70`
  opened filtering `Feitiço da Purificação` where it had meant `Nível de Ataque`,
  with the right count on screen and no error anywhere.

  So `search_query_url.dart` writes the attribute **by name** and resolves it
  against the index on arrival, and a name this collection no longer has drops
  its criterion rather than falling back to attribute zero. Everything else in a
  query was already stable — class names, cultivations, combo names, game item
  ids. The attribute was the one hole, and any future store of a query outside
  the app inherits the same duty.

  The link's separator is `~` and not `:` for a reason worth keeping: `Uri`
  escapes a colon and escapes the percent signs of a hand-encoded name, so
  `Nível de Ataque` came out `%3AN%25C3%25ADvel%2520de%2520Ataque%3A` — correct,
  and gibberish to the person deciding whether to click.

- **The 70 weapon is almost always rank 4 and refined to +10 — 204 of 205.**
  Which kills the obvious preset: `refino +10` returns 597 of 830 and
  `rank 4 na arma` 594, because they ask "do you refine?", which nearly everyone
  does, rather than "do you have the weapon", which is the question. A chip that
  leaves three quarters of the market on screen teaches nothing. `presets_test`
  therefore demands each preset cut the market **at least in half**; the first
  bar, "narrows at all", passed both bad ones.

- **In `flutter_test` every glyph is a square of the font size.** So a chip
  reading `Arma de 70 até 500 TCC` measures 286 px in a test and about 150 in a
  browser. Two consequences, both met the hard way: a horizontally scrolling row
  builds fewer items than it will in the app, so `find.text` misses one that is
  plainly on screen in real life; and a `Row` that fits everywhere overflows in
  a test. Widen `tester.view.physicalSize` or assert on something else — but
  check which of the two it is before "fixing" a layout that was never broken.

- **Marcellus draws Roman figures, so no number may use it.** Its `1` has no
  flag and its `0` is barely an `O`: `150 TCC` reads `I5O TCC`. The display face
  is for the headline and tool names only, and `PWTheme.display` says so. Every
  price, count and attribute stays on Roboto — they are numbers somebody is
  deciding money on. Accented capitals were checked against the file before
  adopting it (Á À Â Ã É Ê Í Ó Ô Õ Ú Ü Ç all draw).

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
- **Routing belongs to `MaterialApp`, never to a `Navigator` under it.** A
  nested Navigator moves between screens perfectly and never touches the
  address bar: the filter had no link of its own and the browser's back button
  left the site instead of going home. Both looked fine in a screenshot. Check
  a navigation change by reading `location.href`, not by looking at the page.

  Flutter web's default strategy writes the route after a `#`, and that is
  wanted here — GitHub Pages serves files, so `/filtro` would 404 while
  `/#/filtro` is the same `index.html`. Do not call `usePathUrlStrategy`
  without adding a 404 fallback first.
- **`<use>` renders into a shadow tree, so your CSS never reaches inside it.**
  The war marker on the map is a circle and two strokes; `.selo-guerra circle
  { fill: var(--guerra) }` was in the stylesheet and the circle still came out
  black, because a `<use>` of a `<symbol>` clones its content into a shadow
  tree that outside selectors cannot cross. Only inherited properties get in,
  and `fill` alone would have painted the strokes too. The fix is a plain `<g>`
  template plus `cloneNode(true)` — real nodes in the document, where the
  selector applies — positioned with `transform: translate() scale()`.

- **The top of a shape's bounding box is usually not inside the shape.**
  Anchoring a crest at `ymin` put a third of them in the neighbour's territory:
  the 52 outlines are irregular and several start in a spike. `ancoras.py`
  scans by scanline instead, and it needed two more corrections that are worth
  knowing before writing anything similar. Stopping at the *first* height that
  fits is too early — territory 7 only has width in its left tip at y=65 and
  opens up two pixels lower, so the search collects the candidates in the top
  band and takes the one nearest the territory's centre. And the number is
  already there: at 23 px, **34 of the 52** crests landed on top of their own
  number, so the crest is sized by the band *above* the number, and in the
  eight tightest territories the number yields 1–9 px. That position was never
  sacred — it came from "deepest point of the shape", not from the game.

- **Judge layout on the published site, not on `localhost`.** On this machine
  every page served from `localhost` renders shifted right, with a band of
  empty space on the left. The same build on GitHub Pages, in the same Chrome,
  is correct. It is environmental and none of it is the app's: a forty-line
  static HTML page with a CSS-centred box, no Flutter at all, is shifted too.
  Six different ports made no difference, and page zoom was 100%.

  So: iterate locally for behaviour, and push before judging anything visual.
  The CI round trip is about three minutes.

  **The technique that ended a long wrong hunt is worth keeping.** Screenshots
  arrive resized, which silently invalidates every pixel measurement taken from
  them — three conclusions were drawn and discarded that way. Instead, draw a
  line at `MediaQuery.width / 2` inside the app and screenshot that. It lives
  in the same coordinate system as everything else, so it scales with the image
  and survives any rescaling. It ran through the middle of the logo, which
  proved Flutter was centring correctly and moved the search off the layout in
  one step. Reach for it first.
- **A rebuilt Flutter web app keeps serving the previous bundle, and it looks
  exactly like a change that did not compile.** The file on disk is new, the
  md5 served matches the md5 on disk, and the browser still runs yesterday's
  code. An hour went into a responsive layout that had been correct the whole
  time. **Serve the build on a port you have not used before**, and when a
  change refuses to appear, prove it with a loud temporary marker (an app bar
  in `PWColors.danger`) before touching the code again.

  **It is not the service worker.** That was the first diagnosis here and it
  was wrong. Since Flutter 3.35 the default `--pwa-strategy` emits a 784-byte
  worker whose entire body unregisters itself and re-navigates every client; it
  has no `fetch` handler and caches nothing. Verified on 3.44.8 and against the
  published site. So do not reach for `--pwa-strategy=none` — it emits an empty
  file, which is strictly worse, because it drops the cleanup that evicts a
  legacy worker from a returning visitor's browser.

  What actually goes stale is the plain HTTP cache — and **it is four hours,
  not ten minutes.** GitHub Pages sends `cache-control: max-age=600` on every
  file and gives no way to change a header, but that is only what the origin
  says. Measured on the live site on 2026-08-17, right after a deploy:
  `index.html` comes back `max-age=600`, and `flutter_bootstrap.js` and
  `main.dart.js` come back **`max-age=14400`**. Cloudflare's Browser Cache TTL
  defaults to four hours and overrides the origin unless it is set to "Respect
  existing headers".

  It matters more than it looks, because `flutter_bootstrap.js` asks for
  `"main.dart.js"` with **no version query** — checked in the served file. So
  the URL never changes between builds, and a visitor who opened the site in
  the last four hours runs the old app with the new data: the index is fetched
  with `?t=<millis>` and is always fresh, so the page shows today's numbers in
  yesterday's interface, which looks like a deploy that half worked. It is how
  a shipped change was first judged missing on 2026-08-17; the bundle on the
  server was already correct, byte for byte.

  **Fixed on 2026-08-17**, and the fix is one setting: Cloudflare → Caching →
  Configuration → Browser Cache TTL → *Respect existing headers*. Measured
  afterwards, `index.html`, `flutter_bootstrap.js`, `main.dart.js`, the assets
  and the guides' CSS all come back `max-age=600`. If a deploy ever seems not
  to arrive again, measure that header first — if it is back at 14400, the
  setting was changed, and nothing in this repository can cause that.

  **The md5 comparison does not work on a page that contains a `mailto:`.**
  Cloudflare's email obfuscation rewrites the address into
  `/cdn-cgi/l/email-protection#<token>` and injects a decoder script — and the
  token differs on every response, so the served bytes never match the build
  and two consecutive requests do not match each other. On `/guerras/` that
  read as "the deploy did not arrive" while the page was already correct.
  Diff the two files instead of hashing them, or grep for the specific thing
  the deploy was supposed to add.

  To check a deploy, clear the browser cache rather than reloading: a
  cache-buster on the page URL does not touch the scripts, which is what made
  the bundle look stale while it was already correct on the server. The index JSON
  escapes this because `IndexRepository` appends `?t=<millis>`; that
  cache-buster is why the data is never the stale part, and it is why it must
  stay.

  **That trick does not transfer to Supabase, and it fails loudly.** PostgREST
  reads every query parameter it does not recognise as a filter on a column of
  that name, so `?select=...&t=1755...` answers `PGRST100`,
  *"failed to parse filter"* — no rows, no map. The equivalent there is
  `fetch(url, {cache: 'no-store'})`, which is what `web/guerras/index.html`
  uses. Supabase sends no `cache-control` at all on a REST read, so something
  has to say it.

  Since the site moved behind Cloudflare this is fixable after all — a cache
  rule can override the browser TTL that GitHub sends. If the ten minutes ever
  becomes a real complaint, that is where the fix lives, not in the Flutter
  build.
- **The custom domain and `--base-href` are one change, not two, and between
  them the site is broken.** `portalpw.net` serves from the root, so the build
  takes the default `/`; on `duhfadel.github.io/pw-market-filter/` it needed
  `--base-href "/pw-market-filter/"`. Deploy either half alone and every asset
  404s while `index.html` still loads, which looks like a broken build rather
  than a misconfigured path. Order: DNS first, then the domain in the Pages
  settings, then the flag — and if the custom domain is ever dropped, the flag
  has to come back in the same breath.

  **Cloudflare's proxy has to be off while the certificate is issued, and on
  afterwards.** Orange cloud and GitHub cannot validate the domain, so it never
  issues one and the site answers with an HTTPS error that says nothing about
  DNS. Grey cloud — "DNS only" — until the padlock works, then orange.

  It is orange now, with SSL/TLS on **Full**. Not Flexible, which redirects in
  a loop forever; and deliberately not Full (strict), which would validate
  GitHub's origin certificate and so would take the site down if a renewal ever
  failed behind the proxy — the one failure mode this arrangement is known to
  have. On Full, visitors keep Cloudflare's edge certificate either way.

  What the proxy bought, beyond the padlock: the site is served from Brazil
  instead of `x-github-edge-region: fra`, the browser cache TTL becomes
  changeable, and Web Analytics is injected at the edge, which is why there is
  no beacon script in `web/index.html` and should not be one.
- **When the app looks the wrong size, measure `flutter-view`, not the
  screenshot.** Everything is drawn into a canvas, so the DOM has nothing to
  inspect and the eye has nothing to check against — and screenshots arrive
  resized, which is the trap recorded above. The one number that settles it is

  ```js
  document.querySelector('flutter-view').getBoundingClientRect().width
  ```

  against `window.innerWidth`. A ratio of 1 means the layout is right and the
  problem is elsewhere; anything else is the engine sizing its view wrong, and
  no amount of layout code will fix it.

  It earned its place immediately. The filter looked broken at 390 px — text at
  twice its size, cards running off the right edge — and the ratio said 2.00:
  a 780 px view inside a 390 px window. But the layout was never wrong.
  **Nudging the viewport by one pixel, 390 to 391, takes the ratio straight
  back to 1.00**, and no layout bug is fixed by one pixel. It is the engine
  losing a resize race in Playwright's emulation, where the viewport shrinks to
  phone size while the real window stays 1422 wide.

  So the doubling is a property of the harness, not of the app, and the test
  for it is the nudge. What it cannot tell you is how a real phone behaves,
  which loads once at its own size and is never resized — that still needs a
  real phone.
- **A `catch` that exists to keep a feature quiet will also keep its bugs
  quiet.** `VisitRepository` swallows exceptions on purpose: a counter must
  never take the page down. `shared_preferences` was storing the "already
  counted today" flag, and on the web build it wrote to neither `localStorage`
  nor IndexedDB — it threw `MissingPluginException`, which is an `Exception`,
  which the catch absorbed. The counter silently counted every reload and the
  test suite was green, because the tests used the package's own in-memory
  mock, which works perfectly.

  Two things came out of it. `localStorage` is now reached directly through
  `package:web`, behind the same conditional-import split the collector uses
  for `dart:io` (`visit_memory_stub.dart` for the VM, `visit_memory_web.dart`
  for the browser) — fourteen transitive packages to reach a one-line browser
  API was a bad trade even while it worked. And **a storage layer is not proved
  by a passing test**: open the built page and read `localStorage` in the
  console, or query the table and reload twice.
- **The card was made calmer by taking things away, and the one thing added
  back was the art.** It had gold on the price, red or blue on the path, red on
  the item name, teal on the attribute and six saturated rune icons — nothing
  led, so everything competed. What fixed it: the rune strip lost its heading
  and its row of numbers (the level rides the corner of each icon); the item's
  grade became a dot instead of colouring the whole name; the numbers moved
  into one right-hand column; and the class portrait went from 38 px to 52,
  because it is the best art the game gives and it was a thumbnail.

  Two of those had to be corrected against a mockup before they shipped.
  Putting the realm under the portrait broke `Céu Majestoso V` into three tiny
  lines — worse than the line it replaced — so the realm stayed in the right
  column. And the path badge beside the nickname stole enough width to
  ellipsize every name in the grid; it lives on the stat line now, where it
  sits with the other facts about the person instead of competing with the two
  the card exists for.

  **A `Spacer` beside a `Flexible` splits the free space with it.** That is how
  the badge crushed the nicknames to `NI…` — the name needs `Expanded` and no
  Spacer at all.

  The rune strip is a `FittedBox`, not a `Row` that hopes: ten runes overflow
  the card, and wrapping to a second line would make one card taller than its
  tile, which a single grid height cannot express.
- **The three class arts have their faces about a fifth of the way down, not
  at the centre.** `Alignment.center` looked right for a year of half-width
  cards, because their art box is tall enough that the crop reaches the face
  anyway. The first full-width card turned the box into a 600×110 letterbox and
  the band landed on the priest's skirt. `Alignment(0, -0.6)` matches where the
  faces actually are. Replacing an image means checking this again — and
  checking it on the *widest* card, which is where a bad crop shows first.
- **At zero results the faceted form forgets what it is asking, and that was a
  dead end.** The exclusion rule below is right, and it has one failure mode:
  when nothing passes, *every* control's scope is empty, so the option lists
  are empty, sections that hide on an empty list disappear, and the price hints
  collapse to `0 — 0`. A weapon could be filtering the market with no weapon
  dropdown anywhere on screen, and the only way out was *limpar tudo*, which
  throws away the parts you wanted to keep.

  **The chips are the fix**, not a decoration: `activeFilters` builds them from
  the query and never from the market, so a filter in force always has a way
  out, one at a time. Marking a relic or the anecdotes gets no chip — it prints
  a number and narrows nothing, the same reason it stays out of `isEmpty`.

  The same emptiness **crashed the panel**, and the path there is ordinary:
  choose a weapon, set a price nobody meets, change class. The class list has
  no items while the value is `Guerreiro`, and `DropdownButton` asserts on a
  value absent from its own items. Every list must therefore carry whatever is
  chosen, whatever the scope says — the guard the order picker already had,
  arriving through a different door.
- **"Does this class wear this piece?" is a question about the game, not about
  the current results.** `setClass` asked it of the filtered scope, so a price
  range narrow enough to exclude every Guerreiro wearing the weapon made the
  empty answer read as *Guerreiro does not wear it* — and the weapon was
  dropped without a word. It asks `allFacets` now. The behaviour it exists for
  is unchanged: changing class still drops what the new class cannot wear.
- **Every control reads its options from the characters that pass every filter
  but its own.** Choose Portal de Nuema and the class list drops from
  seventeen to sixteen — no Paladino wears it — the level range collapses to
  105–105, and the cheapest price becomes 450. A form of independent dropdowns
  offers combinations that return nothing and gives no hint which choice
  emptied the result.

  The exclusion is not an optimisation, it is what makes a choice reversible:
  include a control's own dimension and picking Guerreiro leaves the class list
  offering Guerreiro alone. `SearchQuery.without(FacetDimension)` and
  `SearchReady.facetsFor` are the whole mechanism, and `faceted_test.dart`
  pins both halves — that a choice narrows the others, and that it never
  narrows itself.

  The item slots share one dimension rather than owning fourteen. Narrowing the
  helm list by the chosen weapon is right; letting the helm narrow the weapon
  list too would have each control hiding options because of its siblings.

  One exception: the attribute vocabulary comes from `allFacets`, the whole
  market. An attribute list that shrinks while a minimum is being typed removes
  the very entry that says the attribute exists.
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
