import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/rotas.dart' as rotas;
import 'package:pw_market_filter/features/guias/domain/video.dart';
import 'package:pw_market_filter/features/guias/ui/widgets/guerras_secao.dart';

import '../support/load_fonts.dart';

Video _video({
  required String youtube,
  String? detalhes,
  String? personagem,
  String? classe,
  DateTime? data,
}) => Video(
  secao: 'guerras',
  youtube: youtube,
  detalhes: detalhes,
  personagem: personagem,
  classe: classe,
  data: data,
);

Future<void> _montar(
  WidgetTester tester, {
  required Future<List<Video>> Function() carregar,
  String versao = rotas.pw187,
  bool wide = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: GuerrasSecao(versao: versao, wide: wide, carregar: carregar),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Com as fontes reais: sem elas o harness desenha cada glifo como um
  // quadrado do tamanho da fonte e o teste de transbordo mede o harness.
  setUpAll(loadAppFonts);

  testWidgets('as gravações da mesma guerra saem numa linha só', (
    tester,
  ) async {
    await _montar(
      tester,
      carregar: () async => [
        _video(
          youtube: 'a',
          detalhes: 'Ragnarok x BUDOKAI',
          personagem: 'Mozaum',
          classe: 'Retalhador',
          data: DateTime.utc(2026, 11),
        ),
        _video(
          youtube: 'b',
          detalhes: 'Ragnarok x BUDOKAI',
          personagem: 'COMECU',
          classe: 'Mago',
          data: DateTime.utc(2026, 11),
        ),
      ],
    );

    expect(find.text('Ragnarok x BUDOKAI'), findsOneWidget);
    expect(find.text('Mozaum e COMECU'), findsOneWidget);
  });

  testWidgets('a data na home não imprime o ano', (tester) async {
    // Quatro linhas do mês corrente: o ano é a parte que nunca as distingue,
    // e a tela de Guerras continua a imprimi-lo porque lá se rola meses.
    await _montar(
      tester,
      carregar: () async => [
        _video(
          youtube: 'a',
          detalhes: 'Sync x Genesys',
          personagem: 'TeamSpeakUser',
          data: DateTime.utc(2026, 11, 7),
        ),
      ],
    );

    expect(find.text('07/11'), findsOneWidget);
    expect(find.text('07/11/2026'), findsNothing);
  });

  testWidgets('mostra quatro e a porta leva ao resto', (tester) async {
    await _montar(
      tester,
      carregar: () async => [
        for (var i = 0; i < 7; i++)
          _video(
            youtube: '$i',
            detalhes: 'Guerra $i',
            data: DateTime.utc(2026, 11, i + 1),
          ),
      ],
    );

    expect(find.textContaining('Guerra '), findsNWidgets(4));
    expect(find.text('ver todos os 7 →'), findsOneWidget);
    expect(
      find.text('VÍDEOS DE GUERRAS TERRITORIAIS'),
      findsOneWidget,
      reason: 'o nome diz que são gravações e não as guerras',
    );
  });

  testWidgets('um mercado sem vídeo nenhum convida, e diz qual é', (
    tester,
  ) async {
    // **Pedido do dono a 10/11/2026**, contra o silêncio que eu tinha
    // proposto: os 48 vídeos de guerra são todos de 1.8.7, portanto no 1.2.6
    // esta secção não tinha nada — e um mercado vazio é onde o convite tem
    // mais trabalho a fazer, não menos.
    await _montar(tester, versao: rotas.pw126, carregar: () async => const []);

    expect(
      find.textContaining('Ainda não temos vídeos de guerra do 1.2.6'),
      findsOneWidget,
    );
    expect(find.text('Fale comigo no Discord'), findsOneWidget);
    // A porta prometeria uma página vazia.
    expect(find.textContaining('→'), findsNothing);
  });

  testWidgets('um pedido que falha não desenha nada, nem o convite', (
    tester,
  ) async {
    // **Falhar e estar vazio são factos diferentes.** Dizer «ainda não temos
    // vídeos» por causa de um erro de rede seria afirmar sobre o acervo uma
    // coisa que só se sabe sobre a ligação — a mesma regra que impede o
    // Worker de marcar toda a gente offline quando a Twitch não responde.
    await _montar(tester, carregar: () async => throw Exception('sem rede'));

    expect(
      find.text('Vídeos de guerras territoriais'.toUpperCase()),
      findsNothing,
    );
    expect(find.textContaining('Ainda não temos'), findsNothing);
  });

  testWidgets('no telemóvel a cabeça fica sem porta, e não transborda', (
    tester,
  ) async {
    // Medido com as fontes reais a 10/11/2026: a cabeça passou de 191 px
    // para 285 ao ganhar o *Vídeos de*, e com os dois vãos e a porta dá 408
    // contra os ~350 que um ecrã de 390 deixa.
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _montar(
      tester,
      wide: false,
      carregar: () async => [
        _video(
          youtube: 'a',
          detalhes: 'Sync x Genesys',
          data: DateTime.utc(2026, 11, 7),
        ),
      ],
    );

    expect(find.text('VÍDEOS DE GUERRAS TERRITORIAIS'), findsOneWidget);
    expect(find.textContaining('os 1 →'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
