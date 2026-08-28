// Downloads the icons the screen needs, straight from the index.
//
//   dart run tool/fetch_icons.dart
//
// Idempotent: a file already on disk is never fetched again, so a re-run after
// a fresh collection costs only the items that are new to the market.
//
// These come from two hosts, neither of which is the marketplace that rate
// limits: class art from theclassic.games and item art from
// pwdatabase.theclassic.games. Still one at a time, still with a pause — the
// lesson from the marketplace was that a block outlives the run by an hour.

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

Future<void> main() async {
  final file = File('web/market_index.json');
  if (!file.existsSync()) {
    stderr.writeln('web/market_index.json não existe. Rode a coleta primeiro.');
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
      ...index.countedItems.values,
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
