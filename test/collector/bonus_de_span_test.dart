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
    test('o ramo sai do nome: é o mesmo atributo de duas fontes', () {
      // **Decidido duas vezes.** Eu juntei, o dono mandou separar, viu os
      // nove nomes compridos que isso dava num astrolábio de nível 57 e
      // mandou juntar outra vez. Quem tem `Destino · Espírito +155` e
      // `Guia · Espírito +83` tem 238 de espírito.
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
    test('os decimais ficam como a página os escreve', () {
      // **Decisão do dono em 20/10/2026, depois de ver o arredondamento.** A
      // página escreve `HP +69.60` e `Atq Físico +2.20`; o padrão antigo só
      // aceitava inteiros e não via nenhum dos dois. Eu passei a arredondar,
      // o que em `-0.05s` dá zero — e zero na tela diz *não muda*.
      final cond = slot(leandrim, 16);

      expect(cond.attributes['HP'], [69.6]);
      expect(cond.attributes['Def'], [621.4]);
      expect(cond.attributes['Atq Físico'], [2.2]);
      expect(cond.attributes['DefM'], [37.6]);
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
    test('só os ganhos entram nos atributos, que é o que se filtra', () {
      // Um filtro que pergunte por `Nv. de Ataque +15` não pode devolver quem
      // ainda não lá chegou. Os degraus por alcançar vivem na escada, não
      // aqui.
      final livro = slot(mulexta, 11);

      expect(livro.refine, 12);
      expect(livro.attributes['Nv. de Ataque'], [5, 15]);
      expect(livro.attributes['Atq Físico'], contains(50));
      // `Maior Nível` existe duas vezes na página: `(+15)` a cinzento, que
      // não conta, e `+5` no bloco de base, que conta. Portanto está cá — e
      // o que **não** está é o 15 do patamar por alcançar.
      expect(livro.attributes['Maior Nível'], [5]);
      expect(livro.attributes['Maior Nível'], isNot(contains(15)));
    });

    test('a escada vem inteira, com os degraus que faltam marcados', () {
      // Decisão do dono: mostrar o que o jogo mostra. É a diferença entre
      // dizer *este livro dá isto* e *este livro dá isto e ainda pode dar
      // aquilo*, e a segunda é a que ajuda quem está a comprar.
      final escada = slot(mulexta, 11).escada;

      expect(escada, isNotEmpty);
      final porAlcancar = escada.where((d) => !d.ganho).toList();
      expect(porAlcancar, hasLength(1));
      expect(porAlcancar.single.refino, 15);
      expect(porAlcancar.single.atributo, 'Maior Nível');
      expect(porAlcancar.single.valor, 15);

      // E os ganhos trazem o degrau que os exigiu, que é o que o jogo mostra.
      final ganhos = escada.where((d) => d.ganho).toList();
      expect(ganhos.map((d) => d.refino), containsAll([3, 6, 9, 12]));
      expect(
        ganhos.any((d) => d.refino == 12 && d.atributo == 'Nv. de Ataque'),
        isTrue,
      );
    });

    test('um item que não é livro não tem escada nenhuma', () {
      expect(slot(mulexta, 16).escada, isEmpty);
      expect(slot(leandrim, 10).escada, isEmpty);
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
      // E o degrau cinzento está na escada, marcado.
      expect(item.escada.where((d) => !d.ganho).single.atributo, 'Maior Nível');
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

    test('o site a dizer que não sabe cala a leitura e fica marcado', () {
      // Visto num conduíte de nível 2. Ler o resto daria zero atributos, e um
      // zero aqui seria uma afirmação que ninguém verificou.
      //
      // **A marca é o que separa dois factos diferentes**: "este conduíte não
      // dá bónus nenhum" é sobre o personagem; "a página deles não resolve os
      // bónus" é sobre o site. Sem ela os dois saem iguais do parser, e a
      // tela não tem como dizer *não sabemos* em vez de *não tem*.
      final item = comTooltip(
        '<span style="color:#6ea2ff;">Atributos do Conduíte não resolvidos.</span>'
        '<br><span style="color:#6ea2ff;">HP +500</span>',
      ).single;

      expect(item.attributes, isEmpty);
      expect(item.bonusNaoResolvidos, isTrue);
    });

    test('um item sem bónus nenhum não é o mesmo que um por resolver', () {
      final vazio = comTooltip('<strong>Cinto</strong>').single;

      expect(vazio.attributes, isEmpty);
      expect(vazio.bonusNaoResolvidos, isFalse);
    });
  });

  group('o bloco de ouro do livro', () {
    // Nove bónus dentro de **um** `<span>`, separados por `<br />`. Eu tinha
    // deixado o bloco de fora — por serem iguais em todo `Cosmos`, logo sem
    // poder de distinguir, e por trazerem unidades que o modelo não dizia. O
    // dono mandou pô-lo dentro, e a unidade resolveu-se indo para o nome.
    test('entra, com a unidade no nome', () {
      final livro = slot(mulexta, 11);

      expect(livro.attributes['Força'], [50]);
      expect(livro.attributes['Destreza'], [50]);
      // `-5` sem o `%` diria pontos onde há percentagem — o mesmo erro do
      // `Movimento m/seg. +1036831949` já registado neste repositório.
      expect(livro.attributes['Canalização %'], [-5]);
      expect(livro.attributes['Defesa Física %'], [10]);
      expect(livro.attributes.containsKey('Canalização'), isFalse);
    });

    test('o valor que arredondaria para zero fica inteiro', () {
      // `Intervalo de Ataque -0.05s`. Arredondado dá `0`, que na tela diz
      // *não muda* quando muda — foi o que fez o dono recusar o
      // arredondamento. Tentei antes guardar centésimos com a escala no nome
      // e ele recusou também, com razão: um número que precisa de um nome a
      // explicar a escala já não é o número que a página mostra.
      final livro = slot(mulexta, 11);

      expect(livro.attributes['Intervalo de Ataque s'], [-0.05]);
    });

    test('um bloco não relê o que o `<span>` de uma linha já deu', () {
      // **A sonda apanhou isto antes de ir para lado nenhum.** Sem exigir um
      // `<br>` dentro, o padrão do bloco casava também com os `<span>` de uma
      // linha e tudo saía a dobrar: a arma do Leandrim veio com
      // `HP [500, 150, 150, 500, 150, 150]` e com o `➜` colado ao nome.
      final arma = slot(leandrim, 10);

      expect(arma.attributes['HP'], [500, 150, 150]);
      expect(arma.attributes.keys.any((k) => k.startsWith('➜')), isFalse);
      // E o conduíte, que tem seis `<span>` de uma linha cada.
      expect(slot(mulexta, 16).attributes['Nv. de Ataque'], [32]);
    });
  });
}
