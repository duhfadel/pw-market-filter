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
    // Nulo e não string vazia: ausente é o que o card tem de poder ler para
    // não abrir com uma manchete em branco.
    expect(v.titulo, isNull);
    expect(v.classe, isNull);
  });

  group('o título é opcional', () {
    // Posto o primeiro vídeo de guerra a sério, o título do YouTube —
    // `Fluxo x Kaizen 20/09/2026 - Mozaum` — repetia os três campos que o
    // card já imprime por baixo. Nas Guerras os campos são o título.
    test('sem título, a manchete passa a ser a guerra', () {
      const semTitulo = Video(
        secao: 'guerras',
        youtube: 'wrEvjz8hEU0',
        personagem: 'Mozaum',
        detalhes: 'Fluxo x Kaizen',
      );

      expect(semTitulo.manchete, 'Fluxo x Kaizen');
      // E não por baixo também: promovido é gasto.
      expect(semTitulo.detalhesPorBaixo, isNull);
    });

    test('com título, os detalhes continuam na sua linha', () {
      const comTitulo = Video(
        secao: 'guerras',
        youtube: 'x',
        titulo: 'Como ler o mapa durante a TW',
        detalhes: 'Fluxo x Kaizen',
      );

      expect(comTitulo.manchete, 'Como ler o mapa durante a TW');
      expect(comTitulo.detalhesPorBaixo, 'Fluxo x Kaizen');
    });

    test('sem título e sem detalhes não há manchete para inventar', () {
      const nu = Video(secao: 'astrolabio', youtube: 'x');

      expect(nu.manchete, isNull);
      expect(nu.detalhesPorBaixo, isNull);
    });

    test('um título em branco no painel vale como ausente', () {
      // Branco é "não se aplica" e tem de virar nulo, ou o card abre com uma
      // manchete vazia à altura de duas linhas.
      final branco = Video.fromJson(const {
        'secao': 'guerras',
        'youtube': 'x',
        'titulo': '   ',
        'detalhes': 'Fluxo x Kaizen',
      });

      expect(branco.titulo, isNull);
      expect(branco.manchete, 'Fluxo x Kaizen');
    });

    test('a busca sem título continua a achar pela guilda e pelo nick', () {
      // É o que o dono quer que se procure, e é onde a guilda está escrita.
      const v = Video(
        secao: 'guerras',
        youtube: 'x',
        personagem: 'Mozaum',
        classe: 'Retalhador',
        detalhes: 'Fluxo x Kaizen',
      );

      expect(v.contem('kaizen'), isTrue);
      expect(v.contem('mozaum'), isTrue);
      expect(v.contem('retalhador'), isTrue);
      expect(v.contem('nuema'), isFalse);
    });
  });
}
