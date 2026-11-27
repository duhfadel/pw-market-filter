import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/calculos.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/widgets/grafico_fin.dart';

/// Painting is hard to assert on, so this test only confirms the chart
/// mounts and draws without throwing — the same bar it checks for the
/// empty-list placeholder.
void main() {
  testWidgets('renders the bars, the legend and the gasto fixo line '
      'without throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraficoFin(
            meses: [
              MesFinanceiro(
                ano: 2026,
                mes: 10,
                entrada: 1000,
                despesa: 400,
                staff: 200,
              ),
              MesFinanceiro(
                ano: 2026,
                mes: 11,
                entrada: 1500,
                despesa: 300,
                staff: 600,
              ),
            ],
            gastoFixo: 500,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.textContaining('Gasto fixo'), findsOneWidget);
  });

  testWidgets('shows a placeholder instead of a blank chart when there are '
      'no lançamentos', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GraficoFin(meses: [], gastoFixo: 0)),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sem lançamentos ainda.'), findsOneWidget);
  });

  testWidgets('renders without throwing on a narrow viewport, where many '
      'months force the chart to scroll', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraficoFin(
            meses: List.generate(
              8,
              (i) => MesFinanceiro(
                ano: 2026,
                mes: (i % 12) + 1,
                entrada: 100 * (i + 1),
                despesa: 50 * (i + 1),
                staff: 20 * (i + 1),
              ),
            ),
            gastoFixo: 300,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
