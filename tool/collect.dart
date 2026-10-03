// Collects a Classic PW marketplace into its own `web/market_index*.json`.
//
//   dart run tool/collect.dart                     # pw187, from scratch
//   dart run tool/collect.dart --resume             # continue an interrupted run
//   dart run tool/collect.dart --server pw126       # collect the other version
//   dart run tool/collect.dart --server pw126 --carry-forward
//                                                    # fetch pw126's own
//                                                    # published index and
//                                                    # write it to disk —
//                                                    # no crawl at all
//
// This is the only file allowed to touch the network or the disk. Everything
// it calls lives in `lib/collector/` and is pure Dart, so the tests can run it
// and the web app can share its model.
//
// `--carry-forward` exists for CI alone. One workflow run collects one
// version and deploys the whole site, so the version it did NOT collect has
// to come from what is already live or the deploy would erase that market —
// the index files are gitignored. See `_carryForward` below.
//
// `--server` selects the whole per-version profile, including which parser
// reads the worn items — `lib/collector/servidor.dart`'s `itensEquipados` and
// `sexo` fields. This file never names `parseEquippedItems` or
// `parseEquippedItems126` itself; it only ever calls through `_servidor`, so
// there is exactly one place that decides which page shape to expect.
//
// It is slow on purpose. Four concurrent workers earned an IP block that
// outlived the run by more than twenty minutes, refusing even a single
// request. One at a time, three seconds apart, is the design — not a first
// version to speed up later.

import 'dart:convert';
import 'dart:io';

import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/index_builder.dart';
import 'package:pw_market_filter/collector/listing_parser.dart';
import 'package:pw_market_filter/collector/memoria.dart';
import 'package:pw_market_filter/market/alerta_de_entrada.dart';

import 'avisar_discord.dart';
import 'package:pw_market_filter/collector/servidor.dart';
import 'package:pw_market_filter/market/card_combos.dart';
import 'package:pw_market_filter/market/celestial_realm.dart';
import 'package:pw_market_filter/market/counted_items.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/versoes.dart';

/// The version being collected. `--server <chave>` picks one; `pw187` is the
/// default so an unqualified run keeps its current behaviour. Everything that
/// used to be the two constants `_server`/`_origin` now reads this — see
/// `lib/collector/servidor.dart` for what varies between versions and why the
/// detail URL shape is inverted between them.
late final Servidor _servidor;

/// What the version-chooser door calls each version. Kept here rather than
/// on `Servidor` because it is the one thing about a version that is purely
/// presentation — `Servidor` is addresses and file paths, this is a label.
const _nomesLegiveis = <String, String>{'pw187': '1.8.7', 'pw126': '1.2.6'};
const _userAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';

/// Halved from three seconds when the redirect below was removed. That change
/// cut the requests per character from two to one, so this keeps the sustained
/// rate at the same ~40 per minute that has been running without trouble —
/// the same load, half the wall clock. Do not lower it further without
/// evidence: a block costs an hour, measured.
const _politeDelay = Duration(milliseconds: 1500);
const _blockedPause = Duration(minutes: 5);
const _attemptsPerPage = 4;

/// Twelve tries five minutes apart — an hour of patience. The block measured
/// on 2026-08-09 lasted well over twenty minutes.
const _listingAttempts = 12;

/// Reads `--server <chave>` or `--server=<chave>` out of the argument list.
/// Defaults to `pw187` so an unqualified run keeps today's behaviour.
String _serverArg(List<String> arguments) {
  for (var i = 0; i < arguments.length; i++) {
    final arg = arguments[i];
    if (arg.startsWith('--server=')) return arg.substring('--server='.length);
    if (arg == '--server' && i + 1 < arguments.length) return arguments[i + 1];
  }
  return 'pw187';
}

/// Reads one detail page into a [CollectedPage], through whichever parsers
/// [servidor] names for the worn items and the sex row.
///
/// This is the one seam `main`'s per-character loop calls — pulled out to a
/// public top-level function so a test can prove the 1.2.6 parser is actually
/// wired into the production path, rather than only into its own unit tests.
/// See `test/tool/collect_servidor_test.dart`: it is what caught the parser
/// being built, tested and never called.
///
/// The other seven readers — cards, anecdotes, inventory, realm, path, runes,
/// titles —
/// are not yet per-version: nobody has written a 1.2.6 counterpart, and their
/// 1.8.7 selectors (`.pw187-anecdote-summary`, `.pw187-rune-pair`, …) simply
/// find nothing on a 1.2.6 page, the same way they find nothing on a 1.8.7
/// page that carries none of those panels. That is a gap in scope, not a
/// silent wrong answer — unlike the items, which were the whole point.
CollectedPage collectedPageFrom(Servidor servidor, String page) =>
    CollectedPage(
      items: servidor.itensEquipados(page),
      cards: parseEquippedCards(page),
      sex: servidor.sexo(page),
      anecdotes: parseAnecdotes(page),
      inventory: parseInventory(page),
      realm: parseCelestialRealm(page) ?? '',
      path: parsePath(page) ?? '',
      runes: parseRunes(page),
      titles: parseTitles(page),
    );

