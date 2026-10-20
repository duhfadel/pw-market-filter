import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

/// O astrolábio, o conduíte e o livro divino, que o parser via vazios.
///
/// **Medido a 20/10/2026 antes de uma linha ser escrita**: 2.193 astrolábios,
/// 1.998 conduítes e 1.726 livros divinos no índice do 1.8.7, todos com zero
/// atributos, contra 2.193 de 2.193 na armadura. Os dados estavam na página;
/// o parser é que só conhecia a forma `➜ Nome +Valor`.
///
/// Os números abaixo foram lidos das páginas reais com o browser, e só depois
/// cravados aqui — é essa a ordem que faz um teste valer alguma coisa.
void main() {
  late List<ParsedItem> leandrim;
  late List<ParsedItem> mulexta;

  setUpAll(() {
    leandrim = parseEquippedItems(
      File('test/fixtures/detail_64112.html').readAsStringSync(),
    );
    mulexta = parseEquippedItems(
      File('test/fixtures/detail_92624.html').readAsStringSync(),
    );
  });

  ParsedItem slot(List<ParsedItem> itens, int n) =>
      itens.singleWhere((i) => i.slot == n);

  group('astrolábio', () {
    test('os ramos somam-se em vez de se dividirem em dois atributos', () {
      // `Destino · Espírito +155` e `Guia · Espírito +83` são o mesmo espírito
      // vindo dos dois ramos. Guardar `Destino · Espírito` e `Guia · Espírito`
      // separados partiria em duas colunas uma coisa que o jogador soma.
      final astro = slot(leandrim, 17);

      expect(astro.attributes['Espírito'], [155, 83]);
      // `Destino · Atq Físico +497` aparece duas vezes na página, e as duas
      // contam — é a mesma razão de `HP +500 / +150 / +150` numa arma.
      expect(astro.attributes['Atq Físico'], [497, 497]);
      expect(astro.attributes['Def Fogo'], [1020]);
      expect(astro.attributes.containsKey('Destino · Atq Físico'), isFalse);
    });

    test('o nível é lido, e é contexto e não força', () {
      // Lido para a tela poder dizê-lo. Quem o usar como medida erra: três
      // personagens no nível 100 do conduíte dão +32, +32 e +26 de ataque.
      expect(slot(leandrim, 17).nivel, 49);
      expect(slot(mulexta, 17).nivel, 57);
    });

    test('um astrolábio rico traz as nove linhas, não as duas de um fraco', () {
      final astro = slot(mulexta, 17);

      expect(astro.attributes['Atq Físico'], [658, 890]);
      expect(astro.attributes['Pen. Física'], [872, 1339]);
      expect(astro.attributes['Def Terra'], [1652, 2088]);
    });
  });

  group('conduíte', () {
    test('os decimais são arredondados, não descartados', () {
      // A página escreve `HP +69.60` e `Atq Físico +2.20`. O padrão antigo só
      // aceitava inteiros, portanto não via nenhum dos dois.
      final cond = slot(leandrim, 16);

      expect(cond.attributes['HP'], [70]);
      expect(cond.attributes['Def'], [621]);
      expect(cond.attributes['Atq Físico'], [2]);
      expect(cond.attributes['DefM'], [38]);
      expect(cond.nivel, 60);
    });

    test('o nível de ataque do conduíte entra no índice', () {
      // **É o número que faltava.** Este site gira à volta de uma arma com
      // nível de ataque 70; o conduíte do Mulexta acrescenta +32, e a tela
      // não o via de todo.
      final cond = slot(mulexta, 16);

      expect(cond.attributes['Nv. de Ataque'], [32]);
      expect(cond.attributes['Nv. de Defesa'], [32]);
      expect(cond.attributes['Atq Físico'], [2008]);
      expect(cond.nivel, 100);
    });
  });

  group('livro divino', () {
    test('só os patamares já ganhos contam, e a cor é quem os separa', () {
      // O livro imprime a escada inteira. O `Cosmos +12` tem `(+3)`, `(+6)`,
      // `(+9)` e `(+12)` a verde e `(+15) : Maior Nível +15` a cinzento. Ler
      // a escada toda daria a um +12 os bónus de um +15.
      final livro = slot(mulexta, 11);

      expect(livro.refine, 12);
      expect(livro.attributes['Nv. de Ataque'], [5, 15]);
      expect(livro.attributes['Atq Físico'], contains(50));
      expect(livro.attributes.containsKey('Maior Nível'), isFalse);
    });

    test('o patamar sai do nome: `(+3) : Atq Físico` é Atq Físico', () {
      final livro = slot(mulexta, 11);

      expect(livro.attributes.keys.any((k) => k.startsWith('(+')), isFalse);
    });
  });

  test('o que já funcionava continua a funcionar', () {
    // A arma do Leandrim é o caso que o resto da suíte crava, e a forma com
    // seta não pode ter-se partido ao acrescentar a forma com `<span>`.
    final arma = slot(leandrim, 10);

    expect(arma.attributes['Nível de Ataque'], [70]);
    expect(arma.attributes['HP'], [500, 150, 150]);
    expect(arma.nivel, 0);
  });

  group('a cor é a gramática, e não a decoração', () {
    // O `Maior Nível` do livro está ausente por **duas** razões ao mesmo
    // tempo — o patamar cinzento e o bloco de ouro — e um teste sobre a
    // fixture não sabe dizer qual delas funcionou. Estes dois provam cada
    // mecanismo sozinho.
    List<ParsedItem> comTooltip(String tooltip) => parseEquippedItems(
      '<ul class="character-equip--list"><li data-item-type="slot-11" '
      'data-item-grade="grade-6"><img src="/1.png" alt="x" '
      'data-pw187-tooltip=\'$tooltip\'></li></ul>',
    );

    test('verde conta, cinzento não', () {
      final item = comTooltip(
        '<span style="color:#6cff6c;">(+3) : Atq Físico +50</span><br>'
        '<span style="color:#a7a7a7;">(+15) : Maior Nível +15</span>',
      ).single;

      expect(item.attributes['Atq Físico'], [50]);
      expect(item.attributes.containsKey('Maior Nível'), isFalse);
    });

    test(
      'uma cor que não é a do não-ganho conta, e isso é a escolha segura',
      () {
        // Se o site inventar uma cor nova para um bónus real, incluí-la erra
        // para o lado de mostrar a mais, que alguém vê e corrige. Excluí-la
        // apagaria em silêncio um atributo que o personagem tem.
        final item = comTooltip(
          '<span style="color:#123456;">Def Fogo +99</span>',
        ).single;

        expect(item.attributes['Def Fogo'], [99]);
      },
    );

    test('o site a dizer que não sabe cala a leitura inteira', () {
      // Visto num conduíte de nível 2. Ler o resto daria zero atributos, e um
      // zero aqui seria uma afirmação que ninguém verificou.
      final item = comTooltip(
        '<span style="color:#6ea2ff;">Atributos do Conduíte não resolvidos.</span>'
        '<br><span style="color:#6ea2ff;">HP +500</span>',
      ).single;

      expect(item.attributes, isEmpty);
    });
  });

  test('o bloco de ouro do livro fica de fora, e é decisão e não descuido', () {
    // `Força +50`, `Canalização -5%`, `Intervalo de Ataque -0.05s`: nove
    // bónus dentro de **um** `<span>`, separados por `<br />`.
    //
    // Ficam fora por duas razões. São intrínsecos ao item — todo `Cosmos` tem
    // os mesmos —, portanto não distinguem um personagem de outro, que é a
    // única coisa que este índice serve para fazer. E trazem unidades que o
    // modelo não sabe dizer: guardar `Canalização = -5` quando a página diz
    // `-5%` seria afirmar pontos onde há percentagem.
    //
    // Se um dia forem precisos, o sítio é `MarketIndex.items` — uma vez por
    // item — e não a lista de cada personagem.
    final livro = slot(mulexta, 11);

    expect(livro.attributes.containsKey('Força'), isFalse);
    expect(livro.attributes.containsKey('Canalização'), isFalse);
  });
}
