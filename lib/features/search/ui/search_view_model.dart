import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../market/index_repository.dart';
import '../data/address_bar.dart';
import '../domain/item_criterion.dart';
import '../domain/matcher.dart';
import '../domain/search_query.dart';
import '../domain/search_query_url.dart';
import 'search_state.dart';

/// The ViewModel is the Bloc. Every change to the form rebuilds the query and
/// re-runs it — 779 characters against a handful of criteria is nothing, so
/// there is no reason to make the user press a button.
class SearchViewModel extends Cubit<SearchState> {
  SearchViewModel(this._repository, [this._addressBar = const AddressBar()])
    : super(const SearchLoading());

  final IndexRepository _repository;
  final AddressBar _addressBar;

  /// A search that arrived from outside the form — a shared link, or a figure
  /// on the front page — before there was an index to run it against.
  SearchQuery? _pending;

  /// A link's parameters, still unread. They cannot be turned into a query
  /// without the index: the attribute travels by name and only the index knows
  /// what number this collection gives that name.
  Map<String, List<String>>? _pendingUrl;

  /// Runs [query] as soon as there is something to run it against.
  ///
  /// The index is 1.7 MB and the link is read the instant the page opens, so
  /// most shared links arrive here first. Dropping the query while loading
  /// would open somebody's careful search on the unfiltered market, which reads
  /// as a filter that failed rather than a page still loading.
  void request(SearchQuery query) {
    if (state is SearchReady) {
      _apply(query);
    } else {
      _pending = query;
    }
  }

  /// The search a link is asking for, read against the index once there is one.
  void requestUrl(Map<String, List<String>> params) {
    final ready = state;
    if (ready is SearchReady) {
      _apply(decodeQuery(params, ready.index));
    } else {
      _pendingUrl = params;
    }
  }

  Future<void> load() async {
    emit(const SearchLoading());
    final result = await _repository.load();

    emit(
      result.fold(
        (index) {
          // Whatever the link asked for, or everybody. The address already says
          // it, so nothing is written back: replacing the visitor's own link
          // with our rendering of it, before they have read it, buys nothing.
          final url = _pendingUrl;
          final query =
              _pending ??
              (url == null ? const SearchQuery() : decodeQuery(url, index));
          _pending = null;
          _pendingUrl = null;
          return SearchReady(
            index: index,
            query: query,
            results: runQuery(index, query),
          );
        },
        (failure) => switch (failure) {
          IndexMissingFailure() => const SearchNoIndex(
            IndexRepository.collectCommand,
          ),
          IndexUnreadableFailure(:final field, :final detail) =>
            SearchUnreadable(field, detail),
        },
      ),
    );
  }

  void _apply(SearchQuery query) {
    final ready = state;
    if (ready is! SearchReady) return;

    _addressBar.writeFilter(encodeQuery(query, ready.index));
    emit(ready.copyWith(query: query, results: runQuery(ready.index, query)));
  }

  SearchQuery? get _query =>
      state is SearchReady ? (state as SearchReady).query : null;

  /// Changing the class drops any chosen item that class never wears.
  ///
  /// Without this, picking Guerreiro while a Mago weapon is selected produces
  /// zero results and no explanation — and the dropdown would be showing a
  /// value that is no longer in its own list, which Flutter throws on.
  void setClass(String? value) {
    final ready = state as SearchReady;
    final query = ready.query;

    final surviving = <int, int>{};
    for (final chosen in query.itemBySlot.entries) {
      final available = ready
          .facetsFor(FacetDimension.items)
          .itemsIn(chosen.key, characterClass: value);
      if (available.any((item) => item.itemId == chosen.value)) {
        surviving[chosen.key] = chosen.value;
      }
    }

    _apply(query.copyWith(characterClass: () => value, itemBySlot: surviving));
  }

  void setCombo(String? name) =>
      _apply(_query!.copyWith(comboName: () => name));

  void setCardRarity(String? rarity) =>
      _apply(_query!.copyWith(cardRarity: () => rarity));