Future<void> main(List<String> arguments) async {
  final resume = arguments.contains('--resume');

  // Refused loudly rather than guessed: a typo here would collect against a
  // 404 for forty minutes and write an empty index over a good one.
  try {
    _servidor = Servidor.de(_serverArg(arguments));
  } on ArgumentError catch (e) {
    stderr.writeln('Servidor inválido: ${e.message}');
    exit(1);
  }

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

  // Carries the OTHER version forward into this run's deploy — no crawl, one
  // request to our own CDN. See `_carryForward` for why a failed fetch must
  // abort rather than publish.
  if (arguments.contains('--carry-forward')) {
    await _carryForward(client);
    return;
  }

  // Rewrites the index from what is already on disk. The state file keeps
  // every attribute occurrence, so a change to `attributeRules` costs this
  // instead of a fresh crawl of all 771 pages.
  if (arguments.contains('--rebuild')) {
    client.close();
    _rebuildFromState();
    return;
  }

  try {
    final listing = await _fetchListing(client);
    stdout.writeln('${listing.length} personagens à venda.');

    MarketIndex? publicado;
    try {
      publicado = await _fetchPublishedIndex(client);
    } on PublishedIndexUnavailable catch (e) {
      if (!e.notFound) {
        // Refusing to write beats writing a reset index: a stale index is
        // still correct, and the site keeps serving it while the Worker's
        // retry tries again. A reset index would look exactly like a working
        // one and erase every character's history in the same breath.
        stderr.writeln(
          'Não consegui ler o índice publicado ($e). Não vou escrever um '
          'novo índice agora — isso apagaria a história de preço de todo '
          'mundo. O site continua servindo o último índice bom.',
        );
        exit(1);
      }
      // A 404 here is this version's first-ever collection — there is no
      // history to lose, only none to start. `null` is exactly what
      // `avancarTodos`/`historyFromDe` already read as "nobody has ever been
      // seen", so this is not a special case for them, only for this message.
      stdout.writeln(
        'Nenhum índice publicado para ${_servidor.chave} ainda ($e) — '
        'primeira coleta desta versão, seguindo sem histórico.',
      );
      publicado = null;
    }

    final state = _CollectState.load(_servidor.arquivoDoEstado, resume: resume);
    // Characters that left the market since the last run. Dropping them keeps
    // the state from growing forever and keeps the index describing the market
    // as it is now, not as it once was.
    final delisted = state.pruneTo(listing);
    state.listing = listing;

    final pending = listing
        .where((card) => !state.isDone(card.roleId))
        .toList(growable: false);

    if (state.done.isNotEmpty) {
      stdout.writeln(
        '${state.done.length} já no índice, $delisted saíram do mercado, '
        '${pending.length} a buscar.',
      );
    }
    _reportEstimate(pending.length);

    var blockedPauses = 0;
    for (var i = 0; i < pending.length; i++) {
      final card = pending[i];
      final page = await _fetchDetail(
        client,
        card.roleId,
        onBlocked: () => blockedPauses++,
      );

      if (page == null) {
        state.markFailed(card.roleId);
        stdout.writeln('  ${card.roleId} ${card.name}: falhou');
      } else {
        state.markDone(card.roleId, collectedPageFrom(_servidor, page));
      }
      state.save(_servidor.arquivoDoEstado);

      _reportProgress(i + 1, pending.length, card.name);
      if (i + 1 < pending.length) await Future<void>.delayed(_politeDelay);
    }

    final entradas = _writeIndex(listing, state, publicado: publicado);
    _reportSummary(listing, state, blockedPauses);
    await avisarEntradas(entradas, _servidor.chave);
  } finally {
    client.close(force: true);
  }
}

