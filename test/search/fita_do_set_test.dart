import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/core/widgets/game_icon.dart';
import 'package:pw_market_filter/features/search/ui/widgets/fita_do_set.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/pedras.dart';
import 'package:pw_market_filter/market/slot_names.dart';

/// A fita diz o que o personagem veste, e a ordem dela é a do jogador.
MarketIndex _index({String server = 'pw187'}) => MarketIndex(
  server: server,
  collectedAt: DateTime.utc(2026, 10, 20),
  attributes: const [],
  items: const {
    50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6),
    1: MarketItem(name: 'Elmo', grade: 2),
    2: MarketItem(name: 'Armadura', grade: 2),
  },
  characters: const [],
);

EquippedItem _peca(
  int slot, {
  int item = 1,
  int refine = 0,
  List<int> pedras = const [],
}) => EquippedItem(
  slot: slot,
  itemId: item,
  refine: refine,
  stones: pedras,
  attributes: const {},
);

MarketCharacter _quem(List<EquippedItem> pecas) => MarketCharacter(
  roleId: 1,
  name: 'quem',
  characterClass: 'Bardo',
  occupation: 1,
  level: 105,
  price: 40,
  fame: 0,
  cultivation: 'Leal',
  equipped: pecas,
);

Future<void> _montar(
  WidgetTester tester,
  MarketCharacter quem,
  MarketIndex index,
) => tester.pumpWidget(
  MaterialApp(
    theme: PWTheme.build(),
    home: Scaffold(
      body: SizedBox(
        width: 324,
        child: FitaDoSet(character: quem, index: index),
      ),
    ),
  ),
);

void main() {
  testWidgets('a arma não entra na fita, porque o bloco acima já a nomeia', (
    tester,
  ) async {
    // Um ícone de 30 px a repetir a arma não acrescenta nada e tira o lugar
    // de uma peça que mais ninguém mostra.
    await _montar(
      tester,
      _quem([_peca(weaponSlot, item: 50206), _peca(8), _peca(2)]),
      _index(),
    );

    expect(find.byType(ItemIcon), findsNWidgets(2));
  });

  test('as peças saem na ordem das linhas, não na do número do slot', () {
    // Por número, o cinto (5) viria antes da capa (6) e antes do elmo (8). A
    // ordem do jogador põe o elmo e a armadura na primeira linha e o cinto na
    // segunda — e é essa a ordem que a fita percorre.
    final linhas = linhasDaFitaDe(_index());

    expect(linhas.first, [8, 2, 7, 3, 4]);
    expect(linhas[1], contains(5));
    expect(linhas.last, [17, 16, 11]);

    // Nenhum slot em duas linhas: um ícone repetido seria uma peça inventada.
    final todos = linhas.expand((l) => l).toList();
    expect(todos.toSet(), hasLength(todos.length));
  });

  testWidgets('uma peça num slot que nenhuma linha reclama desenha na mesma', (
    tester,
  ) async {
    // As linhas são a arrumação de hoje. Um slot que o jogo acrescente amanhã
    // não pode desaparecer em silêncio: um personagem a usar uma peça que o
    // card não mostra é pior do que uma fila desarrumada.
    await _montar(tester, _quem([_peca(8), _peca(99)]), _index());

    expect(find.byType(ItemIcon), findsNWidgets(2));
  });

  testWidgets('o refino aparece, e só quando existe', (tester) async {
    await _montar(tester, _quem([_peca(8, refine: 12), _peca(2)]), _index());

    expect(find.text('+12'), findsOneWidget);
    expect(find.textContaining('+0'), findsNothing);
  });

  testWidgets('sem peça nenhuma não desenha fita', (tester) async {
    await _montar(tester, _quem(const []), _index());

    expect(find.byType(ItemIcon), findsNothing);
  });

  test('as linhas do 1.2.6 usam os números daquele mercado', () {
    // Os anéis são 0 e 1 lá, 18 e 19 aqui — e aquele mercado não tem
    // astrolábio, conduíte nem livro divino.
    final pw126 = _index(server: 'pw126');
    final linhas126 = linhasDaFitaDe(pw126);
    final linhas187 = linhasDaFitaDe(_index());

    expect(linhas126.expand((l) => l), containsAll([0, 1]));
    expect(linhas126.expand((l) => l), isNot(contains(17)));
    expect(linhas187.expand((l) => l), containsAll([18, 19, 17, 16, 11]));

    // E a arma fica fora das duas, porque o card já a nomeia.
    expect(linhas126.expand((l) => l), isNot(contains(weaponSlot)));
    expect(linhas187.expand((l) => l), isNot(contains(weaponSlot)));
  });

  test('toda a pedra do mercado real tem nome, ou é dita como número', () {
    // **Mede sem reprovar**, que é a linha do `confirmedCountedItems`: uma
    // pedra nova é facto sobre o mercado deles, não defeito nosso. O que
    // falharia aqui é a tabela estar vazia — isso seria nosso.
    expect(nomesDasPedras, isNotEmpty);
    expect(nomesDasPedras[51112], contains('Olho Vermelho'));
  });

  group('duas ocorrências do mesmo atributo', () {
    // **A queixa do dono em 21/10/2026.** O astrolábio do Mulexta dá
    // `Atq Físico +658` por um ramo e `+890` pelo outro, e a tela mostrava
    // `+1548`. Ele quer os dois: são dois bónus, de dois sítios, e vê-los
    // separados diz onde o personagem investiu.
    final index = MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 21),
      attributes: const ['Atq Físico', 'Nível de Ataque'],
      items: const {1: MarketItem(name: 'Astrolábio: Arqueiro', grade: 6)},
      characters: const [],
    );

    const astrolabio = EquippedItem(
      slot: 17,
      itemId: 1,
      refine: 0,
      stones: [],
      attributes: {
        0: [658, 890],
      },
    );

    test('o índice guarda as duas, e não a soma', () {
      expect(astrolabio.attributes[0], [658, 890]);
      expect(astrolabio.attributes[0], isNot(contains(1548)));
    });

    test('mas quem precisa de um número só continua a ter a soma', () {
      // O filtro compara com um mínimo e a moldura escolhe um degrau —
      // nenhum deles sabe o que fazer com duas, e os dois têm de aplicar a
      // **mesma** regra, ou dois sítios do site dizem números diferentes
      // sobre a mesma peça.
      expect(astrolabio.atributo(0, index), 1548);
    });

    test('os três níveis continuam a tomar a maior, não a soma', () {
      // Uma arma que lista `70` e depois `+1` é uma 70. Somar punha-a acima
      // de todas as 70 verdadeiras, com um número que nenhuma outra tem.
      const arma = EquippedItem(
        slot: 10,
        itemId: 1,
        refine: 12,
        stones: [],
        attributes: {
          1: [70, 1],
        },
      );

      expect(arma.atributo(1, index), 70);
    });
  });
}
