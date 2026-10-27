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

  group('a linha de versões', () {
    // **A regra, pedida pelo dono a 27/10/2026:** uma linha só com marcadores
    // entre parênteses retos diz a que mercado o recado pertence. Com dois
    // mercados no ar e um terceiro a caminho, metade dos recados não é para
    // metade das pessoas.
    test('uma versão é lida e sai do corpo', () {
      final n = Novidade.deTexto('**Título**\n[1.8.7]\n\nO corpo.');

      expect(n.versoes, ['1.8.7']);
      expect(n.corpo, 'O corpo.');
      expect(n.titulo, 'Título');
    });

    test('várias na mesma linha', () {
      final n = Novidade.deTexto('**T**\n[1.8.7] [1.2.6]\n\nCorpo.');

      expect(n.versoes, ['1.8.7', '1.2.6']);
      expect(n.corpo, 'Corpo.');
    });

    test('todos é só mais um marcador, sem significado especial aqui', () {
      expect(Novidade.deTexto('**T**\n[todos]\n\nC.').versoes, ['todos']);
    });

    // **Sem marcador é vazio, nunca "para todos".** Os recados anteriores a
    // esta regra não têm linha nenhuma, e inventar-lhes uma etiqueta seria o
    // site afirmar o que ninguém escreveu.
    test('sem marcador não inventa etiqueta', () {
      expect(Novidade.deTexto('**T**\n\nSó o corpo.').versoes, isEmpty);
      expect(Novidade.deTexto('Uma nota solta.').versoes, isEmpty);
    });

    // O caso que separa uma etiqueta de alguém a falar de uma versão. Sem
    // isto, qualquer frase com `[1.8.7]` no meio viraria marcador e perderia
    // esse pedaço do texto — a mesma forma do negrito no meio da frase que
    // não pode virar título.
    test('uma versão citada no meio da frase não é etiqueta', () {
      final n = Novidade.deTexto('**T**\n\nFalei do [1.8.7] aqui.');

      expect(n.versoes, isEmpty);
      expect(n.corpo, 'Falei do [1.8.7] aqui.');
    });

    test('vale sem título, para um recado curto', () {
      final n = Novidade.deTexto('[1.4.4]\n\nUma nota.');

      expect(n.versoes, ['1.4.4']);
      expect(n.titulo, isNull);
      expect(n.corpo, 'Uma nota.');
    });

    // O que vem do banco tem de carregar as versões também: é a travessia que
    // `deTexto` sozinho não prova, e é onde um campo costuma morrer aqui.
    test('fromJson leva as versões até o fim', () {
      final n = Novidade.fromJson({
        'texto': '**T**\n[1.2.6]\n\nCorpo.',
        'autor': 'Duh',
        'publicada_em': '2026-10-27T12:00:00Z',
      });

      expect(n.versoes, ['1.2.6']);
      expect(n.autor, 'Duh');
    });
  });
}
