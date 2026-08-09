import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// One card on `marketplace.theclassic.games/pw187`.
///
/// The listing page is the cheap half of a collection: a single request
/// returns all 779 cards, server-rendered, with everything except the gear.
class ListingCard {
  const ListingCard({
    required this.roleId,
    required this.name,
    required this.characterClass,
    required this.occupation,
    required this.level,
    required this.price,
    required this.fame,
    required this.cultivation,
  });

  final int roleId;
  final String name;
  final String characterClass;
  final int occupation;
  final int level;
  final int price;
  final int fame;
  final String cultivation;
}

/// Reads every character card out of the listing page.
///
/// A page without the list yields an empty result rather than throwing: the
/// collector treats "nothing found" as something to report, not as a crash.
List<ListingCard> parseListing(String html) {
  final document = html_parser.parse(html);

  return document
      .querySelectorAll('#character-list li.character-card')
      .map(_readCard)
      .toList(growable: false);
}

ListingCard _readCard(Element element) {
  int attribute(String name) =>
      int.tryParse(element.attributes[name] ?? '') ?? 0;

  String text(String selector) =>
      element.querySelector(selector)?.text.trim() ?? '';

  // Cultivation is the first `.display-score` block. Fame is the second, and
  // is the only one carrying `.power`.
  final scores = element.querySelectorAll('.display-score dd');

  return ListingCard(
    roleId: attribute('data-roleid'),
    name: text('dd.item-name'),
    characterClass: text('dd.item-type'),
    occupation: attribute('data-occupation'),
    level: attribute('data-level'),
    price: attribute('data-price'),
    fame: int.tryParse(text('dd.power')) ?? 0,
    cultivation: scores.isEmpty ? '' : scores.first.text.trim(),
  );
}
