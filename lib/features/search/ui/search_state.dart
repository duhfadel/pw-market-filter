import '../../../market/market_index.dart';
import '../domain/index_facets.dart';
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
  const SearchReady({
    required this.index,
    required this.facets,
    required this.query,
    required this.results,
  });

  final MarketIndex index;
  final IndexFacets facets;
  final SearchQuery query;
  final List<MarketCharacter> results;

  int get total => index.characters.length;

  /// Prices move fast enough that a filter over month-old data reads as
  /// correct while being wrong. A week is where the screen starts saying so.
  bool isStale(DateTime now) => now.difference(index.collectedAt).inDays >= 7;

  SearchReady copyWith({SearchQuery? query, List<MarketCharacter>? results}) =>
      SearchReady(
        index: index,
        facets: facets,
        query: query ?? this.query,
        results: results ?? this.results,
      );
}
