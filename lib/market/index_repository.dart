import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/result/result.dart';
import 'market_index.dart';

/// Reads the index the collector wrote. Never throws.
///
/// The index is fetched over HTTP from the app's own origin rather than
/// bundled as an asset, and that is deliberate. Bundled, refreshing the market
/// means rebuilding the whole Flutter app and redeploying it — which makes
/// "always up to date" expensive by construction, when what changed is one
/// megabyte of JSON. Served, a refresh is one file.
///
/// It also removes a caching trap: a bundled asset sits at a fixed URL and a
/// browser is free to keep serving yesterday's copy, which looks exactly like
/// a market where nothing happened.
class IndexRepository {
  /// The client is injectable so a test can answer without a network.
  ///
  /// [server] is kept positional, alongside [client], rather than named: this
  /// repository already has call sites passing a bare client
  /// (`IndexRepository(client)`), and a named-parameter list cannot sit next
  /// to a positional-optional one in Dart — this is the shape that keeps all
  /// of them compiling unchanged.
  IndexRepository([http.Client? client, this.server = pw187])
    : _client = client ?? http.Client();

  final http.Client _client;

  /// The marketplace this repository reads — matching `MarketIndex.server`
  /// and the collector's `Servidor.chave` — `pw187` or `pw126`. Defaults to
  /// `pw187`, the version already live, so every call site that predates the
  /// two marketplaces keeps reading the same file without having to say so.
  final String server;

  /// The 1.8.7 marketplace.
  static const pw187 = 'pw187';

  /// The 1.2.6 marketplace.
  static const pw126 = 'pw126';

  /// One file per marketplace. `pw187`'s name is pinned exactly as it always
  /// was — `market_index.json` is the file live on the site right now, and
  /// changing it would break the deploy that ships this change.
  static const _fileNames = {
    pw187: 'market_index.json',
    pw126: 'market_index_126.json',
  };

  /// The file [server] reads. An unknown [server] is refused rather than
  /// guessed — the same call `Servidor.de` makes on the collector side — so a
  /// typo fails loudly instead of fetching a 404 that looks like a missing
  /// index.
  String get fileName {
    final name = _fileNames[server];
    if (name == null) {
      throw ArgumentError.value(
        server,
        'server',
        'unknown marketplace — known: ${_fileNames.keys.join(', ')}',
      );
    }
    return name;
  }

  /// The command that produces the file, shown to whoever has not run it yet.
  static const collectCommand = 'dart run tool/collect.dart';

  Future<Result<MarketIndex>> load() async {
    final http.Response response;
    try {
      // The timestamp defeats the browser cache. A stale index is the failure
      // this whole design exists to avoid, and it is invisible when it happens.
      response = await _client.get(
        Uri.base.resolve(
          '$fileName?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    } on Exception catch (e) {
      return Failure(IndexUnreadableFailure('(rede)', e.toString()));
    }

    if (response.statusCode == 404) {
      return const Failure(IndexMissingFailure());
    }
    if (response.statusCode != 200) {
      return Failure(
        IndexUnreadableFailure('(rede)', 'HTTP ${response.statusCode}'),
      );
    }

    try {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      if (json is! Map<String, dynamic>) {
        return const Failure(
          IndexUnreadableFailure('(raiz)', 'esperava um objeto JSON'),
        );
      }
      return Success(MarketIndex.fromJson(json));
    } on IndexFormatException catch (e) {
      return Failure(IndexUnreadableFailure(e.field, e.detail));
    } on FormatException catch (e) {
      return Failure(IndexUnreadableFailure('(arquivo)', e.message));
    }
  }
}
