import '../../../market/celestial_realm.dart';
import '../../../market/market_index.dart';
import '../../../market/slot_names.dart';
import 'item_criterion.dart';
import 'search_query.dart';

/// One thing the form is asking, said in words, with the way to stop asking it.
///
/// The panel has a dozen sections and each one hides its own controls, so the
/// only way to know what is in force was to hunt for badges. Worse, a search
/// that finds nobody collapses the sections themselves — the weapon dropdown
/// disappears while the weapon is still being filtered on — and then the only
/// way out is *limpar tudo*, which throws away the parts you wanted.
///
/// A chip cannot disappear: it is drawn from the query, not from the market.
class ActiveFilter {
  const ActiveFilter(this.label, this.remove);

  final String label;

  /// The same query with this one condition taken out.
  final SearchQuery Function(SearchQuery) remove;
}

/// Everything [query] is asking of the market, one entry each.
///
/// **Only filters.** Marking a relic or the anecdotes prints a number on the
/// cards and narrows nothing, so it gets no chip — the same reason it stays
/// out of `isEmpty` and out of the count of filters in force. Ordering is not
/// a filter either.
List<ActiveFilter> activeFilters(MarketIndex index, SearchQuery query) {
  final filters = <ActiveFilter>[];

  void add(String label, SearchQuery Function(SearchQuery) remove) =>
      filters.add(ActiveFilter(label, remove));

  if (query.characterClass != null) {
    add(query.characterClass!, (q) => q.copyWith(characterClass: () => null));
  }
  if (query.path != null) {
    add(query.path!, (q) => q.copyWith(path: () => null));
  }
  if (query.cultivation != null) {
    add(query.cultivation!, (q) => q.copyWith(cultivation: () => null));
  }

  final preco = _rangeLabel(query.minPrice, query.maxPrice, 'TCC');
  if (preco != null) {
    add(preco, (q) => q.copyWith(minPrice: () => null, maxPrice: () => null));
  }
  final nivel = _rangeLabel(query.minLevel, query.maxLevel, 'de nível');
  if (nivel != null) {
    add(nivel, (q) => q.copyWith(minLevel: () => null, maxLevel: () => null));
  }

  final rung = query.minRealm;
  if (rung != null) {
    final tier = (rung - 1) ~/ 10;
    final step = rung - tier * 10;
    final nome = tier < celestialTiers.length
        ? '${celestialTierLabel(celestialTiers[tier])} ${_roman(step)}'
        : 'céu $rung';
    add('$nome ou mais', (q) => q.copyWith(minRealm: () => null));
  }

  if (query.minAnecdotes != null) {
    add(
      '${query.minAnecdotes} anedotas ou mais',
      (q) => q.copyWith(minAnecdotes: () => null),
    );
  }

  final runes = query.runes;
  if (runes != null) {
    final cor = runes.type == null ? '' : ' ${runes.type}';
    add(
      '${runes.minimum} runas$cor nível ${runes.minimumLevel}+',
      (q) => q.copyWith(runes: () => null),
    );
  }

  for (final pet in query.pets) {
    add(pet, (q) => q.copyWith(pets: {...q.pets}..remove(pet)));
  }

  if (query.comboName != null) {
    add(query.comboName!, (q) => q.copyWith(comboName: () => null));
  }
  if (query.cardRarity != null) {
    add(
      'seis cartas ${query.cardRarity}',
      (q) => q.copyWith(cardRarity: () => null),
    );
  }
  if (query.cardsMaxed) {
    add('cartas no máximo', (q) => q.copyWith(cardsMaxed: false));
  }

  for (final chosen in query.itemBySlot.entries) {
    // Named from the index when it can, and by its slot when it cannot — an
    // item the collection no longer carries must still be removable, which is
    // the whole dead end this list exists to close.
    final nome =
        index.items[chosen.value]?.name ?? '${slotLabel(chosen.key)} escolhida';
    add(
      nome,
      (q) => q.copyWith(itemBySlot: {...q.itemBySlot}..remove(chosen.key)),
    );
  }

  for (var i = 0; i < query.criteria.length; i++) {
    final criterion = query.criteria[i];
    add(_criterionLabel(index, criterion), (q) {
      final criteria = [...q.criteria];
      if (i < criteria.length) criteria.removeAt(i);
      return q.copyWith(criteria: criteria);
    });
  }

  return filters;
}

String? _rangeLabel(int? min, int? max, String unidade) {
  if (min == null && max == null) return null;
  if (min != null && max != null) return '$min a $max $unidade';
  if (min != null) return 'a partir de $min $unidade';
  return 'até $max $unidade';
}

String _criterionLabel(MarketIndex index, ItemCriterion criterion) {
  final partes = <String>[
    if (criterion.slot != null) slotLabel(criterion.slot!),
    if (criterion.attributeId != null &&
        criterion.attributeId! < index.attributes.length)
      '${index.attributes[criterion.attributeId!]} ${criterion.minimum}',
    if (criterion.minimumRefine > 0) '+${criterion.minimumRefine}',
    if (criterion.minimumRank > 0) 'rank ${criterion.minimumRank}',
  ];
  return partes.isEmpty ? 'critério' : partes.join(' · ');
}

String _roman(int step) => const [
  'I',
  'II',
  'III',
  'IV',
  'V',
  'VI',
  'VII',
  'VIII',
  'IX',
  'X',
][(step - 1).clamp(0, 9)];
