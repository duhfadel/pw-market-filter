import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_theme.dart';
import 'package:pw_market_filter/features/home/domain/canal_ao_vivo.dart';
import 'package:pw_market_filter/features/home/ui/ao_vivo_view_model.dart';
import 'package:pw_market_filter/features/home/ui/widgets/ao_vivo_strip.dart';

import '../support/load_fonts.dart';

/// The strip, mounted, filtering by the page's version.
///
/// The domain test proves the rule; this proves the **wiring** — a widget
/// passing `null` by oversight would leave every screen showing everybody
/// with a green domain suite on top of it, which is exactly the shape that
/// let the 1.2.6 filter rewrite the address to 1.8.7 for a day.
class _Fixo extends Cubit<List<CanalAoVivo>> implements AoVivoViewModel {
  _Fixo(super.canais);

  @override
  Future<void> load() async {}
}

void main() {
  setUpAll(loadAppFonts);

  CanalAoVivo canal(String login, String? titulo) => CanalAoVivo(
    canal: login.toLowerCase(),
    nome: login,
    aoVivo: true,
    titulo: titulo,
    jogo: 'Perfect World',
    espectadores: 10,
    vistoEm: DateTime.now(),
  );

  final elenco = [
    canal('DoOitoSete', 'The Classic PW 1.8.7'),
    canal('DoDoisSeis', 'pw126 rate baixa'),
    // O caso real medido a 09/11/2026: o único canal em directo, e nem o
    // 1.8.7 nem o 1.2.6 o devem mostrar.
    canal('Magraotvv', 'THE CLASSIC PW 1.4.4 BETA ABERTO'),
    canal('SemVersao', 'Perfect World com os amigos'),
  ];

  Future<void> pump(WidgetTester tester, {String? versao}) async {
    tester.view.physicalSize = const Size(1040, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      BlocProvider<AoVivoViewModel>.value(
        value: _Fixo(elenco),
        child: MaterialApp(
          theme: PWTheme.build(),
          home: Scaffold(body: AoVivoStrip(wide: true, versao: versao)),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a página do 1.8.7 mostra só o do 1.8.7', (tester) async {
    await pump(tester, versao: '1.8.7');

    expect(find.text('DoOitoSete'), findsOneWidget);
    expect(find.text('DoDoisSeis'), findsNothing);
    expect(find.text('Magraotvv'), findsNothing);
    expect(find.text('SemVersao'), findsNothing);
  });

  testWidgets('a página do 1.2.6 mostra só o do 1.2.6', (tester) async {
    await pump(tester, versao: '1.2.6');

    expect(find.text('DoDoisSeis'), findsOneWidget);
    expect(find.text('DoOitoSete'), findsNothing);
  });

  testWidgets('sem versão, mostra todos — e é a raiz', (tester) async {
    // A raiz não é de versão nenhuma, portanto não afirma nada. É também a
    // única tela onde quem não escreve a versão continua a aparecer.
    await pump(tester);

    // **Contado pelo título e não pelos cartões**, porque a faixa é um
    // carrossel de dois por página: `find.text` só acha quem está na página
    // à vista, e procurar os quatro mediria o carrossel em vez do filtro.
    expect(find.text('4 ao vivo'), findsOneWidget);
    expect(find.text('DoOitoSete'), findsOneWidget);
  });

  testWidgets('o título conta os desta versão e não os do site', (
    tester,
  ) async {
    // Se o número vier de antes do filtro, a faixa anuncia «4 ao vivo» e
    // mostra um — e a conta é a única parte que o visitante pode verificar.
    await pump(tester, versao: '1.8.7');
    // Um só, portanto a faixa não imprime contagem nenhuma — e sobretudo não
    // imprime a do site inteiro. O cartão continua a dizer `ao vivo na
    // Twitch`, que é sobre aquele canal e não uma conta.
    expect(find.text('4 ao vivo'), findsNothing);
    expect(find.text('1 ao vivo'), findsNothing);
  });

  testWidgets('ninguém desta versão não desenha título solto', (tester) async {
    // Hoje é o caso comum e não o raro: medido a 09/11, o único canal em
    // directo escrevia 1.4.4 no título, portanto as duas páginas com faixa
    // ficariam sem ninguém. A secção some inteira, como já fazia quando
    // ninguém está ao vivo — nunca uma cabeça sobre o vazio.
    await pump(tester, versao: '1.4.4');
    expect(find.text('Magraotvv'), findsOneWidget);

    await tester.pumpWidget(
      BlocProvider<AoVivoViewModel>.value(
        value: _Fixo([canal('SemVersao', 'Perfect World com os amigos')]),
        child: MaterialApp(
          theme: PWTheme.build(),
          home: const Scaffold(body: AoVivoStrip(wide: true, versao: '1.8.7')),
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('ao vivo'), findsNothing);
    expect(find.text('SemVersao'), findsNothing);
  });

  testWidgets('o título é lido e nunca mostrado', (tester) async {
    // Está cheio de cupões e emoji, e já tinha sido deixado de fora do cartão
    // por isso. Agora que ele decide quem aparece, vale cravar que continua
    // a não aparecer.
    await pump(tester, versao: '1.8.7');
    expect(find.textContaining('The Classic PW'), findsNothing);
  });
}
