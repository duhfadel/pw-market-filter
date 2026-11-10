import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/guia.dart';
import 'package:pw_market_filter/features/guias/ui/widgets/guias_secao.dart';

import '../support/load_fonts.dart';

/// The guides section on a version's screen.
///
/// Runs on **both** marketplaces, because the two vocabularies are not the
/// same: 1.8.7 has seven guides of its own and 1.2.6 has none, so the branch
/// that matters — a version whose only guide is the one that serves all — is
/// only reachable from the 1.2.6 side. This repository has lost three defects
/// to a test that only ever loaded one version.
void main() {
  // **Com as fontes reais, e isso não é zelo.** Sem elas o harness desenha
  // cada glifo como um quadrado do tamanho da fonte, e os três testes de
  // transbordo abaixo passam a medir a fonte falsa: `GUIAS DESTA VERSÃO` dava
  // 281 px em quadrados contra os **177** que Marcellus desenha, e fabricava
  // um transbordo de 6,3 px a 390 que nenhum navegador mostra. Um teste de
  // largura sobre a fonte do harness mede o harness.
  setUpAll(loadAppFonts);

  Future<void> montar(
    WidgetTester tester,
    String? versao, {
    double largura = 1280,
  }) async {
    tester.view.physicalSize = Size(largura, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GuiasSecao(versao: versao, wide: largura >= 772),
          ),
        ),
      ),
    );
  }

  testWidgets('o 1.8.7 mostra os seus, com a linha de cada um', (tester) async {
    await montar(tester, '1.8.7');

    expect(find.text('GUIAS DESTA VERSÃO'), findsOneWidget);
    expect(find.text('Cartas Nuema'), findsOneWidget);
    expect(find.text('Quanto custa uma runa nível 10'), findsOneWidget);
    // A linha é o que separa um nome numa gaveta de um artigo vendido.
    expect(
      find.textContaining('As seis cartas S do conjunto Portal de Nuema'),
      findsOneWidget,
    );
  });

  testWidgets('o 1.2.6 recebe o que fala do cliente e nada do 1.8.7', (
    tester,
  ) async {
    await montar(tester, '1.2.6');

    expect(find.text('Multi contas'), findsOneWidget);
    expect(find.text('Cartas Nuema'), findsNothing);
    // E a secção não nasce vazia, que era o risco de filtrar por versão numa
    // versão que ainda não tem guias próprios.
    expect(find.text('GUIAS DESTA VERSÃO'), findsOneWidget);
  });

  testWidgets('a porta para a lista inteira fica, nas duas versões', (
    tester,
  ) async {
    for (final versao in ['1.8.7', '1.2.6']) {
      await montar(tester, versao);
      // **A porta mudou de sítio e de palavra a 09/11/2026**: estava no fim
      // da secção, depois de oito cartas, e só a encontrava quem rolasse até
      // lá. Vive na cabeça agora, e diz o que a outra página acrescenta.
      expect(
        find.text('os ${guias.length} →'),
        findsOneWidget,
        reason: 'sem ela, $versao lê como se o site tivesse só estes',
      );
    }
  });

  testWidgets('só o guia de todas as versões ganha etiqueta', (tester) async {
    // Escrever `1.8.7` em sete de oito cartas numa tela de 1.8.7 é ruído. O
    // que vale dizer é qual delas não é de cá.
    await montar(tester, '1.8.7');

    expect(find.text('todas as versões'), findsOneWidget);
    expect(find.text('1.8.7'), findsNothing);
  });

  testWidgets('nenhum minuto de leitura aqui', (tester) async {
    // Medir o ficheiro é `dart:io`, que `lib/` não importa — e guardar os
    // minutos à mão na declaração seria o mesmo facto em dois sítios. A
    // medida vive na página `/guias/`, que é onde alguém escolhe o que ler.
    await montar(tester, '1.8.7');
    expect(find.textContaining('min de leitura'), findsNothing);
  });

  for (final largura in const [390.0, 772.0, 1280.0]) {
    testWidgets('não transborda a $largura px', (tester) async {
      await montar(tester, '1.8.7', largura: largura);
      expect(tester.takeException(), isNull);
    });
  }

  test('nenhuma versão fica sem guia nenhum, e é por isso que a cabeça '
      'nunca está sozinha', () {
    // **A guarda do `isEmpty` no widget é inalcançável hoje, e isto diz
    // porquê em vez de finjir que a testou.** Vazio em `Guia.versoes` quer
    // dizer *todas*, portanto até uma versão que não existe recebe as multi
    // contas — escrevi primeiro um teste a montar `'inexistente'` à espera de
    // nada, e ele reprovou com razão.
    //
    // A guarda fica porque passa a valer no dia em que as multi contas
    // declararem versões, e o que se crava é a premissa dela: enquanto cada
    // versão oferecida tiver um guia, nenhum `GUIAS` desenha sobre nada.
    for (final versao in const ['1.8.7', '1.2.6', '1.4.4']) {
      expect(
        guiasDe(versao),
        isNotEmpty,
        reason:
            '$versao ficaria com a '
            'cabeça GUIAS sobre uma lista vazia',
      );
    }
  });

  testWidgets('a raiz lista todos, cada um com a sua versão à vista', (
    tester,
  ) async {
    // **Este teste substituiu um que afirmava o contrário**, e é decisão de
    // produto e não conserto: `GuiasSecao.versao` era obrigatório para que
    // ninguém montasse a secção numa tela sem mercado escolhido. A 09/11/2026
    // a raiz deixou de ser um torniquete e passou a ter secções próprias,
    // portanto o caso de fora passou a existir — e ali a versão de cada guia
    // é precisamente a informação que falta.
    await montar(tester, null);

    // Na raiz a secção é mesmo toda a lista; numa tela de versão é um
    // recorte, e chamar-lhe «todos» afirmaria oito guias de 1.2.6.
    expect(find.text('TODOS OS GUIAS'), findsOneWidget);
    expect(find.text('Cartas Nuema'), findsOneWidget);
    expect(find.text('Multi contas'), findsOneWidget);
    // Sete cartas de 1.8.7 e uma de todas as versões.
    expect(find.text('1.8.7'), findsNWidgets(guiasDe('1.8.7').length - 1));
    expect(find.text('todas as versões'), findsOneWidget);
  });
}
