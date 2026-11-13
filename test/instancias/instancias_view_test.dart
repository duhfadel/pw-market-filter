import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/features/instancias/data/instancias_memoria.dart';
import 'package:pw_market_filter/features/instancias/ui/instancias_view.dart';

import '../support/load_fonts.dart';
import '../support/novidades_test_support.dart';

/// **Montada como o `main.dart` a monta, e não com um falso injetado.**
///
/// A 02/10/2026 três defeitos bloqueantes chegaram a um build verde porque os
/// testes injetavam o que a produção resolve. Aqui o `configureDependencies` é
/// o de verdade, portanto um `getIt` em falta rebenta no teste em vez de
/// girar para sempre no navegador.
Future<void> _montar(
  WidgetTester tester, {
  Map<String, List<String>> query = const {},
  double largura = 1200,
}) async {
  tester.view.physicalSize = Size(largura, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: comNovidades(InstanciasView(query: query))),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    if (!getIt.isRegistered<InstanciasMemoria>()) configureDependencies();
  });

  testWidgets('a lista do endereço abre desenhada, com grupos e total', (
    tester,
  ) async {
    await _montar(
      tester,
      query: const {
        'g': ['Principal', 'Mula'],
        'p': ['0~Bardo~3~1~2~14~~duhit', '1~Mago~0~0~1~2~~mula1'],
      },
    );

    expect(find.text('Principal'), findsWidgets);
    expect(find.text('Mula'), findsWidgets);
    expect(find.text('duhit'), findsOneWidget);
    expect(find.text('mula1'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    // Total geral das chaves: 14 + 2.
    expect(find.textContaining('Total · 2'), findsOneWidget);
    expect(find.text('16'), findsWidgets);
  });

  testWidgets('a tela diz onde a lista fica guardada', (tester) async {
    await _montar(tester);
    expect(find.textContaining('guardada neste navegador'), findsOneWidget);
  });

  testWidgets('no telemóvel as quatro colunas ficam, e nada transborda', (
    tester,
  ) async {
    await _montar(
      tester,
      largura: 390,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~3~1~2~14~~duhit', '0~Arqueiro~5~5~5~31~~farmante'],
      },
    );
    expect(find.text('Artefato'), findsOneWidget);
    expect(find.text('Chave'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar + e − muda o número e o total', (tester) async {
    // O pedido do dono: usar uma chave é um toque, não selecionar e reescrever.
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~5~~duhit'],
      },
    );

    // A Chave é a última coluna; o + dela é o último botão 'add' da linha.
    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Total · 1'), findsOneWidget);
    expect(find.text('6'), findsWidgets, reason: '5 + 1');

    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.pumpAndSettle();
    expect(find.text('4'), findsWidgets, reason: '6 − 2');
  });

  testWidgets('tocar no cabeçalho ordena dentro do grupo e desfaz', (
    tester,
  ) async {
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~2~~poucas', '0~Mago~0~0~0~90~~muitas'],
      },
    );

    double y(String n) => tester.getTopLeft(find.text(n)).dy;
    expect(y('poucas'), lessThan(y('muitas')));
    await tester.tap(find.text('Chave'));
    await tester.pumpAndSettle();
    expect(y('muitas'), lessThan(y('poucas')));
  });

  testWidgets('arrastar um personagem leva-o para outro grupo', (tester) async {
    // **O coração do pedido.** Um toque longo levanta o personagem, e largar
    // dentro do outro grupo move-o para lá.
    await _montar(
      tester,
      query: const {
        'g': ['Principal', 'Mula'],
        'p': ['0~Bardo~0~0~0~1~~viajante', '1~Mago~0~0~0~2~~fixo'],
      },
    );

    // Pega-se pela pega: só ela arrasta, e o arrasto é imediato (sem toque
    // longo) para o rato o descobrir. viajante é o primeiro, logo a sua pega
    // é o primeiro drag_indicator.
    final pega = tester.getCenter(find.byIcon(Icons.drag_indicator).first);
    final alvo = tester.getCenter(find.text('fixo'));
    final gesto = await tester.startGesture(pega);
    await tester.pump();
    for (var i = 1; i <= 8; i++) {
      await gesto.moveTo(Offset.lerp(pega, alvo, i / 8)!);
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesto.up();
    await tester.pumpAndSettle();

    // Ainda lá está, mas agora abaixo do 'fixo' — mudou de grupo.
    expect(find.text('viajante'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('fixo')).dy,
      lessThan(tester.getTopLeft(find.text('viajante')).dy),
      reason: 'viajante foi para o grupo Mula, abaixo do fixo',
    );
  });

  testWidgets('criar um grupo não some com os outros', (tester) async {
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~1~~duhit'],
      },
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Grupo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Mula');
    await tester.tap(find.widgetWithText(FilledButton, 'Criar'));
    await tester.pumpAndSettle();

    expect(find.text('Mula'), findsWidgets);
    expect(find.text('duhit'), findsOneWidget);
  });

  testWidgets('pegar a diária de um personagem soma 1 em cada entrada', (
    tester,
  ) async {
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~5~~duhit'],
      },
    );

    // O botão de pegar a diária é o único Icons.redeem (um por personagem e
    // um na barra do grupo — aqui o do personagem é o segundo; a barra é o
    // primeiro). Pegar pela barra do grupo soma a todos; vamos pelo do
    // personagem, que é o último redeem da linha.
    await tester.tap(find.byIcon(Icons.redeem).last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Artefato/Arma/Armadura passaram de 0 para 1; a chave ficou em 5.
    expect(find.text('1'), findsWidgets);
    expect(find.text('5'), findsWidgets, reason: 'a chave não mudou');
    // E agora diz que já pegou: aparece o visto.
    expect(find.byIcon(Icons.event_available), findsWidgets);
  });

  testWidgets('a barra do grupo pega por todos e depois diz que já pegaram', (
    tester,
  ) async {
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~1~~a', '0~Mago~0~0~0~2~~b'],
      },
    );

    expect(find.textContaining('Pegar entradas de hoje'), findsOneWidget);
    await tester.tap(find.textContaining('Pegar entradas de hoje'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Já não há botão de pegar — todos pegaram — e a barra vira o recado.
    expect(find.textContaining('Pegar entradas de hoje'), findsNothing);
    expect(find.textContaining('Todos já pegaram'), findsOneWidget);
  });

  testWidgets('um campo do link aparece como ficha no personagem', (
    tester,
  ) async {
    // O caso que o dono descreveu: o amigo abre o link e vê tudo. A marcação
    // ligada, a escolha e a nota chegam todas pelo endereço.
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'cf': ['0~c~Fez TW', '1~e~Status', '2~t~Obs'],
        'co': ['1~Ativo', '1~Vendendo'],
        'p': ['0~Bardo~0~0~0~0~~duhit'],
        'x': ['0~0~1', '0~1~Ativo', '0~2~lembrete aqui'],
      },
    );

    expect(find.text('Fez TW'), findsOneWidget);
    expect(find.text('Ativo'), findsWidgets);
    expect(find.textContaining('lembrete aqui'), findsOneWidget);
  });

  testWidgets('criar um campo pela folha põe-no no personagem', (tester) async {
    await _montar(
      tester,
      query: const {
        'g': ['A'],
        'p': ['0~Bardo~0~0~0~0~~duhit'],
      },
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Campo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Nome curto do campo'),
      'Fez TW',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Criar campo'));
    await tester.pumpAndSettle();
    // Fecha a folha.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // A ficha do campo novo aparece no personagem, por marcar.
    expect(find.text('Fez TW'), findsOneWidget);
  });
}
