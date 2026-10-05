import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/video.dart';

/// Lê os vídeos de uma seção. Nunca lança.
///
/// **Uma lista vazia para toda falha**, como a faixa de streamers e a barra de
/// novidades: a grelha simplesmente não desenha. Um vídeo que grita um erro
/// quando não carrega é pior do que um que espera o próximo carregamento — e,
/// ao contrário do índice do mercado, aqui não há nada que o visitante possa
/// fazer com a informação de que o pedido falhou.
///
/// A seção é filtrada no servidor e não no cliente. Uma tela que baixasse os
/// vídeos das cinco para mostrar os de uma estaria a pagar pelo conteúdo das
/// outras quatro — o mesmo raciocínio que fez `public.mapa` existir.
class VideoRepository {
  VideoRepository([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _url = 'https://yadfbwsolmkcaylbxviw.supabase.co/rest/v1/videos';
  static const _key = 'sb_publishable_D2hgezeh5BbZVpt_QLeXwg_FowKweu2';

  Future<List<Video>> daSecao(String secao) async {
    try {
      final resposta = await _client.get(
        Uri.parse(
          '$_url?select=*&visivel=is.true'
          '&secao=eq.${Uri.encodeComponent(secao)}'
          '&order=ordem.asc,publicado_em.desc',
        ),
        headers: const {
          'apikey': _key,
          'Authorization': 'Bearer $_key',
          // O mesmo motivo do mapa de guerras: o Supabase não manda
          // `cache-control` nenhum numa leitura REST, então alguém tem de o
          // dizer. E o truque do `?t=` que o índice usa não serve aqui — o
          // PostgREST lê todo parâmetro que não reconhece como filtro de uma
          // coluna com esse nome e responde `PGRST100`.
          'Cache-Control': 'no-store',
        },
      );
      if (resposta.statusCode != 200) return const [];

      final linhas = jsonDecode(utf8.decode(resposta.bodyBytes)) as List;
      return [
        for (final linha in linhas)
          Video.fromJson(linha as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }
}
