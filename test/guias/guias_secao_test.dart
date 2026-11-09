import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/guia.dart';
import 'package:pw_market_filter/features/guias/ui/widgets/guias_secao.dart';

/// The guides section on a version's screen.
///
/// Runs on **both** marketplaces, because the two vocabularies are not the
/// same: 1.8.7 has seven guides of its own and 1.2.6 has none, so the branch
/// that matters — a version whose only guide is the one that serves all — is
/// only reachable from the 1.2.6 side. This repository has lost three defects
/// to a test that only ever loaded one version.
void main() {
  Future<void> montar(
    WidgetTester tester,
    String versao, {
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

    expect(find.text('GUIAS'), findsOneWidget);
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
    expect(find.text('GUIAS'), findsOneWidget);
  });

  testWidgets('a porta para a lista inteira fica, nas duas versões', (
    tester,
  ) async {
    for (final versao in ['1.8.7', '1.2.6']) {
      await montar(tester, versao);
      expect(
        find.text('Todos os guias'),
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

  test('a tela de escolha não tem secção de guias, e por isso não é nula', () {
    // `null` em `guiasDe` quer dizer «todos», que é a página `/guias/`.
    // `GuiasSecao.versao` é obrigatório exactamente para que ninguém monte
    // esta secção a listar os oito numa tela que ainda não escolheu mercado.
    expect(guiasDe(null), hasLength(guias.length));
  });
}
