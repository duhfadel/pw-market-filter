import 'package:flutter/material.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../domain/news.dart';

/// The front page's news, newest first.
///
/// **It starts open**, because the reason it exists is to be read by somebody
/// who did not come looking for it. It can be closed, and that is the other
/// half: a visitor who has read it can put it away and get on with the tool,
/// which a permanent panel never allowed.
///
/// Nothing here is drawn when there is no news at all — a section whose only
/// content is its own title is furniture.
class NewsSection extends StatefulWidget {
  const NewsSection({required this.entries, required this.wide, super.key});

  final List<NewsEntry> entries;
  final bool wide;

  @override
  State<NewsSection> createState() => _NewsSectionState();
}

class _NewsSectionState extends State<NewsSection> {
  bool _open = true;

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

  Widget _cabecalho() => InkWell(
    onTap: () => setState(() => _open = !_open),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        widget.wide ? 24 : 18,
        widget.wide ? 18 : 15,
        widget.wide ? 18 : 12,
        _open ? 0 : (widget.wide ? 18 : 15),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined, size: 18, color: PWColors.accent),
          const SizedBox(width: 9),
          const Text(
            'NOVIDADES',
            style: TextStyle(
              color: PWColors.accent,
              fontSize: 11,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          // Closed, the count is the only thing saying there is anything
          // inside — the same job the filter's collapsed sections do.
          if (!_open)
            Text(
              widget.entries.length == 1
                  ? '1 recado'
                  : '${widget.entries.length} recados',
              style: const TextStyle(color: PWColors.textMuted, fontSize: 12),
            ),
          Icon(
            _open ? Icons.expand_less : Icons.expand_more,
            size: 20,
            color: PWColors.textMuted,
          ),
        ],
      ),
    ),
  );

  Widget _entrada(NewsEntry entry, {required bool primeira}) => Padding(
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
          entry.label,
          style: const TextStyle(
            color: PWColors.textMuted,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          entry.title,
          style: TextStyle(
            color: PWColors.text,
            fontSize: widget.wide ? 19 : 17,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        SizedBox(height: widget.wide ? 12 : 10),
        entry.body(context, widget.wide),
      ],
    ),
  );
}
