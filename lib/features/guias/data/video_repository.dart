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

  /// [versao] filtra por mercado quando a seção existe nos dois — as guerras
  /// territoriais são a primeira. Nulo pede a seção inteira, que é o que as
  /// seções de uma versão só querem.
  ///
  /// **[curada] inverte a prioridade da ordenação, e só o canal do Portal a
  /// pede.** As guerras são um feed cronológico — a última guerra em cima —, por
  /// isso a data manda e `ordem` só desempata. O canal é uma lista curada: o
  /// vídeo de apresentação fica fixo no topo (ordem baixa) e o resto segue por
  /// recência. Então aqui `ordem` manda e a data desempata — dar à apresentação
  /// uma ordem menor que a dos outros fixa-a em primeiro sem lhe mentir a data,
  /// e os outros, com a mesma ordem, ficam entre si por data decrescente.
  Future<List<Video>> daSecao(
    String secao, {
    String? versao,
    bool curada = false,
  }) async {
    try {
      final ordenacao = curada
          ? 'ordem.asc,data.desc.nullslast,publicado_em.desc'
          : 'data.desc.nullslast,ordem.asc,publicado_em.desc';
      final resposta = await _client.get(
        Uri.parse(
          '$_url?select=*&visivel=is.true'
          '&secao=eq.${Uri.encodeComponent(secao)}'
          '${versao == null ? '' : '&versao=eq.${Uri.encodeComponent(versao)}'}'
          // **A data manda, e `ordem` passa a ser só o desempate** — exceto no
          // canal curado, onde [curada] troca os dois. A primeira grelha com
          // dois vídeos mostrou o 20/09 antes do 04/10, porque a ordem era a de
          // inserção, e quem abre uma página de guerras quer ver a última.
          // `nullslast` é o que mantém as seções de guia a funcionar: lá ninguém
          // preenche a data, e sem isso elas iriam todas para o topo ou para o
          // fundo conforme o humor do Postgres, em vez de ficarem na ordem que
          // alguém lhes deu.
          '&order=$ordenacao',
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
