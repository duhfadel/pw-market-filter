// Downloads the icons the screen needs, straight from the index.
//
//   dart run tool/fetch_icons.dart                  # pw187
//   dart run tool/fetch_icons.dart --server pw126    # the other marketplace
//
// Idempotent: a file already on disk is never fetched again, so a re-run after
// a fresh collection costs only the items that are new to the market.
//
// These come from two hosts, neither of which is the marketplace that rate
// limits: class art from theclassic.games and item art from
// pwdatabase.theclassic.games. Still one at a time, still with a pause — the
// lesson from the marketplace was that a block outlives the run by an hour.
//
// Both markets' icons are written into the same `assets/icons/...`
// directories: an item id names one file regardless of which index met it
// first, the same way `assets/icons/items` already holds cards and counted
// items alongside equipment. There is nothing per-version to keep apart here
// the way `tool/collect.dart` keeps `.collect_state_126.json` apart from the
// 1.8.7 one — only *which index to read ids from* differs, which is exactly
// what `--server` selects.

import 'dart:convert';
import 'dart:io';

import 'package:pw_market_filter/market/market_index.dart';

const _classIcons = 'https://theclassic.games/assets/img/pw_roles';
const _itemIcons =
    'https://pwdatabase.theclassic.games/assets/img/vtheclassicpw187';
const _userAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/126.0 Safari/537.36';
const _pause = Duration(milliseconds: 250);

/// One index file per marketplace — the same keys and defaulting
/// `tool/collect.dart`'s own `_serverArg` uses, so `--server pw126` means the
/// same thing in both tools.
const _indexFiles = {
  'pw187': 'web/market_index.json',
  'pw126': 'web/market_index_126.json',
};

/// Reads `--server <chave>` out of the argument list. Defaults to `pw187` so
/// an unqualified run keeps today's behaviour.
String _serverArg(List<String> arguments) {
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--server' && i + 1 < arguments.length) {
      return arguments[i + 1];
    }
  }
  return 'pw187';
}

Future<void> main(List<String> arguments) async {
  final server = _serverArg(arguments);
  final indexPath = _indexFiles[server];
  if (indexPath == null) {
    stderr.writeln(
      'Servidor desconhecido: $server — conhecidos: ${_indexFiles.keys.join(', ')}',
    );
    exit(1);
  }

  final file = File(indexPath);
  if (!file.existsSync()) {
    stderr.writeln('$indexPath não existe. Rode a coleta primeiro.');
    exit(1);
  }

  final index = MarketIndex.fromJson(
    jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
  );
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);

  try {
    final occupations = index.characters.map((c) => c.occupation).toSet();
    await _fetchAll(
      client,
      label: 'classes',
      directory: 'assets/icons/classes',
      names: {for (final o in occupations) '$o': '$_classIcons/occu_$o.png'},
    );

    // Equipment, War Avatar cards and the counted items share one icon host
    // and one id space, but **not** one index field: `items` holds only
    // equipment. Reading just that left every card in the app with a blank
    // square and a 404 in the console — and the relics would have gone the
    // same way, since a `Relíquia Maravilha` is carried, never worn.
    final iconIds = {
      ...index.items.keys,
      // A label can gather several ids, and each draws its own sprite.
      ...index.countedItems.values.expand((ids) => ids),
      // Runes are the third field that shares the id space without sharing
      // `items`, and the card draws them at 22 px — their art carries both the
      // colour and the level, so a missing file loses real information.
      ...index.runes.keys,
      for (final character in index.characters)
        for (final card in character.cards) card.cardId,
    };

    await _fetchAll(
      client,
      label: 'itens e cartas',
      directory: 'assets/icons/items',
      names: {for (final id in iconIds) '$id': '$_itemIcons/$id.png'},
    );
  } finally {
    client.close(force: true);
  }
}

Future<void> _fetchAll(
  HttpClient client, {
  required String label,
  required String directory,
  required Map<String, String> names,
}) async {
  Directory(directory).createSync(recursive: true);

  var fetched = 0;
  var skipped = 0;
  var failed = 0;

  for (final entry in names.entries) {
    final target = File('$directory/${entry.key}.png');
    if (target.existsSync() && target.lengthSync() > 0) {
      skipped++;
      continue;
    }

    final bytes = await _get(client, entry.value);
    if (bytes == null) {
      failed++;
      stdout.writeln('  ${entry.key}: falhou');
    } else {
      target.writeAsBytesSync(bytes);
      fetched++;
      if (fetched % 50 == 0) stdout.writeln('  $fetched baixados…');
    }
    await Future<void>.delayed(_pause);
  }

  stdout.writeln(
    '$label: $fetched baixados, $skipped já tinha, $failed falharam',
  );
}

Future<List<int>?> _get(HttpClient client, String url) async {
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
    final response = await request.close();
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }

    final bytes = <int>[];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return bytes;
  } on SocketException {
    return null;
  } on HttpException {
    return null;
  }
}
