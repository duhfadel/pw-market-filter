import '../../../market/card_combos.dart';
import '../../../market/market_index.dart';
import '../../../market/slot_names.dart';
import 'item_criterion.dart';
import 'search_query.dart';
import 'search_query_url.dart';

/// A whole search behind one word.
///
/// The filter opens on 968 results and a form nobody has filled in, which asks
/// the visitor to invent a question before the tool has shown it can answer
/// one. A preset is the answer first: one tap and the market is cut to a
/// hundred characters, with the form filled in behind it saying how it was
/// done.
///
/// It is also the thing worth sharing. A preset is a link, and "arma de 70 até
/// 500 TCC" is a message; "there is a filter on that site" is not.
class Preset {
  const Preset(this.label, this.query);

  /// Short enough to sit in a chip on a 390 px screen.
  final String label;

  final SearchQuery query;
}

/// The ready-made searches, resolved against [index].
///
/// This is a function of the index rather than a constant because an attribute
/// is an **index into `MarketIndex.attributes`**, not a name — the same reason
/// `MarketPulse` looks up `Nível de Ataque` instead of hardcoding a number.
///
/// Every preset is written by attribute, never by item id. An item belongs to
/// one class: a preset built on `50206` would work for Guerreiro and quietly
/// return nothing for the other sixteen, which is the failure this whole
/// screen exists to avoid.
///
/// The five were chosen against the collected market, not from taste. Measured
/// on 2026-08-17 over 830 listings: attack level 70 finds 205, the same under
/// 500 TCC finds 82, six S cards 78, Portal de Nuema 48, and 100 TCC 288 —
/// five different axes, none of them leaving most of the market on screen.
///
/// **Refine and rank were tried and dropped.** `+10 na arma` returns 597 and
/// `rank 4 na arma` 594, because of something the market only says when
/// counted: of the 205 characters carrying a 70 weapon, **204 are rank 4 and
/// refined to +10**. Those chips asked "do you refine?", which nearly everyone
/// does, instead of "do you have the weapon", which is the question. A preset
/// that leaves three quarters of the market on screen teaches nothing — the
/// visitor taps it, the page does not move, and the tool looks broken.
List<Preset> presetsFor(MarketIndex index) {
  final weapon = strongWeaponQuery(index);

  return [
    if (weapon != null) ...[
      Preset('Arma de 70 de ataque', weapon),
      Preset('Arma de 70 até 500 TCC', weapon.copyWith(maxPrice: () => 500)),
    ],
    const Preset('Seis cartas S', SearchQuery(cardRarity: 'S')),
    Preset('Portal de Nuema', nuemaQuery),
    const Preset('Até 100 TCC', SearchQuery(maxPrice: 100)),
  ];
}

/// The one weapon tier that decides a purchase: 70 attack level.
///
/// Every class has its own weapon capping there — seventeen names for one tier
/// — which is why this asks for the attribute and never for an item. `null`
/// when the index does not carry the attribute at all, which only a broken
/// collection would produce.
SearchQuery? strongWeaponQuery(MarketIndex index) {
  final attackLevel = index.attributes.indexOf('Nível de Ataque');
  if (attackLevel < 0) return null;

  return SearchQuery(
    criteria: [
      ItemCriterion(slot: weaponSlot, attributeId: attackLevel, minimum: 70),
    ],
  );
}

/// The card combo the market has a name for.
SearchQuery get nuemaQuery => SearchQuery(comboName: nuema.name);

/// The preset [query] is currently asking, if any.
///
/// Two searches are the same when they are written the same, which is what the
/// URL codec already decides — so the chip lights up whether the search came
/// from tapping it or from filling the form to the same place.
///
/// The order is normalised away first. Ordering is how the list is read, not
/// something that was asked for, and losing the highlight because somebody
/// sorted by price would leave the chip claiming the search is off while it is
/// plainly still on.
Preset? activePreset(List<Preset> presets, SearchQuery query) {
  if (query.isEmpty) return null;

  final asked = encodeQuery(query.copyWith(order: ResultOrder.cheapest));

  for (final preset in presets) {
    if (encodeQuery(preset.query.copyWith(order: ResultOrder.cheapest)) ==
        asked) {
      return preset;
    }
  }
  return null;
}