  void setCardsMaxed(bool value) => _apply(_query!.copyWith(cardsMaxed: value));

  void setOrder(ResultOrder order) => _apply(_query!.copyWith(order: order));

  /// Asking for a minimum marks the anecdotes too, exactly as it does for a
  /// counted item.
  void setMinAnecdotes(int? minimum) => _apply(
    _query!.copyWith(minAnecdotes: () => minimum, anecdotesOnCard: true),
  );

  void setMinRealm(int? rung) => _apply(_query!.copyWith(minRealm: () => rung));

  void setPath(String? path) => _apply(_query!.copyWith(path: () => path));

  /// `null` puts the rune question away entirely; anything else replaces it.
  void setRunes(RuneCriterion? criterion) =>
      _apply(_query!.copyWith(runes: () => criterion));

  /// A pet is a plain filter: ticked means the character has to have it.
  void setPetRequired(String label, bool required) {
    final query = _query!;
    final pets = {...query.pets};
    if (required) {
      pets.add(label);
    } else {
      pets.remove(label);
    }
    _apply(query.copyWith(pets: pets));
  }

  /// Marks the anecdote progress to be printed on every card, or stops.
  ///
  /// Stopping has to undo everything that forces the line, or the box comes
  /// unticked with the number still on screen: the minimum goes, and so does
  /// the ordering, which is itself a way of asking.
  void setAnecdotesShown(bool shown) {
    final query = _query!;
    if (shown) {
      _apply(query.copyWith(anecdotesOnCard: true));
      return;
    }
    _apply(
      query.copyWith(
        anecdotesOnCard: false,
        minAnecdotes: () => null,
        order: query.order == ResultOrder.mostAnecdotes
            ? ResultOrder.cheapest
            : query.order,
      ),
    );
  }

  /// Marks a counted item to be printed on the card, or stops.
  ///
  /// Unmarking also gives up ordering by relics, since with nothing marked
  /// that order sorts by a number that is the same for everybody.
  void setOwnedShown(String name, bool shown) {
    final query = _query!;
    final shownOwned = {...query.shownOwned};

    if (shown) {
      shownOwned.add(name);
    } else {
      shownOwned.remove(name);
    }
    // Ordering by relics with nothing marked sorts by a number that is the
    // same for everybody, which reads as a broken list rather than an order
    // that stopped meaning anything.
    final order = shownOwned.isEmpty && query.order == ResultOrder.mostOwned
        ? ResultOrder.cheapest
        : query.order;

    _apply(query.copyWith(shownOwned: shownOwned, order: order));
  }

  void setCultivation(String? value) =>
      _apply(_query!.copyWith(cultivation: () => value));

  void setLevelRange(int? min, int? max) =>
      _apply(_query!.copyWith(minLevel: () => min, maxLevel: () => max));

  void setPriceRange(int? min, int? max) =>
      _apply(_query!.copyWith(minPrice: () => min, maxPrice: () => max));

  /// `null` clears the slot instead of storing an impossible item id.
  void setItemInSlot(int slot, int? itemId) {
    final query = _query!;
    final itemBySlot = {...query.itemBySlot};
    if (itemId == null) {
      itemBySlot.remove(slot);
    } else {
      itemBySlot[slot] = itemId;
    }
    _apply(query.copyWith(itemBySlot: itemBySlot));
  }

  void addCriterion(ItemCriterion criterion) {
    final query = _query!;
    _apply(query.copyWith(criteria: [...query.criteria, criterion]));
  }

  void replaceCriterion(int position, ItemCriterion criterion) {
    final query = _query!;
    final criteria = [...query.criteria];
    criteria[position] = criterion;
    _apply(query.copyWith(criteria: criteria));
  }

  void removeCriterion(int position) {
    final query = _query!;
    final criteria = [...query.criteria]..removeAt(position);
    _apply(query.copyWith(criteria: criteria));
  }

  /// Clearing empties the filters but keeps the ordering — it is how the list
  /// is read, not something that was asked for.
  void clear() => _apply(SearchQuery(order: _query!.order));
}
