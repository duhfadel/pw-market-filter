import 'item_criterion.dart';

/// One control on the form.
///
/// Each control's options are read from the characters that pass every filter
/// **except its own**. Including its own would collapse the control to the
/// single value already chosen — pick Guerreiro and the class list would offer
/// Guerreiro and nothing else, with no way back.
enum FacetDimension {
  characterClass,
  cultivation,
  level,
  price,
  cards,
  items,
  criteria,
}

/// How the results are ordered.
///
/// The default is the cheapest first, and that is a decision about the task
/// rather than a preference: finding who has the weapon is half the question,
/// and "which of them is cheapest" is the other half. The site's own order
/// carries no meaning, so inheriting it would waste the answer.
enum ResultOrder {
  cheapest('Menor preço'),
  dearest('Maior preço'),
  highestLevel('Maior nível'),
  highestFame('Maior fama');

  const ResultOrder(this.label);

  final String label;
}

/// Everything the form asks for. A field left `null` asks nothing.
class SearchQuery {
  const SearchQuery({
    this.characterClass,
    this.cultivation,
    this.minLevel,
    this.maxLevel,
    this.minPrice,
    this.maxPrice,
    this.itemBySlot = const {},
    this.comboName,
    this.cardRarity,
    this.cardsMaxed = false,
    this.criteria = const [],
    this.order = ResultOrder.cheapest,
  });

  final String? characterClass;
  final String? cultivation;
  final int? minLevel;
  final int? maxLevel;
  final int? minPrice;
  final int? maxPrice;

  /// Slot to the exact item that has to be worn there. The shortcut behind the
  /// weapon dropdown: pick `★★★Dilacerador Raivoso · +70 nível de ataque` and
  /// the number is in the label, so nobody has to know which of the three
  /// weapons called *Dilacerador* is the good one.
  final Map<int, int> itemBySlot;

  /// An AND. Every criterion has to find its own satisfying item.
  final List<ItemCriterion> criteria;

  /// Name of a [CardCombo] the character must wear in full.
  final String? comboName;

  /// All six cards at this rarity — useful even where no named combo applies,
  /// because six S cards is the thing that moves the price whatever the set is
  /// called.
  final String? cardRarity;

  /// Every card at its cap. A combo of six S cards sitting at 1/80 is not the
  /// same purchase as one at 80/80.
  final bool cardsMaxed;

  final ResultOrder order;

  /// The order is not part of this: it is always set, and a query that only
  /// orders is still a query that asks nothing.
  bool get isEmpty =>
      characterClass == null &&
      cultivation == null &&
      minLevel == null &&
      maxLevel == null &&
      minPrice == null &&
      maxPrice == null &&
      itemBySlot.isEmpty &&
      comboName == null &&
      cardRarity == null &&
      !cardsMaxed &&
      criteria.isEmpty;

  /// This query with [dimension] switched off, which is the population a
  /// control should read its options from.
  ///
  /// The item slots are one dimension rather than fourteen: narrowing the helm
  /// list by the weapon already chosen is right, but it also means the weapon
  /// list is not narrowed by the helm. One shared dimension keeps every item
  /// control offering what the rest of the query allows, without a control
  /// hiding an option because of a sibling.
  SearchQuery without(FacetDimension dimension) => switch (dimension) {
    FacetDimension.characterClass => copyWith(characterClass: () => null),
    FacetDimension.cultivation => copyWith(cultivation: () => null),
    FacetDimension.level => copyWith(
      minLevel: () => null,
      maxLevel: () => null,
    ),
    FacetDimension.price => copyWith(
      minPrice: () => null,
      maxPrice: () => null,
    ),
    FacetDimension.cards => copyWith(
      comboName: () => null,
      cardRarity: () => null,
      cardsMaxed: false,
    ),
    FacetDimension.items => copyWith(itemBySlot: const {}),
    FacetDimension.criteria => copyWith(criteria: const []),
  };

  SearchQuery copyWith({
    String? Function()? characterClass,
    String? Function()? cultivation,
    int? Function()? minLevel,
    int? Function()? maxLevel,
    int? Function()? minPrice,
    int? Function()? maxPrice,
    Map<int, int>? itemBySlot,
    String? Function()? comboName,
    String? Function()? cardRarity,
    bool? cardsMaxed,
    List<ItemCriterion>? criteria,
    ResultOrder? order,
  }) => SearchQuery(
    characterClass: characterClass == null
        ? this.characterClass
        : characterClass(),
    cultivation: cultivation == null ? this.cultivation : cultivation(),
    minLevel: minLevel == null ? this.minLevel : minLevel(),
    maxLevel: maxLevel == null ? this.maxLevel : maxLevel(),
    minPrice: minPrice == null ? this.minPrice : minPrice(),
    maxPrice: maxPrice == null ? this.maxPrice : maxPrice(),
    itemBySlot: itemBySlot ?? this.itemBySlot,
    comboName: comboName == null ? this.comboName : comboName(),
    cardRarity: cardRarity == null ? this.cardRarity : cardRarity(),
    cardsMaxed: cardsMaxed ?? this.cardsMaxed,
    criteria: criteria ?? this.criteria,
    order: order ?? this.order,
  );
}