Future<List<ListingCard>> _fetchListing(HttpClient client) async {
  stdout.writeln('Lendo a lista…');

  // The listing is the first request of a run, so it is also where a block
  // left over from a previous run shows up. Waiting it out beats aborting:
  // the whole point of the run is that it takes a while anyway.
  String? body;
  for (var attempt = 1; attempt <= _listingAttempts; attempt++) {
    body = await _get(client, '${_servidor.origem}/${_servidor.chave}');
    if (body != null) break;
    if (attempt == _listingAttempts) break;
    stdout.writeln(
      '  sem resposta — esperando ${_blockedPause.inMinutes} min '
      '(tentativa $attempt de $_listingAttempts)',
    );
    await Future<void>.delayed(_blockedPause);
  }

  if (body == null) {
    stderr.writeln('Não consegui ler a lista. O site segue bloqueando.');
    exit(1);
  }

  final cards = parseListing(body);
  if (cards.isEmpty) {
    stderr.writeln(
      'A lista veio sem nenhum card. Ou o mercado está vazio, ou o HTML '
      'mudou — rode os testes do parser contra a fixture antes de insistir.',
    );
    exit(1);
  }
  return cards;
}

/// Thrown when the published index could not be read — a non-200 status, a
/// network error, or a body that will not parse.
///
/// **Never confused with a genuine "no history yet".** That is a successful
/// 200 whose own `historyFrom` happens to be `null` — the site's first run
/// with this feature — and [MarketIndex.fromJson] returns it normally.
/// `PublishedIndexUnavailable` is the *other* case, where nothing was read at
/// all, and it must never be treated the same way: `avancarTodos` reads
/// `publicado == null` as "nobody has ever been seen" and would stamp
/// `firstSeen` on every character alive, erasing the market's whole memory in
/// one run. `main` catches this and refuses to write anything — except for
/// [notFound], which is the one flavour it is safe to treat as that same
/// `null`. See [notFound] for why.
class PublishedIndexUnavailable implements Exception {
  const PublishedIndexUnavailable(this.reason, {this.notFound = false});

  final String reason;

  /// True when the request reached the server and it answered 404 — the
  /// *bootstrap* case: this version has never published an index, because
  /// nobody has collected it yet. That is a fact about the world, not an
  /// outage, and it is exactly what `publicado == null` already means
  /// everywhere downstream — `avancarTodos` starts everyone's history today,
  /// `historyFromDe` stamps `historyFrom` to now. Before this field existed,
  /// a 404 here and a 500 there looked identical, and both aborted: the first
  /// `pw126` run could never complete (its own `--carry-forward` for pw187
  /// has no problem, but `main()` fetching pw126's own not-yet-published
  /// index would 404 and exit before writing anything), and the first `pw187`
  /// run after merging this code would 404 on pw126's not-yet-published index
  /// in the carry-forward step and freeze every deploy.
  ///
  /// Any other failure — a different status, a connection error, a body that
  /// will not parse — leaves this `false`, and the caller must still abort:
  /// those are the cases where an index genuinely exists and we simply could
  /// not read it, and writing over it would erase real history.
  final bool notFound;

  @override
  String toString() => reason;
}

/// Turns a fetched status and body into the published index, or throws
/// [PublishedIndexUnavailable] when it cannot.
///
/// Pure — no network, no clock — so this is what a test exercises instead of
/// a live fetch: a 200 with `{"formatVersion": 2, ...}` and no `historyFrom`
/// is the genuine first run and must succeed; a 404 is a bootstrap and throws
/// with [PublishedIndexUnavailable.notFound] set; any other status, or a body
/// `MarketIndex.fromJson` rejects, is an outage and throws without it.
MarketIndex parsePublishedIndex(int statusCode, String body) {
  if (statusCode == 404) {
    throw const PublishedIndexUnavailable(
      'respondeu 404 — esta versão nunca publicou um índice',
      notFound: true,
    );
  }
  if (statusCode != 200) {
    throw PublishedIndexUnavailable('respondeu $statusCode');
  }
  try {
    return MarketIndex.fromJson(jsonDecode(body) as Map<String, dynamic>);
  } catch (e) {
    throw PublishedIndexUnavailable('não deu para interpretar o índice: $e');
  }
}

