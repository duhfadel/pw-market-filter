/// One line of the search form: an item in this slot, of at least this rank
/// and refine, giving at least this much of this attribute.
///
/// [slot] is optional because "70 attack level anywhere on the character" is a
/// real question and costs nothing to answer.
///
/// [attributeId] is optional too, but for a different reason. "Any attribute
/// above 70" would mix Attack Level with HP and mean nothing — so the minimum
/// only applies when an attribute is named. What a criterion without one asks
/// about is the **item**: "a rank 4 weapon at +11 or better", which was
/// unsayable while every criterion had to name an attribute.
class ItemCriterion {
  const ItemCriterion({
    this.slot,
    this.attributeId,
    this.minimum = 0,
    this.minimumRefine = 0,
    this.minimumRank = 0,
  });

  /// `null` means any slot.
  final int? slot;

  /// Index into `MarketIndex.attributes`, or `null` for "do not ask".
  final int? attributeId;

  /// Ignored when [attributeId] is null.
  final int minimum;

  /// Both of these are checked on the same item that carries the attribute,
  /// not on the slot at large — a spare with the right refine must not vouch
  /// for the worn piece.
  final int minimumRefine;

  /// The stars in the item's name: no stars is rank 1, `★★★` is rank 4. Zero
  /// means "do not ask". Independent of the attribute — ★★★Dilacerador Raivoso
  /// gives 70 attack level and ★★★Geada Tardia gives none, and both are rank 4.
  final int minimumRank;

  ItemCriterion copyWith({
    int? Function()? slot,
    int? Function()? attributeId,
    int? minimum,
    int? minimumRefine,
    int? minimumRank,
  }) => ItemCriterion(
    slot: slot == null ? this.slot : slot(),
    attributeId: attributeId == null ? this.attributeId : attributeId(),
    minimum: minimum ?? this.minimum,
    minimumRefine: minimumRefine ?? this.minimumRefine,
    minimumRank: minimumRank ?? this.minimumRank,
  );
}
