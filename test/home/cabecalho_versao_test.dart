import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/tool.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';

import '../support/novidades_test_support.dart';

/// A barra é a mesma em todas as telas, e até 05/10/2026 listava as
/// ferramentas do 1.8.7 dentro do 1.2.6 — quatro portas das quais nenhuma
/// servia o mercado onde o visitante estava.
///
/// **Nenhuma delas erraria em silêncio.** O filtro tem `/1.8.7/filtro` cravado
/// na rota, portanto clicar nele a partir do 1.2.6 trocava a versão debaixo
/// dos pés de quem clicou.
Future<void> _montar(
  WidgetTester tester, {
  String? versao,
  bool semMercado = false,
  bool wide = true,
}) async {
  tester.view.physicalSize = const Size(1400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      home: Scaffold(
        appBar: AppBar(
          title: comVisitas(
            comNovidades(
              Cabecalho(wide: wide, versao: versao, semMercado: semMercado),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('no 1.8.7 as pílulas das suas ferramentas aparecem', (
    tester,
  ) async {
    await _montar(tester, versao: '1.8.7');

    expect(find.text('Ferramentas'), findsOneWidget);
    expect(find.text('Guias'), findsOneWidget);
  });

  testWidgets('no 1.2.6 aparece só a pílula que serve o 1.2.6', (tester) async {
    // **Este teste mudou de forma a 09/11/2026, e era o que ele próprio
    // mandava.** Dizia: «hoje nenhuma ferramenta serve o 1.2.6, portanto as
    // duas pílulas somem — quando houver uma, ela aparece sozinha, e este
    // teste passa a cravar que só a dela aparece». É agora: as multi contas
    // deixaram de estar presas a `/1.8.7` e passaram a servir as três
    // versões, por falarem do cliente do jogo e não de um mercado.
    //
    // Nenhuma *ferramenta* serve o 1.2.6 ainda, portanto essa pílula continua
    // a sumir — e é isso que faz este teste continuar a ser sobre a pergunta
    // certa, e não só sobre o número de pílulas.
    await _montar(tester, versao: '1.2.6');

    expect(find.text('Ferramentas'), findsNothing);
    expect(find.text('Guias'), findsOneWidget);
  });

  testWidgets('no seletor, que ainda não escolheu mercado, aparece tudo', (
    tester,
  ) async {
    // Ali a barra é o catálogo do site. Esconder tudo deixaria a página de
    // entrada sem menu nenhum.
    await _montar(tester);

    expect(find.text('Ferramentas'), findsOneWidget);
    expect(find.text('Guias'), findsOneWidget);
  });

  test('só o que não depende de um mercado fica sem versão', () {
    // **A regra que estava aqui era «toda ferramenta declara a versão», e o
    // comentário dela já dizia a excepção**: uma entrada sem versões vale
    // para todas, «o que é certo para o que não depende de um mercado — e
    // errado para tudo o que a lista tem hoje». A 09/11/2026 passou a haver
    // um caso certo, portanto a regra é nomeada em vez de absoluta: jogar com
    // dois clientes abertos é uma coisa do computador de quem joga.
    //
    // Nomeada e não aberta, de propósito. Uma entrada sem versão por
    // distracção é o defeito de 05/10 outra vez — um menu a oferecer portas
    // que não servem a versão onde o visitante está — e a lista aqui obriga
    // a decidir em vez de deixar passar.
    const semMercado = {'Multi contas'};
    for (final tool in tools) {
      if (semMercado.contains(tool.name)) {
        expect(
          tool.versoes,
          isEmpty,
          reason: '${tool.name} serve as três e não deve declarar versão',
        );
        continue;
      }
      expect(
        tool.versoes,
        isNotEmpty,
        reason: '${tool.name} não diz a que mercado pertence',
      );
    }
    expect(toolsDe('Ferramentas', versao: '1.2.6'), isEmpty);
    expect(toolsDe('Ferramentas', versao: '1.8.7'), isNotEmpty);
  });

  // **O seletor não pode oferecer porta nenhuma de mercado, e isto é a
  // correcção de um defeito de 27/10/2026.**
  //
  // `Tool.serveA(null)` devolve tudo, por isso a página de entrada exibia as
  // quatro secções. O que ninguém pesou: `rotaDaTool` sem versão cai no
  // 1.8.7, portanto clicar em *Ferramentas* ali escolhia o mercado em
  // silêncio — a única pergunta que aquela tela existe para fazer, respondida
  // por ela mesma.
  //
  // *Novidades* fica, e é a única que pode: lê as mesmas mensagens para os
  // dois mercados.
  testWidgets('o seletor só mostra Novidades, em qualquer largura', (
    tester,
  ) async {
    for (final wide in [true, false]) {
      await _montar(tester, semMercado: true, wide: wide);

      for (final secao in secoesDaHome) {
        expect(
          find.text(secao),
          findsNothing,
          reason: 'A secção $secao não pode aparecer antes de escolher mercado',
        );
      }
      expect(find.text('Novidades'), wide ? findsOneWidget : findsNothing);
      expect(find.byKey(const Key('cabecalho-marca')), findsOneWidget);
    }
  });

  // E o contrário, para o teste acima não passar por o cabeçalho ter deixado
  // de desenhar seja o que for: com mercado, as secções voltam.
  testWidgets('com mercado escolhido, as secções voltam', (tester) async {
    await _montar(tester, versao: '1.8.7');

    expect(find.text('Ferramentas'), findsOneWidget);
  });
}
