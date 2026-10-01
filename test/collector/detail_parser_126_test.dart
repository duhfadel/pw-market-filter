import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/collector/detail_parser_126.dart';

void main() {
  // role 229217, saved 01/10/2026. Eleven worn slots, with six interchangeable
  // weapons sitting unworn in the same `Equipamento` tab — the trap this file
  // exists to guard against, the same shape as 1.8.7's spares.
  late String comSeisArmas;

  // role 5424, an Arqueiro saved 01/10/2026. Nine of its eleven worn pieces
  // carry elemental resistance, and two of its rings share one item id with
  // different rolls — the duplicate-id trap positional pairing exists for.
  late String arqueiro;

  setUpAll(() {
    comSeisArmas = File(
      'test/fixtures/detail_pw126_229217.html',
    ).readAsStringSync();
    arqueiro = File('test/fixtures/detail_pw126_5424.html').readAsStringSync();
  });

  test('reads the eleven worn slots, not the six spare weapons', () {
    // The `Equipamento` tab lists 21 entries on this character: the 11 worn
    // pieces plus ten unworn weapons and fashion items with no stat JSON.
    // Only the paper doll says what is on the body.
    final itens = parseEquippedItems126(comSeisArmas);
    expect(itens.map((i) => i.slot).toSet(), hasLength(11));
    expect(itens.map((i) => i.slot).reduce(max), 10);
  });

  test('the attributes carry our labels, resolved from the JSON', () {
    final itens = parseEquippedItems126(arqueiro);
    final comResistencia = itens.where(
      (i) => i.attributes.containsKey('Resistência ao fogo'),
    );
    expect(comResistencia, isNotEmpty);
    // Every value is a real number off the JSON, never a placeholder.
    for (final i in comResistencia) {
      expect(i.attributes['Resistência ao fogo']!.single, greaterThan(0));
    }
  });

  test(
    'a field we have not translated is dropped, never shown as its column',
    () {
      final itens = parseEquippedItems126(comSeisArmas);
      for (final i in itens) {
        expect(i.attributes.keys, isNot(contains('item_flag')));
        expect(i.attributes.keys, isNot(contains('item_class')));
      }
    },
  );

  test('require_level goes to its own field, not into the attributes', () {
    final itens = parseEquippedItems126(comSeisArmas);
    expect(itens.any((i) => i.requireLevel > 0), isTrue);
    for (final i in itens) {
      expect(i.attributes.keys, isNot(contains('require_level')));
      expect(i.attributes.keys, isNot(contains('weapon_level')));
    }
  });

  test('reads the weapon field by field', () {
    final arma = parseEquippedItems126(
      comSeisArmas,
    ).singleWhere((i) => i.slot == 10);

    expect(arma.itemId, 8305);
    expect(arma.name, '★Besta Perseguidora do Vento');
    expect(arma.grade, 5);
    expect(arma.refine, 1);
    expect(arma.requireLevel, 88);
    expect(arma.weaponLevel, 11);
    expect(arma.attributes['Dano mínimo'], [656]);
    expect(arma.attributes['Dano máximo'], [1531]);
    expect(arma.attributes['Velocidade de ataque'], [30]);
    expect(arma.attributes['Alcance'], [22]);
    // Zero in the JSON means the weapon does not deal magic damage — not a
    // real `+0` line, so it is left out exactly as an absent tooltip line is.
    expect(arma.attributes.containsKey('Dano mágico máximo'), isFalse);
    expect(arma.attributes.containsKey('Dano mágico mínimo'), isFalse);
  });

  test('reads an armour piece field by field, stones included', () {
    final peitoral = parseEquippedItems126(
      comSeisArmas,
    ).singleWhere((i) => i.slot == 2);

    expect(peitoral.itemId, 12663);
    expect(peitoral.name, '★Armadura Leve de Mercenário');
    expect(peitoral.grade, 5);
    expect(peitoral.refine, 0);
    expect(peitoral.requireLevel, 60);
    expect(peitoral.weaponLevel, 0);
    expect(peitoral.stones, [6385, 6385, 6385]);
    expect(peitoral.attributes['Defesa'], [477]);
    expect(peitoral.attributes['HP'], [70]);
    expect(peitoral.attributes['Resistência ao metal'], [740]);
    expect(peitoral.attributes['Resistência à madeira'], [740]);
    expect(peitoral.attributes['Resistência à água'], [740]);
    expect(peitoral.attributes['Resistência ao fogo'], [740]);
    expect(peitoral.attributes['Resistência à terra'], [740]);
    // Both present in the JSON, both zero on this piece — left out.
    expect(peitoral.attributes.containsKey('Armadura'), isFalse);
    expect(peitoral.attributes.containsKey('MP'), isFalse);
  });

  test('two rings sharing one item id carry different stats, '
      'read by position and not by id', () {
    // detail_pw126_5424.html wears `Anel da Estrela Cadente` (id 6175)
    // twice — in slots 0 and 1 — and the two copies are rolled
    // differently: one gives 81 defence, the other 60. Joining by id alone
    // could not tell them apart; the parser pairs the worn piece with the
    // `Equipamento` tab entry at the same position instead.
    final aneis =
        parseEquippedItems126(arqueiro).where((i) => i.itemId == 6175).toList()
          ..sort((a, b) => a.slot.compareTo(b.slot));

    expect(aneis, hasLength(2));
    expect(aneis[0].slot, 0);
    expect(aneis[1].slot, 1);
    expect(aneis[0].attributes['Defesa'], [81]);
    expect(aneis[1].attributes['Defesa'], [60]);
  });

  test('parses sex off the character sheet', () {
    expect(parseSex126(comSeisArmas), 'Feminino');
    expect(parseSex126(arqueiro), 'Feminino');
  });

  test('parses the class off the header badge', () {
    expect(parseClasse126(comSeisArmas), 'Arqueiro');
    expect(parseClasse126(arqueiro), 'Arqueiro');
  });
}
