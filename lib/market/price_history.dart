/// What the market remembers about one character between collections.
///
/// Four numbers and nothing else, deliberately. A full price series per
/// character would grow the index without answering a question anybody asks:
/// the screen says *"baixou de 500 para 400, já cortou três vezes"*, and that
/// is four numbers.
class PriceHistory {
  const PriceHistory({
    required this.firstSeen,
    this.previousPrice,
    required this.lowestPrice,
    this.cuts = 0,
  });

  /// When this `roleId` was first met by a collection that was keeping
  /// records. **Never moves** — a character that leaves the market and comes
  /// back keeps the date, because forgetting it would call an old listing new.
  final DateTime firstSeen;

  /// What it asked immediately before the most recent change, or `null` while
  /// the price has never moved.
  ///
  /// The price *before the last move* rather than "yesterday's price": a
  /// character standing at 400 for a week should still be able to say it came
  /// down from 500.
  final int? previousPrice;

  /// The cheapest it has ever asked.
  final int lowestPrice;

  /// How many times the price has **fallen**. A rise is not a cut, which is
  /// why this is counted rather than derived from the two prices.
  final int cuts;

  Map<String, dynamic> toJson() => {
    'firstSeen': firstSeen.toUtc().toIso8601String(),
    if (previousPrice != null) 'previousPrice': previousPrice,
    'lowestPrice': lowestPrice,
    if (cuts > 0) 'cuts': cuts,
  };

  factory PriceHistory.fromJson(Map<String, dynamic> json) => PriceHistory(
    firstSeen: DateTime.parse(json['firstSeen'] as String).toUtc(),
    previousPrice: json['previousPrice'] as int?,
    lowestPrice: json['lowestPrice'] as int,
    cuts: json['cuts'] as int? ?? 0,
  );
}

/// Advances [antes] by one collection.
///
/// [precoAnterior] is what the character asked at the previous collection. It
/// lives on the character in the published index rather than in the record,
/// so it arrives as an argument — keeping it out of [PriceHistory] is what
/// stops the same number being written twice and drifting.
///
/// `antes == null` is a character this site has never recorded: the record
/// starts today, and **today is not the same as new** — see
/// `MarketIndex.historyFrom`, which is what lets the screen tell a first
/// sighting from a genuine arrival.
PriceHistory avancar(
  PriceHistory? antes, {
  required int preco,
  required int? precoAnterior,
  required DateTime agora,
}) {
  if (antes == null) {
    return PriceHistory(firstSeen: agora, lowestPrice: preco);
  }

  final menor = preco < antes.lowestPrice ? preco : antes.lowestPrice;

  // A price that did not move writes nothing. Most never do, and standing
  // still must not cost a row every fifteen minutes.
  if (precoAnterior == null || preco == precoAnterior) {
    return PriceHistory(
      firstSeen: antes.firstSeen,
      previousPrice: antes.previousPrice,
      lowestPrice: menor,
      cuts: antes.cuts,
    );
  }

  return PriceHistory(
    firstSeen: antes.firstSeen,
    previousPrice: precoAnterior,
    lowestPrice: menor,
    cuts: preco < precoAnterior ? antes.cuts + 1 : antes.cuts,
  );
}
