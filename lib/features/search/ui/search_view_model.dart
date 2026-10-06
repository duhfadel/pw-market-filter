import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/result/result.dart';
import '../../../market/index_repository.dart';
import '../data/address_bar.dart';
import '../domain/item_criterion.dart';
import '../domain/matcher.dart';
import '../../../market/counted_items.dart';
import '../domain/presets.dart';
import '../domain/search_query.dart';
import '../domain/search_query_url.dart';
import 'search_state.dart';

/// The ViewModel is the Bloc. Every change to the form rebuilds the query and
/// re-runs it — 779 characters against a handful of criteria is nothing, so
/// there is no reason to make the user press a button.
class SearchViewModel extends Cubit<SearchState> {
  // The address bar defaults to one built for `repository.server` rather than
  // a bare `const AddressBar()` — the two marketplaces share this class, and
  // a hardcoded default is exactly how a 1.2.6 search once rewrote its own
  // address into the 1.8.7 market (see `AddressBar`'s own note).
  SearchViewModel(IndexRepository repository, [AddressBar? addressBar])
    : _repository = repository,
      _addressBar = addressBar ?? AddressBar(repository.server),
      super(const SearchLoading());

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
              (url == null ? buscaInicial : decodeQuery(url, index));
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
  ///
  /// **Asked of the whole market, not of the current results.** "Does this
  /// class wear this piece?" is a question about the game; asking it of the
  /// filtered scope meant that a price range narrow enough to exclude every
  /// Guerreiro wearing the weapon made the empty answer read as "Guerreiro
  /// does not wear it", and the weapon was thrown away without a word.
  /// A fragment of a nickname, or `null` to stop asking.
  ///
  /// Blank is normalised away here rather than at the edge, so nothing
  /// downstream has to know that a field can hold spaces: `askedName` is what
  /// the matcher, the link and the chips all read.
  void setName(String? typed) => _apply(
    _query!.copyWith(
      name: () => (typed?.trim().isEmpty ?? true) ? null : typed,
    ),
  );

  void setClass(String? value) {
    final ready = state as SearchReady;
    final query = ready.query;

    final surviving = <int, int>{};
    for (final chosen in query.itemBySlot.entries) {
      final available = ready.allFacets.itemsIn(
        chosen.key,
        characterClass: value,
      );
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

  /// The lowest founder pack that still passes. `1` is *qualquer fundador*;
  /// `null` puts the question away.
  void setMinFounderTier(int? tier) =>
      _apply(_query!.copyWith(minFounderTier: () => tier));

  void setForjaMinima(int? nivel) =>
      _apply(_query!.copyWith(forjaMinima: () => nivel));

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
    final ready = state as SearchReady;
    final query = ready.query;
    final shownOwned = {...query.shownOwned};

    if (shown) {
      shownOwned.add(name);
    } else {
      shownOwned.remove(name);
    }
    // Ordering by relics with **no relic** marked sorts by a number that is
    // the same for everybody, which reads as a broken list rather than an
    // order that stopped meaning anything.
    //
    // It asks about relics and not about `shownOwned` being empty, and the
    // difference stopped being academic when the `Chave da Sorte` started out
    // marked: the set is never empty now, so the old test never fired and the
    // order survived with nothing left to order by.
    // Only relics **this market has**. `shownOwned` opens with all three
    // marked and a collection may know just one of them, so counting the
    // names alone kept the order alive on a number nobody carries.
    final semReliquia = !shownOwned.any(
      (n) => relicNames.contains(n) && ready.index.countedItems.containsKey(n),
    );
    final order = semReliquia && query.order == ResultOrder.mostOwned
        ? ResultOrder.cheapest
        : query.order;

    // Unmarking takes the minimum with it: the slider goes off the screen, and
    // a filter in force with no control is the dead end the chips exist to
    // close.
    final minimumOwned = {...query.minimumOwned};
    if (!shown) minimumOwned.remove(name);

    _apply(
      query.copyWith(
        shownOwned: shownOwned,
        minimumOwned: minimumOwned,
        order: order,
      ),
    );
  }

  /// The fewest of [name] a character may carry, from the slider under the
  /// mark.
  ///
  /// Zero is not stored. It is where the slider starts, and it is the answer
  /// "I only wanted to see the number" — the mark's own meaning.
  void setOwnedMinimum(String name, int minimum) {
    final minimumOwned = {..._query!.minimumOwned};

    if (minimum > 0) {
      minimumOwned[name] = minimum;
    } else {
      minimumOwned.remove(name);
    }
    _apply(_query!.copyWith(minimumOwned: minimumOwned));
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
  /// "Limpar tudo" means no filters. It does **not** mean taking the key's
  /// number off the card: nobody asked to remove that, and the page would
  /// come back emptier than it opened.
  void clear() => _apply(
    SearchQuery(order: _query!.order, shownOwned: buscaInicial.shownOwned),
  );
}
