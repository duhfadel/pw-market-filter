import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pw_market_filter/core/di/injection.dart';
import 'package:pw_market_filter/core/result/result.dart';
import 'package:pw_market_filter/features/guild/data/financeiro_repository.dart';
import 'package:pw_market_filter/features/guild/data/formacao_repository.dart';
import 'package:pw_market_filter/features/guild/data/jogadores_repository.dart';
import 'package:pw_market_filter/features/guild/domain/financeiro/lancamento.dart';
import 'package:pw_market_filter/features/guild/domain/guerra/formacao_guerra.dart';
import 'package:pw_market_filter/features/guild/domain/jogador.dart';
import 'package:pw_market_filter/features/guild/domain/papel.dart';
import 'package:pw_market_filter/features/guild/ui/financeiro/fin_view_model.dart';
import 'package:pw_market_filter/features/guild/ui/guerra/sala_view_model.dart';
import 'package:pw_market_filter/features/guild/ui/menu_view.dart';

/// The guild panel's menu-hub. `sala_guerras` has no business on the players
/// screen — the server's RLS mirrors this — so its card must be absent, not
/// merely dimmed, the same distinction `SecaoGuild.visivelPara` encodes.
class _FakeFormacaoRepository implements FormacaoRepository {
  @override
  Future<Result<FormacaoCarregada>> carregar() async =>
      Success(FormacaoCarregada(FormacaoGuerra(grupos: const [])));

  @override
  Future<Result<String?>> salvar(FormacaoGuerra f) async => const Success(null);
}

class _FakeJogadoresRepository implements JogadoresRepository {
  @override
  Future<Result<List<Jogador>>> lista() async => const Success([]);

  @override
  Future<Result<void>> criar(Jogador j) async => const Success<void>(null);

  @override
  Future<Result<String>> subirPrint(
    Uint8List bytes,
    String nomeArquivo,
  ) async => Success(nomeArquivo);

  @override
  Future<Result<void>> editar(String id, Map<String, dynamic> campos) async =>
      const Success<void>(null);
}

class _FakeFinanceiroRepository implements FinanceiroRepository {
  @override
  Future<Result<List<Lancamento>>> lista() async => const Success([]);

  @override
  Future<Result<void>> adicionar(Lancamento l) async => const Success<void>(null);

  @override
  Future<Result<void>> remover(String id) async => const Success<void>(null);
}

void main() {
  Future<void> montar(WidgetTester tester, Papel papel) async {
    await tester.pumpWidget(MaterialApp(home: MenuView(papel: papel)));
    await tester.pumpAndSettle();
  }

  setUp(() {
    // The sala and financeiro cards now navigate for real, which means
    // their views resolve their view models out of `getIt` exactly as
    // production does — so fakes have to stand in for every repository they
    // need, the same registration `guerra/sala_view_test.dart` and
    // `financeiro/fin_view_test.dart` make.
    getIt.registerFactory<SalaGuerrasViewModel>(
      () => SalaGuerrasViewModel(
        _FakeFormacaoRepository(),
        _FakeJogadoresRepository(),
      ),
    );
    getIt.registerFactory<FinanceiroViewModel>(
      () => FinanceiroViewModel(
        _FakeFinanceiroRepository(),
        _FakeJogadoresRepository(),
      ),
    );
  });

  tearDown(() {
    if (getIt.isRegistered<SalaGuerrasViewModel>()) {
      getIt.unregister<SalaGuerrasViewModel>();
    }
    if (getIt.isRegistered<FinanceiroViewModel>()) {
      getIt.unregister<FinanceiroViewModel>();
    }
  });

  testWidgets('sala_guerras sees its own room but not Jogadores', (
    tester,
  ) async {
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

  testWidgets(
    'staff_basico sees Jogadores and Sala de Guerras, not Financeiro',
    (tester) async {
      await montar(tester, Papel.staffBasico);

      expect(find.text('Jogadores'), findsOneWidget);
      expect(find.text('Sala de Guerras'), findsOneWidget);
      expect(find.text('Financeiro'), findsNothing);
    },
  );

  testWidgets('the financeiro card is no longer dimmed, now that it is built', (
    tester,
  ) async {
    await montar(tester, Papel.admin);

    final salaTitulo = tester.widget<Text>(find.text('Sala de Guerras'));
    final financeiroTitulo = tester.widget<Text>(find.text('Financeiro'));

    // All three cards are `pronta` now, so the title color is the same one
    // as every other built section's, not the dimmed `textMuted` the
    // placeholder used to draw.
    expect(financeiroTitulo.style?.color, salaTitulo.style?.color);
  });

  testWidgets('tapping the sala card pushes SalaGuerrasView', (tester) async {
    await montar(tester, Papel.admin);

    await tester.tap(find.text('Sala de Guerras'));
    await tester.pumpAndSettle();

    // SalaGuerrasView's own AppBar title ("Sala de guerras", lowercase g),
    // distinct from the menu card's title just tapped.
    expect(find.text('Sala de guerras'), findsOneWidget);
    expect(find.text('Disponíveis (0)'), findsOneWidget);
  });

  testWidgets('tapping the financeiro card pushes FinanceiroView', (
    tester,
  ) async {
    await montar(tester, Papel.admin);

    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();

    // FinanceiroView's own content once loaded — distinct from the menu
    // card's title just tapped, since the AppBar titles are the same word.
    expect(find.text('Total da guild'), findsOneWidget);
  });
}
