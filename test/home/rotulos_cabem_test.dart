import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/destaques.dart';
import 'package:pw_market_filter/market/market_index.dart';

import '../support/load_fonts.dart';

/// Every card label has to fit on one line, measured rather than counted.
///
/// A truncated label is worse than a missing one: `Um dos que mais carr…`
/// shipped on 02/10/2026 and said nothing about what the card filters, which
/// is the label's whole job. The owner spotted it on the live page.
///
/// The four that broke were the **softened** labels — the ones the
/// distinct-class rule produces when a category's true winner is pushed. They
/// are the rarest path through this code and therefore the least looked at,
/// which is exactly why they need a test rather than an eye.
///
/// This measures with the real fonts and the card's real text width instead
/// of counting characters: `flutter_test`'s square glyphs would make every
/// label look far wider than it is, and counting characters cannot know that
/// `UP5` is narrower than `mmm`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadAppFonts();
    // `loadAppFonts` traz Marcellus e Roboto; o corpo da app é **Inter**, e a
    // largura de um rótulo depende dela. Sem este registo o `TextPainter` cai
    // na fonte de teste, onde todo glifo é um quadrado do tamanho da fonte —
    // e aí `Arma de 70 mais barata` mede 226 px em vez de 115. Foi exatamente
    // nisso que a primeira versão deste teste tropeçou: o teste escrito para
    // evitar a armadilha caiu nela.
    final bytes = File('assets/fonts/Inter-Bold.ttf').readAsBytesSync();
    await (FontLoader(
      'Inter',
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  });

  /// The widest a label may be, derived rather than guessed.
  ///
  /// Six columns inside the page's 1180 px reading column, 12 px of gap
  /// between them and 10 px of padding on each side of the footer — which is
  /// what `destaques_view.dart` lays out.
  // A coluna de leitura da home tem 1180, `_ComMargem` tira 40 de cada lado
  // em tela larga, são seis colunas com 12 de intervalo, e o rodapé da carta
  // tem 10 de padding de cada lado.
  const larguraDoTexto = ((1180 - 80 - 12 * 5) / 6) - 20;

  const estilo = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  double larguraDe(String texto) {
    final pintor = TextPainter(
      text: TextSpan(text: texto, style: estilo),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return pintor.width;
  }

  test('every label on the real market fits the card on one line', () {
    final arquivo = File('web/market_index.json');
    if (!arquivo.existsSync()) return; // a fresh clone has not collected yet

    final index = MarketIndex.fromJson(
      jsonDecode(arquivo.readAsStringSync()) as Map<String, dynamic>,
    );

    for (final destaque in destaquesDe(index)) {
      expect(
        larguraDe(destaque.rotulo),
        lessThanOrEqualTo(larguraDoTexto),
        reason:
            'o rótulo "${destaque.rotulo}" seria cortado, e um rótulo cortado '
            'não diz do que é o filtro',
      );
      expect(
        larguraDe(destaque.nota),
        lessThanOrEqualTo(larguraDoTexto),
        reason: 'a nota "${destaque.nota}" seria cortada',
      );
    }
  });

  test('the softened labels fit too, and they are the ones that broke', () {
    // They only appear when a class collision pushes a category past its true
    // winner, so a market without a collision never draws them — and that is
    // precisely how four of them shipped too long.
    const suaves = [
      'Um dos mais baratos',
      'Barato com arma de 70',
      'Barato com Atq lvl UP5',
      'Barato com Def lvl UP5',
      'Um dos mais caros',
      'Muitas relíquias',
    ];

    for (final rotulo in suaves) {
      expect(
        larguraDe(rotulo),
        lessThanOrEqualTo(larguraDoTexto),
        reason: 'o rótulo suave "$rotulo" seria cortado',
      );
    }
  });
}
