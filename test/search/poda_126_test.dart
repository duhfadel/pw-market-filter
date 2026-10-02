import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/core/rotas.dart' as rotas;
import 'package:pw_market_filter/features/home/ui/widgets/cabecalho.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/presets.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';
import 'package:pw_market_filter/market/slot_names.dart';

import '../support/novidades_test_support.dart';

/// Task 5's pruning: a control reads its options from what the market has,
/// and that rule now covers the families 1.8.7 assumed — cards, the combo
/// built on them, the essence, runes, anecdotes, the celestial realm, and
/// the path — plus the slot names and the header's own version label.
///
/// **The group that matters most is the last one.** Pruning is precisely
/// where the version already in the air gets broken, so every assertion
/// about 1.8.7 below exists to prove the opposite of what the 1.2.6
/// assertions prove: that nothing which used to draw, draw somebody, or say
/// "1.8.7" has stopped doing so.
void main() {
  final file187 = File('web/market_index.json');
  final file126 = File('web/market_index_126.json');

  MarketIndex? index187;
  MarketIndex? index126;

  setUpAll(() {
    if (file187.existsSync()) {
      index187 = MarketIndex.fromJson(
        jsonDecode(file187.readAsStringSync()) as Map<String, dynamic>,
      );
    }
    if (file126.existsSync()) {
      index126 = MarketIndex.fromJson(
        jsonDecode(file126.readAsStringSync()) as Map<String, dynamic>,
      );
    }
  });

  group('1.2.6: the chips this collection cannot back do not exist', () {
    test('cards, the Nuema combo and the essence have no chip', () {
      final index = index126;
      if (index == null) return;
      final labels = presetsFor(index).map((p) => p.label).toSet();

      expect(labels, isNot(contains('Seis cartas S')));
      expect(labels, isNot(contains('Portal de Nuema')));
      expect(labels, isNot(contains('5 essências ou mais')));
    });

    test('every chip that is offered still finds somebody', () {
      final index = index126;
      if (index == null) return;
      for (final preset in presetsFor(index)) {
        expect(
          runQuery(index, preset.query),
          isNotEmpty,
          reason: '"${preset.label}" matches nobody',
        );
      }
    });
  });

  group('1.2.6: the sections with nothing to show have nothing to show', () {
    test('no character carries a card, a rune, an anecdote, a realm or a '
        'counted item', () {
      final index = index126;
      if (index == null) return;

      expect(index.characters.any((c) => c.cards.isNotEmpty), isFalse);
      expect(index.runes, isEmpty);
      expect(index.characters.any((c) => c.anecdotes != null), isFalse);
      expect(index.characters.any((c) => c.realm.isNotEmpty), isFalse);
      expect(index.countedItems, isEmpty);
    });

    test('the path is pending, not detected — every character reads empty', () {
      // Not cancelled: the owner decided 01/10/2026 it stays once the
      // collector gains skills. Nothing here may guess it in the meantime,
      // so the only honest state today is "unknown for everybody".
      final index = index126;
      if (index == null) return;
      expect(index.characters.any((c) => c.path.isNotEmpty), isFalse);
    });
  });

  group('1.2.6: the eleven slots read their own table', () {
    test('slot 10 is still the weapon — the one number both markets share', () {
      final index = index126;
      if (index == null) return;
      expect(slotLabel(weaponSlot, index), 'Arma');
    });

    test('the rings are 0 and 1 here, not 1.8.7\'s 18 and 19', () {
      final index = index126;
      if (index == null) return;
      expect(slotLabel(0, index), 'Anel 1');
      expect(slotLabel(1, index), 'Anel 2');
      // 18 and 19 name nothing in this client at all — a fallback, never a
      // borrowed 1.8.7 name.
      expect(slotLabel(18, index), 'Slot 18');
      expect(slotLabel(19, index), 'Slot 19');
    });

    test(
      'the filter panel groups all eleven slots this market actually has',
      () {
        final index = index126;
        if (index == null) return;
        final grouped = slotGroupsFor(index).expand((g) => g.slots).toSet();
        expect(grouped, {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10});
      },
    );
  });

  group('1.8.7 loses nothing', () {
    test('every chip this version had keeps existing and finding somebody', () {
      final index = index187;
      if (index == null) return;
      final presets = presetsFor(index);
      final labels = presets.map((p) => p.label).toSet();

      for (final expected in [
        'Atq lvl UP5',
        'Def lvl UP5',
        'Arma de 70 ou mais',
        '5 essências ou mais',
        'Seis cartas S',
        'Portal de Nuema',
        'Até 100 TCC',
      ]) {
        expect(labels, contains(expected), reason: '"$expected" is missing');
      }
      for (final preset in presets) {
        expect(
          runQuery(index, preset.query),
          isNotEmpty,
          reason: '"${preset.label}" matches nobody',
        );
      }
    });

    test('every family the 1.2.6 pruning touches is still real here, so its '
        'section still has something to draw', () {
      final index = index187;
      if (index == null) return;

      expect(index.characters.any((c) => c.cards.isNotEmpty), isTrue);
      expect(index.runes, isNotEmpty);
      expect(index.characters.any((c) => c.anecdotes != null), isTrue);
      expect(index.characters.any((c) => c.realm.isNotEmpty), isTrue);
      expect(index.countedItems, isNotEmpty);
    });

    test('slot names and groups are exactly what they were before 1.2.6 '
        'existed', () {
      final index = index187;
      if (index == null) return;

      expect(slotLabel(weaponSlot, index), 'Arma');
      expect(slotLabel(18, index), 'Anel 1');
      expect(slotLabel(19, index), 'Anel 2');
      expect(slotGroupsFor(index), same(slotGroups));
    });
  });

  group('the header prints the version of the screen, not a constant', () {
    test('pw187 and pw126 both resolve to their own readable label', () {
      expect(rotas.versaoDoServidor(IndexRepository.pw187), '1.8.7');
      expect(rotas.versaoDoServidor(IndexRepository.pw126), '1.2.6');
    });

    testWidgets('Cabecalho draws whatever version it is given', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Cabecalho(wide: false, versao: '1.2.6')),
        ),
      );

      expect(find.text('1.2.6'), findsOneWidget);
      expect(find.text('1.8.7'), findsNothing);
    });

    testWidgets(
      'Cabecalho draws no version at all when none is given — the chooser '
      'and /novidades, which belong to neither market',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: Cabecalho(wide: false))),
        );

        expect(find.text('1.8.7'), findsNothing);
        expect(find.text('1.2.6'), findsNothing);
      },
    );

    testWidgets('the filter screen reads the version off its own index', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final index = MarketIndex(
        server: IndexRepository.pw126,
        collectedAt: DateTime.utc(2026, 10, 1),
        attributes: const [],
        items: const {},
        characters: const [
          MarketCharacter(
            roleId: 1,
            name: 'Qualquer',
            characterClass: 'Guerreiro',
            occupation: 1,
            level: 10,
            price: 10,
            fame: 1,
            cultivation: 'Leal',
            equipped: [],
          ),
        ],
      );

      final client = MockClient(
        (_) async =>
            http.Response.bytes(utf8.encode(jsonEncode(index.toJson())), 200),
      );
      final viewModel = SearchViewModel(IndexRepository(client));

      await tester.pumpWidget(
        BlocProvider.value(
          value: viewModel..load(),
          child: MaterialApp(home: comNovidades(const SearchView())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.2.6'), findsOneWidget);
      expect(find.text('1.8.7'), findsNothing);
    });
  });

  group('the path dropdown follows the same rule as every other section', () {
    MarketCharacter character(int roleId, {String path = ''}) =>
        MarketCharacter(
          roleId: roleId,
          name: 'P$roleId',
          characterClass: 'Guerreiro',
          occupation: 1,
          level: 105,
          price: 100,
          fame: 1,
          cultivation: 'Leal',
          equipped: const [],
          path: path,
        );

    MarketIndex indexWithPath(bool algumCaminho) => MarketIndex(
      server: 'pw187',
      collectedAt: DateTime.utc(2026, 10, 1),
      attributes: const [],
      items: const {},
      characters: [
        character(1, path: algumCaminho ? 'God' : ''),
        character(2),
      ],
    );

    Future<void> pumpPanel(WidgetTester tester, bool algumCaminho) async {
      tester.view.physicalSize = const Size(1400, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final client = MockClient(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode(indexWithPath(algumCaminho).toJson())),
          200,
        ),
      );
      final viewModel = SearchViewModel(IndexRepository(client));
      await viewModel.load();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocBuilder<SearchViewModel, SearchState>(
              bloc: viewModel,
              builder: (context, state) => FilterPanel(
                state: state as SearchReady,
                viewModel: viewModel,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'no character with a known path: the dropdown does not draw — 1.2.6 '
      'today',
      (tester) async {
        await pumpPanel(tester, false);
        expect(find.text('God e Evil'), findsNothing);
      },
    );

    testWidgets(
      'at least one character with a known path: the dropdown draws — '
      '1.8.7, unchanged',
      (tester) async {
        await pumpPanel(tester, true);
        expect(find.text('God e Evil'), findsOneWidget);
      },
    );
  });
}
