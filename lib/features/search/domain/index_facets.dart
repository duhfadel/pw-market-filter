import '../../../market/market_index.dart';

/// One entry of the attribute dropdown.
class AttributeFacet {
  const AttributeFacet({
    required this.attributeId,
    required this.name,
    required this.characterCount,
    required this.highestValue,
  });

  final int attributeId;
  final String name;

  /// How many characters have this attribute in the slot being asked about.
  final int characterCount;

  /// The best value anyone reaches. It tells you where to put the minimum
  /// before you type a number nobody can meet.
  final int highestValue;
}

/// One entry of an item dropdown — a specific weapon, helm, and so on.
class ItemFacet {
  const ItemFacet({
    required this.itemId,
    required this.name,
    required this.grade,
    required this.characterCount,
    required this.attackLevel,
    required this.lowestAttackLevel,
  });

  final int itemId;
  final String name;
  final int grade;

  /// How many characters wear this item in the slot being asked about.
  final int characterCount;

  /// The highest attack level seen on this item, and `null` when it gives
  /// none. Two weapons can share most of their name and differ only here —
  /// three of them are called *Dilacerador* and give 30, 40 and 70 — so the
  /// label carries the number and the name never has to be trusted on its own.
  final int? attackLevel;

  /// The lowest seen. Usually equal to [attackLevel]: across 62 weapons in the
  /// collected market, exactly one varied between instances (★★★Dilacerador
  /// Raivoso, 70 on one wearer and 71 on another). Rare is not never, and
  /// announcing the maximum alone would promise 71 on a weapon that mostly
  /// gives 70.
  final int? lowestAttackLevel;

  bool get attackLevelVaries =>
      attackLevel != null && lowestAttackLevel != attackLevel;

  /// Null when the item gives no attack level, so the caller can leave the
  /// space empty rather than print a misleading `+0`.
  String? get attackLevelText => attackLevel == null
      ? null
      : (attackLevelVaries
            ? '+$lowestAttackLevel a +$attackLevel'
            : '+$attackLevel');

  /// Name and number in one string, for places with a single line and no room
  /// to lay the two out separately.
  String get label =>
      attackLevelText == null ? name : '$name  ·  $attackLevelText';

  /// The second line of the open menu, where there is room to spell it out.
  String get detail {
    final wearers = characterCount == 1
        ? '1 personagem'
        : '$characterCount personagens';
    return attackLevelText == null
        ? wearers
        : '$attackLevelText nível de ataque  ·  $wearers';
  }
}

/// Everything the form's dropdowns offer, read off the index rather than
/// written by hand.
///
/// Nobody has to know Attack Level exists in order to find it, and nobody
/// wastes a query on an attribute the chosen slot never carries.
class IndexFacets {
  IndexFacets(this.index);

  final MarketIndex index;

  late final List<int> slots = _slots();
  late final List<String> classes = _distinct((c) => c.characterClass);

  /// Class name to the `occupation` number, which is what names the portrait
  /// file. The listing carries both, so nothing has to be hardcoded.
  late final Map<String, int> occupationOf = {
    for (final character in index.characters)
      character.characterClass: character.occupation,
  };
  late final List<String> cultivations = _distinct((c) => c.cultivation);

  late final int lowestPrice = _lowest((c) => c.price);
  late final int highestPrice = _highest((c) => c.price);
  late final int lowestLevel = _lowest((c) => c.level);
  late final int highestLevel = _highest((c) => c.level);

  final _attributeCache = <int?, List<AttributeFacet>>{};

  /// Keyed by slot and class together — the same slot answers differently for
  /// a Guerreiro and for a Mago.
  final _itemCache = <String, List<ItemFacet>>{};
  final _exampleCache = <int, String>{};

  /// The attribute whose value goes into an item's label. Looked up by the
  /// name the site prints, and simply absent if the market has no item that
  /// gives it — the labels then fall back to plain names.
  static const attackLevelName = 'Nível de Ataque';

  late final int? _attackLevelId = () {
    final id = index.attributes.indexOf(attackLevelName);
    return id < 0 ? null : id;
  }();

  /// Every distinct item worn in [slot], best first, optionally narrowed to one
  /// class.
  ///
  /// **Narrowing by class is not a convenience.** Every class has its own
  /// weapon, and its own +70 among them; a list mixing all seventeen is a list
  /// where the entry you want is buried among sixteen you can never equip. And
  /// left unnarrowed it invites the silent failure — Guerreiro plus a Mago
  /// weapon, zero results, nothing on screen explaining why.
  ///
  /// Ordering by attack level rather than alphabetically puts the weapon worth
  /// 1000 TCC at the top and the ones worth 40 at the bottom, which is the
  /// order somebody shopping reads in.
  List<ItemFacet> itemsIn(int slot, {String? characterClass}) =>
      _itemCache.putIfAbsent(
        '$slot|$characterClass',
        () => _itemsIn(slot, characterClass),
      );

