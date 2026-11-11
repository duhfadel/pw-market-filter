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
/// testes injetavam o que a produção resolve: a tela de escolha nem carregava
/// e nenhum teste passava pelo caminho que um visitante faz. Aqui o
/// `configureDependencies` é o de verdade, portanto um `getIt` em falta
/// rebenta aqui em vez de girar para sempre no navegador.
Future<void> _montar(
  WidgetTester tester, {
  Map<String, List<String>> query = const {},
  double largura = 1200,
}) async {
  tester.view.physicalSize = Size(largura, 1400);
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
    // O mesmo contentor da produção. `BrowserMemory` fora do browser é a
    // implementação em memória, portanto cada teste começa com a gaveta do
    // processo — que é o que `InstanciasMemoria.chave` nomeia.
    if (!getIt.isRegistered<InstanciasMemoria>()) configureDependencies();
  });

  testWidgets(
    'sem ninguém, a tela diz o que fazer em vez de uma tabela vazia',
    (tester) async {
      await _montar(tester);

      expect(find.text('Nenhum personagem ainda.'), findsOneWidget);
      expect(find.text('Personagem'), findsOneWidget);
      // Um botão que copia um link vazio promete guardar o que não existe.
      expect(find.text('Copiar link'), findsNothing);
    },
  );

  testWidgets('a lista do endereço abre desenhada', (tester) async {
    // É isto que faz do link uma passagem para outro aparelho. Sem este
    // caminho, o botão de copiar seria um botão que não leva a lado nenhum.
    await _montar(
      tester,
      query: const {
        'p': ['Bardo~3~1~2~14~duhit', 'Mago~0~0~1~2~Mulexta'],
      },
    );

    expect(find.text('2 personagens'), findsOneWidget);
    expect(find.text('Copiar link'), findsOneWidget);
    // A soma de baixo: 14 + 2.
    expect(find.text('16'), findsOneWidget);
  });

  testWidgets('a tela diz onde a lista fica guardada', (tester) async {
    // **Quem não sabe que é por aparelho descobre a perder tudo.** Uma
    // ferramenta sem conta que parece ter conta é uma promessa que o site
    // não fez.
    await _montar(tester);

    expect(find.textContaining('guardada neste navegador'), findsOneWidget);
  });

  testWidgets('no telemóvel as quatro colunas ficam, e nada transborda', (
    tester,
  ) async {
    // **Empilhar os números daria quatro linhas por personagem** e acabava-se
    // a comparação, que é a razão de a ferramenta existir. O que encolhe é a
    // folga e o corpo, nunca o número de colunas — a mesma regra da grelha
    // dos Títulos.
    await _montar(
      tester,
      largura: 390,
      query: const {
        'p': ['Bardo~3~1~2~14~duhit', 'Arqueiro~5~5~5~31~farmante'],
      },
    );

    expect(find.text('Artefato'), findsOneWidget);
    expect(find.text('Chave'), findsOneWidget);
    expect(find.text('45'), findsOneWidget, reason: 'a soma das chaves');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar no cabeçalho ordena e tocar outra vez desfaz', (
    tester,
  ) async {
    await _montar(
      tester,
      query: const {
        'p': ['Bardo~0~0~0~2~poucas', 'Mago~0~0~0~90~muitas'],
      },
    );

    double y(String nome) => tester.getTopLeft(find.text(nome)).dy;
    expect(y('poucas'), lessThan(y('muitas')), reason: 'ordem de entrada');

    await tester.tap(find.text('Chave'));
    await tester.pumpAndSettle();
    expect(y('muitas'), lessThan(y('poucas')), reason: 'quem tem mais em cima');

    await tester.tap(find.text('Chave'));
    await tester.pumpAndSettle();
    expect(y('poucas'), lessThan(y('muitas')), reason: 'de volta ao início');
  });
}
