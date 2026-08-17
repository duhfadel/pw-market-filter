import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/theme/pw_colors.dart';
import 'package:pw_market_filter/features/ads/ad_slot.dart';

/// The slot's rules are about trust, not layout. This screen tells visitors it
/// sells nothing, and an advert that arrives unlabelled — or wearing the same
/// surface as a result card — turns that sentence into a lie without anybody
/// editing it.
Future<void> _pump(WidgetTester tester, AdConfig config) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: AdSlot(config: config)),
  ),
);

void main() {
  testWidgets('an empty slot takes no room at all', (tester) async {
    // Not an empty bordered box: a space reserved for nothing is a hole.
    await _pump(tester, const AdConfig());

    expect(find.text('PUBLICIDADE'), findsNothing);
    expect(tester.getSize(find.byType(AdSlot)), Size.zero);
  });

  testWidgets('a banner always says it is one', (tester) async {
    await _pump(tester, const AdConfig(active: true));

    expect(find.text('PUBLICIDADE'), findsOneWidget);
  });

  testWidgets('the slot never wears a result card\'s surface', (tester) async {
    // `PWColors.surface` is what a character card is painted in. An advert in
    // that colour is an advert being read as a listing.
    await _pump(tester, const AdConfig(active: true));

    final box = tester.widget<Container>(
      find
          .descendant(of: find.byType(AdSlot), matching: find.byType(Container))
          .first,
    );
    expect(box.color, isNot(PWColors.surface));
    expect(box.color, PWColors.background);
  });

  testWidgets('with nobody buying it, the space offers itself', (tester) async {
    await _pump(tester, const AdConfig(active: true));

    expect(find.textContaining('Quer anunciar aqui'), findsOneWidget);
  });

  testWidgets('the compact slot is shorter than the full one', (tester) async {
    // The filter is the densest screen on the site; an advert there takes half.
    await _pump(tester, const AdConfig(active: true));
    final cheio = tester.getSize(find.byType(AdSlot)).height;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdSlot(compact: true, config: AdConfig(active: true)),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AdSlot)).height, lessThan(cheio));
  });
}
