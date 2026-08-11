import '../../../market/market_index.dart';
import '../domain/index_facets.dart';
import '../domain/matcher.dart';
import '../domain/search_query.dart';

sealed class SearchState {
  const SearchState();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

/// No collection has been run. Not a failure — the first screen anybody sees.
class SearchNoIndex extends SearchState {
  const SearchNoIndex(this.command);

  final String command;
}

class SearchUnreadable extends SearchState {
  const SearchUnreadable(this.field, this.detail);

  final String field;
  final String detail;
}

class SearchReady extends SearchState {
  SearchReady({
    required this.index,
    required this.query,
    required this.results,
  });

  final MarketIndex index;
  final SearchQuery query;
  final List<MarketCharacter> results;

  final _facetCache = <FacetDimension, IndexFacets>{};

  /// The options a control should offer: read from the characters that pass
  /// every filter **but its own**.
  ///
  /// This is what makes the form answer back — choose Portal de Nuema and the
  /// class list drops to the classes somebody actually plays with it, the
  /// weapon list to the weapons those characters wear, the price range to what
  /// they cost. Computed lazily and cached; a new query builds a new state, so
  /// the cache can never go stale.
  IndexFacets facetsFor(FacetDimension dimension) => _facetCache.putIfAbsent(
    dimension,
    () => IndexFacets(index, runQuery(index, query.without(dimension))),
  );

  /// For anything that needs the whole market rather than the current slice —
  /// the attribute vocabulary, which must not shrink as you type a minimum.
  late final IndexFacets allFacets = IndexFacets(index);

  int get total => index.characters.length;

  /// Prices move fast enough that a filter over month-old data reads as
  /// correct while being wrong. A week is where the screen starts saying so.
  bool isStale(DateTime now) => now.difference(index.collectedAt).inDays >= 7;

  SearchReady copyWith({SearchQuery? query, List<MarketCharacter>? results}) =>
      SearchReady(
        index: index,
        query: query ?? this.query,
        results: results ?? this.results,
      );
}
