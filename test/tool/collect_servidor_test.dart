import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/servidor.dart';

import '../../tool/collect.dart';

/// [collectedPageFrom] is the exact seam `main`'s per-character loop calls —
/// see its docstring. Calling it here, through a [Servidor] picked by
/// `Servidor.de`, exercises the same path `dart run tool/collect.dart
/// --server pw126` would, instead of calling `parseEquippedItems126`
/// directly the way `indice_126_test.dart` does. That direct call already
/// passed while `tool/collect.dart:170` still hard-called the 1.8.7 parser
/// for every version — proving the parser works is not proving it is wired.
void main() {
  test('the pw126 path reads attributes, not eleven bare items', () {
    final html = File(
      'test/fixtures/detail_pw126_5424.html',
    ).readAsStringSync();

    final page = collectedPageFrom(Servidor.de('pw126'), html);

    expect(page.items, hasLength(11));
    // Before BLOCKER B was fixed, running the 1.8.7 parser over this page
    // produced eleven items and not one attribute between them — measured
    // in the final review. Every worn piece here has to carry at least one.
    for (final item in page.items) {
      expect(
        item.attributes,
        isNotEmpty,
        reason:
            '${item.name} (slot ${item.slot}) came back with no '
            'attributes — the 1.8.7 parser would do exactly this on a '
            '1.2.6 page.',
      );
    }
    expect(page.sex, 'Feminino');
  });

  test('the pw187 path still reads through the 1.8.7 parser', () {
    // Leandrim, role 64112 — the fixture `detail_parser_test.dart` pins field
    // by field. Reproducing those exact numbers here, through `Servidor`
    // rather than by calling `parseEquippedItems` directly, is what would
    // catch the wiring being swapped or dropped in a future refactor.
    final html = File('test/fixtures/detail_64112.html').readAsStringSync();

    final page = collectedPageFrom(Servidor.de('pw187'), html);

    expect(page.items, hasLength(14));
    final weapon = page.items.singleWhere((i) => i.slot == 10);
    expect(weapon.itemId, 50206);
    expect(weapon.refine, 12);
    expect(weapon.stones, [51112, 51112]);
    expect(weapon.attributes['Nível de Ataque'], [70]);
  });
}
