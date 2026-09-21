/// One announcement, written in the Discord channel and shown on the page.
///
/// The whole site's news now comes from `#📢・novidades`: the owner writes
/// there once and it reaches both places. Nothing here is written in code any
/// more, which also means nothing here waits for a deploy.
///
/// **Its safety is a Discord permission, not a field in this file.** Whoever
/// can post in that channel publishes on the home page. The channel is
/// restricted to the owner, and no amount of parsing below could replace that.
class Novidade {
  const Novidade({
    required this.titulo,
    required this.corpo,
    required this.autor,
    required this.publicadaEm,
  });

  /// The first line when it is wholly bold — the convention a person already
  /// uses in a chat box to head an announcement. `null` for a plain note,
  /// which then draws as a paragraph and not as a shout.
  final String? titulo;

  final String corpo;
  final String? autor;
  final DateTime publicadaEm;

  factory Novidade.fromJson(Map<String, dynamic> json) {
    final base = Novidade.deTexto((json['texto'] as String?) ?? '');
    return Novidade(
      titulo: base.titulo,
      corpo: base.corpo,
      autor: json['autor'] as String?,
      publicadaEm:
          DateTime.tryParse((json['publicada_em'] as String?) ?? '') ??
          DateTime.utc(2000),
    );
  }

  /// Splits a raw message into heading and body.
  factory Novidade.deTexto(String texto) {
    final linhas = texto.trimRight().split('\n');
    final primeira = linhas.isEmpty ? '' : linhas.first.trim();
    final cabecalho = _tituloPattern.firstMatch(primeira);

    if (cabecalho == null) {
      return Novidade(
        titulo: null,
        corpo: texto.trim(),
        autor: null,
        publicadaEm: DateTime.utc(2000),
      );
    }

    return Novidade(
      titulo: cabecalho.group(1)!.trim(),
      corpo: linhas.skip(1).join('\n').trim(),
      autor: null,
      publicadaEm: DateTime.utc(2000),
    );
  }

  /// A line that is **entirely** bold. Bold in the middle of a sentence is
  /// emphasis, not a heading, and promoting it would turn a remark into a
  /// title with the rest of the sentence orphaned under it.
  static final _tituloPattern = RegExp(r'^\*\*(.+)\*\*$');
}

/// The paragraphs of a message.
///
/// **Only a blank line starts a new one.** A single newline stays inside the
/// paragraph, because Discord hard-wraps as somebody types and honouring every
/// break would draw one thought as a staircase — the lesson the war map
/// already paid for.
List<String> paragrafos(String texto) => [
  for (final bloco in texto.split(RegExp(r'\n\s*\n')))
    if (bloco.trim().isNotEmpty) bloco.trim(),
];

/// A run of text with one property: bold, a link, or neither.
class Pedaco {
  const Pedaco(this.texto, {this.negrito = false, this.url});

  final String texto;
  final bool negrito;
  final String? url;
}

/// Breaks a paragraph into runs the page can draw.
///
/// Three words wide on purpose — bold, link, plain — and **everything else
/// arrives as characters somebody typed**. An `@everyone`, a stray asterisk,
/// a `<b>` tag: all of it comes out as text. Flutter draws into a canvas, so
/// none of it could execute anyway, but the rule is the same one the war map
/// follows and it is the rule that survives the day this moves to HTML.
List<Pedaco> pedacos(String paragrafo) {
  final saida = <Pedaco>[];
  var resto = paragrafo;

  while (resto.isNotEmpty) {
    final achado = _marcacao.firstMatch(resto);
    if (achado == null) {
      saida.add(Pedaco(resto));
      break;
    }

    if (achado.start > 0) saida.add(Pedaco(resto.substring(0, achado.start)));

    final negrito = achado.group(1);
    if (negrito != null) {
      saida.add(Pedaco(negrito, negrito: true));
    } else {
      var url = achado.group(0)!;
      // Punctuation at the end of a sentence is not part of the address, and
      // carrying it in gives a link that 404s.
      final cauda = RegExp(r'[.,;:!?)\]]+$').firstMatch(url);
      if (cauda != null) {
        url = url.substring(0, cauda.start);
        saida.add(Pedaco(url, url: url));
        saida.add(Pedaco(cauda.group(0)!));
      } else {
        saida.add(Pedaco(url, url: url));
      }
    }

    resto = resto.substring(achado.end);
  }

  return saida;
}

/// Bold first, so `**https://x**` reads as emphasis rather than half a link.
final _marcacao = RegExp(r'\*\*(.+?)\*\*|https?://\S+');
