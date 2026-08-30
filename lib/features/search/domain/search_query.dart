import '../../../market/celestial_realm.dart';
import '../../../market/counted_items.dart';
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
  realm,
  path,
  runes,
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
  /// [mostOwned] adds the three relics, and the `Chave da Sorte` is not one of
  /// them — it is a different kind of thing, and [relicNames] carries both the
  /// player's reason and the measurement that agrees with him. It used to sum
  /// whatever was **marked**, and to be offered only once something was, which
  /// asked the visitor to jump a hoop for a question with one obvious meaning.
  mostAnecdotes('Mais anedotas'),
  mostOwned('Mais relíquias'),

  /// Both directions, like the price and unlike everything else here. The two
  /// are different searches: the most advanced character, and the cheapest one
  /// still worth raising.
  highestRealm('Maior céu'),
  lowestRealm('Menor céu');

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
    ResultOrder.mostOwned => relicNames.any(index.countedItems.containsKey),
    ResultOrder.highestRealm ||
    ResultOrder.lowestRealm => index.characters.any((c) => c.realm.isNotEmpty),
    _ => true,
  };
}

/// One question about the runes a character has set.
///
/// Colour **and** level, because that is how the question is asked in the
/// game: a rune is not better for being any colour, but it is better for being
/// level 9 — every colour was seen from 4 to 9, so the colour is a category
/// and the level is the grade.
///
/// [minimum] is what makes it a filter worth having. Across the market's
/// dearest characters, *at least one rune of level 7+* took 93% of them —
/// a filter that leaves the market on screen teaches nothing. Three of them
/// halves it.
class RuneCriterion {
  const RuneCriterion({this.type, this.minimumLevel = 7, this.minimum = 1});

  /// `null` means any colour, which is the question that separates the market
  /// rather than the one that describes a build.
  final String? type;

  final int minimumLevel;
  final int minimum;

  RuneCriterion copyWith({
    String? Function()? type,
    int? minimumLevel,
    int? minimum,
  }) => RuneCriterion(
    type: type == null ? this.type : type(),
    minimumLevel: minimumLevel ?? this.minimumLevel,
    minimum: minimum ?? this.minimum,
  );
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
    this.shownOwned = const {},
    this.anecdotesOnCard = false,
    this.pets = const {},
    this.minRealm,
    this.path,
    this.runes,
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

  /// Counted items whose number the card should print.
  ///
  /// **Marking, and nothing else.** There was a *pelo menos N* filter beside
  /// it and it was dropped: a relic count is a number to compare, not a bar to
  /// clear, and *Mais relíquias* already sorts by it. Two controls asked one
  /// question, and the filter half was the one nobody wanted.
  ///
  /// Out of [isEmpty] and out of the count of filters in force, for the same
  /// reason [order] is: it is how the list is read, not something asked of the
  /// market.
  final Set<String> shownOwned;

  /// Print the anecdote progress on every card, asking nothing of the market.
  ///
  /// The counted items' checkbox, for the one thing that is not an item. It is
  /// out of [isEmpty] and out of the count of filters in force for the same
  /// reason [shownOwned] is.
  final bool anecdotesOnCard;

  /// Pets the character must have, by the label in [countedItemIds].
  ///
  /// A plain filter, unlike the counted items: a pet is a yes or a no, and
  /// there is no quantity to compare across characters — so there is nothing
  /// for a "show it" mark to add that passing the filter does not already say.
  ///
  /// Only the Feiticeira has combat pets, so asking for one narrows to that
  /// class by itself; nothing here knows about classes.
  final Set<String> pets;

  /// The lowest rung of the celestial scale that still passes, as a
  /// [CelestialRealm.ordinal] — 1 to 100.
  ///
  /// A number and not a pair of fields, because the scale is one ladder: the
  /// tier and the step are how the game writes it, not how it compares.
  final int? minRealm;

  /// `God` or `Evil`. A character whose path could not be read fails either
  /// one, rather than being sorted into the half he might not belong to.
  final String? path;

  /// One question about the runes he has set.
  final RuneCriterion? runes;

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
      pets.isEmpty &&
      minRealm == null &&
      path == null &&
      runes == null;

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
    FacetDimension.realm => copyWith(minRealm: () => null),
    FacetDimension.path => copyWith(path: () => null),
    FacetDimension.runes => copyWith(runes: () => null),
    FacetDimension.owned => copyWith(shownOwned: const {}, pets: const {}),
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
    Set<String>? shownOwned,
    bool? anecdotesOnCard,
    Set<String>? pets,
    int? Function()? minRealm,
    String? Function()? path,
    RuneCriterion? Function()? runes,
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
    shownOwned: shownOwned ?? this.shownOwned,
    anecdotesOnCard: anecdotesOnCard ?? this.anecdotesOnCard,
    pets: pets ?? this.pets,
    minRealm: minRealm == null ? this.minRealm : minRealm(),
    path: path == null ? this.path : path(),
    runes: runes == null ? this.runes : runes(),
    order: order ?? this.order,
  );
}
