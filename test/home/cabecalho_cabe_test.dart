import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';

import '../support/load_fonts.dart';
import '../support/novidades_test_support.dart';

/// A barra não transborda seja qual for a largura que a página lhe dê.
///
/// **É o teste que faltava, e a quarta pílula mostrou porquê — duas vezes.**
/// Ao acrescentar *Guerras* a barra transbordou 70 px com o nome completo; a
/// primeira versão deste ficheiro media a *janela*, deu tudo verde aos 772 px
/// e a suíte continuou a acusar 62 px de transbordo dentro de `first_fold`.
/// A razão é a diferença entre as duas medidas: `wide` liga aos 772 px de
/// janela, mas a home prende o conteúdo a 780 px entre 680 e 1279 e ainda lhe
/// tira margens — a barra recebe bastante menos do que o número que a acendeu.
///
/// Por isso o que se varre aqui é a largura **disponível**, e vai muito abaixo
/// do limiar: nenhuma secção futura pode voltar a partir a barra, e o teste
/// não deve ter de saber de quanto é a margem da página para continuar a
/// valer.
///
/// Com as fontes reais, sempre: `flutter_test` desenha cada glifo como um
/// quadrado do tamanho da fonte, o que inventaria um transbordo onde o
/// browser não tem nenhum e esconderia um que ele tem.
void main() {
  setUpAll(loadAppFonts);

  for (final disponivel in [360.0, 560.0, 700.0, 740.0, 772.0, 900.0, 1400.0]) {
    testWidgets('cabe em ${disponivel.toInt()} px de espaço', (tester) async {
      tester.view.physicalSize = const Size(1600, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: PWTheme.build(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: disponivel,
                child: comVisitas(
                  comNovidades(const Cabecalho(wide: true, versao: '1.8.7')),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // A marca é o que nunca sai: é o caminho de volta a casa.
      expect(find.byKey(const Key('cabecalho-marca')), findsOneWidget);
    });
  }
}
