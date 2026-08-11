import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../market/index_repository.dart';
import '../domain/item_criterion.dart';
import '../domain/matcher.dart';
import '../domain/search_query.dart';
import 'search_state.dart';

/// The ViewModel is the Bloc. Every change to the form rebuilds the query and
/// re-runs it — 779 characters against a handful of criteria is nothing, so
/// there is no reason to make the user press a button.
class SearchViewModel extends Cubit<SearchState> {
  SearchViewModel(this._repository) : super(const SearchLoading());

  final IndexRepository _repository;

  Future<void> load() async {
    emit(const SearchLoading());
    final result = await _repository.load();

    emit(
      result.fold(
        (index) {
          const query = SearchQuery();
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
      final available = ready.facetsFor(FacetDimension.items).itemsIn(chosen.key, characterClass: value);
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

  void setCardsMaxed(bool value) =>
      _apply(_query!.copyWith(cardsMaxed: value));

  void setOrder(ResultOrder order) => _apply(_query!.copyWith(order: order));

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
