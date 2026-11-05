@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/search/domain/active_filters.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/features/search/domain/stone_set_criterion.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/set_stones.dart';

/// O filtro visto de fora: o que ele corta, o que viaja no link, e o chip.
void main() {
  final ficheiro = File('web/market_index.json');
  if (!ficheiro.existsSync()) return;
  final index = MarketIndex.fromJson(
    jsonDecode(ficheiro.readAsStringSync()) as Map<String, dynamic>,
  );

  int quantos(StoneKind kind, int level) => index.characters
      .where(
        (c) => matchesQuery(
          index,
          c,
          SearchQuery(
            stoneSet: StoneSetCriterion(kind: kind, level: level),
          ),
        ),
      )
      .length;

  test('o filtro corta o mercado, e corta muito', () {
    // Um conjunto completo é raro: nenhum destes pode aproximar-se do
    // mercado inteiro, senão o filtro não ensina nada — a lição do
    // `presets_test`. Mas também não pode dar zero.
    for (final s in setsDisponiveis) {
      final n = quantos(s.kind, s.level);
      expect(n, greaterThan(0), reason: '${setLabel(s.kind, s.level)} dá zero');
      expect(
        n,
        lessThan(index.characters.length ~/ 4),
        reason:
            '${setLabel(s.kind, s.level)} deixa um quarto do mercado no ecrã',
      );
    }
  });

  test('pedir mais nunca devolve mais gente', () {
    // O «pelo menos» tem de ser monótono: quem passa em +3 passa em +2.
    for (final kind in StoneKind.values) {
      final niveis = setsDisponiveis
          .where((s) => s.kind == kind)
          .map((s) => s.level)
          .toList();
      for (var i = 1; i < niveis.length; i++) {
        expect(
          quantos(kind, niveis[i]),
          lessThanOrEqualTo(quantos(kind, niveis[i - 1])),
        );
      }
    }
  });

  test('quem passa tem mesmo a pedra nas sete peças', () {
    final passam = index.characters
        .where(
          (c) => matchesQuery(
            index,
            c,
            const SearchQuery(
              stoneSet: StoneSetCriterion(kind: StoneKind.attack, level: 3),
            ),
          ),
        )
        .toList();
    expect(passam, isNotEmpty);
    for (final c in passam.take(20)) {
      final comPedra = <int>{};
      for (final item in c.equipped) {
        if (!setSlots.contains(item.slot)) continue;
        final acessorio = accessorySlots.contains(item.slot);
        for (final id in item.stones) {
          final p = stoneById[id];
          if (p != null &&
              p.kind == StoneKind.attack &&
              p.level >= 3 &&
              p.accessory == acessorio) {
            comPedra.add(item.slot);
          }
        }
      }
      expect(comPedra, setSlots, reason: '${c.name} passou sem as sete');
    }
  });

  SearchQuery daUrl(String consulta) => decodeQuery(
    Uri.splitQueryString(consulta).map((k, v) => MapEntry(k, [v])),
    index,
  );

  test('o conjunto viaja no link e volta inteiro', () {
    for (final s in setsDisponiveis) {
      final q = SearchQuery(
        stoneSet: StoneSetCriterion(kind: s.kind, level: s.level),
      );
      final voltou = daUrl(encodeQuery(q, index));
      expect(voltou.stoneSet, q.stoneSet, reason: setLabel(s.kind, s.level));
    }
  });

  test('um conjunto que não existe num link antigo é ignorado', () {
    // `pedras=d1` pediria uma pedra que o jogo não tem; aceitar devolveria
    // uma grelha vazia sem nada a explicar porquê.
    expect(daUrl('pedras=d1').stoneSet, isNull);
    expect(daUrl('pedras=z9').stoneSet, isNull);
    expect(daUrl('pedras=a').stoneSet, isNull);
  });

  test('o chip diz qual conjunto está em vigor, e desliga-o', () {
    const q = SearchQuery(
      stoneSet: StoneSetCriterion(kind: StoneKind.defence, level: 3),
    );
    final chips = activeFilters(index, q);
    final chip = chips.firstWhere((f) => f.label.startsWith('pedras'));
    expect(chip.label, 'pedras Defesa +3');
    expect(chip.remove(q).stoneSet, isNull);
  });
}
