import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';

/// Um vídeo de uma tela de guia.
void main() {
  Video video({String? classe, String youtube = 'abc123'}) => Video(
    secao: 'guerras',
    youtube: youtube,
    titulo: 'Guerra em Nuema',
    classe: classe,
  );

  group('o endereço vem do id', () {
    test('a miniatura e o link derivam ambos do mesmo id', () {
      final v = video();
      expect(v.miniatura, 'https://img.youtube.com/vi/abc123/hqdefault.jpg');
      expect(v.endereco, 'https://www.youtube.com/watch?v=abc123');
    });

    test('a miniatura é hqdefault, que existe sempre', () {
      // `maxresdefault` só existe se o canal tiver enviado capa em alta, e
      // quando não existe o YouTube responde uma imagem cinzenta de 120×90
      // em vez de um 404 — falha parecendo que funcionou.
      expect(video().miniatura, contains('hqdefault'));
      expect(video().miniatura, isNot(contains('maxres')));
    });
  });

  group('a classe', () {
    test('texto vazio vira nulo, não uma classe chamada vazio', () {
      expect(Video.fromJson(const {'classe': '  '}).classe, isNull);
      expect(Video.fromJson(const {'classe': 'Bárbaro'}).classe, 'Bárbaro');
    });

    test('a fila de classes vem dos vídeos, nunca das dezassete do jogo', () {
      final lista = [
        video(classe: 'Bárbaro', youtube: 'a'),
        video(classe: 'Arqueiro', youtube: 'b'),
        video(classe: 'Bárbaro', youtube: 'c'),
        video(youtube: 'd'),
      ];

      expect(classesCom(lista), ['Bárbaro', 'Arqueiro']);
    });

    test('uma seção sem classe nenhuma não oferece filtro', () {
      expect(classesCom([video(), video(youtube: 'x')]), isEmpty);
    });
  });

  test('uma linha incompleta não derruba a lista', () {
    // O painel é editado à mão. Uma linha a meio não pode levar a tela
    // inteira — o mesmo motivo de o repositório devolver lista vazia.
    final v = Video.fromJson(const {});
    expect(v.youtube, '');
    expect(v.titulo, '');
    expect(v.classe, isNull);
  });
}
