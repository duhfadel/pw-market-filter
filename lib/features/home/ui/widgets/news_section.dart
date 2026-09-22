import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import 'novidade_texto.dart';
import '../../data/browser_memory.dart';
import '../../domain/novidade.dart';

/// The front page's news, newest first.
///
/// **It starts closed, and the header is the news.** It started open, and with
/// three entries it ran to a thousand pixels — the tools began two screens
/// below the fold, so the page led with a newspaper instead of with what the
/// site does. Nothing was dropped to fix it: the header now carries the latest
/// entry's own title and date, which says more than the `3 recados` a closed
/// panel used to show, and opening it gives back exactly what was there.
///
/// Fifty-six pixels whatever the count, which is the property that matters —
/// the Worker reads a twenty-message window, so the open version grew without
/// any ceiling at all.
///
/// Nothing here is drawn when there is no news at all — a section whose only
/// content is its own title is furniture.
class NewsSection extends StatefulWidget {
  const NewsSection({
    required this.entries,
    required this.wide,
    this.memoria,
    super.key,
  });

  final List<Novidade> entries;
  final bool wide;

  /// Where this browser remembers the last entry it was shown. Injected so the
  /// suite can hand in a fresh one; `null` draws no dot at all, which is what
  /// every caller that does not care about it gets.
  final BrowserMemory? memoria;

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  bool _open = false;

  /// What the stored marker said when the page loaded, read once.
  ///
  /// Once, and not on every build, because opening the panel writes to it:
  /// re-reading would clear the dot in the same frame, so the thing announcing
  /// something new would vanish as the new thing appeared.
  String? _lidaAoAbrir;
  var _leu = false;

  String get _marcaDaUltima =>
      widget.entries.first.publicadaEm.toIso8601String();

  /// Something published since this browser last opened the panel.
  ///
  /// A browser that has never opened it counts as having something new, which
  /// is the useful direction to be wrong in: a first-time visitor is exactly
  /// who has read none of it.
  bool get _temNovidade {
    if (widget.memoria == null || widget.entries.isEmpty) return false;
    if (!_leu) {
      _lidaAoAbrir = widget.memoria!.read();
      _leu = true;
    }
    return _lidaAoAbrir != _marcaDaUltima;
  }

