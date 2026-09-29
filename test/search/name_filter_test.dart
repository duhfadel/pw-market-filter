import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// Filtering by the character's own nickname.
///
/// It is a **filter and not a jump**: typing a name narrows the grid instead
/// of opening that character, so it composes with everything else — "algum
/// Leite com arma de 70" is a question the form could not ask before.
MarketCharacter _named(int roleId, String name) => MarketCharacter(
  roleId: roleId,
  name: name,
  characterClass: 'Guerreiro',
  occupation: 1,
  level: 105,
  price: 100,
  fame: 0,
  cultivation: 'Leal',
  equipped: const [],
);

final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 9, 29),
  attributes: const [],
  items: const {},
  characters: [
    _named(1, 'Cordeira-Sagrada'),
    _named(2, 'Leite-da-Vida'),
    _named(3, 'LeRato'),
    _named(4, 'João Coração'),
    _named(5, '??SK??'),
  ],
);

List<String> _found(String typed) =>
    runQuery(_index, SearchQuery(name: typed)).map((c) => c.name).toList();

void main() {
  test('it matches a fragment, not only the start', () {
    // `Cordeira-Sagrada` has to answer to both halves of itself. Somebody
    // hunting a character remembers a piece of the name, rarely the whole of
    // it and almost never where the piece sits.
    expect(_found('cordeira'), ['Cordeira-Sagrada']);
    expect(_found('sagrada'), ['Cordeira-Sagrada']);
    expect(_found('eira-sag'), ['Cordeira-Sagrada']);
  });

  test('case is ignored in both directions', () {
    expect(_found('lerato'), ['LeRato']);
    expect(_found('LERATO'), ['LeRato']);
    expect(_found('LeRaTo'), ['LeRato']);
  });

  test('accents are ignored in both directions', () {
    // The market is Brazilian and half the nicknames carry one. Somebody
    // typing `joao` on a phone keyboard must find `João`, and somebody
    // pasting `João` out of the game must find him too.
    expect(_found('joao'), ['João Coração']);
    expect(_found('João'), ['João Coração']);
    expect(_found('coracao'), ['João Coração']);
    expect(_found('coraçao'), ['João Coração']);
  });

  test('a name nobody has answers nothing, and that is an answer', () {
    expect(_found('gandalf'), isEmpty);
  });

  test('punctuation in a nickname is matched as typed', () {
    // `??SK??` is a real shape in this market. Nothing is stripped from the
    // haystack, so the question marks are still there to be found.
    expect(_found('?SK?'), ['??SK??']);
  });

  test('blank is not a filter', () {
    // A field the visitor tabbed through and left empty must not empty the
    // grid, and neither must one holding only spaces.
    expect(_found('').length, _index.characters.length);
    expect(_found('   ').length, _index.characters.length);
    expect(const SearchQuery(name: '').isEmpty, isTrue);
    expect(const SearchQuery(name: '  ').isEmpty, isTrue);
  });

  test('a name in force counts as a filter', () {
    // Unlike `shownOwned`, which prints a number and narrows nothing, this
    // one is a question asked of the market — so the screen must count it,
    // offer *limpar tudo*, and give it a chip.
    expect(const SearchQuery(name: 'Leite').isEmpty, isFalse);
  });

  test('a name survives the trip through a link', () {
    // Shared searches outlive a collection, and a nickname is stable in a way
    // an attribute id is not — but it still has to be escaped, because names
    // carry spaces, accents and question marks.
    for (final typed in ['Leite-da-Vida', 'João Coração', '??SK??']) {
      final back = decodeQuery(
        Uri.parse(
          '?${encodeQuery(SearchQuery(name: typed))}',
        ).queryParametersAll,
      );
      expect(back.name, typed, reason: typed);
    }
  });

  test('a blank name is never written into a link', () {
    expect(encodeQuery(const SearchQuery(name: '')), '');
    expect(encodeQuery(const SearchQuery(name: '   ')), '');
  });

  test('the name narrows alongside everything else', () {
    // It is an AND with the rest of the form, like every other filter here.
    expect(
      runQuery(_index, const SearchQuery(name: 'le', maxPrice: 50)),
      isEmpty,
    );
    expect(
      runQuery(
        _index,
        const SearchQuery(name: 'le', maxPrice: 200),
      ).map((c) => c.name),
      ['Leite-da-Vida', 'LeRato'],
    );
  });
}
