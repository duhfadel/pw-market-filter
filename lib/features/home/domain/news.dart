import 'package:flutter/widgets.dart';

import '../ui/widgets/home_notice.dart';

/// One dated entry on the front page.
///
/// The site had a standing panel announcing the reopening, and a standing
/// panel is the wrong shape for news: with no date it never stops being
/// current, and whoever writes the next one has to decide what to do with the
/// old. Dated entries in a list solve both — the newest is what a returning
/// visitor reads, and nothing has to be deleted to make room.
///
/// [body] is a builder rather than a string because the first entry carries a
/// list and a button. Most will be a paragraph; the type should not force the
/// exception into a second mechanism.
class NewsEntry {
  const NewsEntry({
    required this.date,
    required this.title,
    required this.body,
  });

  /// The day it happened, not the day it was published — and written down
  /// rather than computed: news does not age into being about today.
  final DateTime date;

  final String title;

  final Widget Function(BuildContext context, bool wide) body;

  /// `18/09/2026`, the same shape the collection date uses on the filter.
  String get label =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

/// Every entry, newest first. Adding one is adding a `NewsEntry` here.
///
/// `final` and not `const` because a `DateTime` is not a compile-time
/// constant — the one thing every entry must carry.
final portalNews = <NewsEntry>[
  NewsEntry(
    date: DateTime.utc(2026, 9, 18),
    title: 'Estamos de volta!',
    body: (context, wide) => HomeNotice(wide: wide),
  ),
];
