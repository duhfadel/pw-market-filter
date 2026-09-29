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
/// **Seventy stopped being the ceiling.** The game added an 80 tier after this
/// file was written, and for a while the site swallowed it in silence: the
/// chip asked for `minimum: 70`, so the 80s came back inside the results and
/// were counted as 70s, and nothing on any screen said a tier above existed.
/// Measured on 2026-09-21: attack 70+ finds 663 characters at a median of 400
/// TCC, attack 80 finds 10 at a median of 8000. Twenty times the price — the
/// same shape that made this site exist, one step up, and invisible.
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

  // Ataque **ou** defesa: a UP5 vem nas duas caras e quem procura a arma de
  // topo quer as duas na mesma lista.
  final up5 = weaponQuery(index, 'Nível de Ataque', 80);

  return [
    // **`Arma UP5` é o nome que a comunidade usa**, e usar o nosso seria pedir
    // que ela traduzisse. São 29 personagens em 1.624: 21 pelo ataque e 8 pela
    // defesa. Os dois eram chips separados e viraram um, porque dividir a
    // mesma ideia em dois pedia que o visitante soubesse de antemão qual
    // metade queria.
    if (up5 != null) Preset('Arma UP5', up5),
    // O degrau de baixo, e ele ainda decide a maior parte das compras: 801
    // personagens, quase metade do mercado. Fica por último entre as armas.
    if (weapon != null) Preset('Arma de 70 ou mais', weapon),
    // 161 personagens. A essência é o item novo do mercado e ninguém tinha
    // como procurá-la.
    Preset('5 essências ou mais', essenciasQuery),
    const Preset('Seis cartas S', SearchQuery(cardRarity: 'S')),
    Preset('Portal de Nuema', nuemaQuery),
    const Preset('Até 100 TCC', SearchQuery(maxPrice: 100)),
  ];
}

/// Five essences or more — 161 of 1.624, a tenth of the market.
///
/// The number asks for the **group**: the essence, the raw one and the chest
/// are one line on the card and one number here, the same way `countOf` adds
/// them everywhere else.
const essenciasQuery = SearchQuery(
  minimumOwned: {'Essência Dracônica': 5},
  shownOwned: {'Essência Dracônica'},
);

/// The tier that decides most purchases: 70 attack level, 45% of the market.
///
/// It asks for the attribute and never for an item, because seventeen classes
/// carry seventeen different names for the same tier — a preset built on one
/// item id would work for Guerreiro and quietly return nothing for the other
/// sixteen.
/// What the filter opens with.
///
/// **The three relics are already marked.** They are one question asked three
/// ways — 94% of the market carries each — and what a buyer compares is the
/// spread between them, which is only visible with all three on the card.
/// Marking narrows nothing, so the whole cost is three lines of text; the
/// benefit is that somebody who never opens the panel still sees the market
/// has this dimension at all.
///
/// The `Chave da Sorte` was here first and came off on the owner's call. It is
/// a different animal and `counted_items.dart` already says why: 57% carry
/// one, half of those carry exactly one, and the top carries thousands — a
/// line that says more about hoarding than about the character.
///
/// Not in the constructor's default on purpose. A link without `mostra` has to
/// mean *nothing marked*, or a search shared with a relic deliberately
/// unticked would arrive with it back on.
const buscaInicial = SearchQuery(
  shownOwned: {
    'Relíquia Maravilha: Artefato',
    'Relíquia Maravilha: Arma',
    'Relíquia Maravilha: Armadura',
  },
);

SearchQuery? strongWeaponQuery(MarketIndex index) =>
    weaponQuery(index, 'Nível de Ataque', 70);

/// A weapon asking [minimo] of the attribute called [atributo].
///
/// `null` when this collection does not carry that attribute — which is not
/// only the broken-collection case any more. **Eighty is a tier the game
/// added after this site was written**, and a tier the market has not reached
/// yet simply has no attribute to point at, so the chip does not exist rather
/// than existing and finding nobody.
SearchQuery? weaponQuery(MarketIndex index, String atributo, int minimo) {
  final id = index.attributes.indexOf(atributo);
  if (id < 0) return null;

  return SearchQuery(
    criteria: [
      ItemCriterion(slot: weaponSlot, attributeId: id, minimum: minimo),
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
