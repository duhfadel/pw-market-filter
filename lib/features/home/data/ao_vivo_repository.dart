import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/canal_ao_vivo.dart';

/// Reads who is streaming, from the table the Worker fills. Never throws.
///
/// Answers with a plain list rather than a `Result`, for the reason
/// `VisitRepository` does: every failure here has the same answer, which is to
/// show no strip at all. A typed failure nobody reads would be ceremony — and
/// a courtesy strip must never be the thing that breaks a page.
class AoVivoRepository {
  AoVivoRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url =
      'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/canais_twitch';

  /// The same publishable key the rest of the site carries. It reads and
  /// nothing else: `canais_twitch` has a select policy and no insert, update
  /// or delete policy at all, so the only thing that writes is the Worker,
  /// with a key that never leaves Cloudflare.
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  Future<List<CanalAoVivo>> load() async {
    try {
      final resposta = await _client.get(
        Uri.parse('$_url?select=*&ativo=is.true&ao_vivo=is.true'),
        headers: const {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
          // Not `?t=<millis>`: PostgREST reads an unknown query parameter as a
          // filter on a column of that name and answers PGRST100.
          'Cache-Control': 'no-store',
        },
      );

      if (resposta.statusCode != 200) return const [];

      final linhas = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
      return [
        for (final linha in linhas)
          CanalAoVivo.fromJson(linha as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }
}
