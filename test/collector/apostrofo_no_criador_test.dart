import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart' show ParsedItem;
import 'package:pw_market_filter/collector/detail_parser_126.dart';

/// Um apóstrofo no nick de quem criou a peça cortava o JSON dela a meio.
///
/// **Relatado pelo dono em 21/10/2026**, sobre o Baekchu: as calças e as
/// botas apareciam sem pedras no site e com pedras na página. Esta fixture é
/// a página dele, guardada porque o caso não se encontra a rolar a grelha —
/// precisa de alguém cujo equipamento tenha sido forjado por um `Antonio'`.
void main() {
  late List<ParsedItem> baekchu;

  setUpAll(() {
    baekchu = parseEquippedItems126(
      File('test/fixtures/detail_pw126_359665.html').readAsStringSync(),
    );
  });

  ParsedItem slot(int n) => baekchu.singleWhere((i) => i.slot == n);

  test('as peças forjadas por um nick com apóstrofo trazem as suas pedras', () {
    // O criador das calças chama-se `king[D]oug'` e o das botas `Antonio'`.
    // O apóstrofo fechava o atributo a meio do JSON, o `jsonDecode` falhava e
    // o `catch` devolvia nulo — a peça ficava sem pedras **e sem atributos**,
    // sem um aviso em lado nenhum.
    expect(slot(3).stones, [6387, 6387, 6387, 6387]);
    expect(slot(4).stones, [6387, 6387, 6387, 6387]);
    expect(slot(3).attributes, isNotEmpty);
    expect(slot(4).attributes, isNotEmpty);
  });

  test('nenhuma peça deste personagem fica sem nada', () {
    // Antes eram duas em onze, e era esse o sintoma: não um erro, um silêncio.
    final mudas = baekchu.where(
      (i) => i.attributes.isEmpty && i.stones.isEmpty,
    );

    expect(mudas, isEmpty);
  });

  test('o que já lia continua a ler', () {
    // A reparação reescreve o HTML antes de o entregar ao leitor, portanto
    // tem de deixar intacto tudo o que já estava bem.
    expect(baekchu, hasLength(11));
    expect(slot(2).stones, [6387, 6387, 6387, 6387]);
    expect(slot(10).stones, [6370, 6370]);
    expect(slot(10).name, contains('Trovão Celestial'));
  });
}