  List<ItemFacet> _itemsIn(int slot, String? characterClass) {
    final counts = <int, int>{};
    final highest = <int, int>{};
    final lowest = <int, int>{};

    for (final character in index.characters) {
      if (characterClass != null &&
          character.characterClass != characterClass) {
        continue;
      }
      for (final item in character.equipped) {
        if (item.slot != slot) continue;
        counts[item.itemId] = (counts[item.itemId] ?? 0) + 1;
        if (_attackLevelId == null) continue;

        // An instance without the attribute counts as zero towards the floor.
        // Dropping it would hide the sharpest case there is: the same weapon
        // giving 70 to one wearer and nothing to another.
        final value = item.attributes[_attackLevelId] ?? 0;
        final best = highest[item.itemId];
        if (best == null || value > best) highest[item.itemId] = value;
        final worst = lowest[item.itemId];
        if (worst == null || value < worst) lowest[item.itemId] = value;
      }
    }

    final facets = counts.entries.map((entry) {
      final item = index.items[entry.key];
      final best = highest[entry.key];
      return ItemFacet(
        itemId: entry.key,
        name: item?.name ?? 'item ${entry.key}',
        grade: item?.grade ?? 0,
        characterCount: entry.value,
        // An item nobody wears with any attack level has none to show, rather
        // than a misleading `+0`.
        attackLevel: best == null || best == 0 ? null : best,
        lowestAttackLevel: best == null || best == 0 ? null : lowest[entry.key],
      );
    }).toList();

    facets.sort((a, b) {
      final byAttack = (b.attackLevel ?? -1).compareTo(a.attackLevel ?? -1);
      if (byAttack != 0) return byAttack;
      final byCount = b.characterCount.compareTo(a.characterCount);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
    return facets;
  }

  /// The attributes that appear in [slot], commonest first. A `null` slot asks
  /// about the whole character.
  List<AttributeFacet> attributesIn(int? slot) =>
      _attributeCache.putIfAbsent(slot, () => _attributesIn(slot));

  /// The item most often found in [slot] — the hint that tells you what an
  /// unnamed slot actually is.
  String exampleItemIn(int slot) => _exampleCache.putIfAbsent(slot, () {
    final counts = <int, int>{};
    for (final character in index.characters) {
      for (final item in character.equipped) {
        if (item.slot == slot) {
          counts[item.itemId] = (counts[item.itemId] ?? 0) + 1;
        }
      }
    }
    if (counts.isEmpty) return '';
    final commonest = counts.entries.reduce(
      (a, b) => b.value > a.value ? b : a,
    );
    return index.items[commonest.key]?.name ?? '';
  });

  List<AttributeFacet> _attributesIn(int? slot) {
    final characterCount = <int, int>{};
    final highest = <int, int>{};

    for (final character in index.characters) {
      final seen = <int>{};
      for (final item in character.equipped) {
        if (slot != null && item.slot != slot) continue;
        for (final entry in item.attributes.entries) {
          if (seen.add(entry.key)) {
            characterCount[entry.key] = (characterCount[entry.key] ?? 0) + 1;
          }
          final best = highest[entry.key];
          if (best == null || entry.value > best) {
            highest[entry.key] = entry.value;
          }
        }
      }
    }

    final facets = characterCount.entries
        .map(
          (entry) => AttributeFacet(
            attributeId: entry.key,
            name: index.attributes[entry.key],
            characterCount: entry.value,
            highestValue: highest[entry.key]!,
          ),
        )
        .toList();

    facets.sort((a, b) {
      final byCount = b.characterCount.compareTo(a.characterCount);
      return byCount != 0 ? byCount : a.name.compareTo(b.name);
    });
    return facets;
  }

  List<int> _slots() {
    final slots = <int>{};
    for (final character in index.characters) {
      for (final item in character.equipped) {
        slots.add(item.slot);
      }
    }
    return slots.toList()..sort();
  }

  List<String> _distinct(String Function(MarketCharacter) of) {
    final values = index.characters.map(of).where((v) => v.isNotEmpty).toSet();
    return values.toList()..sort();
  }

  int _lowest(int Function(MarketCharacter) of) => index.characters.isEmpty
      ? 0
      : index.characters.map(of).reduce((a, b) => a < b ? a : b);

  int _highest(int Function(MarketCharacter) of) => index.characters.isEmpty
      ? 0
      : index.characters.map(of).reduce((a, b) => a > b ? a : b);
}
