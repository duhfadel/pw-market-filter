import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/menu_view.dart';

/// The guild panel's menu-hub. `sala_guerras` has no business on the players
/// screen — the server's RLS mirrors this — so its card must be absent, not
/// merely dimmed, the same distinction `SecaoGuild.visivelPara` encodes.
void main() {
  Future<void> montar(WidgetTester tester, Papel papel) async {
    await tester.pumpWidget(MaterialApp(home: MenuView(papel: papel)));
    await tester.pumpAndSettle();
  }

  testWidgets('sala_guerras sees its own room but not Jogadores', (tester) async {
    await montar(tester, Papel.salaGuerras);

    expect(find.text('Sala de Guerras'), findsOneWidget);
    expect(find.text('Jogadores'), findsNothing);
  });

  testWidgets('admin sees all three sections', (tester) async {
    await montar(tester, Papel.admin);

    expect(find.text('Jogadores'), findsOneWidget);
    expect(find.text('Sala de Guerras'), findsOneWidget);
    expect(find.text('Financeiro'), findsOneWidget);
  });

  testWidgets('staff_basico sees Jogadores and Sala de Guerras, not Financeiro', (tester) async {
    await montar(tester, Papel.staffBasico);

    expect(find.text('Jogadores'), findsOneWidget);
    expect(find.text('Sala de Guerras'), findsOneWidget);
    expect(find.text('Financeiro'), findsNothing);
  });
}
