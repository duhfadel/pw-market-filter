import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/collected_page.dart';
import 'package:pw_market_filter/collector/reler_sem_campo.dart';

/// Reler só quem está sem o campo, em vez de recolher o mercado inteiro.
///
/// A 06/11/2026 o site traduziu-se a meio de duas recolhas e o sexo e o reino
/// vieram vazios em 2.879 personagens. O arrasto da última leitura boa salvou
/// 2.785 no índice, mas o **estado** continuou vazio — e é dele que a próxima
/// recolha parte. Subir o carimbo custaria ~150 minutos numa corrida só;
/// isto custa ~11 por corrida e o site publica em todas.
CollectedPage _pagina({String sex = '', String realm = ''}) =>
    CollectedPage(items: const [], cards: const [], sex: sex, realm: realm);

void main() {
  test('escolhe quem tem algum dos dois campos em falta', () {
    final alvos = aReler({
      1: _pagina(sex: 'Masculino', realm: 'Céu Real I'),
      2: _pagina(),
      3: _pagina(realm: 'Céu Devoto V'),
    }, const {});

    expect(alvos, {2, 3});
  });

  test('faltar um dos dois já basta', () {
    // **Mudou a 07/11, e a mudança vem de se saber a causa.** Enquanto ela
    // era desconhecida, exigir os dois vazios era a assinatura prudente de
    // uma leitura falhada. Com a língua fixa a ficha lê-se inteira, portanto
    // faltar um já é motivo — e era exactamente o caso que escapava: o reino
    // vinha do painel `Alma Celeste` e o sexo ficava vazio.
    final alvos = aReler({
      1: _pagina(realm: 'Céu Real I'),
      2: _pagina(sex: 'Feminino'),
      3: _pagina(sex: 'Feminino', realm: 'Céu Real I'),
    }, const {});

    expect(alvos, {1, 2});
  });

  test('quem já foi relido não volta à fila', () {
    // Sem esta memória, um personagem cuja ficha genuinamente não imprime os
    // dois campos seria relido em todas as corridas para sempre — que é a
    // razão pela qual o carimbo é um número e não «falta esta chave?».
    final estado = {1: _pagina(), 2: _pagina()};

    expect(aReler(estado, const {1}), {2});
    expect(aReler(estado, const {1, 2}), isEmpty);
  });

  test('o motivo é um número, para a memória poder ser esquecida', () {
    // `relidos` guarda quem já foi relido **por um motivo**. Quando o motivo
    // muda, a memória passa a responder a outra pergunta — foi o que
    // aconteceu à primeira: releu-se o mercado por faltarem os campos, e no
    // dia seguinte descobriu-se que a língua era sorteada por pedido. As
    // mesmas páginas precisavam de voltar à fila, e `relidos` dizia que não.
    expect(motivoDaReleitura, greaterThan(1));
  });

  test('o tecto é respeitado, e é ele que separa isto de um carimbo novo', () {
    final estado = {for (var i = 0; i < 500; i++) i: _pagina()};

    expect(aReler(estado, const {}, tecto: 200), hasLength(200));
    expect(releiturasPorCorrida, 200);
  });

  test('um estado inteiro já lido não gera trabalho nenhum', () {
    // O conjunto esgota-se sozinho: é isso que torna a reparação temporária
    // em vez de um custo permanente em cada corrida.
    final estado = {1: _pagina(sex: 'Masculino', realm: 'Céu Real I')};

    expect(aReler(estado, const {}), isEmpty);
  });
}
