import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/arte_da_classe.dart';
import 'package:pw_market_filter/features/portas/ui/widgets/heroi_da_raiz.dart';

import '../support/load_fonts.dart';

/// O herói da raiz.
void main() {
  setUpAll(loadAppFonts);

  Future<void> montar(
    WidgetTester tester, {
    double largura = 1440,
    DateTime? quando,
  }) async {
    tester.view.physicalSize = Size(largura, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: PWTheme.build(),
        home: Scaffold(
          body: HeroiDaRaiz(
            wide: largura >= 620,
            quando: quando ?? DateTime.utc(2026, 11, 9, 13),
          ),
        ),
      ),
    );
  }

  testWidgets('diz o que o site faz, e abre uma porta só', (tester) async {
    await montar(tester);

    expect(find.text('FERRAMENTAS E GUIAS · THE CLASSIC PW'), findsOneWidget);
    expect(find.text('As contas que o jogo não faz'), findsOneWidget);
    // **Uma porta, e para os guias.** «Ver o mercado» responderia em silêncio
    // a pergunta *qual mercado* que as portas abaixo existem para fazer — o
    // defeito de 27/10/2026, quando o seletor oferecia pílulas que escolhiam
    // o 1.8.7 sem dizer.
    expect(find.text('Ver todos os guias'), findsOneWidget);
    // Uma só, e é esta: nenhum botão aqui abre um mercado. A sub-linha fala
    // do mercado, que é diferente — descrever não é escolher por alguém.
    expect(find.byType(OutlinedButton), findsOneWidget);
  });

  testWidgets('a manchete usa a face de display, e não tem algarismos', (
    tester,
  ) async {
    await montar(tester);
    final manchete = tester.widget<Text>(
      find.text('As contas que o jogo não faz'),
    );
    expect(manchete.style?.fontFamily, PWTheme.display);
    // Marcellus desenha figuras romanas: um dígito aqui sairia como `I`.
    expect(RegExp(r'\d').hasMatch(manchete.data!), isFalse);
  });

  group('a classe que ele veste', () {
    test('sai das seis que existem nas três versões', () {
      // Uma das onze que só o 1.8.7 tem diria, em arte, que esta é a página
      // do 1.8.7 — e ela serve as três.
      for (var h = 0; h < 48; h++) {
        final quando = DateTime.utc(2026, 11, 1).add(Duration(hours: h));
        expect(
          classesClassicasPw126,
          contains(HeroiDaRaiz.classeDe(quando)),
          reason: 'às $h horas vestiu uma classe que não serve as três',
        );
      }
    });

    test('a mesma coleta desenha sempre a mesma página', () {
      // Deriva de uma data e nunca do relógio: um recarregamento que mudasse
      // a cara leria como caça-níqueis em vez de site.
      final coleta = DateTime.utc(2026, 11, 9, 13, 40, 1);
      expect(HeroiDaRaiz.classeDe(coleta), HeroiDaRaiz.classeDe(coleta));
    });

    test('coletas diferentes acabam por mudar a cara', () {
      final vistas = {
        for (var d = 0; d < 12; d++)
          HeroiDaRaiz.classeDe(
            DateTime.utc(2026, 11, 1).add(Duration(days: d)),
          ),
      };
      expect(vistas.length, greaterThan(1));
    });
  });

  testWidgets('não transborda em nenhuma largura', (tester) async {
    for (final largura in const [390.0, 620.0, 1040.0, 1440.0, 1920.0]) {
      await montar(tester, largura: largura);
      expect(tester.takeException(), isNull, reason: 'a $largura px');
    }
  });

  testWidgets('o enquadramento da arte é o que a maquete escreve', (
    tester,
  ) async {
    // **Lido do CSS dela e não deduzido**: `object-fit: cover` na largura
    // toda com `object-position: 76% 20%`, que em Flutter é
    // `Alignment(0.52, -0.6)`.
    //
    // Houve uma volta errada no meio e vale cravá-la. Experimentei o `cover`
    // com o Arqueiro, vi cabelo e pano sem cara, e concluí que ele não servia
    // num herói largo — a conclusão certa teria sido que o enquadramento
    // estava mal. Daí saiu um painel encostado à direita que o dono viu logo
    // como errado.
    await montar(tester);

    final arte = tester.widget<Image>(
      find.descendant(
        of: find.byType(HeroiDaRaiz),
        matching: find.byType(Image),
      ),
    );
    expect(arte.fit, BoxFit.cover);
    expect(arte.alignment, const Alignment(0.52, -0.6));
  });

  test('a altura é min(86vh, 760), a medida da maquete', () {
    expect(HeroiDaRaiz.alturaPara(true, 1000), closeTo(860.0.clamp(0, 760), 1));
    expect(HeroiDaRaiz.alturaPara(true, 800), closeTo(688, 1));
    // O tecto, para não ficar absurda num monitor alto.
    expect(HeroiDaRaiz.alturaPara(true, 1600), 760);
    // E um chão, para não desaparecer numa janela baixa.
    expect(HeroiDaRaiz.alturaPara(true, 400), 420);
  });
}
