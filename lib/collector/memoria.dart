import 'listing_parser.dart';
import '../market/market_index.dart';
import '../market/price_history.dart';

/// The record for every character on the listing, carried forward from the
/// index the site is currently serving.
///
/// **The published index is the durable record**, which is why this reads a
/// `MarketIndex` rather than a state file: the Actions cache that holds the
/// collector's state is evicted after seven days unused, and a memory that
/// erases itself would have the site announce 1519 arrivals one random
/// morning. The cache stays as the second copy.
///
/// `precoAnterior` comes off the published character rather than out of
/// [PriceHistory], so the same number is never written twice.
Map<int, PriceHistory> avancarTodos({
  required List<ListingCard> listing,
  required MarketIndex? publicado,
  required DateTime agora,
}) {
  final antes = <int, MarketCharacter>{
    for (final c in publicado?.characters ?? const <MarketCharacter>[])
      c.roleId: c,
  };

  return {
    for (final card in listing)
      card.roleId: avancar(
        antes[card.roleId]?.history,
        preco: card.price,
        precoAnterior: antes[card.roleId]?.price,
        agora: agora,
      ),
  };
}

/// The date the site started keeping records.
///
/// Carried forward once set, and **never restamped**: writing today's date on
/// every run would put every character's `firstSeen` at or before it for ever,
/// and nothing would ever read as new.
DateTime historyFromDe(MarketIndex? publicado, DateTime agora) =>
    publicado?.historyFrom ?? agora;
