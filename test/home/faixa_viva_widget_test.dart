import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/ui/widgets/faixa_viva.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/price_history.dart';

/// Mounts the strip itself.
///
/// The domain test proves the numbers; this proves the **door** — that the
/// query the figure carries is the query the page receives. The two halves
/// cannot be checked together: a correct number behind a wrong door is the
/// failure mode here, and both look right on screen.
void main() {
  MarketCharacter pessoa({
    required int id,
    required int preco,
    PriceHistory? historia,
  }) => MarketCharacter(
    roleId: id,
    name: 'P$id',
    characterClass: 'Guerreiro',
    occupation: 1,
    level: 105,
    price: preco,
    cultivation: 'Céu',
    fame: 0,
    equipped: const [],
    history: historia,
  );

  MarketIndex mercadoDe(DateTime quando, List<MarketCharacter> gente) =>
      MarketIndex(
        server: 'pw187',
        collectedAt: quando,
        attributes: const [],
        items: const {},
        characters: gente,
      );

  late List<SearchQuery> abertas;

  Future<void> montar(
    WidgetTester tester,
    MarketIndex index, {
    double largura = 1280,
  }) async {
    abertas = [];
    tester.view.physicalSize = Size(largura, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FaixaViva(
            index: index,
            wide: largura >= 772,
            onAbrir: abertas.add,
          ),
        ),
      ),
    );
  }

  MarketIndex comMovimento() {
    final agora = DateTime(2026, 11, 9, 14, 30);
    return mercadoDe(agora, [
      // Entrou hoje e baixou — uma pessoa responde às duas perguntas, que é o
      // caso que um teste com uma figura por pessoa nunca exercita.
      pessoa(
        id: 1,
        preco: 100,
        historia: PriceHistory(
          firstSeen: agora,
          previousPrice: 200,
          lowestPrice: 100,
          cuts: 1,
        ),
      ),
      pessoa(
        id: 2,
        preco: 300,
        historia: PriceHistory(
          firstSeen: agora.subtract(const Duration(days: 40)),
          lowestPrice: 300,
          cuts: 0,
        ),
      ),
    ]);
  }

  testWidgets('desenha os três números com separador de milhar', (
    tester,
  ) async {
    final agora = DateTime(2026, 11, 9, 14, 30);
    await montar(
      tester,
      mercadoDe(agora, [
        for (var i = 0; i < 1234; i++) pessoa(id: i, preco: 10),
      ]),
    );
    expect(find.text('1.234'), findsOneWidget);
    expect(find.text('personagens à venda'), findsOneWidget);
  });

  testWidgets('cada porta entrega a sua própria pergunta', (tester) async {
    await montar(tester, comMovimento());

    await tester.tap(find.text('entraram hoje'));
    expect(abertas.single.novosEmDias, 1);
    expect(abertas.single.soComQueda, isFalse);

    await tester.tap(find.text('baixaram o preço'));
    expect(abertas.last.soComQueda, isTrue);
    expect(abertas.last.novosEmDias, isNull);

    await tester.tap(find.text('personagens à venda'));
    expect(abertas.last.isEmpty, isTrue, reason: 'o total não pede nada');
  });

  testWidgets('o carimbo de hoje diz a hora, não os dias', (tester) async {
    await montar(tester, comMovimento());
    // «há 0 dias» não responde à pergunta que alguém que voltou tem.
    expect(find.textContaining('hoje às 14:30'), findsOneWidget);
    expect(find.textContaining('há 0 dias'), findsNothing);
  });

  testWidgets('um índice de semanas atrás acende o carimbo', (tester) async {
    final velho = DateTime.now().subtract(const Duration(days: 30));
    await montar(tester, mercadoDe(velho, [pessoa(id: 1, preco: 10)]));
    final texto = tester.widget<Text>(find.textContaining('há 30 dias'));
    expect(texto.style?.color, isNot(equals(const Color(0xFF8F9BB8))));
  });

  // A faixa é três colunas de texto num telefone, e em `flutter_test` cada
  // glifo é um quadrado do tamanho da letra — portanto é aqui, e não no
  // navegador, que um rótulo de dezenove caracteres estoura primeiro.
  for (final largura in const [390.0, 772.0, 1280.0, 1920.0]) {
    testWidgets('não transborda a $largura px', (tester) async {
      await montar(tester, comMovimento(), largura: largura);
      expect(tester.takeException(), isNull);
    });
  }

  // A coleta corre a cada meia hora, portanto a fronteira da meia-noite é um
  // caso real e não construído: zero dias decorridos e ainda assim ontem.
  test('ontem às 23:50 lido à 00:10 não é hoje', () {
    final dias = FaixaViva.diasDeCalendario(
      DateTime(2026, 11, 8, 23, 50),
      DateTime(2026, 11, 9, 0, 10),
    );
    expect(dias, 1);
  });

  test('o mesmo dia é zero, por mais horas que separem', () {
    expect(
      FaixaViva.diasDeCalendario(
        DateTime(2026, 11, 9, 0, 5),
        DateTime(2026, 11, 9, 23, 55),
      ),
      0,
    );
  });
}
