@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/stone_set_criterion.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/set_stones.dart';

/// A tabela das nove pedras, cravada contra o mercado colhido.
///
/// **Um id inventado dá um filtro que não acha ninguém, e *ninguém tem este
/// conjunto* é uma resposta que parece verdadeira** — a mesma razão pela qual
/// `combo_test` crava os ids das cartas. Estes nove saíram de 44 páginas do
/// mercado a 04/11/2026; se o jogo os renumerar, é aqui que se vê.
void main() {
  final ficheiro = File('web/market_index.json');
  if (!ficheiro.existsSync()) return;
  final index = MarketIndex.fromJson(
    jsonDecode(ficheiro.readAsStringSync()) as Map<String, dynamic>,
  );

  test('cada pedra da tabela existe no mercado, encaixada', () {
    final encaixadas = <int, int>{};
    for (final c in index.characters) {
      for (final item in c.equipped) {
        for (final id in item.stones) {
          encaixadas[id] = (encaixadas[id] ?? 0) + 1;
        }
      }
    }
    for (final pedra in setStones) {
      expect(
        encaixadas[pedra.id] ?? 0,
        greaterThan(0),
        reason:
            '${pedra.name} (${pedra.id}) não aparece encaixada em ninguém. '
            'Ou o id está errado, ou o jogo renumerou a pedra.',
      );
    }
  });

  test('cada pedra só aparece na família de peças que lhe cabe', () {
    // A Pedra do Demônio e a Pedra de Yan Luo são ambas Ataque +3 e não se
    // substituem. Se uma aparecer no slot da outra, a separação que
    // `stoneSetLevel` faz deixou de corresponder ao jogo.
    for (final pedra in setStones) {
      final slots = <int>{};
      for (final c in index.characters) {
        for (final item in c.equipped) {
          if (item.stones.contains(pedra.id)) slots.add(item.slot);
        }
      }
      final esperados = pedra.accessory ? accessorySlots : equipmentSlots;
      expect(
        slots.where(setSlots.contains),
        everyElement(isIn(esperados)),
        reason:
            '${pedra.name} apareceu numa peça da outra família. '
            'slots vistos: ${slots.toList()..sort()}',
      );
    }
  });

  test('o nível do conjunto é o da pior peça, nunca a soma', () {
    var conferidos = 0;
    for (final c in index.characters) {
      for (final kind in StoneKind.values) {
        final nivel = stoneSetLevel(c, kind);
        if (nivel == null) continue;

        final porSlot = <int, int>{};
        for (final item in c.equipped) {
          if (!setSlots.contains(item.slot)) continue;
          final acessorio = accessorySlots.contains(item.slot);
          for (final id in item.stones) {
            final p = stoneById[id];
            if (p == null || p.kind != kind || p.accessory != acessorio) {
              continue;
            }
            final atual = porSlot[item.slot];
            if (atual == null || p.level > atual) porSlot[item.slot] = p.level;
          }
        }
        expect(porSlot.length, setSlots.length);
        expect(nivel, porSlot.values.reduce((a, b) => a < b ? a : b));
        conferidos++;
      }
    }
    expect(
      conferidos,
      greaterThan(0),
      reason: 'ninguém no mercado tem conjunto nenhum — o teste não provou nada',
    );
  });

  test('faltando uma peça, não há conjunto', () {
    // O que o dono pediu em voz alta: «se alguma parte não tiver, não
    // aparecerá». A quem falte exactamente uma das sete tem de dar nulo.
    var achou = false;
    for (final c in index.characters) {
      for (final kind in StoneKind.values) {
        final comPedra = <int>{};
        for (final item in c.equipped) {
          if (!setSlots.contains(item.slot)) continue;
          final acessorio = accessorySlots.contains(item.slot);
          if (item.stones.any((id) {
            final p = stoneById[id];
            return p != null && p.kind == kind && p.accessory == acessorio;
          })) {
            comPedra.add(item.slot);
          }
        }
        if (comPedra.length == setSlots.length - 1) {
          expect(stoneSetLevel(c, kind), isNull);
          achou = true;
        }
      }
    }
    expect(achou, isTrue, reason: 'ninguém no mercado está a uma peça do set');
  });

  test('Defesa +1 não é oferecida, porque a pedra não existe', () {
    expect(
      setStones.any((p) => p.kind == StoneKind.defence && p.level == 1),
      isFalse,
    );
    expect(
      setsDisponiveis.any((s) => s.kind == StoneKind.defence && s.level == 1),
      isFalse,
    );
  });

  test('as sete peças são as que o dono escolheu, e não as nove', () {
    // A capa e a arma aceitam estas pedras e ficam de fora de propósito:
    // medido a 04/11/2026, incluí-las levava o conjunto de Ataque +3 de 32
    // pessoas para 6. Se alguém as acrescentar sem medir outra vez, este
    // teste diz que foi decisão e não esquecimento.
    expect(setSlots, {8, 2, 3, 4, 7, 9, 5});
    expect(setSlots.contains(6), isFalse, reason: 'a capa fica de fora');
    expect(setSlots.contains(10), isFalse, reason: 'a arma fica de fora');
  });
}
