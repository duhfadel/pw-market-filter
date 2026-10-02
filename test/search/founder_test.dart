import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pw_market_filter/features/search/domain/active_filters.dart';
import 'package:pw_market_filter/features/search/domain/matcher.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/domain/search_query_url.dart';
import 'package:pw_market_filter/features/search/ui/search_state.dart';
import 'package:pw_market_filter/features/search/ui/search_view_model.dart';
import 'package:pw_market_filter/features/search/ui/widgets/filter_panel.dart';
import 'package:pw_market_filter/market/index_repository.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The founder packs: a title the game no longer hands out, asked for as a
/// floor.
MarketCharacter _character(int roleId, String name, {int? founderTier}) =>
    MarketCharacter(
      roleId: roleId,
      name: name,
      characterClass: 'Guerreiro',
      occupation: 1,
      level: 105,
      price: 100 * roleId,
      fame: 0,
      cultivation: 'Leal',
      equipped: const [],
      founderTier: founderTier,
    );

MarketIndex _index({required bool comFundadores}) => MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 10, 2),
  attributes: const [],
  items: const {},
  characters: [
    _character(1, 'Zé', founderTier: comFundadores ? 4 : null),
    _character(2, 'Maloquivera', founderTier: comFundadores ? 10 : null),
    _character(3, 'Ninguém'),
  ],
);

