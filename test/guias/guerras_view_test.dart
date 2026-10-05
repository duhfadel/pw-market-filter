import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';
import 'package:pw_market_filter/features/guias/ui/guerras_view.dart';

import '../support/load_fonts.dart';
import '../support/novidades_test_support.dart';

/// A tela das guerras territoriais.
void main() {
  setUpAll(loadAppFonts);

  Video video(
    String youtube, {
    String? classe,
    String? personagem,
    DateTime? data,
    String? detalhes,
  }) => Video(
    secao: 'guerras',
    youtube: youtube,
    titulo: 'Guerra $youtube',
    classe: classe,
    personagem: personagem,
    data: data,
    detalhes: detalhes,
  );

  Future<void> montar(WidgetTester tester, List<Video> videos) async {
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: PWTheme.build(),
        home: comBusca(
          comVisitas(comNovidades(GuerrasView(carregar: () async => videos))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a política aparece antes dos vídeos', (tester) async {
    // É o que distingue esta página de um agregador, e o dono escreveu-a ele
    // próprio. Enterrada no meio passaria como detalhe.
    await montar(tester, [video('a', classe: 'Bárbaro')]);

    expect(find.textContaining('me deram permissão para tal'), findsOneWidget);
  });

  testWidgets('o filtro só oferece as classes que têm vídeo', (tester) async {
    // A regra de todo controlo deste site: uma fila de dezassete ícones dos
    // quais quinze não dão resultado ensina o contrário do que devia.
    await montar(tester, [
      video('a', classe: 'Bárbaro'),
      video('b', classe: 'Arqueiro'),
    ]);

    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Bárbaro'), findsWidgets);
    expect(find.text('Arqueiro'), findsWidgets);
    expect(find.text('Mago'), findsNothing);
  });

  testWidgets('escolher uma classe esconde os vídeos das outras', (
    tester,
  ) async {
    await montar(tester, [
      video('a', classe: 'Bárbaro'),
      video('b', classe: 'Arqueiro'),
    ]);

    expect(find.text('Guerra a'), findsOneWidget);
    expect(find.text('Guerra b'), findsOneWidget);

    await tester.tap(find.text('Arqueiro').first);
    await tester.pumpAndSettle();

    expect(find.text('Guerra a'), findsNothing);
    expect(find.text('Guerra b'), findsOneWidget);
  });

  testWidgets('sem vídeo nenhum, a página é um convite e não um beco', (
    tester,
  ) async {
    await montar(tester, const []);

    expect(find.textContaining('Ainda não há vídeos'), findsOneWidget);
    expect(find.textContaining('Quer o seu vídeo aqui'), findsOneWidget);
  });

  testWidgets('o convite fica mesmo quando já há vídeos', (tester) async {
    // Como nada é garimpado, a página depende de alguém se oferecer.
    // Escondê-lo depois de entrar o primeiro fecharia a porta por onde ela
    // se enche.
    await montar(tester, [video('a', classe: 'Bárbaro')]);

    expect(find.textContaining('Quer o seu vídeo aqui'), findsOneWidget);
  });

  testWidgets('o card diz quem gravou, quando, e qual foi a guerra', (
    tester,
  ) async {
    await montar(tester, [
      video(
        'a',
        classe: 'Bárbaro',
        personagem: 'Maloquivera',
        data: DateTime.utc(2026, 10, 12),
        detalhes: 'Guerra Alpha x Omega',
      ),
    ]);

    expect(find.textContaining('Maloquivera'), findsOneWidget);
    // Em dia/mês/ano, nunca no ISO que a base guarda: ninguém lê
    // `2026-10-12` como uma data desta semana.
    expect(find.textContaining('12/10/2026'), findsOneWidget);
    expect(find.text('Guerra Alpha x Omega'), findsOneWidget);
  });

  testWidgets('campos em falta não deixam separadores soltos', (tester) async {
    // Um `·` a abrir a linha é o que acontece quando se juntam campos vazios
    // sem olhar — e o painel é editado à mão, portanto faltarão.
    await montar(tester, [video('a', personagem: 'Maloquivera')]);

    expect(find.text('Maloquivera'), findsOneWidget);
    expect(find.textContaining('·  Maloquivera'), findsNothing);
  });

  testWidgets('a busca procura em tudo, inclusive na guilda escrita à mão', (
    tester,
  ) async {
    // Ideia do dono: um campo de texto sobre o que já está escrito torna a
    // guilda procurável sem lhe dar coluna própria.
    await montar(tester, [
      video('a', personagem: 'Maloquivera', detalhes: 'Guerra Alpha x Omega'),
      video('b', personagem: 'Crux', detalhes: 'Guerra Delta x Sigma'),
    ]);

    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pumpAndSettle();

    expect(find.text('Guerra a'), findsOneWidget);
    expect(find.text('Guerra b'), findsNothing);

    // E pelo personagem também, com o mesmo campo.
    await tester.enterText(find.byType(TextField), 'crux');
    await tester.pumpAndSettle();

    expect(find.text('Guerra a'), findsNothing);
    expect(find.text('Guerra b'), findsOneWidget);
  });

  testWidgets('"nada ainda" e "nada que case" são recados diferentes', (
    tester,
  ) async {
    // Só o primeiro é sobre a página. Dizer o errado manda o visitante
    // embora quando bastava apagar o que escreveu.
    await montar(tester, [video('a', personagem: 'Maloquivera')]);

    await tester.enterText(find.byType(TextField), 'ninguém');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Nenhum vídeo com esses filtros'),
      findsOneWidget,
    );
    expect(find.textContaining('Ainda não há vídeos'), findsNothing);
  });

  testWidgets('uma seção sem classe nenhuma não desenha filtro', (
    tester,
  ) async {
    // As outras quatro telas usarão a mesma grelha com a coluna vazia.
    await montar(tester, [video('a'), video('b')]);

    expect(find.text('Todos'), findsNothing);
    expect(find.text('Guerra a'), findsOneWidget);
  });
}
