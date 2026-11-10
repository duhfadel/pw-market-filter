import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/guias/domain/video.dart';
import 'package:pw_market_filter/features/guias/ui/widgets/ultimos_videos_de_guerra.dart';

import '../support/load_fonts.dart';

Video _video({
  required String youtube,
  String? versao,
  String? detalhes,
  String? personagem,
  DateTime? data,
}) => Video(
  secao: 'guerras',
  youtube: youtube,
  versao: versao,
  detalhes: detalhes,
  personagem: personagem,
  data: data,
);

Future<void> _montar(
  WidgetTester tester, {
  required Future<List<Video>> Function() carregar,
  bool wide = true,
  double largura = 1280,
}) async {
  tester.view.physicalSize = Size(largura, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UltimosVideosDeGuerra(wide: wide, carregar: carregar),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// O mercado real a 10/11/2026: tudo no 1.8.7, nada nos outros dois.
List<Video> _comoHoje() => [
  _video(
    youtube: 'a',
    versao: '1.8.7',
    detalhes: 'Sync x Genesys',
    personagem: 'TeamSpeakUser',
    data: DateTime.utc(2026, 11, 7),
  ),
  _video(
    youtube: 'b',
    versao: '1.8.7',
    detalhes: 'Ragnarok x BUDOKAI',
    personagem: 'Mozaum',
    data: DateTime.utc(2026, 11),
  ),
];

void main() {
  setUpAll(loadAppFonts);

  testWidgets('os três mercados aparecem, mesmo os que não têm vídeo', (
    tester,
  ) async {
    // **É isto que a secção existe para fazer.** A home de cada versão mostra
    // as quatro mais recentes daquele mercado; aqui é uma por mercado, e sem
    // essa cota o 1.8.7 — 47 vídeos contra zero e zero — encheria a secção
    // sozinho e os outros dois nunca apareceriam.
    await _montar(tester, carregar: () async => _comoHoje());

    expect(find.text('1.2.6'), findsOneWidget);
    expect(find.text('1.4.4'), findsOneWidget);
    expect(find.text('1.8.7'), findsOneWidget);
    expect(find.textContaining('Ainda sem vídeos'), findsNWidgets(2));
  });

  testWidgets('cada mercado mostra a sua guerra mais recente, não a do site', (
    tester,
  ) async {
    // Sem o agrupamento por versão, o 1.2.6 herdaria a guerra do 1.8.7 só por
    // ela ser a mais recente de todas — que é o site a afirmar que houve uma
    // guerra num mercado onde não houve.
    await _montar(
      tester,
      carregar: () async => [
        ..._comoHoje(),
        _video(
          youtube: 'c',
          versao: '1.2.6',
          detalhes: 'Antigos x Novos',
          personagem: 'Baekchu',
          data: DateTime.utc(2026, 10, 30),
        ),
      ],
    );

    expect(find.text('Sync x Genesys'), findsOneWidget);
    expect(find.text('Antigos x Novos'), findsOneWidget);
    expect(find.textContaining('Ainda sem vídeos'), findsOneWidget);
    // A mais recente do 1.8.7 é a de 07/11, não a de 01/11.
    expect(find.text('Ragnarok x BUDOKAI'), findsNothing);
  });

  testWidgets('a etiqueta do mercado é a ouro', (tester) async {
    // Decisão do dono a 10/11/2026. O ouro é a cor do dinheiro nesta casa, e
    // aqui não a gasta: esta secção não imprime preço nenhum, portanto não há
    // com que colidir.
    await _montar(tester, carregar: () async => _comoHoje());

    final etiqueta = tester.widget<Text>(find.text('1.8.7'));
    expect(etiqueta.style?.color, PWColors.accent);
  });

  testWidgets('a porta de cada coluna leva ao mercado dela', (tester) async {
    // Uma porta só na régua teria de escolher um mercado, e a secção existe
    // para não escolher.
    await _montar(tester, carregar: () async => _comoHoje());

    expect(find.text('os 2 →'), findsOneWidget);
  });

  testWidgets('sem vídeo nenhum em lado nenhum não desenha nada', (
    tester,
  ) async {
    // Três convites seguidos são um formulário, não uma secção.
    await _montar(tester, carregar: () async => const []);

    expect(find.textContaining('Últimos vídeos'.toUpperCase()), findsNothing);
    expect(find.textContaining('Ainda sem vídeos'), findsNothing);
  });

  testWidgets('um pedido que falha não desenha nada, nem os convites', (
    tester,
  ) async {
    // **Falhar e estar vazio são factos diferentes.** Dizer «ainda sem
    // vídeos» por causa de um erro de rede seria afirmar sobre o acervo uma
    // coisa que só se sabe sobre a ligação.
    await _montar(tester, carregar: () async => throw Exception('sem rede'));

    expect(find.textContaining('Ainda sem vídeos'), findsNothing);
  });

  testWidgets('no estreito as colunas empilham e nada transborda', (
    tester,
  ) async {
    await _montar(
      tester,
      wide: false,
      largura: 390,
      carregar: () async => _comoHoje(),
    );

    expect(find.text('1.2.6'), findsOneWidget);
    expect(find.text('Sync x Genesys'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
