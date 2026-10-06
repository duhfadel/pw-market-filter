import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/guias/data/video_repository.dart';

/// O pedido que a tela faz ao Supabase.
void main() {
  late Uri pedida;

  VideoRepository comResposta(Object corpo, [int status = 200]) =>
      VideoRepository(
        MockClient((request) async {
          pedida = request.url;
          return http.Response(jsonEncode(corpo), status);
        }),
      );

  test('filtra a seção e a versão no servidor, não no cliente', () async {
    // Uma tela que baixasse os vídeos das cinco seções para mostrar os de uma
    // estaria a pagar pelo conteúdo das outras quatro — o mesmo raciocínio
    // que fez `public.mapa` existir.
    await comResposta(const []).daSecao('guerras', versao: '1.2.6');
    expect(pedida.query, contains('secao=eq.guerras'));
    expect(pedida.query, contains('versao=eq.1.2.6'));
  });

  test('sem versão pede a seção inteira', () async {
    // As outras quatro seções existem numa versão só, e um filtro a mais ali
    // esconderia as linhas de quem deixou a coluna em branco.
    await comResposta(const []).daSecao('astrolabio');
    expect(pedida.query, isNot(contains('versao=')));
  });

  test('só os visíveis, e o mais recente primeiro', () async {
    // Quem abre uma página de guerras quer ver a última. `ordem` fica como
    // desempate, e `nullslast` é o que mantém as seções de guia — onde
    // ninguém preenche a data — na ordem que alguém lhes deu.
    await comResposta(const []).daSecao('guerras');
    expect(pedida.query, contains('visivel=is.true'));
    expect(pedida.query, contains('order=data.desc.nullslast,ordem.asc'));
  });

  test('uma falha devolve lista vazia, nunca uma exceção', () async {
    // A grelha simplesmente não desenha. Um vídeo que grita um erro quando
    // não carrega é pior do que um que espera o próximo carregamento.
    expect(await comResposta(const {}, 500).daSecao('guerras'), isEmpty);
    expect(await comResposta('não é json').daSecao('guerras'), isEmpty);
  });
}
