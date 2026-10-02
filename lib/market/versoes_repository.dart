import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/result/result.dart';
import 'versoes.dart';

/// Reads `web/versoes.json` — one row per version, written by the collector.
/// Never throws.
///
/// This is the whole reason the version-chooser screen can exist without
/// downloading either marketplace's index to show two numbers: those are
/// ~4 MB each, and this file is one row per version.
///
/// [IndexMissingFailure] and [IndexUnreadableFailure] are reused rather than
/// given names of their own here, the same way `NovidadeRepository.carregar`
/// already reuses them for a table that has nothing to do with the index
/// either: "nobody has ever collected anything" and "the file is there and
/// will not parse" are the same two shapes of failure `IndexRepository`
/// already named, and a version with no row in this file is drawn exactly
/// the same as a version absent from an empty file — there is no third
/// meaning to invent a type for.
class VersoesRepository {
  VersoesRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const fileName = 'versoes.json';

  Future<Result<Map<String, VersaoResumo>>> carregar() async {
    final http.Response response;
    try {
      // The timestamp defeats the browser cache, the same way
      // `IndexRepository.load` does — a stale row here would print a
      // character count and a date that no longer match the published index.
      response = await _client.get(
        Uri.base.resolve(
          '$fileName?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
      );
    } catch (e) {
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
      return Success(versoesFromJson(json));
    } catch (e) {
      return Failure(IndexUnreadableFailure('(arquivo)', e.toString()));
    }
  }
}