  void _alternar() {
    setState(() {
      _open = !_open;
      // Marked on the way open and never on the way closed: somebody who
      // opens and shuts it has seen the title either way.
      if (_open) {
        widget.memoria?.write(_marcaDaUltima);
        _lidaAoAbrir = _marcaDaUltima;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      // The accent stripe is a child and not the box's left border: a
      // `BoxDecoration` with a `borderRadius` asserts when its border colours
      // are not uniform, and it asserts only in debug — the release build drew
      // it perfectly while `flutter test` refused it.
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: PWColors.accent),
            Expanded(child: _painel()),
          ],
        ),
      ),
    );
  }

  Widget _painel() => Container(
    decoration: const BoxDecoration(
      color: PWColors.surface,
      border: Border(
        top: BorderSide(color: PWColors.border),
        right: BorderSide(color: PWColors.border),
        bottom: BorderSide(color: PWColors.border),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cabecalho(),
        if (_open)
          for (var i = 0; i < widget.entries.length; i++)
            _entrada(widget.entries[i], primeira: i == 0),
      ],
    ),
  );

  Widget _cabecalho() =>
      InkWell(onTap: _alternar, child: _conteudoDoCabecalho());

  Widget _conteudoDoCabecalho() => Padding(
    padding: EdgeInsets.fromLTRB(
      widget.wide ? 24 : 18,
      widget.wide ? 18 : 15,
      widget.wide ? 18 : 12,
      _open ? 0 : (widget.wide ? 18 : 15),
    ),
    child: Row(
      children: [
        // The game's own Alto-Falante (item 12979), not a Material
        // megaphone — the same choice the filter's section headers make, and
        // for the same reason: a picture of the thing beats a glyph meaning
        // "some section".
        //
        // On a raised chip at 28 px because it is a 32 px sprite carrying
        // its own busy background: loose on the page and shrunk past about
        // 22 it reads as a dark smudge, with no edge to say where the
        // picture stops.
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: PWColors.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: const ItemIcon(12979, size: 28),
        ),
        const SizedBox(width: 10),
        // `Expanded` and no `Spacer`: a Spacer beside a Flexible splits the
        // free space with it, which is what once crushed the nicknames on
        // the results card to `NI…`.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // **Whose news.** A bare `NOVIDADES` sits a few hundred
                  // pixels under the Perfect World mark and reads as the
                  // game's own patch notes — which this site must never imply,
                  // since it speaks for nobody but itself.
                  const Text(
                    'NOVIDADES DO PORTAL',
                    style: TextStyle(
                      color: PWColors.accent,
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  // The date rides with the label rather than at the far
                  // right, where it sat over the art and could not be read.
                  // Every text on a tool card lives on the left half for the
                  // same reason: the picture owns the other side.
                  if (!_open) ...[
                    const Text(
                      '  ·  ',
                      style: TextStyle(color: PWColors.textMuted, fontSize: 11),
                    ),
                    Text(
                      _data(widget.entries.first.publicadaEm),
                      style: const TextStyle(
                        color: PWColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  // MOCKUP: a bolinha de "tem coisa nova desde sua ultima
                  // visita". A logica do localStorage entra depois da arte.
                  // Lit only while this browser has not opened the panel
                  // since the latest entry was published. A dot still on after
                  // it has been read teaches the reader to stop seeing it —
                  // the same failure the `novo` badge's expiry avoids.
                  if (!_open && _temNovidade) ...[
                    const SizedBox(width: 7),
                    Container(
                      key: const Key('novidade-nao-lida'),
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: PWColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              // Closed, the latest entry's own title is what says there is
              // something inside. It replaced a count of messages, which
              // told a returning visitor nothing about whether the thing
              // inside was the one they had already read.
              if (!_open) ...[
                const SizedBox(height: 3),
                Text(
                  _chamada,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: PWColors.text,
                    fontSize: widget.wide ? 15 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(
          _open ? Icons.expand_less : Icons.expand_more,
          size: 20,
          color: PWColors.textMuted,
        ),
      ],
    ),
  );

  /// The latest entry's heading, or the plain word when it has none.
  ///
  /// A message with no bold first line is a remark rather than an
  /// announcement, and cutting its body off mid-sentence to fill this line
  /// would put half a thought where a title goes.
  String get _chamada =>
      widget.entries.first.titulo ?? 'Tem recado novo por aqui';

  Widget _entrada(Novidade entry, {required bool primeira}) => Padding(
    padding: EdgeInsets.fromLTRB(
      widget.wide ? 24 : 18,
      primeira ? (widget.wide ? 14 : 12) : 0,
      widget.wide ? 24 : 18,
      widget.wide ? 20 : 16,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A rule above every entry but the first, so a list of three reads as
        // three things rather than as one long column.
        if (!primeira) ...[const Divider(color: PWColors.border, height: 28)],
        Text(
          _data(entry.publicadaEm),
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        // Uma novidade sem título é um recado, não um anúncio, e desenhar
        // a primeira linha como manchete transformaria "coletei agora" num
        // grito.
        if (entry.titulo != null) ...[
          Text(
            entry.titulo!,
            style: TextStyle(
              color: PWColors.text,
              fontSize: widget.wide ? 19 : 17,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          SizedBox(height: widget.wide ? 12 : 10),
        ] else
          const SizedBox(height: 6),
        NovidadeTexto(corpo: entry.corpo),
      ],
    ),
  );

  /// `21/09/2026`, a mesma forma que a data da coleta usa no filtro.
  static String _data(DateTime quando) {
    final local = quando.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}