/// The index the site is currently serving.
///
/// **This is where the memory lives.** One request to our own CDN per run,
/// and the file is served `cf-cache-status: DYNAMIC` — Cloudflare does not
/// cache it at the edge — so what comes back is the real current file rather
/// than a ten-minute-old one. Measured 2026-09-30; if that ever changes, this
/// needs the `?t=<millis>` buster the app already uses.
///
/// A read failure throws [PublishedIndexUnavailable] rather than returning
/// `null`. It used to return `null`, and `--rebuild` and a fetch failure both
/// fed that `null` to `avancarTodos` as if the market had never been seen
/// before — a `--rebuild` after a network hiccup silently erased every
/// character's `firstSeen`, `lowestPrice` and `cuts`. Now the two cases
/// cannot be confused: a genuine first run is a parsed [MarketIndex] (whose
/// own `historyFrom` may itself be `null`), and a failure to read is an
/// exception that stops the run before anything is written.
Future<MarketIndex> _fetchPublishedIndex(HttpClient client) async {
  final int statusCode;
  final String body;
  try {
    final request = await client.getUrl(Uri.parse(_servidor.indicePublicado));
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    final response = await request.close();
    statusCode = response.statusCode;
    body = await response.transform(utf8.decoder).join();
  } catch (e) {
    throw PublishedIndexUnavailable('não deu para conectar: $e');
  }
  return parsePublishedIndex(statusCode, body);
}

/// Downloads `_servidor`'s own published index and writes it, unchanged, to
/// `_servidor.arquivoDoIndice` — no crawl, no state file, one request.
///
/// **What this exists for:** one CI job alternates between the two versions,
/// and a deploy publishes the whole site. A run that collected `pw126` still
/// has to publish a `pw187` index, because the index files are gitignored —
/// without this, that deploy would serve a site with the 1.8.7 market simply
/// absent, erasing it rather than merely leaving it stale. So the workflow
/// runs this once more, pointed at the version it did NOT collect, to carry
/// that version's already-live index into this run's `web/` before building.
///
/// Reuses [_fetchPublishedIndex] rather than a second downloader — it is the
/// same request the price-memory feature already makes, just aimed at
/// whichever `Servidor` `--server` selected this time.
///
/// **A failed fetch aborts rather than writes nothing — unless the failure is
/// a 404.** Exiting 1 on anything else is the same decision `main()` already
/// takes when its own published index does not arrive: publishing without
/// the carried-forward index would erase that market from the site, and a
/// stale-but-present index is strictly better than that.
///
/// **A 404 is different: it means this version has never been published at
/// all, which is the state of the world the moment this feature first
/// merges.** Aborting on it would deadlock every run forever — the pw187 run
/// that carries pw126 forward 404s and freezes the whole site's deploys, and
/// the first pw126 run that could break that deadlock 404s on its own
/// published index in `main()` before writing anything either. So a 404 here
/// is logged and skipped rather than aborted: this run simply does not write
/// that version's index, and the deploy publishes the version it DID collect
/// without the other door yet existing. The moment either version has
/// published once, every future 404 here is a genuine outage again — a
/// published file does not un-publish itself — and the abort below still
/// applies to that case exactly as before.
Future<void> _carryForward(HttpClient client) async {
  try {
    final index = await _fetchPublishedIndex(client);
    final file = File(_servidor.arquivoDoIndice)
      ..parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode(index.toJson()));
    escreverVersoes(index, _servidor);
    stdout.writeln(
      'Arrastado: ${_servidor.chave} (${index.characters.length} '
      'personagens, coletado em ${index.collectedAt}) -> '
      '${_servidor.arquivoDoIndice}',
    );
  } on PublishedIndexUnavailable catch (e) {
    if (e.notFound) {
      stdout.writeln(
        '${_servidor.chave} nunca foi publicado ($e) — nada a arrastar '
        'ainda. Este deploy sai sem aquela porta; ela aparece assim que a '
        'primeira coleta dessa versão rodar.',
      );
      return;
    }
    stderr.writeln(
      'Não consegui baixar o índice publicado de ${_servidor.chave} ($e). '
      'Abortando sem publicar — publicar sem ele apagaria aquele mercado '
      'do site.',
    );
    exit(1);
  } finally {
    client.close(force: true);
  }
}

/// Reads `web/market_index.json` off disk — the index this program itself
/// last wrote — so `--rebuild` costs no network and still carries the price
/// history forward.
///
/// `null` when the file does not exist, which is a genuine first rebuild:
/// starting fresh is correct there, the same as a brand-new site. A file that
/// exists but will not parse is left to throw — it is our own last output,
/// and a rebuild silently discarding it would be exactly the erasure this
/// whole fix exists to prevent.
MarketIndex? _readLocalIndex() {
  final file = File(_servidor.arquivoDoIndice);
  if (!file.existsSync()) return null;
  return MarketIndex.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
}

