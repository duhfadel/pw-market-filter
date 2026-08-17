import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';

/// The link is the share. A search that cannot be written down can only be
/// recommended as "that site", never as the finding — and the finding is the
/// argument.
///
/// Decoding is the half that has to be forgiving: a link pasted a month ago,
/// carrying an item that has since left the market or a parameter this version
/// no longer knows, must still open the filter.
SearchQuery roundTrip(SearchQuery query) =>
    decodeQuery(Uri.parse('?${encodeQuery(query)}').queryParametersAll);

void main() {
  test('an empty query in the default order writes nothing', () {
    expect(encodeQuery(const SearchQuery()), '');
  });

  test('every dimension survives a round trip', () {
    const query = SearchQuery(
      characterClass: 'Mago',
      cultivation: 'Alma Nascente',
      minLevel: 100,
      maxLevel: 105,
      minPrice: 40,
      maxPrice: 500,
      itemBySlot: {10: 50206},
      comboName: 'nuema',
      cardRarity: 'S',
      cardsMaxed: true,
      criteria: [
        ItemCriterion(
          slot: 10,
          attributeId: 3,
          minimum: 70,
          minimumRefine: 10,
          minimumRank: 4,
        ),
      ],
      order: ResultOrder.dearest,
    );

    final back = roundTrip(query);

    expect(back.characterClass, 'Mago');
    expect(back.cultivation, 'Alma Nascente');
    expect(back.minLevel, 100);
    expect(back.maxLevel, 105);
    expect(back.minPrice, 40);
    expect(back.maxPrice, 500);
    expect(back.itemBySlot, {10: 50206});
    expect(back.comboName, 'nuema');
    expect(back.cardRarity, 'S');
    expect(back.cardsMaxed, isTrue);
    expect(back.order, ResultOrder.dearest);

    final criterion = back.criteria.single;
    expect(criterion.slot, 10);
    expect(criterion.attributeId, 3);
    expect(criterion.minimum, 70);
    expect(criterion.minimumRefine, 10);
    expect(criterion.minimumRank, 4);
  });

  test('a half-open range keeps its open end open', () {
    final back = roundTrip(const SearchQuery(maxPrice: 500));

    expect(back.minPrice, isNull);
    expect(back.maxPrice, 500);
  });

  test('a criterion may name no slot and no attribute', () {
    final back = roundTrip(
      const SearchQuery(criteria: [ItemCriterion(minimumRank: 4)]),
    );

    final criterion = back.criteria.single;
    expect(criterion.slot, isNull);
    expect(criterion.attributeId, isNull);
    expect(criterion.minimumRank, 4);
  });

  test('several criteria keep their order', () {
    final back = roundTrip(
      const SearchQuery(
        criteria: [
          ItemCriterion(slot: 10, attributeId: 3, minimum: 70),
          ItemCriterion(slot: 1, attributeId: 5, minimum: 500),
        ],
      ),
    );

    expect(back.criteria, hasLength(2));
    expect(back.criteria.first.slot, 10);
    expect(back.criteria.last.slot, 1);
  });

  test('a criterion that asks nothing is not written down', () {
    // An empty row on screen is a row being filled in, not a question. Writing
    // it would put a criterion in the shared link that matches everybody and
    // explains nothing.
    expect(encodeQuery(const SearchQuery(criteria: [ItemCriterion()])), '');
  });

  test('a name with a space and an accent survives', () {
    final back = roundTrip(const SearchQuery(cultivation: 'Alma Nascente'));

    expect(back.cultivation, 'Alma Nascente');
  });

  test('garbage is ignored rather than thrown', () {
    final back = decodeQuery(
      Uri.parse(
        '?preco=abc&nivel=&c=x:y&item=dez:onze&ordem=inventada&desconhecido=1',
      ).queryParametersAll,
    );

    expect(back.isEmpty, isTrue);
    expect(back.order, ResultOrder.cheapest);
  });

  test('a partly readable range keeps the half it can read', () {
    final back = decodeQuery(Uri.parse('?preco=40-abc').queryParametersAll);

    expect(back.minPrice, 40);
    expect(back.maxPrice, isNull);
  });
}
