import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser.dart';

/// The three things the page says about the character himself rather than
/// about his gear: the celestial realm, the path he took, and his runes.
///
/// Four real pages, chosen so that each awkward case is a real page and not a
/// hand-made one:
///
/// - **64112** Leandrim, Guerreiro, `Céu Ápice VIII`, Evil, six runes.
/// - **330640** LeRato, Feiticeira, `Céu Ápice IX`, Evil, six runes.
/// - **11076** the character the player confirmed as Evil: `Céu Oscilante X`,
///   a third tier, and **no runes at all** — the section is there and empty.
void main() {
  late String leandrim;
  late String lerato;
  late String evil;

  setUpAll(() {
    leandrim = File('test/fixtures/detail_64112.html').readAsStringSync();
    lerato = File('test/fixtures/detail_330640.html').readAsStringSync();
    evil = File('test/fixtures/detail_11076.html').readAsStringSync();
  });

  group('the celestial realm', () {
    test('reads the row beside Classe and Sexo', () {
      expect(parseCelestialRealm(leandrim), 'Céu Ápice VIII');
      expect(parseCelestialRealm(lerato), 'Céu Ápice IX');
      expect(parseCelestialRealm(evil), 'Céu Oscilante X');
    });

    test('a page without the row says nothing rather than guessing', () {
      expect(parseCelestialRealm('<html><body></body></html>'), isNull);
    });
  });

  group('the path', () {
    test('reads Evil off the skill the game names', () {
      // The player's own test: Evil has Erupção Demoníaca, God has Erupção
      // Celestial. 11076 is the character he confirmed.
      expect(parsePath(evil), 'Evil');
      expect(parsePath(leandrim), 'Evil');
      expect(parsePath(lerato), 'Evil');
    });

    test('a page with neither eruption is unknown, not God by omission', () {
      expect(parsePath('<html><body></body></html>'), isNull);
    });
  });

  group('the runes', () {
    test('reads six pairs, each a rune and the skill it sits on', () {
      final runes = parseRunes(leandrim);

      expect(runes, hasLength(6));
      expect(runes.first.slot, 0);
      expect(runes.first.itemId, 52220);
      expect(runes.first.type, 'Argêntea');
      expect(runes.first.level, 6);
      expect(runes.first.skillName, 'ΨIra do Paraíso');
    });

    test('reads both spellings of the level', () {
      // The same page writes `Nv. 6` and `Nível 8`. Reading only the first
      // would drop the level 8s — which are the ones anybody is looking for.
      final runes = parseRunes(lerato);

      expect(runes, hasLength(6));
      expect(
        runes.singleWhere((r) => r.slot == 0),
        isA<ParsedRune>()
            .having((r) => r.type, 'type', 'Argêntea')
            .having((r) => r.level, 'level', 8),
      );
      expect(runes.map((r) => r.level), containsAll([8, 1, 5]));
    });

    test('every rune lands in its own slot, in order', () {
      final slots = parseRunes(lerato).map((r) => r.slot).toList();

      expect(slots, [0, 1, 2, 3, 4, 5]);
    });

    test('a character with the section empty has no runes and no error', () {
      expect(parseRunes(evil), isEmpty);
    });

    test('a page without the section at all yields nothing', () {
      expect(parseRunes('<html><body></body></html>'), isEmpty);
    });
  });

  group('a ficha lê-se pelo valor, não pelo rótulo', () {
    // **O rótulo era a dependência e custou 200 minutos de recolha.** Até
    // 06/11/2026 isto comparava o `.skill-desc` com `'Sexo'` e
    // `'Reino Celestial'` por igualdade exacta. O site passou a oscilar entre
    // português e espanhol — a mesma página mudou de língua três vezes nesse
    // dia — e duas recolhas completas trouxeram **zero de 2.879** nos dois
    // campos, enquanto anedotas, cartas e caminho saíam inteiros das mesmas
    // páginas. É por isso que estes casos existem: a forma que falha não se
    // encontra a rolar a grelha.
    String ficha(String rotuloSexo, String rotuloReino, String sexo) =>
        '<ul>'
        '<li class="character-info--list"><span class="skill-desc">Clase</span>'
        '<strong class="value">Bardo</strong></li>'
        '<li class="character-info--list">'
        '<span class="skill-desc">$rotuloSexo</span>'
        '<strong class="value">$sexo</strong></li>'
        '<li class="character-info--list">'
        '<span class="skill-desc">$rotuloReino</span>'
        '<strong class="value">Céu Soberano IV</strong></li>'
        '</ul>';

    test('o rótulo em português continua a ser lido', () {
      final h = ficha('Sexo', 'Reino Celestial', 'Masculino');
      expect(parseSex(h), 'Masculino');
      expect(parseCelestialRealm(h), 'Céu Soberano IV');
    });

    test('um rótulo noutra língua não impede a leitura', () {
      final h = ficha('Género', 'Reino Celeste', 'Femenino');
      expect(parseSex(h), 'Femenino');
      expect(parseCelestialRealm(h), 'Céu Soberano IV');
    });

    test('um rótulo que não existe também não impede', () {
      // O caso-limite honesto: não sabemos que variante o site serviu
      // naquelas horas, portanto a leitura não pode depender de adivinhá-la.
      final h = ficha('', '', 'Feminino');
      expect(parseSex(h), 'Feminino');
      expect(parseCelestialRealm(h), 'Céu Soberano IV');
    });

    test('o contentor mudar de classe também não impede', () {
      expect(
        parseSex(
          '<li class="character-info--item">'
          '<strong class="value">Masculino</strong></li>',
        ),
        'Masculino',
      );
    });

    test('o reino tem segunda fonte no painel Alma Celeste', () {
      // Duas fontes independentes para o mesmo facto, e é o que torna o reino
      // mais robusto do que o sexo, que a página só imprime num lugar.
      expect(
        parseCelestialRealm(
          '<div class="pw187-detail-attr-row"><span>Reino Celestial</span>'
          '<strong>Céu Devoto V</strong></div>',
        ),
        'Céu Devoto V',
      );
    });

    test('a linha da classe nunca é confundida com as outras duas', () {
      // O que torna a leitura pelo valor segura é o vocabulário fechado de
      // cada campo: `Bardo` está na ficha, em primeiro lugar, e não é nem um
      // sexo nem um reino.
      final h = ficha('', '', 'Masculino');
      expect(parseSex(h), 'Masculino');
      expect(parseCelestialRealm(h), 'Céu Soberano IV');
    });

    test('o caminho sobrevive ao acento da erupção', () {
      // O caminho não tem campo nenhum na página — lê-se do nome de uma
      // habilidade — portanto perdê-lo por um acento seria perder a
      // distinção inteira entre Sagrado e Demoníaco.
      expect(parsePath('<div aria-label="Erupción Demoníaca"></div>'), 'Evil');
      expect(parsePath('<div aria-label="Erupção Celestial"></div>'), 'God');
    });

    test('uma ficha sem nada diz nada, nunca um palpite', () {
      expect(parseSex('<html><body></body></html>'), isEmpty);
      expect(parseCelestialRealm('<html><body></body></html>'), isNull);
    });
  });
}