/// Returns null when the page could not be read after every attempt.
Future<String?> _fetchDetail(
  HttpClient client,
  int roleId, {
  required void Function() onBlocked,
}) async {
  for (var attempt = 1; attempt <= _attemptsPerPage; attempt++) {
    // The canonical shape is per-version and inverted between them — see
    // `Servidor.detalhe` for the measurement. Using the other form doubles
    // the request count for the whole collection via a redirect (pw187) or
    // answers 404 outright (pw126).
    final body = await _get(client, _servidor.detalhe(roleId));
    if (body != null) return body;

    if (attempt == _attemptsPerPage) return null;

    // A refused connection is the block's face. Retrying through it only
    // extends it, so back off by minutes rather than by seconds.
    final pause = _lastErrorWasRefusal ? _blockedPause : _politeDelay * attempt;
    if (_lastErrorWasRefusal) {
      onBlocked();
      stdout.writeln(
        '  bloqueado — pausando ${pause.inMinutes} min '
        '(tentativa $attempt de $_attemptsPerPage)',
      );
    }
    await Future<void>.delayed(pause);
  }
  return null;
}

bool _lastErrorWasRefusal = false;

Future<String?> _get(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    request.headers.set(HttpHeaders.acceptLanguageHeader, 'pt-BR,pt;q=0.9');
    // The server compresses: a detail page is 1.13 MB plain and 116 KB gzipped,
    // and arrives in two thirds of the time. `autoUncompress` is on by default,
    // so the bytes are transparent from here on.
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
    final response = await request.close();

    if (response.statusCode != 200) {
      await response.drain<void>();
      _lastErrorWasRefusal = response.statusCode == 429;
      return null;
    }
    _lastErrorWasRefusal = false;
    return await response.transform(utf8.decoder).join();
  } on SocketException {
    _lastErrorWasRefusal = true;
    return null;
  } on HttpException {
    _lastErrorWasRefusal = false;
    return null;
  }
}

/// An inventory as name to total, summing the stacks that share a name.
///
/// Summed rather than taken one stack at a time because the same name can
/// arrive under more than one id — *Essência Dracônica* is two items in the
/// game's own database — and because a bag stack and a bank stack of one item
/// are the same item to anybody deciding whether to buy.
Map<String, int> _porNome(List<ParsedStack> inventario) {
  final total = <String, int>{};
  for (final stack in inventario) {
    if (stack.name.isEmpty) continue;
    total[stack.name] = (total[stack.name] ?? 0) + stack.count;
  }
  return total;
}