Future<SearchViewModel> _pump(
  WidgetTester tester, {
  required bool comFundadores,
}) async {
  tester.view.physicalSize = const Size(1400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient(
    (_) async => http.Response.bytes(
      utf8.encode(jsonEncode(_index(comFundadores: comFundadores).toJson())),
      200,
    ),
  );
  final viewModel = SearchViewModel(IndexRepository(client));
  await viewModel.load();

  await tester.pumpWidget(
    BlocProvider.value(
      value: viewModel,
      child: MaterialApp(
        home: Scaffold(
          body: BlocBuilder<SearchViewModel, SearchState>(
            builder: (context, state) =>
                FilterPanel(state: state as SearchReady, viewModel: viewModel),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return viewModel;
}

void main() {
  final mercado = _index(comFundadores: true).characters;

  List<String> passam(SearchQuery query) => [
    for (final c in mercado)
      if (matchesQuery(_index(comFundadores: true), c, query)) c.name,
  ];

  group('the filter is a floor', () {
    test('qualquer fundador takes every rung and nobody else', () {
      expect(passam(const SearchQuery(minFounderTier: 1)), [
        'Zé',
        'Maloquivera',
      ]);
    });

    test('a rung takes itself and everything above it', () {
      expect(passam(const SearchQuery(minFounderTier: 4)), [
        'Zé',
        'Maloquivera',
      ]);
      expect(passam(const SearchQuery(minFounderTier: 5)), ['Maloquivera']);
      expect(passam(const SearchQuery(minFounderTier: 10)), ['Maloquivera']);
    });

    test('having no title fails, the same way an unread realm fails', () {
      // Never passing by being unknown: that is how somebody ends up on a
      // list he was never measured for.
      expect(
        passam(const SearchQuery(minFounderTier: 1)),
        isNot(contains('Ninguém')),
      );
    });

    test('asking nothing leaves the market alone', () {
      expect(passam(const SearchQuery()).length, 3);
      expect(const SearchQuery(minFounderTier: 1).isEmpty, isFalse);
      expect(const SearchQuery().isEmpty, isTrue);
    });
  });

  group('the link', () {
    final index = _index(comFundadores: true);

    test('travels as the figure the game prints, not as the rung', () {
      // `fundador=X`, never `fundador=10`: the rung is arithmetic this app
      // happens to do today, the figure is what is written on the title.
      expect(
        encodeQuery(const SearchQuery(minFounderTier: 10), index),
        contains('fundador=X'),
      );
      expect(
        encodeQuery(const SearchQuery(minFounderTier: 4), index),
        contains('fundador=IV'),
      );
    });

    test('comes back the same on the other side', () {
      for (var grau = 1; grau <= 10; grau++) {
        final query = SearchQuery(minFounderTier: grau);
        expect(
          decodeQuery(
            Uri.parse('?${encodeQuery(query, index)}').queryParametersAll,
            index,
          ).minFounderTier,
          grau,
          reason: 'rung $grau did not survive the trip',
        );
      }
    });

    test('a figure this version cannot place drops the filter', () {
      // Dropped and not widened to *qualquer*: a link that silently asks for
      // less still puts a count on screen, and the count looks like an answer.
      expect(
        decodeQuery(
          Uri.parse('?fundador=XI').queryParametersAll,
          index,
        ).minFounderTier,
        isNull,
      );
      expect(
        decodeQuery(
          Uri.parse('?fundador=10').queryParametersAll,
          index,
        ).minFounderTier,
        isNull,
      );
      expect(
        decodeQuery(
          Uri.parse('?fundador=').queryParametersAll,
          index,
        ).minFounderTier,
        isNull,
      );
    });
  });

  group('the chip', () {
    test('names the pack, and the lowest rung names none', () {
      final index = _index(comFundadores: true);
      expect(
        activeFilters(
          index,
          const SearchQuery(minFounderTier: 6),
        ).map((f) => f.label),
        contains('Fundador VI ou mais'),
      );
      // `1` is the floor at its lowest — the *qualquer fundador* entry — so
      // naming a pack there would name one the person never picked.
      expect(
        activeFilters(
          index,
          const SearchQuery(minFounderTier: 1),
        ).map((f) => f.label),
        contains('Fundador'),
      );
    });

    test('takes the filter off again', () {
      final index = _index(comFundadores: true);
      final chip = activeFilters(
        index,
        const SearchQuery(minFounderTier: 6),
      ).firstWhere((f) => f.label.startsWith('Fundador'));

      expect(
        chip.remove(const SearchQuery(minFounderTier: 6)).minFounderTier,
        isNull,
      );
    });
  });

  group('the section', () {
    testWidgets('a market with no founder collected grows no section', (
      tester,
    ) async {
      // Every index written before 2026-10-02 is this one. A menu whose only
      // entry empties the results reads as a broken page.
      await _pump(tester, comFundadores: false);

      expect(find.text('FUNDADOR'), findsNothing);
    });

    testWidgets('offers only the packs somebody on screen actually bought', (
      tester,
    ) async {
      await _pump(tester, comFundadores: true);

      await tester.tap(find.text('FUNDADOR'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ninguém em especial'));
      await tester.pumpAndSettle();

      expect(find.text('Qualquer fundador'), findsOneWidget);
      expect(find.text('Fundador X'), findsOneWidget);
      // Rung 4 is the lowest the market holds, which is what *qualquer* means
      // here — a second entry for it would be two doing one job.
      expect(find.text('Fundador IV'), findsNothing);
      // And never a pack nobody bought.
      expect(find.text('Fundador VII'), findsNothing);
    });

    testWidgets('choosing a pack narrows the market and counts as a filter', (
      tester,
    ) async {
      final viewModel = await _pump(tester, comFundadores: true);

      viewModel.setMinFounderTier(10);
      await tester.pumpAndSettle();

      final state = viewModel.state as SearchReady;
      expect(state.results.map((c) => c.name), ['Maloquivera']);
      expect(find.text('FUNDADOR'), findsOneWidget);
    });

    testWidgets('a rung the market no longer holds does not throw the page', (
      tester,
    ) async {
      // The month-old-link hazard, met here by a fourth door: `fundador=VII`
      // against a market whose founders are IV and X. A `DropdownButton`
      // asserts on a value absent from its own items, which is a crash and
      // not a wrong answer.
      final viewModel = await _pump(tester, comFundadores: true);

      viewModel.setMinFounderTier(7);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tester.tap(find.text('FUNDADOR'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      // Shown as *qualquer*, which widens by a rung rather than throwing the
      // page away — and the filter itself still asks what the link asked.
      expect(find.text('Qualquer fundador'), findsOneWidget);
      expect((viewModel.state as SearchReady).query.minFounderTier, 7);
    });

    testWidgets('the note quotes the game rather than promising a future', (
      tester,
    ) async {
      // "these can no longer be obtained" is a claim about what The Classic
      // will do next; "Recompensa exclusiva de pré-lançamento" is what the
      // title itself says. This site speaks for nobody but itself.
      await _pump(tester, comFundadores: true);

      await tester.tap(find.text('FUNDADOR'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Recompensa exclusiva de pré-lançamento'),
        findsOneWidget,
      );
      expect(find.textContaining('montarias, voos'), findsOneWidget);
    });
  });
}
