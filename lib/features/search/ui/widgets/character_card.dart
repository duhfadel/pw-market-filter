import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/pw_colors.dart';
import '../../../../core/widgets/game_icon.dart';
import '../../../../market/market_index.dart';
import '../../../../market/slot_names.dart';
import '../../domain/index_facets.dart';
import '../../domain/matcher.dart';
import '../../domain/search_query.dart';

/// One item worth naming on a card, and every reason it is there.
///
/// The reasons are collected per **item**, not per condition. Choosing a weapon
/// from the dropdown and then adding a criterion that also lands on the weapon
/// are two questions about one piece of gear, and listing it twice reads as a
/// character wearing two of them.
class _Highlight {
  _Highlight({required this.item, required String note}) : notes = [note];

  final EquippedItem item;
  final List<String> notes;

  void addNote(String note) {
    if (!notes.contains(note)) notes.add(note);
  }

  String get text => notes.join('  ·  ');
}

/// A character in the results.
///
/// Below the usual card fields it shows, for each criterion in force, the item
/// that satisfied it and by how much. Without that the list answers "these
/// match" and leaves you opening pages to find out which weapon it was — which
/// is the work this tool exists to remove.
class CharacterCard extends StatelessWidget {
  const CharacterCard({
    required this.character,
    required this.index,
    required this.query,
    super.key,
  });

  final MarketCharacter character;
  final MarketIndex index;

  /// The whole query, not just its criteria: a weapon chosen from the dropdown
  /// deserves the same line on the card as a criterion does. Reading only the
  /// criteria left the easiest path through the app — pick a weapon, look at
  /// the results — showing cards with nothing on them.
  final SearchQuery query;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: PWColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _open,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PWColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The portrait, because a grid of forty cards is scanned
                  // before it is read and seventeen faces separate faster than
                  // seventeen class names set in the same grey.
                  ClassIcon(character.occupation, size: 38),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${character.price} TCC',
                              style: const TextStyle(
                                color: PWColors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'nv ${character.level} · '
                          '${character.characterClass}',
                          style: const TextStyle(
                            color: PWColors.textMuted,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_lines.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 10),
                ..._lines.map(_highlightLine),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// What the card shows below the divider: the weapon, then everything the
  /// query asked about.
  ///
  /// The weapon has a permanent line because it is the reason this tool
  /// exists. Three weapons share the word *Dilacerador* and carry 30, 40 and
  /// 70 attack level, and the 70 sells for eleven times the 40 — so a card
  /// that gives the class and the price and says nothing about the weapon is
  /// withholding the number the sale turns on. It took the place of `fama`,
  /// which is five digits nobody buys on.
  ///
  /// It is skipped when a highlight already covers the weapon: a card naming
  /// the same piece twice reads as a character wearing two of them.
  List<_Highlight> get _lines {
    final asked = _highlights;
    if (asked.any((h) => h.item.slot == weaponSlot)) return asked;

    for (final item in character.equipped) {
      if (item.slot != weaponSlot) continue;
      return [_Highlight(item: item, note: _attackLevelNote(item)), ...asked];
    }
    // A character with no weapon on the doll. Rare, and not worth a blank row.
    return asked;
  }

  /// One line per thing the query asked for, in the order the form shows them:
  /// the items picked from a dropdown first, then the criteria.
  ///
  /// A criterion's line reads the same rule the matcher does — a card claiming
  /// a match the filter did not make would be worse than showing nothing.
  List<_Highlight> get _highlights {
    final byItem = <String, _Highlight>{};

    void note(EquippedItem item, String note) {
      final key = '${item.slot}:${item.itemId}';
      final existing = byItem[key];
      if (existing == null) {
        byItem[key] = _Highlight(item: item, note: note);
      } else {
        existing.addNote(note);
      }
    }

    for (final chosen in query.itemBySlot.entries) {
      for (final item in character.equipped) {
        if (item.slot != chosen.key || item.itemId != chosen.value) continue;
        note(item, _attackLevelNote(item));
        break;
      }
    }

    for (final criterion in query.criteria) {
      final item = bestMatchFor(index, character, criterion);
      if (item == null) continue;

      final attributeId = criterion.attributeId;
      note(
        item,
        attributeId == null
            ? _attackLevelNote(item)
            : '${slotLabel(item.slot)} · '
                  '${index.attributes[attributeId]} '
                  '${item.attributes[attributeId]}',
      );
    }
    return byItem.values.toList(growable: false);
  }

  /// A weapon chosen by name still has to show its number, or the card hands
  /// back the confusion the dropdown's label removed.
  String _attackLevelNote(EquippedItem item) {
    final id = index.attributes.indexOf(IndexFacets.attackLevelName);
    final value = id < 0 ? null : item.attributes[id];
    final slot = slotLabel(item.slot);
    return value == null
        ? slot
        : '$slot · ${IndexFacets.attackLevelName} $value';
  }

  Widget _highlightLine(_Highlight highlight) {
    final item = index.items[highlight.item.itemId];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemIcon(highlight.item.itemId, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item?.name ?? 'item ${highlight.item.itemId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: PWColors.grade(item?.grade ?? 0),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (highlight.item.refine > 0)
                      Text(
                        '+${highlight.item.refine}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PWColors.textMuted,
                        ),
                      ),
                  ],
                ),
                Text(
                  highlight.text,
                  style: const TextStyle(fontSize: 11, color: PWColors.ok),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The site already draws the character sheet well; rebuilding it here would
  /// be work for no gain.
  /// The canonical form. `/details/<server>/<id>` — the one the listing links
  /// to — answers 302 and redirects here, costing a needless round trip.
  void _open() => unawaited(
    launchUrl(
      Uri.parse(
        'https://marketplace.theclassic.games/'
        '${index.server}/details/${character.roleId}',
      ),
      mode: LaunchMode.externalApplication,
    ),
  );
}
