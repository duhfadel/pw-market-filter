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
Future<void> _montar(WidgetTester tester, {String? versao}) async {
  tester.view.physicalSize = const Size(1400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: PWTheme.build(),
      home: Scaffold(
        appBar: AppBar(
          title: comVisitas(
            comNovidades(Cabecalho(wide: true, versao: versao)),
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

  testWidgets('no 1.2.6 não aparece pílula de ferramentas do 1.8.7', (
    tester,
  ) async {
    // Hoje nenhuma ferramenta serve o 1.2.6, portanto as duas pílulas somem.
    // Quando houver uma, ela aparece sozinha — e este teste passa a cravar
    // que só a dela aparece, que é a mesma pergunta.
    await _montar(tester, versao: '1.2.6');

    expect(find.text('Ferramentas'), findsNothing);
    expect(find.text('Guias'), findsNothing);
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

  test('toda ferramenta de hoje declara a versão a que serve', () {
    // Uma entrada sem versões vale para todas, o que é certo para o que não
    // depende de um mercado — e errado para tudo o que a lista tem hoje.
    for (final tool in tools) {
      expect(
        tool.versoes,
        isNotEmpty,
        reason: '${tool.name} não diz a que mercado pertence',
      );
    }
    expect(toolsDe('Ferramentas', versao: '1.2.6'), isEmpty);
    expect(toolsDe('Ferramentas', versao: '1.8.7'), isNotEmpty);
  });
}