/// Writes the index and returns the arrivals worth announcing.
///
/// The alert is computed **here** rather than from the published index, and
/// that is forced by what the feed is for: the index merges the essence, the
/// raw essence and the chest under one label on purpose, and the raw one is
/// the rare half — two arrivals a day against 233. Only the state knows which
/// is which, because only the state keeps the inventory name by name.
List<EntradaNova> _writeIndex(
  List<ListingCard> listing,
  _CollectState state, {
  MarketIndex? publicado,
}) {
  final builder = IndexBuilder(
    server: _servidor.chave,
    collectedAt: DateTime.now().toUtc(),
  );

  final agora = DateTime.now().toUtc();
  final memoria = avancarTodos(
    listing: listing,
    publicado: publicado,
    agora: agora,
  );

  for (final card in listing) {
    final collected = state.itemsFor(card.roleId);
    if (collected != null) {
      builder.add(
        card,
        collected.items,
        sex: collected.sex,
        cards: collected.cards,
        anecdotes: collected.anecdotes,
        inventory: collected.inventory,
        realm: collected.realm,
        path: collected.path,
        runes: collected.runes,
        titles: collected.titles,
        history: memoria[card.roleId],
      );
    }
  }

  final inventarios = {
    for (final card in listing)
      if (state.itemsFor(card.roleId) case final colhido?)
        card.roleId: _porNome(colhido.inventory),
  };

  // Which watched names this collection never met. A quiet channel and a
  // misspelt item look identical from the outside, and this is the line that
  // tells them apart — the same job the unresolved counted names already get.
  final nuncaVistos = nomesNuncaVistos(inventarios.values);
  if (nuncaVistos.isNotEmpty) {
    stdout.writeln(
      '  AVISO: item(ns) vigiado(s) que não apareceram em nenhum '
      'inventário: ${nuncaVistos.join(', ')}.',
    );
  }

  // How common each watched item actually is, and who carries most. This is
  // what turns a floor from taste into a measurement: an item nearly everybody
  // carries needs one, and this line is where that becomes visible instead of
  // being discovered by a channel filling up.
  for (final entry in vigiaDeItens.entries) {
    final quantidades = [
      for (final inventario in inventarios.values)
        if ((inventario[entry.key] ?? 0) > 0) inventario[entry.key]!,
    ]..sort();
    if (quantidades.isEmpty) continue;
    final acima = quantidades.where((q) => q >= entry.value).length;
    stdout.writeln(
      '  vigia "${entry.key}": ${quantidades.length} carregam '
      '(mediana ${quantidades[quantidades.length ~/ 2]}, '
      'topo ${quantidades.last}) · $acima acima do piso de ${entry.value}',
    );
  }

  final entradas = entradasParaAvisar(
    anuncios: [
      for (final card in listing)
        AnuncioNoMercado(
          roleId: card.roleId,
          nome: card.name,
          classe: card.characterClass,
          nivel: card.level,
          preco: card.price,
        ),
    ],
    inventarios: inventarios,
    memoria: memoria,
    agora: agora,
  );

  final index = builder.build(historyFrom: historyFromDe(publicado, agora));
  final file = File(_servidor.arquivoDoIndice)
    ..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(index.toJson()));
  escreverVersoes(index, _servidor);

  // Realms the scale could not place. Eight of the ten tiers had never been
  // seen on a real sheet when the table was written, so a spelling nobody
  // predicted has to be reported on the first run — otherwise that character
  // drops out of every ordering in silence.
  final estranhos = <String>{};
  for (final character in index.characters) {
    if (character.realm.isEmpty) continue;
    if (CelestialRealm.parse(character.realm) == null) {
      estranhos.add(character.realm);
    }
  }
  if (estranhos.isNotEmpty) {
    stdout.writeln(
      '  AVISO: ${estranhos.length} reino(s) que a escala não reconhece: '
      '${estranhos.take(8).join(', ')}',
    );
  }

  final semReino = index.characters.where((c) => c.realm.isEmpty).length;
  final comRuna = index.characters.where((c) => c.runes.isNotEmpty).length;
  stdout
    ..writeln('  reinos lidos: ${index.characters.length - semReino}')
    ..writeln('  com runas: $comRuna, tipos distintos: ${index.runes.length}')
    ..writeln(
      '  God: ${index.characters.where((c) => c.path == 'God').length}, '
      'Evil: ${index.characters.where((c) => c.path == 'Evil').length}',
    );

  // Which counted items this collection actually met. A name that finds
  // nothing is either misspelt or genuinely not on sale, and this line is
  // where that question gets answered — the suite cannot tell the two apart
  // and must not stop the deploy for a market fact.
  for (final label in countedItemGroups.keys) {
    final ids = index.countedItems[label];
    if (ids == null || ids.isEmpty) {
      stdout.writeln('  AVISO: "$label" não apareceu em nenhum inventário.');
      continue;
    }

    // Named, not just counted. These items are rare enough that "how many
    // carry one" can be a single digit, and a name is what lets the player
    // open that character's page and check the number against the site —
    // which is the only verification available for an item no fixture holds.
    final portadores = index.characters
        .where((c) => (index.countOf(c, label) ?? 0) > 0)
        .toList();
    final melhor = portadores.isEmpty
        ? null
        : portadores.reduce(
            (a, b) =>
                (index.countOf(b, label) ?? 0) > (index.countOf(a, label) ?? 0)
                ? b
                : a,
          );

    stdout.writeln(
      '  "$label" = ${ids.join(', ')} · '
      '${portadores.length} portadores'
      '${melhor == null ? '' : ' · maior: ${melhor.name} '
                '(${index.countOf(melhor, label)}, id ${melhor.roleId})'}',
    );
  }

  // And which named combos nobody is wearing. Same job as the line above, and
  // the same reason it is a line and not an assertion: `cardCombos` is written
  // by hand from data, so a pair nobody wears is either a mistake in the table
  // or a market where the one owner delisted — and on 2026-09-11 it was the
  // second, which stopped the site publishing for eight hours.
  //
  // The two are told apart by *when* the line appears. A combo that has just
  // been added and shows up here on its first run is a wrong pair; an old one
  // that shows up is news about the market, and the dropdown drops it by
  // itself.
  final semDono = [
    for (final combo in cardCombos)
      if (!index.characters.any(
        (c) => c.cards
            .map((card) => card.cardId)
            .toSet()
            .containsAll(combo.cardIds),
      ))
        combo.name,
  ];
  if (semDono.isNotEmpty) {
    stdout.writeln(
      '  AVISO: combo(s) que ninguém está usando: ${semDono.join(', ')}. '
      'Se algum acabou de entrar na tabela, o par está errado.',
    );
  }

  return entradas;
}

