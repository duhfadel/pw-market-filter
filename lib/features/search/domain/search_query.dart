import '../../../market/market_index.dart';
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
  anecdotes,
  owned,
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
  highestFame('Maior fama'),

  /// The two that read the character's own page rather than his gear.
  ///
  /// [mostOwned] adds up the counted items that are **marked**, which is what
  /// says which relic "mais relíquias" means — the market has three of them
  /// and the order must not pick one on the visitor's behalf. It is offered
  /// only while something is marked, for the same reason.
  mostAnecdotes('Mais anedotas'),
  mostOwned('Mais relíquias');

  const ResultOrder(this.label);

  final String label;

  /// Whether this order can say anything about [query]'s results.
  ///
  /// An order nobody can read is worse than an absent one: it rearranges the
  /// list by a number that is the same for everybody and looks like a bug.
  bool offeredFor(MarketIndex index, SearchQuery query) => switch (this) {
    ResultOrder.mostAnecdotes => index.characters.any(
      (c) => c.anecdotes != null,
    ),
    ResultOrder.mostOwned => query.ownedOnCard.isNotEmpty,
    _ => true,
  };
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
    this.minAnecdotes,
    this.minimumOwned = const {},
    this.shownOwned = const {},
    this.anecdotesOnCard = false,
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

  /// How many anecdotes the character must have completed. It is the one
  /// number on the page that measures time spent rather than money spent.
  final int? minAnecdotes;

  /// A counted item's **name** to how many of it the character must carry.
  ///
  /// By name and not by id, for the same reason the shared link writes the
  /// attribute by name: the name is what `countedItemNames` holds and what a
  /// link can carry across collections, and only the index knows which id this
  /// collection found it under.
  final Map<String, int> minimumOwned;

  /// Counted items whose number the card should print, whether or not a
  /// minimum is being asked for.
  ///
  /// Marking is not filtering. "Show me how many relics each of these carries"
  /// is a different question from "only show me who carries five", and tying
  /// them together forced a filter on anybody who just wanted to look. So this
  /// is out of [isEmpty] and out of the count of filters in force, for the same
  /// reason [order] is: it is how the list is read, not something that was
  /// asked of the market.
  ///
  /// A minimum implies its own name is shown — a card that refuses to say why
  /// a character passed is worse than one that says nothing.
  final Set<String> shownOwned;

  /// Every counted item the card should print for, in one place so the card
  /// and the grid that sizes it cannot disagree.
  Set<String> get ownedOnCard => {...shownOwned, ...minimumOwned.keys};

  /// Print the anecdote progress on every card, asking nothing of the market.
  ///
  /// The counted items' checkbox, for the one thing that is not an item. It is
  /// out of [isEmpty] and out of the count of filters in force for the same
  /// reason [shownOwned] is.
  final bool anecdotesOnCard;

  /// Whether the card should print the anecdote progress.
  ///
  /// Marking says so outright. So does asking for a minimum — a card that will
  /// not say why a character passed is worse than one that says nothing — and
  /// so does ordering by it: the count is then why a card sits where it does,
  /// and demanding a minimum as well, only to see the number, would throw away
  /// every result below the cut.
  bool get showsAnecdotes =>
      anecdotesOnCard ||
      minAnecdotes != null ||
      order == ResultOrder.mostAnecdotes;

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
      criteria.isEmpty &&
      minAnecdotes == null &&
      minimumOwned.isEmpty;

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
    FacetDimension.anecdotes => copyWith(minAnecdotes: () => null),
    FacetDimension.owned => copyWith(minimumOwned: const {}),
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
    int? Function()? minAnecdotes,
    Map<String, int>? minimumOwned,
    Set<String>? shownOwned,
    bool? anecdotesOnCard,
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
    minAnecdotes: minAnecdotes == null ? this.minAnecdotes : minAnecdotes(),
    minimumOwned: minimumOwned ?? this.minimumOwned,
    shownOwned: shownOwned ?? this.shownOwned,
    anecdotesOnCard: anecdotesOnCard ?? this.anecdotesOnCard,
    order: order ?? this.order,
  );
}
