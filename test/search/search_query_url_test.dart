import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/item_criterion.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/market/market_index.dart';

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
        '?preco=abc&nivel=&c=x~y&item=dez~onze&ordem=inventada&desconhecido=1',
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

  group('the attribute travels by name', () {
    // `attributeId` is a position in `MarketIndex.attributes`, and the
    // collector numbers those in the order it happens to meet them. Two
    // collections a week apart can therefore disagree about what "attribute 0"
    // is — so a link that carried the number would keep working, keep looking
    // right, and quietly filter by something else entirely.
    MarketIndex indexWith(List<String> attributes) => MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 8, 9),
      attributes: attributes,
      items: const {},
      characters: const [],
    );

    final august = indexWith(['Nível de Ataque', 'HP']);
    final september = indexWith(['Vitalidade', 'HP', 'Nível de Ataque']);

    test('the name is what is written down', () {
      final written = encodeQuery(
        const SearchQuery(
          criteria: [ItemCriterion(slot: 10, attributeId: 0, minimum: 70)],
        ),
        august,
      );

      // Readable once the browser has decoded it, which is the state anyone
      // pasting a link sees.
      expect(Uri.decodeQueryComponent(written), 'c=10~Nível de Ataque~70~0~0');
    });

    test('a link survives the market being collected again', () {
      final link = encodeQuery(
        const SearchQuery(
          criteria: [ItemCriterion(slot: 10, attributeId: 0, minimum: 70)],
        ),
        august,
      );

      final back = decodeQuery(
        Uri.parse('?$link').queryParametersAll,
        september,
      );

      expect(
        september.attributes[back.criteria.single.attributeId!],
        'Nível de Ataque',
      );
    });

    test('an attribute the market no longer has drops its criterion', () {
      // Not "falls back to attribute zero": that would filter by whatever
      // happens to sit first and call it the visitor's search.
      final link = encodeQuery(
        const SearchQuery(
          criteria: [ItemCriterion(slot: 10, attributeId: 0, minimum: 70)],
        ),
        august,
      );

      final back = decodeQuery(
        Uri.parse('?$link').queryParametersAll,
        indexWith(['HP']),
      );

      expect(back.criteria, isEmpty);
    });

    test('a name carrying a colon survives, because they do', () {
      // "Feitiço da Purificação: Ao ser atingido" is a real attribute name,
      // and a colon is this format's own separator.
      final tricky = indexWith(['Feitiço da Purificação: Ao ser atingido']);
      final link = encodeQuery(
        const SearchQuery(
          criteria: [ItemCriterion(attributeId: 0, minimum: 3)],
        ),
        tricky,
      );

      final back = decodeQuery(Uri.parse('?$link').queryParametersAll, tricky);

      expect(back.criteria.single.attributeId, 0);
      expect(back.criteria.single.minimum, 3);
    });
  });

  group('anecdotes and counted items in a link', () {
    test('both survive a round trip', () {
      const query = SearchQuery(
        minAnecdotes: 1000,
        minimumOwned: {'Relíquia Maravilha: Arma': 5},
      );

      final restored = roundTrip(query);
      expect(restored.minAnecdotes, 1000);
      expect(restored.minimumOwned, {'Relíquia Maravilha: Arma': 5});
    });

    test('the counted item travels by name, readable in the address bar', () {
      // The id is the collection's business. A link says what it asks for, and
      // that is half of why anyone clicks it.
      expect(
        encodeQuery(
          const SearchQuery(minimumOwned: {'Relíquia Maravilha: Arma': 5}),
        ),
        contains('Rel'),
      );
    });

    test('marked anecdotes survive a round trip', () {
      const query = SearchQuery(anecdotesOnCard: true);

      expect(encodeQuery(query), contains('anedotas'));
      expect(roundTrip(query).anecdotesOnCard, isTrue);
      expect(roundTrip(query).minAnecdotes, isNull);
    });

    test('a minimum implies the mark without writing it twice', () {
      const query = SearchQuery(minAnecdotes: 1000, anecdotesOnCard: true);

      expect(encodeQuery(query), isNot(contains('mostra')));
      expect(roundTrip(query).showsAnecdotes, isTrue);
    });

    test('a marked item survives a round trip on its own', () {
      const query = SearchQuery(shownOwned: {'Chave da Sorte'});

      expect(roundTrip(query).shownOwned, {'Chave da Sorte'});
    });

    test('an item with a minimum is not written twice', () {
      // `tem` already implies the item is shown; saying it again in `mostra`
      // would double the link's length for nothing.
      const query = SearchQuery(
        minimumOwned: {'Relíquia Maravilha: Arma': 5},
        shownOwned: {'Relíquia Maravilha: Arma'},
      );

      expect(encodeQuery(query), isNot(contains('mostra')));
      expect(roundTrip(query).ownedOnCard, {'Relíquia Maravilha: Arma'});
    });

    test('a required pet survives a round trip', () {
      const query = SearchQuery(pets: {'Harpia', 'Hércules'});

      expect(roundTrip(query).pets, {'Harpia', 'Hércules'});
    });

    test('a minimum of zero is not a question and is left out', () {
      expect(
        encodeQuery(const SearchQuery(minimumOwned: {'Chave da Sorte': 0})),
        '',
      );
    });

    test('an unreadable entry is dropped rather than read as zero', () {
      final query = decodeQuery({
        'tem': ['sem separador nenhum'],
        'anedotas': ['não é número'],
      });

      expect(query.minimumOwned, isEmpty);
      expect(query.minAnecdotes, isNull);
    });
  });
}
