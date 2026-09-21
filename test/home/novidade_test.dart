import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/home/domain/novidade.dart';

/// Reading a Discord message into something the page can draw.
///
/// The vocabulary is deliberately three words wide — paragraph, bold, link —
/// because everything else somebody types has to come out as plain text rather
/// than as instructions to the page.

void main() {
  group('the title', () {
    test('a first line in bold becomes the heading', () {
      final n = Novidade.deTexto('**Estamos de volta!**\n\nO resto do texto.');

      expect(n.titulo, 'Estamos de volta!');
      expect(n.corpo, 'O resto do texto.');
    });

    test('without a bold first line there is no heading', () {
      // Taking the first line regardless would turn "Coletei agora" into a
      // heading with an empty body — a shout where somebody wrote a note.
      final n = Novidade.deTexto('Coletei agora, o mercado está fresco.');

      expect(n.titulo, isNull);
      expect(n.corpo, 'Coletei agora, o mercado está fresco.');
    });

    test('bold in the middle of the first line is not a heading', () {
      final n = Novidade.deTexto('Olha o **Mundo Primitivo**, 118 por página.');

      expect(n.titulo, isNull);
    });
  });

  group('the three words it understands', () {
    test('bold survives', () {
      final partes = pedacos('nick **duhit** no jogo');

      expect(partes.map((p) => p.texto), ['nick ', 'duhit', ' no jogo']);
      expect(partes.map((p) => p.negrito), [false, true, false]);
    });

    test('a link becomes something to tap', () {
      final partes = pedacos('entra em https://discord.gg/abc agora');

      expect(partes[1].texto, 'https://discord.gg/abc');
      expect(partes[1].url, 'https://discord.gg/abc');
    });

    test('a link at the end keeps no trailing punctuation', () {
      // "veja https://portalpw.net." — the full stop belongs to the sentence,
      // and carrying it into the address gives a link that 404s.
      final partes = pedacos('veja https://portalpw.net.');

      expect(partes[1].url, 'https://portalpw.net');
      expect(partes.last.texto, '.');
    });

    test('anything else is text, never markup', () {
      // The message is written by a person in a chat box. Whatever it holds —
      // angle brackets, a stray asterisk, an @mention — has to arrive on the
      // page as characters somebody typed, not as something the page obeys.
      const bruto = '<b>oi</b> * solto @everyone';
      final partes = pedacos(bruto);

      expect(partes.single.texto, bruto);
      expect(partes.single.negrito, isFalse);
      expect(partes.single.url, isNull);
    });
  });

  group('paragraphs', () {
    test('a blank line starts a new one', () {
      expect(paragrafos('um\n\ndois'), ['um', 'dois']);
    });

    test('a single newline stays inside the paragraph', () {
      // Discord wraps as you type. Treating every newline as a paragraph would
      // turn one thought into a staircase — the same lesson the war map
      // already learned.
      expect(paragrafos('uma frase\nquebrada'), ['uma frase\nquebrada']);
    });

    test('trailing blank lines make no empty paragraphs', () {
      expect(paragrafos('texto\n\n\n\n'), ['texto']);
    });
  });
}
