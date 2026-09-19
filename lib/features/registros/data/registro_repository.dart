import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/result/result.dart';
import '../domain/registro.dart';

/// Reads the 126 recipes from Supabase. Never throws.
///
/// **The table and not a bundled file**, for the reason the map already
/// proved: twenty-seven of these recipes have no bonus recorded, and they will
/// be filled in one at a time over months. Bundled, each correction would be a
/// commit, a CI run and a deploy for one number. In the table it is a row
/// edited in the dashboard, live on the next page load.
///
/// The whole thing is 2 KB gzipped, so there is no paging and no caching layer
/// — one request, the entire table, and the screen sorts it.
class RegistroRepository {
  RegistroRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url =
      'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/registros';

  /// Public by design, the same key the counter and the map already carry: it
  /// is compiled into every visitor's browser and there is no hiding it. What
  /// holds the line is the table — `registros` has a select policy and no
  /// insert, update or delete policy at all, so this key reads and nothing
  /// else. Probed with curl before shipping: an insert answers `42501`, and a
  /// PATCH answers 204 with the row unchanged, because RLS filters the row out
  /// rather than refusing the verb.
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  Future<Result<List<Registro>>> load() async {
    final http.Response resposta;
    try {
      resposta = await _client.get(
        Uri.parse('$_url?select=*&order=aba,ordem'),
        headers: const {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
          // No `?t=<millis>` here, unlike the market index. PostgREST reads an
          // unrecognised query parameter as a filter on a column of that name
          // and answers `PGRST100`, so the cache-buster that keeps the index
          // fresh would empty this screen instead.
          'Cache-Control': 'no-store',
        },
      );
    } catch (e) {
      return Failure(IndexUnreadableFailure('rede', e.toString()));
    }

    if (resposta.statusCode != 200) {
      return Failure(
        IndexUnreadableFailure('resposta', 'HTTP ${resposta.statusCode}'),
      );
    }

    try {
      final linhas = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
      return Success([
        for (final linha in linhas)
          Registro.fromJson(linha as Map<String, dynamic>),
      ]);
    } catch (e) {
      return Failure(IndexUnreadableFailure('formato', e.toString()));
    }
  }
}
