import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/rotas.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';
import 'package:pw_market_filter/features/guias/ui/multi_contas_view.dart';

import '../support/load_fonts.dart';
import '../support/novidades_test_support.dart';

/// O guia de multi contas, e o que ele herda da tela genérica de vídeos.
void main() {
  setUpAll(loadAppFonts);

  Future<void> montar(WidgetTester tester, List<Video> videos) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: PWTheme.build(),
        home: comBusca(
          comVisitas(
            comNovidades(MultiContasView(carregar: () async => videos)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a tela abre pelo que o guia é, não por uma grelha nua', (
    tester,
  ) async {
    await montar(tester, const []);

    expect(find.text('Multi contas'), findsOneWidget);
    // **A ferramenta tem nome, e o nome é o que se procura.** Quem chega
    // aqui quer saber como, e `TC Helper` é a palavra que resolve a busca —
    // um guia que a omitisse mandava a pessoa procurar noutro sítio.
    expect(find.textContaining('TC Helper'), findsOneWidget);
    // E que é permitido: é a primeira coisa que alguém quer confirmar antes
    // de abrir a segunda janela.
    expect(find.textContaining('é permitido'), findsOneWidget);
  });

  testWidgets('vazia, convida em vez de ser um beco', (tester) async {
    // O mesmo recado da tela das guerras, e pela mesma razão: nada aqui é
    // garimpado, portanto a página depende de alguém se oferecer.
    await montar(tester, const []);

    expect(find.textContaining('Ainda não há vídeos'), findsOneWidget);
    expect(find.textContaining('Quer o seu vídeo aqui'), findsOneWidget);
  });

  testWidgets('um vídeo desenha, e sem filtro de classe', (tester) async {
    // **A fila de classes não precisa de ser desligada por seção**: ela lê as
    // classes que os vídeos trazem, e num guia ninguém preenche a coluna. Uma
    // regra por seção seria uma quarta coisa a lembrar ao abrir a quinta tela.
    await montar(tester, [
      const Video(
        secao: 'multicontas',
        youtube: 'abc',
        titulo: 'Dois clientes na mesma máquina',
      ),
    ]);

    expect(find.text('Dois clientes na mesma máquina'), findsOneWidget);
    expect(find.text('Todos'), findsNothing);
  });

  test('a rota do guia resolve, e não tem gémea no 1.2.6', () {
    // Um guia escrito uma vez não existe duas. O que obrigou as guerras a
    // terem duas rotas foi os vídeos serem de um mercado ou do outro.
    expect(
      resolverRota('/1.8.7/multicontas'),
      isA<RotaTela>().having((r) => r.tela, 'tela', Tela.multiContas),
    );
    expect(
      resolverRota('/1.2.6/multicontas'),
      isA<RotaTela>().having((r) => r.tela, 'tela', Tela.home126),
    );
  });
}
