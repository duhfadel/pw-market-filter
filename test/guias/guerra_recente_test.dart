import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/guerra_recente.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';

Video _video({
  required String youtube,
  String? detalhes,
  String? personagem,
  String? classe,
  DateTime? data,
}) => Video(
  secao: 'guerras',
  youtube: youtube,
  detalhes: detalhes,
  personagem: personagem,
  classe: classe,
  data: data,
);

void main() {
  test('quatro gravações da mesma guerra são uma linha', () {
    // O caso real, lido da base a 10/11/2026: a `Ragnarok x BUDOKAI` de
    // 01/11 está lá quatro vezes, uma por pessoa que a filmou.
    final guerras = guerrasRecentes([
      _video(
        youtube: 'a',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'Mozaum',
        classe: 'Retalhador',
        data: DateTime.utc(2026, 11),
      ),
      _video(
        youtube: 'b',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'ANTIФak',
        classe: 'Místico',
        data: DateTime.utc(2026, 11),
      ),
      _video(
        youtube: 'c',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'kS',
        classe: 'Sacerdote',
        data: DateTime.utc(2026, 11),
      ),
      _video(
        youtube: 'd',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'COMECU',
        classe: 'Mago',
        data: DateTime.utc(2026, 11),
      ),
    ]);

    expect(guerras, hasLength(1));
    expect(guerras.single.angulos, 4);
    expect(guerras.single.quem, 'Mozaum, ANTIФak, kS e COMECU');
  });

  test('uma gravação só mantém a classe; várias deixam-na cair', () {
    // Com uma pessoa a classe é informação sobre o ângulo e a tela de Guerras
    // já a imprime. Com quatro, quatro pares nome-classe numa linha deixam de
    // dizer alguma coisa sobre a guerra.
    final sozinho = guerrasRecentes([
      _video(
        youtube: 'a',
        detalhes: 'Sync x Genesys',
        personagem: 'TeamSpeakUser',
        classe: 'Arqueiro',
        data: DateTime.utc(2026, 11, 7),
      ),
    ]);
    expect(sozinho.single.quem, 'TeamSpeakUser · Arqueiro');
  });

  test('a mesma guilda em dias diferentes são duas guerras', () {
    // Só a manchete como chave juntaria duas batalhas de semanas diferentes.
    // A guerra territorial é semanal, portanto este caso é a norma.
    final guerras = guerrasRecentes([
      _video(
        youtube: 'a',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'Mozaum',
        data: DateTime.utc(2026, 11),
      ),
      _video(
        youtube: 'b',
        detalhes: 'Ragnarok x BUDOKAI',
        personagem: 'Mozaum',
        data: DateTime.utc(2026, 10, 25),
      ),
    ]);

    expect(guerras, hasLength(2));
    expect(guerras.first.dataEscrita, '01/11/2026');
  });

  test('a mais recente vem primeiro, e quem não tem data vai para o fim', () {
    // Uma guerra sem dia no topo da lista do que é recente afirmaria
    // exactamente aquilo que não tem como sustentar.
    final guerras = guerrasRecentes([
      _video(youtube: 'a', detalhes: 'Sem data'),
      _video(
        youtube: 'b',
        detalhes: 'Antiga',
        data: DateTime.utc(2026, 10, 25),
      ),
      _video(youtube: 'c', detalhes: 'Nova', data: DateTime.utc(2026, 11, 7)),
    ]);

    expect(
      [for (final g in guerras) g.manchete],
      ['Nova', 'Antiga', 'Sem data'],
    );
  });

  test('dois vídeos sem manchete nenhuma não se juntam um ao outro', () {
    // Sem nome, duas gravações do mesmo dia podiam ser de qualquer coisa, e
    // juntá-las seria afirmar uma guerra que ninguém nomeou.
    final guerras = guerrasRecentes([
      _video(youtube: 'a', data: DateTime.utc(2026, 11)),
      _video(youtube: 'b', data: DateTime.utc(2026, 11)),
    ]);

    expect(guerras, hasLength(2));
  });
}
