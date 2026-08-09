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
  IndexRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const fileName = 'market_index.json';

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
