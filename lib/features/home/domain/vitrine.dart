import '../../../market/market_index.dart';
import '../../search/domain/matcher.dart';
import '../../search/domain/presets.dart';

/// Which three characters the front page's Vitrine shows, and why.
///
/// The claim on the page is "the same weapon tier, sixty times the price" —
/// so [barato] and [caro] have to be the cheapest and dearest of the
/// **exact same** attack level, never merely both at or above
/// [strongWeaponQuery]'s minimum. `strongWeaponQuery` asks for *at least* 70,
/// and the market carries an 80 tier above it (measured 2026-09-29: 789
/// carriers at exactly 70, 21 at exactly 80) — so `carriers.first` and
/// `carriers.last` of that query used to be able to land on different tiers,
/// worn by different classes, and the page still called it "a mesma arma".
/// That is the same swallow `CLAUDE.md` already records for the UP5 chips,
/// happening a second time in a place that prints the swallowed number next
/// to the claim.
///
/// [raro] is the defensive tier of the same weapon slot, shown only when at
/// least one character on this collection carries it — a market that has
/// never reached that tier has nothing to show, and `null` says so rather
/// than repeating one of the other two.
///
/// `null` altogether when fewer than two characters carry the same exact
/// tier: one carrier makes [barato] and [caro] the same person, which is not
/// an argument, and no carriers means no vitrine at all.
///
/// [nivel] is read off the characters actually chosen — through
/// [bestMatchFor], the same lookup the results card uses to say which item
/// answered a criterion — never off the query's minimum. A page that prints
/// "nível de ataque 70" as a literal beside a pair that does not share that
/// number is the same drift, and the fix has to hold even if a future
/// collection changes which tier is the common one.
({
  MarketCharacter barato,
  MarketCharacter caro,
  MarketCharacter? raro,
  int nivel,
})?
vitrineDe(MarketIndex index) {
  final weapon = strongWeaponQuery(index);
  if (weapon == null) return null;
  final criterion = weapon.criteria.first;
  final attributeId = criterion.attributeId;
  if (attributeId == null) return null;

  // `runQuery` orders by cheapest first by default, and that order survives
  // the grouping below.
  final carriers = runQuery(index, weapon);

  // Group by the exact attack level of the weapon each carrier actually
  // wears, read through `bestMatchFor` rather than trusted from the query's
  // `minimum` — `carriers` holds everybody at 70 *and above*, and comparing
  // across tiers is precisely the defect this tool exists to expose
  // elsewhere in the market.
  final porNivel = <int, List<MarketCharacter>>{};
  for (final character in carriers) {
    final item = bestMatchFor(index, character, criterion);
    final valor = item?.attributes[attributeId];
    if (valor == null) continue;
    porNivel.putIfAbsent(valor, () => []).add(character);
  }

  // The tier with the most carriers is the honest pick: it is the one the
  // page's other numbers (the spread, the multiplier) describe best, and
  // picking it this way — rather than assuming it is always the query's own
  // minimum — keeps the pair correct even if the market's balance of tiers
  // shifts. Ties break towards the lower tier for a stable result.
  MapEntry<int, List<MarketCharacter>>? maior;
  for (final entry in porNivel.entries) {
    final melhor =
        maior == null ||
        entry.value.length > maior.value.length ||
        (entry.value.length == maior.value.length && entry.key < maior.key);
    if (melhor) maior = entry;
  }
  if (maior == null || maior.value.length < 2) return null;

  final mesmoPatamar = maior.value;

  final rareQuery = weaponQuery(index, 'Nível de Defesa', 80);
  final rareCarriers = rareQuery == null
      ? const <MarketCharacter>[]
      : runQuery(index, rareQuery);

  return (
    barato: mesmoPatamar.first,
    caro: mesmoPatamar.last,
    raro: rareCarriers.isEmpty ? null : rareCarriers.first,
    nivel: maior.key,
  );
}