const _arquivoVersoes = 'web/versoes.json';

/// Writes [servidor]'s row into [arquivo] — **by merge, never by
/// replacement**. One call collects one version's row only; rewriting the
/// whole file would erase the other version's row, and the chooser screen
/// would open a single door with nothing on screen saying the second one went
/// missing.
///
/// A missing or unreadable file is treated as the first-ever run for every
/// version, not refused: starting a fresh file is correct the first time this
/// ever runs, and a corrupt file holding nothing but two small numbers must
/// not stop a collection that has nothing to do with it.
///
/// **This is also what closes the CI gap the merge alone cannot.** The file
/// is gitignored and nothing restores it between jobs, so a bare checkout
/// never has the other version's row to merge with — the merge was correct
/// and the environment it ran in was empty, and every CI deploy published a
/// one-row file regardless. Both the normal collect path (`_writeIndex`,
/// above) and `_carryForward` call this now, once each, on the SAME run: a
/// run that collects `pw187` writes that row here directly, and the
/// carry-forward step for `pw126` reads the file this just wrote and adds
/// pw126's row from the index it just downloaded — no extra request, no
/// reliance on the cache or on git. By the time the job reaches `Compilar`,
/// both rows are on disk.
///
/// Takes [servidor] explicitly rather than reading the top-level `_servidor`
/// so this is callable from a test without going through `main()` — see
/// `test/tool/escrever_versoes_test.dart` for the merge test `versoes_test`
/// never was (its "replace one version" case only exercised `Map`'s own
/// `[]=`, not this function).
void escreverVersoes(
  MarketIndex index,
  Servidor servidor, {
  String arquivo = _arquivoVersoes,
}) {
  final file = File(arquivo);

  var versoes = <String, VersaoResumo>{};
  if (file.existsSync()) {
    try {
      versoes = versoesFromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    } catch (e) {
      stdout.writeln(
        '  AVISO: não consegui ler $arquivo ($e); recomeçando do zero — a '
        'linha da outra versão será perdida até a próxima coleta dela.',
      );
    }
  }

  versoes[servidor.chave] = VersaoResumo(
    chave: servidor.chave,
    nome: _nomesLegiveis[servidor.chave] ?? servidor.chave,
    personagens: index.characters.length,
    coletadoEm: index.collectedAt,
  );

  file.writeAsStringSync(jsonEncode(versoesToJson(versoes)));
}

void _reportEstimate(int pending) {
  if (pending == 0) {
    stdout.writeln('Nada novo a buscar. Reescrevendo o índice.');
    return;
  }
  // Roughly a second of transfer on top of the pause between requests.
  final seconds = pending * (_politeDelay.inMilliseconds / 1000 + 1);
  final label = seconds < 90
      ? '~${seconds.round()} s'
      : '~${(seconds / 60).ceil()} min';
  stdout.writeln(
    'Estimativa: $label. Ctrl-C a qualquer momento; '
    'rode com --resume para continuar de onde parou.',
  );
}

void _reportProgress(int done, int total, String name) {
  if (done % 25 != 0 && done != total) return;
  stdout.writeln('  $done/$total ($name)');
}

void _reportSummary(
  List<ListingCard> listing,
  _CollectState state,
  int blockedPauses,
) {
  final collected = listing.where((c) => state.itemsFor(c.roleId) != null);
  final bare = collected
      .where((c) => state.itemsFor(c.roleId)!.items.isEmpty)
      .length;

  stdout
    ..writeln('')
    ..writeln('Índice escrito em ${_servidor.arquivoDoIndice}')
    ..writeln('  lidos:    ${collected.length} de ${listing.length}')
    ..writeln('  falharam: ${state.failed.length}')
    ..writeln('  sem equipamento nenhum: $bare');

  if (blockedPauses > 0) {
    stdout.writeln('  pausas por bloqueio: $blockedPauses');
  }
  // A character on sale wearing nothing is rare; hundreds of them means the
  // paper doll's markup moved and the parser is reading an empty page.
  if (bare > collected.length / 4) {
    stdout.writeln(
      '\nAVISO: ${(bare * 100 / collected.length).round()}% vieram sem '
      'equipamento. Isso quase certamente é o HTML do site tendo mudado, não '
      'o mercado. Rode `flutter test test/collector/`.',
    );
  }
}

