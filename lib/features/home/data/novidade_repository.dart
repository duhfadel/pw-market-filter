import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/result/result.dart';
import '../domain/novidade.dart';

/// Reads the announcements the Worker copied out of Discord. Never throws.
///
/// Two doors onto the same table. [load] is what the front page's bar and its
/// `NovidadesViewModel` use: an empty list for every failure, like the
/// live-streamers strip — the section simply is not drawn, because news that
/// shouts an error when it cannot load is worse than news that waits for the
/// next page load. [carregar] is the other door, for the `/novidades` screen
/// whose whole job is this list: there, "nobody has posted" and "the request
/// failed" are different facts and only one is the server's fault, so it
/// answers a typed [Result] instead of collapsing both into one empty list.
class NovidadeRepository {
  NovidadeRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url =
      'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/novidades';
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  Future<List<Novidade>> load() async =>
      (await carregar()).fold((novidades) => novidades, (_) => const []);

  Future<Result<List<Novidade>>> carregar() async {
    final http.Response resposta;
    try {
      resposta = await _client.get(
        Uri.parse('$_url?select=*&visivel=is.true&order=publicada_em.desc'),
        headers: const {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
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
          Novidade.fromJson(linha as Map<String, dynamic>),
      ]);
    } catch (e) {
      return Failure(IndexUnreadableFailure('formato', e.toString()));
    }
  }
}
