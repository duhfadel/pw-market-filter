import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';
import 'package:pw_market_filter/features/guias/ui/widgets/cartao_de_video.dart';
import 'package:pw_market_filter/features/portas/ui/widgets/canal_do_portal.dart';

/// A banda do canal do Portal, na raiz.
void main() {
  // Os dois vídeos reais da tabela a 09/11/2026 — `secao = 'canal'`.
  const reais = [
    Video(
      secao: 'canal',
      youtube: 'USLLzGJmvrA',
      titulo: 'PortalPW 01 — Apresentação!',
      ordem: 1,
    ),
    Video(
      secao: 'canal',
      youtube: 'LneKbsxcCjw',
      titulo: 'PortalPW — Falha territorial 01!',
      ordem: 2,
    ),
  ];

  Future<void> montar(
    WidgetTester tester,
    List<Video> videos, {
    double largura = 1040,
    bool falhar = false,
  }) async {
    tester.view.physicalSize = Size(largura, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CanalDoPortal(
              wide: largura >= 772,
              espacoAcima: 28,
              carregar: () async {
                if (falhar) throw Exception('sem rede');
                return videos;
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('desenha os vídeos do canal, com cabeça própria', (tester) async {
    await montar(tester, reais);

    expect(find.text('O CANAL DO PORTAL PW'), findsOneWidget);
    expect(find.byType(CartaoDeVideo), findsNWidgets(2));
    expect(find.text('PortalPW 01 — Apresentação!'), findsOneWidget);
  });

  testWidgets('o painel convida, e a porta é a mesma nas duas larguras', (
    tester,
  ) async {
    // **O painel substituiu a secção lisa a 09/11/2026.** O canal é o que o
    // site está a começar agora, e a moldura dá-lhe o peso de um anúncio sem
    // precisar de o escrever. No estreito o convite passa para cima dos
    // vídeos em vez de ao lado — dois terços de 390 px não são uma coluna.
    await montar(tester, reais);
    expect(find.text('Os primeiros já estão no ar'), findsOneWidget);
    expect(find.text('Inscrever no YouTube →'), findsOneWidget);

    await montar(tester, reais, largura: 390);
    expect(find.text('Inscrever no YouTube →'), findsOneWidget);
  });

  testWidgets('sem vídeos não desenha nada, nem o espaço', (tester) async {
    // O canal nasceu a 09/11 com dois vídeos; antes disso a tabela estava
    // vazia, e é o estado em que a secção tem de desaparecer inteira. O
    // espaço é desenhado por dentro precisamente para se ir com ela.
    await montar(tester, const []);

    expect(find.text('O CANAL DO PORTAL PW'), findsNothing);
    // **Medido pela altura e não por contar widgets**: a secção devolve um
    // `SizedBox.shrink()`, portanto procurar `SizedBox` encontra-o sempre e
    // provava o contrário do que se quer. O que importa é não ocupar nada.
    expect(tester.getSize(find.byType(CanalDoPortal)).height, 0);
  });

  testWidgets('uma falha de rede cala-se, não grita', (tester) async {
    // É uma secção a somar e não a razão de alguém ter vindo — a mesma
    // escolha que a faixa dos streamers faz. Uma cortesia que grita ao
    // falhar é pior do que uma que se cala.
    await montar(tester, const [], falhar: true);

    expect(tester.takeException(), isNull);
    expect(find.text('O CANAL DO PORTAL PW'), findsNothing);
  });

  testWidgets('não transborda em nenhuma largura', (tester) async {
    for (final largura in const [390.0, 772.0, 1040.0, 1920.0]) {
      await montar(tester, reais, largura: largura);
      expect(tester.takeException(), isNull, reason: 'a $largura px');
    }
  });
}
