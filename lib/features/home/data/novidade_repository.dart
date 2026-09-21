import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/novidade.dart';

/// Reads the announcements the Worker copied out of Discord. Never throws.
///
/// An empty list for every failure, like the live-streamers strip: the section
/// simply is not drawn. News that shouts an error when it cannot load is worse
/// than news that waits for the next page load.
class NovidadeRepository {
  NovidadeRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url =
      'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/novidades';
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  Future<List<Novidade>> load() async {
    try {
      final resposta = await _client.get(
        Uri.parse('$_url?select=*&visivel=is.true&order=publicada_em.desc'),
        headers: const {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
          'Cache-Control': 'no-store',
        },
      );

      if (resposta.statusCode != 200) return const [];

      final linhas = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
      return [
        for (final linha in linhas)
          Novidade.fromJson(linha as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }
}