/// Rewrites `web/market_index.json` from the state file alone.
void _rebuildFromState() {
  final state = _CollectState.load(_servidor.arquivoDoEstado, resume: true);
  if (state.listing.isEmpty) {
    stderr.writeln(
      'Não há coleta gravada em ${_servidor.arquivoDoEstado} para '
      'reconstruir. Rode `dart run tool/collect.dart` primeiro.',
    );
    exit(1);
  }

  // Every entry the state had was written by an older collector and dropped
  // on the way in. Writing the index anyway would replace a good one with an
  // empty market — which looks exactly like everybody having left.
  if (state.done.isEmpty) {
    stderr.writeln(
      'O estado gravado é de uma versão anterior do coletor e foi descartado '
      'inteiro. Não há o que reconstruir sem rede: rode '
      '`dart run tool/collect.dart --resume`.',
    );
    exit(1);
  }

  // Read off disk, not fetched: `--rebuild` costs no network, and this is the
  // index this program itself last wrote, so it is the right record to carry
  // history forward from. Nothing existing on disk is a genuine first
  // rebuild, and `_writeIndex` starting fresh from `null` there is correct.
  // Nothing is announced from a rebuild. It rewrites the index from a state
  // that was already collected, so every arrival in it has already been
  // through a real run — announcing again would repeat the channel's last
  // hour every time somebody corrects a label.
  _writeIndex(state.listing, state, publicado: _readLocalIndex());
  _reportSummary(state.listing, state, 0);
}

/// What has already been read, so an interrupted run can continue — and so a
/// rebuild never needs the network.
class _CollectState {
  _CollectState(this.done, this.failed, this.listing);

  final Map<int, CollectedPage> done;
  final Set<int> failed;

  /// The roster as it was when this collection started. Kept so `--rebuild`
  /// can write a whole index offline, and so the index always describes one
  /// consistent moment of the market rather than mixing two.
  List<ListingCard> listing;

  static _CollectState load(String path, {required bool resume}) {
    final file = File(path);
    if (!resume || !file.existsSync()) return _CollectState({}, {}, []);

    final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final names = {
      for (final entry
          in (json['itemNames'] as Map<String, dynamic>? ?? const {}).entries)
        int.parse(entry.key): entry.value as String,
    };

    final done = <int, CollectedPage>{};
    for (final entry in (json['done'] as Map<String, dynamic>).entries) {
      // An entry this version cannot have written is dropped rather than
      // adapted, and the collector fetches that page again. The point of the
      // new fields is that they are missing; keeping the entry would leave
      // most of the market without them and nothing on screen saying why.
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;
      if (!CollectedPage.isCurrent(value)) continue;
      done[int.parse(entry.key)] = CollectedPage.fromJson(value, names);
    }
    return _CollectState(
      done,
      (json['failed'] as List<dynamic>).cast<int>().toSet(),
      (json['listing'] as List<dynamic>? ?? const [])
          .map((c) => _cardFromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Forgets everyone no longer on sale. Returns how many were dropped.
  int pruneTo(List<ListingCard> listing) {
    final onSale = listing.map((c) => c.roleId).toSet();
    final gone = done.keys.where((id) => !onSale.contains(id)).toList();
    for (final id in gone) {
      done.remove(id);
    }
    failed.removeWhere((id) => !onSale.contains(id));
    return gone.length;
  }

  bool isDone(int roleId) => done.containsKey(roleId);

  CollectedPage? itemsFor(int roleId) => done[roleId];

  void markDone(int roleId, CollectedPage collected) {
    done[roleId] = collected;
    failed.remove(roleId);
  }

  void markFailed(int roleId) => failed.add(roleId);

  void save(String path) {
    final names = itemNamesOf(done.values);

    File(path).writeAsStringSync(
      jsonEncode({
        'done': {
          for (final entry in done.entries)
            entry.key.toString(): entry.value.toJson(),
        },
        'itemNames': {
          for (final entry in names.entries) entry.key.toString(): entry.value,
        },
        'failed': failed.toList(),
        'listing': listing.map(_cardToJson).toList(),
      }),
    );
  }
}

Map<String, dynamic> _cardToJson(ListingCard card) => {
  'roleId': card.roleId,
  'name': card.name,
  'class': card.characterClass,
  'occupation': card.occupation,
  'level': card.level,
  'price': card.price,
  'fame': card.fame,
  'cultivation': card.cultivation,
};

ListingCard _cardFromJson(Map<String, dynamic> json) => ListingCard(
  roleId: json['roleId'] as int,
  name: json['name'] as String,
  characterClass: json['class'] as String,
  occupation: json['occupation'] as int,
  level: json['level'] as int,
  price: json['price'] as int,
  fame: json['fame'] as int,
  cultivation: json['cultivation'] as String,
);
