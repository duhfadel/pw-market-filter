// Collects the pw187 marketplace into `web/market_index.json`.
//
//   dart run tool/collect.dart            # from scratch
//   dart run tool/collect.dart --resume   # continue an interrupted run
//
// This is the only file allowed to touch the network or the disk. Everything
// it calls lives in `lib/collector/` and is pure Dart, so the tests can run it
// and the web app can share its model.
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
import 'package:pw_market_filter/market/celestial_realm.dart';
import 'package:pw_market_filter/market/counted_items.dart';

const _server = 'pw187';
const _origin = 'https://marketplace.theclassic.games';
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

final _statePath = 'tool/.collect_state.json';
final _outputPath = 'web/market_index.json';

Future<void> main(List<String> arguments) async {
  final resume = arguments.contains('--resume');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);

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

    final state = _CollectState.load(_statePath, resume: resume);
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
        state.markDone(
          card.roleId,
          CollectedPage(
            items: parseEquippedItems(page),
            cards: parseEquippedCards(page),
            sex: parseSex(page),
            anecdotes: parseAnecdotes(page),
            inventory: parseInventory(page),
            realm: parseCelestialRealm(page) ?? '',
            path: parsePath(page) ?? '',
            runes: parseRunes(page),
          ),
        );
      }
      state.save(_statePath);

      _reportProgress(i + 1, pending.length, card.name);
      if (i + 1 < pending.length) await Future<void>.delayed(_politeDelay);
    }

    _writeIndex(listing, state);
    _reportSummary(listing, state, blockedPauses);
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
    body = await _get(client, '$_origin/$_server');
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

/// Returns null when the page could not be read after every attempt.
Future<String?> _fetchDetail(
  HttpClient client,
  int roleId, {
  required void Function() onBlocked,
}) async {
  for (var attempt = 1; attempt <= _attemptsPerPage; attempt++) {
    // `/details/$server/$id` — the form the listing's links use — answers 302
    // and redirects here. Following it doubled the request count for the whole
    // collection, and the rate limit counts redirects.
    final body = await _get(client, '$_origin/$_server/details/$roleId');
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

void _writeIndex(List<ListingCard> listing, _CollectState state) {
  final builder = IndexBuilder(
    server: _server,
    collectedAt: DateTime.now().toUtc(),
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
      );
    }
  }

  final index = builder.build();
  final file = File(_outputPath)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(index.toJson()));

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
  for (final name in countedItemNames) {
    final id = index.countedItems[name];
    stdout.writeln(
      id == null
          ? '  AVISO: "$name" não apareceu em nenhum inventário.'
          : '  "$name" = item $id',
    );
  }
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
    ..writeln('Índice escrito em $_outputPath')
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
  final state = _CollectState.load(_statePath, resume: true);
  if (state.listing.isEmpty) {
    stderr.writeln(
      'Não há coleta gravada em $_statePath para reconstruir. '
      'Rode `dart run tool/collect.dart` primeiro.',
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

  _writeIndex(state.listing, state);
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
