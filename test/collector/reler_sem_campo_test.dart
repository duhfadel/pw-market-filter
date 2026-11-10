import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';
import 'package:pw_market_filter/collector/reler_sem_campo.dart';

/// Reler só quem está sem o campo, em vez de recolher o mercado inteiro.
///
/// A 06/11/2026 o site traduziu-se a meio de duas recolhas e o sexo e o reino
/// vieram vazios em 2.879 personagens. O arrasto da última leitura boa salvou
/// 2.785 no índice, mas o **estado** continuou vazio — e é dele que a próxima
/// recolha parte. Subir o carimbo custaria ~150 minutos numa corrida só;
/// isto custa ~11 por corrida e o site publica em todas.
/// **O critério mudou a 10/11/2026 e o ficheiro ficou**, que é o ponto: a
/// reparação do sexo e do reino acabou — zero em falta no índice daquela
/// manhã — e o mesmo mecanismo passou a servir os títulos de fundador. O
/// parser lia o primeiro card do documento em vez do mais alto, portanto
/// quem tem dois pacotes decodificados ficou com o grau errado guardado.
///
/// São 186 de 2.961 — dez minutos —, contra as duas horas e meia que subir o
/// carimbo custaria.
CollectedPage _pagina({String fundador = ''}) => CollectedPage(
  items: const [],
  cards: const [],
  sex: 'Feminino',
  realm: 'Céu Real I',
  titles: ParsedTitles(
    decoded: 0,
    inOctet: 0,
    equipped: '',
    attributes: const {},
    founder: fundador,
  ),
);

void main() {
  test('escolhe quem tem título de fundador guardado', () {
    final alvos = aReler({
      1: _pagina(fundador: 'Fundador X'),
      2: _pagina(),
      3: _pagina(fundador: 'Fundador I'),
    }, const {});

    expect(alvos, {1, 3});
  });

  test('quem não tem título nenhum fica de fora', () {
    // **Sem card nenhum o parser não teve nada para escolher mal**, portanto
    // a leitura não pode estar errada. Pô-los na fila gastaria duas horas e
    // meia da rede deles para confirmar o que já se sabe — e é precisamente
    // essa diferença que separa isto de subir o carimbo.
    final alvos = aReler({1: _pagina(), 2: _pagina()}, const {});

    expect(alvos, isEmpty);
  });

  test('quem já foi relido não volta à fila', () {
    // Sem esta memória, um personagem cuja ficha genuinamente não imprime os
    // dois campos seria relido em todas as corridas para sempre — que é a
    // razão pela qual o carimbo é um número e não «falta esta chave?».
    final estado = {
      1: _pagina(fundador: 'Fundador X'),
      2: _pagina(fundador: 'Fundador V'),
    };

    expect(aReler(estado, const {1}), {2});
    expect(aReler(estado, const {1, 2}), isEmpty);
  });

  test('o motivo é um número, para a memória poder ser esquecida', () {
    // `relidos` guarda quem já foi relido **por um motivo**. Quando o motivo
    // muda, a memória passa a responder a outra pergunta — foi o que
    // aconteceu à primeira: releu-se o mercado por faltarem os campos, e no
    // dia seguinte descobriu-se que a língua era sorteada por pedido. As
    // mesmas páginas precisavam de voltar à fila, e `relidos` dizia que não.
    // Subiu a 2 quando a causa da tradução foi encontrada, e a 3 quando o
    // mecanismo passou a servir os fundadores. Cada subida esquece tudo uma
    // vez, que é o que põe as mesmas páginas de volta na fila.
    expect(motivoDaReleitura, greaterThan(2));
  });

  test('o tecto é respeitado, e é ele que separa isto de um carimbo novo', () {
    final estado = {
      for (var i = 0; i < 500; i++) i: _pagina(fundador: 'Fundador II'),
    };

    expect(aReler(estado, const {}, tecto: 200), hasLength(200));
    expect(releiturasPorCorrida, 200);
  });

  test('um estado inteiro já lido não gera trabalho nenhum', () {
    // O conjunto esgota-se sozinho: é isso que torna a reparação temporária
    // em vez de um custo permanente em cada corrida.
    final estado = {1: _pagina()};

    expect(aReler(estado, const {}), isEmpty);
  });
}
