import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/ui/search_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

import '../support/novidades_test_support.dart';

/// **Temporário, como o widget que ele guarda.** A 11/11/2026 o marketplace
/// passou a exigir login e a coleta parou; o aviso existe para a tela não
/// apresentar o último índice como se fosse o mercado de agora. Quando o
/// acesso voltar, o widget sai e este ficheiro com ele.
///
/// O que aqui se crava é a parte que não é texto: que o aviso **se apaga
/// sozinho** quando uma coleta passa. Uma bandeira à mão dependeria de
/// alguém se lembrar de a tirar, e um aviso que ficou a mentir deixa de ser
/// lido — a mesma razão pela qual o selo *novo* dos guias expira por data.

MarketIndex _indice(DateTime coleta) => MarketIndex(
  server: 'pw187',
  collectedAt: coleta,
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  characters: [
    MarketCharacter(
      roleId: 1,
      name: 'Leandrim',
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: 300,
      fame: 1,
      cultivation: 'Leal',
      equipped: [
        EquippedItem(
          slot: 10,
          itemId: 50206,
          refine: 12,
          stones: const [],
          attributes: {
            0: [70.0],
          },
        ),
      ],
    ),
  ],
);

Future<void> _montar(WidgetTester tester, DateTime coleta) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(jsonEncode(_indice(coleta).toJson())),
      200,
    ),
  );

  await tester.pumpWidget(
    BlocProvider.value(
      value: SearchViewModel(IndexRepository(client))..load(),
      child: MaterialApp(home: comNovidades(const SearchView())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('uma coleta recente não desenha aviso nenhum', (tester) async {
    // O caso normal, e o que importa é que o aviso não cobra espaço nem
    // assusta quem chega a um mercado que está a funcionar.
    await _montar(
      tester,
      DateTime.now().toUtc().subtract(const Duration(minutes: 20)),
    );

    expect(find.textContaining('exigir login'), findsNothing);
  });

  testWidgets('parada há horas, o aviso diz desde quando', (tester) async {
    // Seis rondas do coletor falhadas. A data é a da coleta e não a de hoje:
    // é ela que diz há quanto tempo o que está na tela deixou de ser o
    // mercado de agora.
    //
    // Relativa ao relógio e nunca cravada: uma data fixa deixa de estar
    // parada há três horas no dia seguinte — e, pior, *passa* a estar, o
    // que faria o teste mudar de resposta com o calendário em vez de com o
    // código. É a forma que já congelou o `presets_test` duas vezes.
    final coleta = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    await _montar(tester, coleta);

    expect(find.textContaining('exigir login'), findsOneWidget);
    final dia = coleta.toLocal();
    final data =
        '${dia.day.toString().padLeft(2, '0')}/'
        '${dia.month.toString().padLeft(2, '0')}';
    expect(find.textContaining(data), findsWidgets);
  });

  testWidgets('o aviso sai sozinho assim que uma coleta passa', (tester) async {
    // **É esta a propriedade que justifica derivar da data.** Nada precisa de
    // ser apagado à mão no dia em que o acesso voltar: a data anda e o aviso
    // deixa de se desenhar.
    await _montar(
      tester,
      DateTime.now().toUtc().subtract(const Duration(hours: 4)),
    );
    expect(find.textContaining('exigir login'), findsOneWidget);

    await _montar(
      tester,
      DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    );
    expect(find.textContaining('exigir login'), findsNothing);
  });

  testWidgets('o disclaimer de sempre continua lá, por baixo', (tester) async {
    // O aviso é notícia e o disclaimer é permanente: um não pode empurrar o
    // outro para fora, porque é o disclaimer que diz que o site não é dono
    // de nada nem vende nada.
    await _montar(
      tester,
      DateTime.now().toUtc().subtract(const Duration(hours: 5)),
    );

    expect(
      find.textContaining('Não somos donos do marketplace'),
      findsOneWidget,
    );
  });
}
