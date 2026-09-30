import '../../../market/market_index.dart';
import '../../search/domain/matcher.dart';
import '../../search/domain/presets.dart';

/// Which three characters the front page's Vitrine shows, and why.
///
/// The claim on the page is "the same weapon, sixty times the price" — so
/// [barato] and [caro] have to be the cheapest and dearest of the **same**
/// weapon tier, never the cheapest and dearest of the whole market. Those
/// would not be carrying the same thing, and the comparison would be false.
///
/// [raro] is the defensive tier of the same weapon slot, shown only when at
/// least one character on this collection carries it — a market that has
/// never reached that tier has nothing to show, and `null` says so rather
/// than repeating one of the other two.
///
/// `null` altogether when fewer than two characters carry the attack tier:
/// one carrier makes [barato] and [caro] the same person, which is not an
/// argument, and no carriers means no vitrine at all.
///
/// [nivel] is the attack level [strongWeaponQuery] actually asked for, read
/// off its own criterion rather than assumed — a page that prints "nível de
/// ataque 70" as a literal beside a query that asks for something else is
/// the same drift that once let an 80 tier slip through a chip still
/// labelled 70. The two must read from one number.
({
  MarketCharacter barato,
  MarketCharacter caro,
  MarketCharacter? raro,
  int nivel,
})?
vitrineDe(MarketIndex index) {
  final weapon = strongWeaponQuery(index);
  if (weapon == null) return null;

  // `runQuery` orders by cheapest first by default.
  final carriers = runQuery(index, weapon);
  if (carriers.length < 2) return null;

  final rareQuery = weaponQuery(index, 'Nível de Defesa', 80);
  final rareCarriers = rareQuery == null
      ? const <MarketCharacter>[]
      : runQuery(index, rareQuery);

  return (
    barato: carriers.first,
    caro: carriers.last,
    raro: rareCarriers.isEmpty ? null : rareCarriers.first,
    nivel: weapon.criteria.first.minimum,
  );
}
