import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/novidade.dart';
import 'package:pw_market_filter/features/home/ui/novidades_view_model.dart';
import 'package:pw_market_filter/features/portas/ui/widgets/novidades_na_raiz.dart';

import '../support/load_fonts.dart';

/// O último recado, na raiz.
class _Fixo extends Cubit<List<Novidade>> implements NovidadesViewModel {
  _Fixo(super.novidades);

  @override
  Future<void> load() async {}
}

void main() {
  // Fontes reais: em `flutter_test` cada glifo é um quadrado do tamanho da
  // letra, e a cabeça desta secção é uma linha de texto contra um link —
  // exactamente a forma que a fonte falsa faz transbordar sem defeito.
  setUpAll(loadAppFonts);

  Novidade recado(String titulo, String corpo, DateTime quando) => Novidade(
    titulo: titulo,
    corpo: corpo,
    autor: 'duhit',
    versoes: const [],
    publicadaEm: quando,
  );

  Future<void> montar(
    WidgetTester tester,
    List<Novidade> novidades, {
    double largura = 1040,
  }) async {
    tester.view.physicalSize = Size(largura, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<NovidadesViewModel>.value(
        value: _Fixo(novidades),
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: NovidadesNaRaiz(wide: largura >= 772, espacoAcima: 34),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('mostra o último recado, aberto', (tester) async {
    // **Aberto e não fechado como a barra antiga.** Três entradas abertas
    // corriam a mil píxeis na home antiga, e foi por isso que aquela nasceu
    // fechada; um recado são noventa a duzentos, e fechado não diria nada
    // que a pílula do cabeçalho já não diga.
    await montar(tester, [
      recado('Três semanas', 'Primeiro.', DateTime.utc(2026, 10, 23)),
      recado('Mais velho', 'Segundo.', DateTime.utc(2026, 9, 1)),
    ]);

    expect(find.text('NOVIDADES DO PORTAL'), findsOneWidget);
    expect(find.text('Três semanas'), findsOneWidget);
    expect(find.text('Primeiro.'), findsOneWidget);
    // Um só: os outros vivem em `/novidades`, e a porta está na cabeça.
    expect(find.text('Mais velho'), findsNothing);
    expect(find.text('todos os recados →'), findsOneWidget);
  });

  testWidgets('a data é por extenso e sem o ano', (tester) async {
    // Um recado que precise do ano para se situar já não é novidade, e
    // estaria em `/novidades`.
    await montar(tester, [
      recado('Título', 'Corpo.', DateTime.utc(2026, 10, 23, 12)),
    ]);
    expect(find.text('23 de outubro'), findsOneWidget);
  });

  testWidgets('sem recado nenhum não desenha nada, nem o espaço', (
    tester,
  ) async {
    // A tabela pode estar vazia e o Discord pode ter apagado — nenhuma
    // dessas é avaria que valha um recado de erro numa página de entrada.
    await montar(tester, const []);

    expect(find.text('NOVIDADES DO PORTAL'), findsNothing);
    expect(tester.getSize(find.byType(NovidadesNaRaiz)).height, 0);
  });

  testWidgets('um recado sem título desenha na mesma', (tester) async {
    // `_tituloPattern` exige a primeira linha inteiramente em negrito; uma
    // nota curta não é um grito, e o painel não pode sumir por isso.
    await montar(tester, [
      Novidade(
        titulo: null,
        corpo: 'Uma nota curta.',
        autor: 'duhit',
        versoes: const [],
        publicadaEm: DateTime.utc(2026, 11, 1),
      ),
    ]);

    expect(find.text('Uma nota curta.'), findsOneWidget);
    expect(find.text('1 de novembro'), findsOneWidget);
  });

  testWidgets('não transborda em nenhuma largura', (tester) async {
    for (final largura in const [390.0, 772.0, 1130.0]) {
      await montar(tester, [
        recado('Título', 'Corpo do recado.', DateTime.utc(2026, 11, 1)),
      ], largura: largura);
      expect(tester.takeException(), isNull, reason: 'a $largura px');
    }
  });
}
