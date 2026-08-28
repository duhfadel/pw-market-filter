import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/search/domain/search_query.dart';
import 'package:pw_market_filter/features/search/ui/widgets/character_card.dart';
import 'package:pw_market_filter/market/market_index.dart';

/// The card is what the whole tool hands back, and it had no test of its own.
final _index = MarketIndex(
  server: 'pw187',
  collectedAt: DateTime.utc(2026, 8, 19),
  attributes: const ['Nível de Ataque'],
  items: const {50206: MarketItem(name: '★★★Dilacerador Raivoso', grade: 6)},
  countedItems: const {'Relíquia Maravilha: Arma': 50410},
  runes: const {
    52220: RuneKind(type: 'Argêntea', level: 6),
    52183: RuneKind(type: 'Áurea', level: 9),
  },
  characters: const [],
);

MarketCharacter _character({
  String sex = '',
  Map<int, int> counts = const {},
  Anecdotes? anecdotes,
  String realm = '',
  String path = '',
  List<int> runes = const [],
}) => MarketCharacter(
  roleId: 64112,
  name: 'Leandrim',
  characterClass: 'Bardo',
  occupation: 1,
  level: 105,
  price: 1000,
  fame: 1,
  cultivation: 'Leal',
  sex: sex,
  counts: counts,
  anecdotes: anecdotes,
  realm: realm,
  path: path,
  runes: runes,
  equipped: const [
    EquippedItem(
      slot: 10,
      itemId: 50206,
      refine: 12,
      stones: [],
      attributes: {0: 70},
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  MarketCharacter character, {
  SearchQuery query = const SearchQuery(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: CharacterCard(
            character: character,
            index: _index,
            query: query,
          ),
        ),
      ),
    ),
  );
}

/// The glyph drawn for the sex, or null when none is.
Icon? _sexIcon(WidgetTester tester) {
  final icons = tester.widgetList<Icon>(find.byType(Icon));
  for (final icon in icons) {
    if (icon.icon == Icons.female || icon.icon == Icons.male) return icon;
  }
  return null;
}

void main() {
  const relic = 'Relíquia Maravilha: Arma';

  testWidgets('the anecdote line says how much of it is done', (tester) async {
    // 1265 of 2756 is a division nobody does in their head while scanning a
    // grid of forty cards.
    await _pump(
      tester,
      _character(anecdotes: const Anecdotes(done: 1265, total: 2756)),
      query: const SearchQuery(minAnecdotes: 1000),
    );

    expect(find.text('1265 de 2756  ·  46%'), findsOneWidget);
  });

  testWidgets('ordering by anecdotes prints them without a filter', (
    tester,
  ) async {
    // The card states what answered the question. When the list is ordered by
    // the anecdotes, the count is why this card is where it is — asking for a
    // minimum as well, only to see the number, would throw away the results
    // below it.
    await _pump(
      tester,
      _character(anecdotes: const Anecdotes(done: 1265, total: 2756)),
      query: const SearchQuery(order: ResultOrder.mostAnecdotes),
    );

    expect(find.text('Anedotas'), findsOneWidget);
  });

  testWidgets('a marked item is printed without any filter in force', (
    tester,
  ) async {
    await _pump(
      tester,
      _character(counts: const {50410: 16}),
      query: const SearchQuery(shownOwned: {relic}),
    );

    expect(find.text(relic), findsOneWidget);
    expect(find.text('carrega 16'), findsOneWidget);
  });

  testWidgets('carrying none of a marked item says so', (tester) async {
    await _pump(
      tester,
      _character(counts: const {50410: 0}),
      query: const SearchQuery(shownOwned: {relic}),
    );

    expect(find.text('carrega 0'), findsOneWidget);
  });

  testWidgets('an unread inventory says nothing rather than zero', (
    tester,
  ) async {
    // Absent is not a number. The line is simply not drawn.
    await _pump(
      tester,
      _character(),
      query: const SearchQuery(shownOwned: {relic}),
    );

    expect(find.text(relic), findsNothing);
  });

  testWidgets('a woman gets the pink glyph beside the class', (tester) async {
    // Bardo on purpose: it is the one class this server has in both, which is
    // why the sex cannot be read off the class and has to be shown.
    await _pump(tester, _character(sex: 'Feminino'));

    expect(find.text('nv 105 · Bardo'), findsOneWidget);
    expect(_sexIcon(tester)?.icon, Icons.female);
    expect(_sexIcon(tester)?.color, PWColors.female);
  });

  testWidgets('a man gets the blue one', (tester) async {
    await _pump(tester, _character(sex: 'Masculino'));

    expect(_sexIcon(tester)?.icon, Icons.male);
    expect(_sexIcon(tester)?.color, PWColors.male);
  });

  testWidgets('the glyph says in words what the colour says', (tester) async {
    // A coloured glyph on its own is opaque to anything that cannot see it,
    // and it is the only place on the card where nothing is written.
    await _pump(tester, _character(sex: 'Feminino'));

    expect(_sexIcon(tester)?.semanticLabel, 'Feminino');
  });

  testWidgets('a character collected before the field draws no glyph', (
    tester,
  ) async {
    // Not a grey placeholder standing for "we do not know".
    await _pump(tester, _character());

    expect(find.text('nv 105 · Bardo'), findsOneWidget);
    expect(_sexIcon(tester), isNull);
  });

  testWidgets('a value the site never prints draws nothing', (tester) async {
    await _pump(tester, _character(sex: 'Outro'));

    expect(_sexIcon(tester), isNull);
  });

  testWidgets('the realm sits under the class, as written', (tester) async {
    await _pump(tester, _character(realm: 'Céu Majestoso II'));

    expect(find.text('Céu Majestoso II'), findsOneWidget);
  });

  testWidgets('the path is a badge carrying the word and the colour', (
    tester,
  ) async {
    await _pump(tester, _character(path: 'Evil'));

    expect(find.text('EVIL'), findsOneWidget);
  });

  testWidgets('no path read draws no badge, not a third state', (tester) async {
    // The whole reason the tinted-card idea was dropped: "no tint" would have
    // read as a path of its own.
    await _pump(tester, _character());

    expect(find.text('EVIL'), findsNothing);
    expect(find.text('GOD'), findsNothing);
  });

  testWidgets('the rune strip shows one level per slot, in order', (
    tester,
  ) async {
    await _pump(tester, _character(runes: const [52220, 52183]));

    // No heading any more: the level rides the corner of each icon.
    expect(find.text('6'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);
  });

  testWidgets('a character with no runes grows no strip', (tester) async {
    await _pump(tester, _character());

    expect(find.byType(FittedBox), findsNothing);
  });

  testWidgets('ten runes are scaled to fit rather than run off the card', (
    tester,
  ) async {
    // Nine slots exist in the market and ten would overflow the row; the strip
    // shrinks instead of spilling past the border.
    await _pump(
      tester,
      _character(
        runes: const [
          52220,
          52220,
          52220,
          52220,
          52220,
          52220,
          52220,
          52220,
          52220,
          52183,
        ],
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(FittedBox), findsOneWidget);
  });
}
